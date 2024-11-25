

heart_data <- fread("data/raw/heart.csv")

num_na <- sum(is.na(heart_data))
num_duplicates <- nrow(heart_data) - nrow(unique(heart_data))
cat("Number of NA values before cleaning:", num_na, "\n")
cat("Number of duplicate rows before cleaning:", num_duplicates, "\n")

heart_data <- unique(heart_data)

numeric_columns <- c("Age", "RestingBP", "Cholesterol", "MaxHR", "Oldpeak")
for (col in numeric_columns) {
  median_value <- median(heart_data[[col]], na.rm = TRUE)
  heart_data[[col]][is.na(heart_data[[col]])] <- median_value
}

categorical_columns <- c("Sex", "ChestPainType", "RestingECG", "ExerciseAngina", "ST_Slope", "FastingBS", "HeartDisease")
for (col in categorical_columns) {
  mode_value <- heart_data[, .N, by = col][order(-N)][1, col, with = FALSE][[1]]
  heart_data[[col]][is.na(heart_data[[col]])] <- mode_value
}

for (col in numeric_columns) {
  le <- quantile(heart_data[[col]], 0.25) - 1.5 * IQR(heart_data[[col]])
  ue <- quantile(heart_data[[col]], 0.75) + 1.5 * IQR(heart_data[[col]])
  mean_value <- mean(heart_data[[col]], na.rm = TRUE)
  heart_data[[col]][heart_data[[col]] < le | heart_data[[col]] > ue] <- mean_value
}

normalize <- function(x) {
  return((x - min(x)) / (max(x) - min(x)))
}
heart_data[, (numeric_columns) := lapply(.SD, normalize), .SDcols = numeric_columns]

heart_data[, (categorical_columns) := lapply(.SD, as.factor), .SDcols = categorical_columns]

num_na_after <- sum(is.na(heart_data))
num_duplicates_after <- nrow(heart_data) - nrow(unique(heart_data))
cat("Number of NA values after cleaning:", num_na_after, "\n")
cat("Number of duplicate rows after cleaning:", num_duplicates_after, "\n")

# Save preprocessed files
preprocessed_dir <- file.path("data", "processed")
dir.create(preprocessed_dir, recursive = TRUE, showWarnings = FALSE)

write.csv(heart_data, file.path(preprocessed_dir, "heart_cleaned.csv"), row.names = FALSE)
