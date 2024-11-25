library(data.table)
library(caret)
library(randomForest)
library(rpart)
library(e1071)

# Load the prepared datasets
train_data <- fread("data/prepared/heart_train.csv")
val_data <- fread("data/prepared/heart_validation.csv")
test_data <- fread("data/prepared/heart_test.csv")

# Convert target variable to factor for classification
train_data$HeartDisease <- as.factor(train_data$HeartDisease)
val_data$HeartDisease <- as.factor(val_data$HeartDisease)
test_data$HeartDisease <- as.factor(test_data$HeartDisease)

# Define control parameters for cross-validation
control <- trainControl(method = "cv", number = 5)

# Model 1: Logistic Regression
start_time <- Sys.time()
logistic_model <- train(HeartDisease ~ ., data = train_data, method = "glm", family = "binomial", trControl = control)
logistic_processing_time <- Sys.time() - start_time

# Model 2: Random Forest
set.seed(123)
start_time <- Sys.time()
rf_model <- train(HeartDisease ~ ., data = train_data, method = "rf", ntree = 100, trControl = control)
rf_processing_time <- Sys.time() - start_time

# Model 3: Decision Tree (CART)
set.seed(123)
start_time <- Sys.time()
cart_model <- train(HeartDisease ~ ., data = train_data, method = "rpart", trControl = control)
cart_processing_time <- Sys.time() - start_time

# Save the models
models_dir <- file.path("data", "models")
dir.create(models_dir, recursive = TRUE, showWarnings = FALSE)

saveRDS(logistic_model, file.path(models_dir, "logistic_model.rds"))
saveRDS(rf_model, file.path(models_dir, "rf_model.rds"))
saveRDS(cart_model, file.path(models_dir, "cart_model.rds"))

# Make predictions on the validation set
val_predictions_logistic <- predict(logistic_model, val_data)
val_predictions_rf <- predict(rf_model, val_data)
val_predictions_cart <- predict(cart_model, val_data)

# Calculate validation accuracy for each model
logistic_accuracy <- confusionMatrix(val_predictions_logistic, val_data$HeartDisease)$overall["Accuracy"]
rf_accuracy <- confusionMatrix(val_predictions_rf, val_data$HeartDisease)$overall["Accuracy"]
cart_accuracy <- confusionMatrix(val_predictions_cart, val_data$HeartDisease)$overall["Accuracy"]

cat("Validation Accuracy for Logistic Regression: ", logistic_accuracy, "\n")
cat("Validation Accuracy for Random Forest: ", rf_accuracy, "\n")
cat("Validation Accuracy for CART: ", cart_accuracy, "\n")

# Determine the best model based on validation accuracy
best_model <- which.max(c(logistic_accuracy, rf_accuracy, cart_accuracy))
model_names <- c("Logistic Regression", "Random Forest", "CART")
best_model_name <- model_names[best_model]
cat("Best Model: ", best_model_name, "\n")

# Make predictions on the test set using the best model
if (best_model == 1) {
  test_predictions <- predict(logistic_model, test_data)
} else if (best_model == 2) {
  test_predictions <- predict(rf_model, test_data)
} else {
  test_predictions <- predict(cart_model, test_data)
}

# Save test predictions
write.csv(data.frame(Predictions = test_predictions), file.path(models_dir, "test_predictions.csv"), row.names = FALSE)

# Save processing times
processing_times <- list(
  logistic_model = logistic_processing_time,
  rf_model = rf_processing_time,
  cart_model = cart_processing_time
)
saveRDS(processing_times, file.path(models_dir, "processing_times.rds"))
