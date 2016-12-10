#######################################################################;
# Project           : kaggle Santendar Product Recomendation
#
# Program name      : 000_setup.R
#
# Author            : Takashi, SUGAWARA
#
# Date created      : 2016-12-06
#
# Purpose           : Setting Up Environment
#
# Input             : nothing
#
# Output            : nothing 
#
# Revision History  : 
#
#
#######################################################################;


#Set working directry
#getwd()
setwd("/home/rstudio/Santendar/")

#load libraries
install_packages <- 0
if(install_packages == 1){
  install.packages(c("Hmisc",
                     "xgboost",
                     "readr",
                     "stringr",
                     "caret",
                     "car",
                     "plyr",
                     "dplyr",
                     "tidyr",
                     "data.table",
                     "DescTools",
                     "Matrix",
                     "glmnet",
                     "randomForest"))
}

# load libraries
library(Hmisc)
library(xgboost)
library(readr)
library(stringr)
library(caret)
library(car)
library(plyr)
library(dplyr)
library(tidyr)
library(data.table)
library(DescTools)
library(Matrix)
library(glmnet)
library(randomForest)