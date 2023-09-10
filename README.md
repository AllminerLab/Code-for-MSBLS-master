# Multi-party Secure Broad Learning System for Privacy Preserving

# This repository contains the code and dataset for the paper:
https://arxiv.org/abs/2206.11133


# Privacy-Preserving Machine Learning (PPML) is a popular research area in recent years. Unlike traditional machine learning methods, PPML usually requires additional considerations such as security and communication costs. The MSBLS method proposed in this paper can well balance the requirements of security, accuracy, efficiency and application scope. The method uses a broad learning system as the neural network classifier and implements privacy computing with a secure multi-party computing protocol, thus training the neural network classifier while protecting data security. Experiments show that the method outperforms various PPML methods such as federated learning.

######
# General Guidelines

# All of the experiments are implemented in Matlab R2019b on a standard Window PC with an Intel 2.4-GHz CPU and 64-GB RAM (64-bit).

# Note that if you would like to use MSBLS as a baseline and run our code: 

# Dataset 

# If you are using other datasets, then you need to adjust the appropriate parameters, which mainly include N1, N2 and N3. N1*N2 indicates the number of mapped features (in general, we divide mapped features into N1 groups with N2 mapped features in each group in the broad learning system), and N3 indicates the number of the number of enhancement features.

# We provide three datasets in the code, see the folder MSBLS-master/data_set/, and the basic information of the three datasets is as follows.

dataset  |trained set |tested set |labels |N1 |N2 |N3
Norb      |24300        |24300       |5        |50 |10  |10000
MNIST   |60000        |10000       |10      |10 |20  |10000
Fashion |60000        |10000        |10      |50 |20  |10000
