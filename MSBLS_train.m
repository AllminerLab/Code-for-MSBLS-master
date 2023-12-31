function [TrainingAccuracy,TestingAccuracy,Training_time,Testing_time] = MSBLS_train(A_train_x,A_train_y,B_train_x,B_train_y,A_test_x,A_test_y,B_test_x,B_test_y,s,C,N1,N2,N3)
% Learning Process of the proposed broad learning system
%Input: 
%---train_x,test_x, : the training data and learning data 
%---train_y,test_y : the label 
%---We: the randomly generated coefficients of feature nodes
%---wh:the randomly generated coefficients of enhancement nodes
%----s: the shrinkage parameter for enhancement nodes
%----C: the regularization parameter for sparse regualarization
%----N1: the number of feature nodes  per window
%----N2: the number of windows of feature nodes

%%%%%%%%%%%%%%interaction%%%%%%%%%%%%%%
tic
A_train_x = zscore(A_train_x')';
B_train_x = zscore(B_train_x')';
A_train_x = [A_train_x, 0.1 * ones(size(A_train_x,1),1)];
B_train_x = [B_train_x, 0.1 * ones(size(B_train_x,1),1)];
y=zeros(size(A_train_x,1) + size(B_train_x,1),N2*N1);
N1_temp = N1/2;
for i=1:N2
%% calculate X_A*W_B

C_RA_1 = 2*rand(size(A_train_x, 1), size(A_train_x, 2))-1;
C_RB_1 = 2*rand(size(A_train_x, 2), N1_temp)-1;
C_Rb_1 = 2*rand(size(A_train_x, 1), N1_temp)-1;

A_train_x_star = A_train_x + C_RA_1;

%Sparse auto encoder is used to generate sparse matrix W_B
B_W_temp_1 = 2*rand(size(A_train_x, 2), N1_temp)-1;
B_W_temp_2 = B_train_x * B_W_temp_1;
B_W_temp_2 = mapminmax(B_W_temp_2);
B_W{i} = sparse_bls(B_W_temp_2, B_train_x, 1e-3, 50)';
clear B_W_temp1 B_W_temp_1
% B_W{i} = 2*rand(size(A_train_x, 2), N1_temp)-1;%Sparse auto encoder is not used
B_W_star = B_W{i} + C_RB_1;
B_E_1 = A_train_x_star * B_W{i} + C_Rb_1;

A_E_2 = B_E_1 - C_RA_1 * B_W_star;

XAWB = A_E_2-C_Rb_1+C_RA_1 * C_RB_1;
C_12 = XAWB ;

%% calculate X_B*W_A
C_RB_2 = 2*rand(size(B_train_x, 1), size(B_train_x, 2))-1;
C_RA_2 = 2*rand(size(B_train_x, 2), N1_temp)-1;
C_Ra_2 = 2*rand(size(B_train_x, 1), N1_temp)-1;

B_train_x_star = B_train_x + C_RB_2;

%Sparse auto encoder is used to generate sparse matrix W_A
A_W_temp_1 = 2*rand(size(B_train_x, 2), N1_temp)-1;
A_W_temp_2 = A_train_x * A_W_temp_1;
A_W_temp_2 = mapminmax(A_W_temp_2);
A_W{i} = sparse_bls(A_W_temp_2, A_train_x, 1e-3, 50)';
clear A_W_temp1 A_W_temp_2
% A_W{i} = 2*rand(size(B_train_x, 2), N1_temp)-1;
A_W_star = A_W{i} + C_RA_2;
A_E_1 = B_train_x_star * A_W{i} + C_Ra_2;

B_E_2 = A_E_1 - C_RB_2 * A_W_star;

XBWA = B_E_2-C_Ra_2+C_RB_2 * C_RA_2;
C_21 = XBWA ;

%% calculate X_A*W_A
XAWA = A_train_x * A_W{i};
C_11 = XAWA ;

%% calculate X_B*W_B
XBWB = B_train_x * B_W{i};
C_22 = XBWB ;

%% 
%%%%%%%%%%%%%%%%%mapped feature%%%%%%%%%%%%%%%%%%%
C_temp = [C_11, C_12;
     C_21, C_22];
%Sparse auto encoder is used to generate sparse matrix C_W_1
C_temp_1 = 2*rand(size(C_temp,2), size(C_temp,2))-1;
C_temp_2 = C_temp * C_temp_1;
C_temp_2 = mapminmax(C_temp_2);
C_W_1{i} = sparse_bls(C_temp_2, C_temp, 1e-3, 50)';
clear beta4_temp_1 beta4_temp_2
C_matrix = C_temp * C_W_1{i};

[C_matrix,ps1]  =  mapminmax(C_matrix',0,1);
C_matrix = C_matrix';
ps(i)=ps1;

y(:,N1*(i-1)+1:N1*i)=C_matrix;
end
Encryption_time = toc;
disp(['The Total Encryption Time in Training is : ', num2str(Encryption_time), ' seconds' ]);
% Training_Communication_Cost = sum([whos('C_RA_1','C_RB_1','C_Rb_1',...
%     'A_train_x_star','B_W_star','B_E_1','A_E_2','C_RB_2','C_RA_2','C_Ra_2',...
%     'B_train_x_star','A_W_star','A_E_1','B_E_2','XAWA','XBWB').bytes])/1024/1024;
% disp(['The Total Communication Cost in Training is : ', num2str(Training_Communication_Cost), ' MB' ]);
% [whos('A_train_x','B_train_x','y').bytes]/1024/1024


tic
clear H1;
clear T1;
%%%%%%%%%%%%%enhancement nodes%%%%%%%%%%%%%%%%%%%%%%%%%%%%

H2 = [y .1 * ones(size(y,1),1)];
if N1*N2>=N3
     wh=orth(2*rand(N2*N1+1,N3)-1);
else
    wh=orth(2*rand(N2*N1+1,N3)'-1)'; 
end
T2 = H2 *wh;
l2 = max(max(T2));
l2 = s/l2;
% fprintf(1,'Enhancement nodes: Max Val of Output %f Min Val %f\n',l2,min(T2(:)));

T2 = tansig(T2 * l2);
T3=[y T2]
clear H2;clear T2;
beta = (T3'  *  T3+eye(size(T3',1)) * (C)) \ ( T3'  *  [A_train_y; B_train_y]);
Enhancemen_time = toc;
Training_time = Encryption_time + Enhancemen_time; % Output training time (including encryption time)
disp('Training has been finished!');
disp(['The Total Training Time is : ', num2str(Training_time), ' seconds' ]);
%%%%%%%%%%%%%%%%%Training Accuracy%%%%%%%%%%%%%%%%%%%%%%%%%%
xx = T3 * beta;
clear T3;

yy = result(xx);
train_yy = result([A_train_y; B_train_y]);
TrainingAccuracy = length(find(yy == train_yy))/size(train_yy,1);
disp(['Training Accuracy is : ', num2str(TrainingAccuracy * 100), ' %' ]);
tic;
%%%%%%%%%%%%%%%%%%%%%%Testing Process%%%%%%%%%%%%%%%%%%%
A_test_x = zscore(A_test_x')';
B_test_x = zscore(B_test_x')';
A_test_x = [A_test_x, 0.1 * ones(size(A_test_x,1),1)];
B_test_x = [B_test_x, 0.1 * ones(size(B_test_x,1),1)];
y=zeros(size(A_test_x,1) + size(B_test_x,1),N2*N1);
for i=1:N2
    
%% calculate X_A*W_B
C_RA_1 = 2*rand(size(A_test_x, 1), size(A_test_x, 2))-1;
C_RB_1 = 2*rand(size(A_test_x, 2), N1_temp)-1;
C_Rb_1 = 2*rand(size(A_test_x, 1), N1_temp)-1;

A_test_x_star = A_test_x + C_RA_1;

B_W_star = B_W{i} + C_RB_1;
B_E_1 = A_test_x_star * B_W{i} + C_Rb_1;

A_E_2 = B_E_1 - C_RA_1 * B_W_star;

C_12 = (A_E_2-C_Rb_1+C_RA_1 * C_RB_1);

%% calculate X_B*W_A
C_RB_2 = 2*rand(size(B_test_x, 1), size(B_test_x, 2))-1;
C_RA_2 = 2*rand(size(B_test_x, 2), N1_temp)-1;
C_Ra_2 = 2*rand(size(B_test_x, 1), N1_temp)-1;

B_test_x_star = B_test_x + C_RB_2;

A_W_star = A_W{i} + C_RA_2;
A_E_1 = B_test_x_star * A_W{i} + C_Ra_2;

B_E_2 = A_E_1 - C_RB_2 * A_W_star;

C_21 = (B_E_2-C_Ra_2+C_RB_2 * C_RA_2) ;

%% calculate X_A*W_A
C_11 = (A_test_x * A_W{i});

%% calculate X_B*W_B
C_22 = (B_test_x * B_W{i});

C_temp = [C_11, C_12;
     C_21, C_22];
C_matrix = C_temp * C_W_1{i};
ps1=ps(i);
 TT1  =  mapminmax('apply',C_matrix',ps1)';

clear beta1; clear ps1;
%yy1=[yy1 TT1];
yy1(:,N1*(i-1)+1:N1*i)=TT1;
end
Encryption_time = toc;
disp(['The Total Encryption Time in Testing is : ', num2str(Encryption_time), ' seconds' ]);
% Testing_Communication_Cost = sum([whos('C_RA_1','C_RB_1','C_Rb_1',...
%     'A_test_x_star','B_W_star','B_E_1','A_E_2','C_RB_2','C_RA_2','C_Ra_2',...
%     'B_test_x_star','A_W_star','A_E_1','B_E_2','C_11','C_22').bytes])/1024/1024;
% disp(['The Total Communication Cost in Testing is : ', num2str(Testing_Communication_Cost), ' MB' ]);
% sum([whos('A_test_x','B_test_x','yy1').bytes])/1024/1024

tic
clear TT1;%clear HH1;
HH2 = [yy1 .1 * ones(size(yy1,1),1)]; 
TT2 = tansig(HH2 * wh * l2);TT3=[yy1 TT2];
clear HH2;clear wh;clear TT2;
%%%%%%%%%%%%%%%%% testing accuracy%%%%%%%%%%%%%%%%%%%%%%%%%%%
x = TT3 * beta;
y = result(x);
test_yy = result([A_test_y; B_test_y]);
TestingAccuracy = length(find(y == test_yy))/size(test_yy,1);
clear TT3;
Enhancemen_time = toc;
Testing_time = Encryption_time + Enhancemen_time; % Output training time (including encryption time)
disp('Testing has been finished!');
disp(['The Total Testing Time is : ', num2str(Testing_time), ' seconds' ]);
disp(['Testing Accuracy is : ', num2str(TestingAccuracy * 100), ' %' ]);
