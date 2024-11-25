library(data.table)
library(caret)

# Load the preprocessed dataset
heart_data <- fread("data/processed/heart_cleaned.csv")

# Splitting the data into train (70%), validation (15%), and test (15%) sets
set.seed(123)  # For reproducibility
train_index <- createDataPartition(heart_data$HeartDisease, p = 0.7, list = FALSE)
train_data <- heart_data[train_index]
remaining_data <- heart_data[-train_index]

val_index <- createDataPartition(remaining_data$HeartDisease, p = 0.5, list = FALSE)
val_data <- remaining_data[val_index]
test_data <- remaining_data[-val_index]

# Save the split datasets
prepared_dir <- file.path("data", "prepared")
dir.create(prepared_dir, recursive = TRUE, showWarnings = FALSE)

write.csv(train_data, file.path(prepared_dir, "heart_train.csv"), row.names = FALSE)
write.csv(val_data, file.path(prepared_dir, "heart_validation.csv"), row.names = FALSE)
write.csv(test_data, file.path(prepared_dir, "heart_test.csv"), row.names = FALSE)
