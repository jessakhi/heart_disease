library(data.table)
library(caret)
library(randomForest)
library(rpart)
library(e1071)

set.seed(123)
train_data <- fread("data/prepared/heart_train.csv")
val_data <- fread("data/prepared/heart_validation.csv")
test_data <- fread("data/prepared/heart_test.csv")

train_data$HeartDisease <- as.factor(train_data$HeartDisease)
val_data$HeartDisease <- as.factor(val_data$HeartDisease)
test_data$HeartDisease <- as.factor(test_data$HeartDisease)

control <- trainControl(method = "cv", number = 5)

set.seed(123)
start_time <- Sys.time()
logistic_model <- train(HeartDisease ~ ., data = train_data, method = "glm", family = "binomial", trControl = control)
logistic_processing_time <- Sys.time() - start_time

set.seed(123)
start_time <- Sys.time()
rf_grid <- expand.grid(mtry = seq(2, ncol(train_data) - 1, by = 1))
rf_model <- train(HeartDisease ~ ., data = train_data, method = "rf", trControl = control, tuneGrid = rf_grid, ntree = 300)
rf_processing_time <- Sys.time() - start_time

set.seed(123)
start_time <- Sys.time()
cart_model <- train(HeartDisease ~ ., data = train_data, method = "rpart", trControl = control)
cart_processing_time <- Sys.time() - start_time

set.seed(123)
start_time <- Sys.time()
knn_model <- train(HeartDisease ~ ., data = train_data, method = "knn", trControl = control, tuneLength = 5)
knn_processing_time <- Sys.time() - start_time

set.seed(123)
start_time <- Sys.time()
linear_model <- train(as.numeric(as.character(HeartDisease)) ~ ., data = train_data, method = "lm", trControl = control)
linear_processing_time <- Sys.time() - start_time

models_dir <- file.path("models")
dir.create(models_dir, recursive = TRUE, showWarnings = FALSE)

saveRDS(logistic_model, file.path(models_dir, "logistic_model.rds"))
saveRDS(rf_model, file.path(models_dir, "rf_model.rds"))
saveRDS(cart_model, file.path(models_dir, "cart_model.rds"))
saveRDS(knn_model, file.path(models_dir, "knn_model.rds"))
saveRDS(linear_model, file.path(models_dir, "linear_model.rds"))

val_predictions_logistic <- predict(logistic_model, val_data)
val_predictions_rf <- predict(rf_model, val_data)
val_predictions_cart <- predict(cart_model, val_data)
val_predictions_knn <- predict(knn_model, val_data)
val_predictions_linear <- ifelse(predict(linear_model, val_data) > 0.5, "1", "0")

logistic_accuracy <- confusionMatrix(val_predictions_logistic, val_data$HeartDisease)$overall["Accuracy"]
rf_accuracy <- confusionMatrix(val_predictions_rf, val_data$HeartDisease)$overall["Accuracy"]
cart_accuracy <- confusionMatrix(val_predictions_cart, val_data$HeartDisease)$overall["Accuracy"]
knn_accuracy <- confusionMatrix(val_predictions_knn, val_data$HeartDisease)$overall["Accuracy"]
linear_accuracy <- confusionMatrix(as.factor(val_predictions_linear), val_data$HeartDisease)$overall["Accuracy"]

cat("Validation Accuracy for Logistic Regression: ", logistic_accuracy, "\n")
cat("Validation Accuracy for Random Forest: ", rf_accuracy, "\n")
cat("Validation Accuracy for CART: ", cart_accuracy, "\n")
cat("Validation Accuracy for KNN: ", knn_accuracy, "\n")
cat("Validation Accuracy for Linear Regression: ", linear_accuracy, "\n")

best_model <- which.max(c(logistic_accuracy, rf_accuracy, cart_accuracy, knn_accuracy, linear_accuracy))
model_names <- c("Logistic Regression", "Random Forest", "CART", "KNN", "Linear Regression")
best_model_name <- model_names[best_model]
cat("Best Model: ", best_model_name, "\n")

if (best_model == 1) {
  test_predictions <- predict(logistic_model, test_data)
} else if (best_model == 2) {
  test_predictions <- predict(rf_model, test_data)
} else if (best_model == 3) {
  test_predictions <- predict(cart_model, test_data)
} else if (best_model == 4) {
  test_predictions <- predict(knn_model, test_data)
} else {
  test_predictions <- ifelse(predict(linear_model, test_data) > 0.5, "1", "0")
}

write.csv(data.frame(Predictions = test_predictions), file.path(models_dir, "test_predictions.csv"), row.names = FALSE)

processing_times <- list(
  logistic_model = logistic_processing_time,
  rf_model = rf_processing_time,
  cart_model = cart_processing_time,
  knn_model = knn_processing_time,
  linear_model = linear_processing_time
)
saveRDS(processing_times, file.path(models_dir, "processing_times.rds"))
