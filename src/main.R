library(data.table)
library(caret)
library(pROC)
library(ggplot2)
library(data.table)
library(caret)
library(dplyr)

setwd(dirname(rstudioapi::getActiveDocumentContext()$path)) # Set to src/
setwd("..") 


# Source the script files
source("data_cleaning.R")        # Perform data cleaning
source("data_preparation.R")     # Prepare data for modeling
source("eda.R")                  # Perform Exploratory Data Analysis (EDA)
source("feature_engineering.R")  # Apply feature engineering techniques
source("model_building.R")       # Train models
source("model_eval.R")           # Evaluate models

# Main workflow
cat("Starting the workflow...\n")

# Step 1: Data Cleaning
cat("Data Cleaning...\n")
cleaned_data <- clean_data("data/raw/heart_disease_data.csv")

# Step 2: Data Preparation
cat("Data Preparation...\n")
prepared_data <- prepare_data(cleaned_data)

# Step 3: Exploratory Data Analysis
cat("Exploratory Data Analysis...\n")
perform_eda(prepared_data)

# Step 4: Feature Engineering
cat("Feature Engineering...\n")
features <- feature_engineering(prepared_data)

# Step 5: Model Building
cat("Model Building...\n")
trained_models <- build_models(features)

# Step 6: Model Evaluation
cat("Model Evaluation...\n")
evaluation_results <- evaluate_models(trained_models, features)

# Finalize and Save Outputs
cat("Workflow completed. Saving outputs...\n")
saveRDS(evaluation_results, file = "results/evaluation_results.rds")

cat("All tasks completed successfully!\n")
