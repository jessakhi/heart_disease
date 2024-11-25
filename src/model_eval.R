library(data.table)
library(caret)
library(pROC)
library(ggplot2)

models_dir <- "data/models"
rf_model <- readRDS(file.path(models_dir, "rf_model.rds"))

train_data <- fread("data/prepared/heart_train.csv")
val_data <- fread("data/prepared/heart_validation.csv")
test_data <- fread("data/prepared/heart_test.csv")
train_data$HeartDisease <- as.factor(train_data$HeartDisease)
val_data$HeartDisease <- as.factor(val_data$HeartDisease)
test_data$HeartDisease <- as.factor(test_data$HeartDisease)

evaluate_model <- function(model, data, dataset_name) {
  predicted_probs <- predict(model, data, type = "prob")
  predicted_labels <- predict(model, data, type = "raw")
  cm <- confusionMatrix(predicted_labels, data$HeartDisease)
  accuracy <- cm$overall["Accuracy"]
  precision <- cm$byClass["Pos Pred Value"]
  recall <- cm$byClass["Sensitivity"]
  f1_score <- 2 * (precision * recall) / (precision + recall)
  roc_curve <- roc(as.numeric(data$HeartDisease) - 1, predicted_probs[, 2])
  auc_value <- auc(roc_curve)
  log_loss <- -mean(rowSums(model.matrix(~ factor(data$HeartDisease) - 1) * log(predicted_probs + 1e-15)))
  
  return(list(
    accuracy = accuracy, precision = precision, recall = recall,
    f1_score = f1_score, auc = auc_value, log_loss = log_loss,
    predicted_labels = predicted_labels, predicted_probs = predicted_probs
  ))
}

rf_train_eval <- evaluate_model(rf_model, train_data, "Train")
rf_val_eval <- evaluate_model(rf_model, val_data, "Validation")
rf_test_eval <- evaluate_model(rf_model, test_data, "Test")

metrics_comparison <- data.table(
  Dataset = c("Train", "Validation", "Test"),
  Accuracy = c(rf_train_eval$accuracy, rf_val_eval$accuracy, rf_test_eval$accuracy),
  Precision = c(rf_train_eval$precision, rf_val_eval$precision, rf_test_eval$precision),
  Recall = c(rf_train_eval$recall, rf_val_eval$recall, rf_test_eval$recall),
  F1_Score = c(rf_train_eval$f1_score, rf_val_eval$f1_score, rf_test_eval$f1_score),
  AUC = c(rf_train_eval$auc, rf_val_eval$auc, rf_test_eval$auc)
)

sample_prediction <- data.table(
  Features = as.list(val_data[1, -c("HeartDisease")]),
  True_Label = as.character(val_data$HeartDisease[1]),
  Predicted_Label = as.character(rf_val_eval$predicted_labels[1]),
  Predicted_Probability = rf_val_eval$predicted_probs[1, 2]
)

predicted_vs_true <- data.table(
  True_Labels = val_data$HeartDisease[1:10],
  Predicted_Labels = rf_val_eval$predicted_labels[1:10]
)

predicted_probs_plot <- data.table(
  Individual = 1:nrow(val_data),
  Probability = rf_val_eval$predicted_probs[, 2],
  True_Label = val_data$HeartDisease
)

heart_disease_likelihood_plot <- ggplot(predicted_probs_plot, aes(x = Individual, y = Probability, color = True_Label)) +
  geom_point(size = 2) +
  geom_hline(yintercept = 0.5, linetype = "dashed", color = "red") +
  labs(title = "Likelihood of Heart Disease", y = "Predicted Probability", x = "Individual") +
  theme_minimal()

ggsave("report/img/eval/heart_disease_likelihood.png", plot = heart_disease_likelihood_plot, width = 8, height = 6)

View(metrics_comparison)
View(sample_prediction)
View(predicted_vs_true)
