# Load required libraries
library(data.table)
library(caret)
library(pROC)
library(ggplot2)

# Load models
models_dir <- "models"
logistic_model <- readRDS(file.path(models_dir, "logistic_model.rds"))
rf_model <- readRDS(file.path(models_dir, "rf_model.rds"))
cart_model <- readRDS(file.path(models_dir, "cart_model.rds"))
knn_model <- readRDS(file.path(models_dir, "knn_model.rds"))

# Load data
train_data <- fread("data/prepared/heart_train.csv")
val_data <- fread("data/prepared/heart_validation.csv")
test_data <- fread("data/prepared/heart_test.csv")
train_data$HeartDisease <- as.factor(train_data$HeartDisease)
val_data$HeartDisease <- as.factor(val_data$HeartDisease)
test_data$HeartDisease <- as.factor(test_data$HeartDisease)

# Define evaluation function
evaluate_model <- function(model, data) {
  predicted_probs <- predict(model, data, type = "prob")
  predicted_labels <- predict(model, data, type = "raw")
  cm <- confusionMatrix(predicted_labels, data$HeartDisease)
  accuracy <- cm$overall["Accuracy"]
  precision <- cm$byClass["Pos Pred Value"]
  recall <- cm$byClass["Sensitivity"]
  f1_score <- 2 * (precision * recall) / (precision + recall)
  roc_curve <- roc(as.numeric(data$HeartDisease) - 1, predicted_probs[, 2])
  auc_value <- auc(roc_curve)
  mae <- mean(abs(predicted_probs[, 2] - (as.numeric(data$HeartDisease) - 1)))
  mse <- mean((predicted_probs[, 2] - (as.numeric(data$HeartDisease) - 1))^2)
  rmse <- sqrt(mse)
  r_squared <- 1 - sum((predicted_probs[, 2] - (as.numeric(data$HeartDisease) - 1))^2) /
    sum((mean(as.numeric(data$HeartDisease) - 1) - (as.numeric(data$HeartDisease) - 1))^2)
  list(
    accuracy = accuracy,
    precision = precision,
    recall = recall,
    f1_score = f1_score,
    auc = auc_value,
    mae = mae,
    mse = mse,
    rmse = rmse,
    r_squared = r_squared,
    roc_curve = roc_curve,
    cm = cm
  )
}

# Evaluate models
models <- list(
  Logistic_Regression = logistic_model,
  Random_Forest = rf_model,
  CART = cart_model,
  KNN = knn_model
)

results <- lapply(models, function(model) {
  list(
    Train = evaluate_model(model, train_data),
    Validation = evaluate_model(model, val_data),
    Test = evaluate_model(model, test_data)
  )
})

# Create benchmark table
benchmark_table <- data.table(
  Model = rep(names(models), each = 3),
  Dataset = rep(c("Train", "Validation", "Test"), times = length(models)),
  Accuracy = unlist(lapply(results, function(res) sapply(res, function(ds) ds$accuracy))),
  Precision = unlist(lapply(results, function(res) sapply(res, function(ds) ds$precision))),
  Recall = unlist(lapply(results, function(res) sapply(res, function(ds) ds$recall))),
  F1_Score = unlist(lapply(results, function(res) sapply(res, function(ds) ds$f1_score))),
  AUC = unlist(lapply(results, function(res) sapply(res, function(ds) ds$auc))),
  MAE = unlist(lapply(results, function(res) sapply(res, function(ds) ds$mae))),
  RMSE = unlist(lapply(results, function(res) sapply(res, function(ds) ds$rmse))),
  R_Squared = unlist(lapply(results, function(res) sapply(res, function(ds) ds$r_squared)))
)

# Save benchmark table to CSV
fwrite(benchmark_table, file = "report/benchmark_table.csv")

# Print benchmark table
print(benchmark_table)

# Generate and save plots for each metric
metrics <- c("Accuracy", "Precision", "Recall", "F1_Score", "AUC", "MAE", "RMSE", "R_Squared")

dir.create("report/img/eval", recursive = TRUE, showWarnings = FALSE)

for (metric in metrics) {
  metric_data <- benchmark_table[, .(Model, Dataset, Value = get(metric))]
  
  metric_plot <- ggplot(metric_data, aes(x = Model, y = Value, fill = Dataset)) +
    geom_bar(stat = "identity", position = "dodge", color = "black") +
    labs(title = paste(toupper(metric), "Comparison Across Models and Datasets"),
         x = "Model", y = toupper(metric)) +
    theme_minimal()
  
  ggsave(file.path("report/img/eval", paste0(tolower(metric), "_comparison.png")),
         plot = metric_plot, width = 8, height = 6)
}

