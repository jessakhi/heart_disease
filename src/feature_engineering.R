library(data.table)

# Load the preprocessed dataset
heart_data <- fread("data/processed/heart_cleaned.csv")

# Feature Engineering
# Adding BMI feature from Age and Cholesterol
heart_data[, BMI := Cholesterol / (Age^2)]

# Creating Age groups
heart_data[, AgeGroup := fifelse(Age < 40, "Young",
                                 fifelse(Age < 60, "Middle-aged", "Old"))]

# Encoding Chest Pain Type as ordinal - based on severity
heart_data[, ChestPainSeverity := fifelse(ChestPainType == "ASY", 3,
                                          fifelse(ChestPainType == "NAP", 2,
                                                  fifelse(ChestPainType == "TA", 1, 0)))]

# Creating a feature for Hypertension (high BP)
heart_data[, Hypertension := fifelse(RestingBP >= 140, 1, 0)]

# Creating interaction features
# Interaction between Age and Cholesterol
heart_data[, AgeCholesterolInteraction := Age * Cholesterol]

# Creating polynomial features
heart_data[, MaxHR_Squared := MaxHR^2]

# Creating statistical features
# Mean Cholesterol by AgeGroup
heart_data[, MeanCholesterolByAgeGroup := mean(Cholesterol, na.rm = TRUE), by = AgeGroup]

# Standard deviation of RestingBP by Sex
heart_data[, SD_RestingBP_BySex := sd(RestingBP, na.rm = TRUE), by = Sex]

# Median MaxHR by ChestPainType
heart_data[, MedianMaxHR_ByChestPain := median(MaxHR, na.rm = TRUE), by = ChestPainType]

# Encoding categorical features as factors for predictive modeling
categorical_columns <- c("Sex", "AgeGroup", "ChestPainType", "RestingECG", "ExerciseAngina", "ST_Slope", "FastingBS", "HeartDisease")
heart_data[, (categorical_columns) := lapply(.SD, as.factor), .SDcols = categorical_columns]

# Save the engineered dataset
engineered_dir <- file.path("data", "engineered")
dir.create(engineered_dir, recursive = TRUE, showWarnings = FALSE)

write.csv(heart_data, file.path(engineered_dir, "heart_engineered.csv"), row.names = FALSE)