# Generate predictions for true vs. predicted labels and save to CSV
get_predictions <- function(model, data, dataset_name, model_name) {
  predicted_labels <- predict(model, data, type = "raw")
  true_labels <- data$HeartDisease
  data.table(
    Dataset = dataset_name,
    Model = model_name,
    True_Label = true_labels,
    Predicted_Label = predicted_labels
  )
}

predictions <- rbindlist(lapply(names(models), function(model_name) {
  rbindlist(list(
    get_predictions(models[[model_name]], train_data, "Train", model_name),
    get_predictions(models[[model_name]], val_data, "Validation", model_name),
    get_predictions(models[[model_name]], test_data, "Test", model_name)
  ))
}))

fwrite(predictions, "report/predictions.csv")

# Save confusion matrices as plots
dir.create("report/img/confusion_matrices", recursive = TRUE, showWarnings = FALSE)

lapply(names(models), function(model_name) {
  lapply(c("Train", "Validation", "Test"), function(dataset) {
    cm <- results[[model_name]][[dataset]]$cm
    cm_plot <- as.table(cm$table)
    cm_title <- paste0(model_name, " - ", dataset, " Confusion Matrix")
    
    # Save confusion matrix
    png(file.path("report/img/confusion_matrices", paste0(model_name, "_", dataset, "_cm.png")))
    fourfoldplot(cm_plot, color = c("#CC6666", "#99CC99"), main = cm_title)
    dev.off()
  })
})

# Save ROC curves
dir.create("report/img/roc_curves", recursive = TRUE, showWarnings = FALSE)

lapply(names(models), function(model_name) {
  lapply(c("Train", "Validation", "Test"), function(dataset) {
    roc_curve <- results[[model_name]][[dataset]]$roc_curve
    roc_title <- paste0(model_name, " - ", dataset, " ROC Curve")
    
    # Save ROC curve
    png(file.path("report/img/roc_curves", paste0(model_name, "_", dataset, "_roc.png")), width = 800, height = 600)
    plot(roc_curve, main = roc_title, col = "#377eb8", lwd = 2)
    abline(a = 0, b = 1, lty = 2, col = "red")
    dev.off()
  })
})





# Define evaluation and metrics extraction functions
evaluate_model <- function(model, data) {
  predicted_probs <- predict(model, data, type = "prob")
  predicted_labels <- predict(model, data, type = "raw")
  cm <- confusionMatrix(predicted_labels, data$HeartDisease)
  list(
    Accuracy = cm$overall["Accuracy"],
    Precision = cm$byClass["Pos Pred Value"],
    Recall = cm$byClass["Sensitivity"],
    F1_Score = 2 * (cm$byClass["Pos Pred Value"] * cm$byClass["Sensitivity"]) / 
      (cm$byClass["Pos Pred Value"] + cm$byClass["Sensitivity"]),
    AUC = auc(roc(as.numeric(data$HeartDisease) - 1, predicted_probs[, 2])),
    Predictions = data.table(
      True_Label = data$HeartDisease,
      Predicted_Label = predicted_labels,
      Predicted_Probability = predicted_probs[, 2]
    )
  )
}

# Load models
models_dir <- "models"
logistic_model <- readRDS(file.path(models_dir, "logistic_model.rds"))
rf_model <- readRDS(file.path(models_dir, "rf_model.rds"))
cart_model <- readRDS(file.path(models_dir, "cart_model.rds"))
knn_model <- readRDS(file.path(models_dir, "knn_model.rds"))

# Load data
train_data <- fread("data/prepared/heart_train.csv")
val_data <- fread("data/prepared/heart_validation.csv")
test_data <- fread("data/prepared/heart_test.csv")
train_data$HeartDisease <- as.factor(train_data$HeartDisease)
val_data$HeartDisease <- as.factor(val_data$HeartDisease)
test_data$HeartDisease <- as.factor(test_data$HeartDisease)

# Models
models <- list(
  Logistic_Regression = logistic_model,
  Random_Forest = rf_model,
  CART = cart_model,
  KNN = knn_model
)

# Evaluate each model and store results
results <- lapply(models, function(model) {
  list(
    Train = evaluate_model(model, train_data),
    Validation = evaluate_model(model, val_data),
    Test = evaluate_model(model, test_data)
  )
})

# Create data frames for each model
logistic_df <- results$Logistic_Regression$Validation$Predictions
rf_df <- results$Random_Forest$Validation$Predictions
cart_df <- results$CART$Validation$Predictions
knn_df <- results$KNN$Validation$Predictions

# Display as data frames
list(
  Logistic_Regression = logistic_df,
  Random_Forest = rf_df,
  CART = cart_df,
  KNN = knn_df
)

