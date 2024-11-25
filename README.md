

# **Heart Disease Data Classification Project**

## **Overview**
This project is part of the TEB2043/TFB2063/TEB2164 Data Science course at Universiti Teknologi PETRONAS. It focuses on predicting the risk of heart disease using the Heart Failure Prediction dataset sourced from Kaggle. The project employs multiple machine learning models, following a systematic pipeline: data preprocessing, exploratory data analysis (EDA), feature engineering, modeling, and evaluation.

The models developed include **Logistic Regression**, **K-Nearest Neighbors (KNN)**, **Random Forest**, and **CART (Classification and Regression Trees)**. Their performance is evaluated using metrics like Accuracy, Precision, Recall, F1-Score, and AUC, with insights into trade-offs between model interpretability and predictive power.

---

## **Dataset**
The **Heart Failure Prediction dataset** includes 918 samples with 12 features covering demographic, clinical, and lifestyle attributes. The dataset has no missing or duplicate values and is used to predict heart disease risk (binary classification: 1 = Heart Disease, 0 = No Heart Disease).

### **Features**
- **Age**: Patient age (years)
- **Sex**: Gender (M/F)
- **RestingBP**: Resting blood pressure (mm Hg)
- **Cholesterol**: Serum cholesterol (mg/dL)
- **FastingBS**: Fasting blood sugar (1 if > 120 mg/dL, else 0)
- **RestingECG**: Resting electrocardiogram results
- **MaxHR**: Maximum heart rate achieved
- **ExerciseAngina**: Angina induced by exercise (Y/N)
- **Oldpeak**: ST depression during exercise relative to rest
- **ST_Slope**: Slope of the peak exercise ST segment
- **HeartDisease**: Target variable (1 = Heart Disease, 0 = No Heart Disease)

### **Source**
Available via [Kaggle](https://www.kaggle.com/datasets/fedesoriano/heart-failure-prediction).

---

## **Objectives**
1. **Data Preprocessing**:
   - Clean data and handle outliers.
   - Normalize numeric features and encode categorical variables.
   - Split the dataset into training (70%), validation (15%), and test (15%) subsets.

2. **Exploratory Data Analysis (EDA)**:
   - Analyze and visualize feature distributions and correlations.
   - Perform dimensionality reduction using PCA and t-SNE.

3. **Feature Engineering**:
   - Derive new features like interaction terms, polynomial features, and statistical summaries.
   - Optimize features for model performance.

4. **Modeling**:
   - Train and evaluate Logistic Regression, KNN, Random Forest, and CART models.
   - Perform hyperparameter tuning using grid search and cross-validation.

5. **Evaluation**:
   - Assess models using Accuracy, Precision, Recall, F1-Score, and AUC.
   - Analyze results through confusion matrices, ROC curves, and key insights.

---

## **Pipeline**
```plaintext
project/
├── src/
│   ├── data_preprocessing.R        # Data cleaning and preparation
│   ├── eda.R                       # Exploratory data analysis
│   ├── feature_engineering.R       # Feature engineering
│   ├── model_training.R            # Train Logistic Regression, KNN, Random Forest, and CART
│   ├── model_evaluation.R          # Evaluate models and generate benchmarks
│   └── main.R                      # Run the full pipeline
├── data/
│   ├── raw/                        # Raw dataset
│   ├── processed/                  # Cleaned and preprocessed data
│   ├── features/                   # Feature-engineered data
├── models/                         # Trained models and results
├── report/
│   ├── img/                        # Visualizations and plots
│   └── report.pdf                  # Final report
├── README.md                       # Documentation
└── .gitignore                      # Files to ignore in Git
```

---

## **How to Run**
1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd project
   ```
2. Install required R packages:
   ```R
   install.packages(c("caret", "tidyverse", "randomForest", "xgboost", "e1071", "Metrics", "ggplot2"))
   ```
3. Run the full pipeline:
   ```R
   source("src/main.R")
   ```

---

## **Key Insights**
- **Best Model**: Logistic Regression was selected for its balanced performance across metrics and interpretability.
- **Feature Importance**: Key predictors include Age, Cholesterol, Oldpeak, and ST Slope.
- **Trade-offs**: Random Forest showed high training accuracy but overfit the data, while CART offered interpretability at the cost of predictive power.

---

## **Team Members**
| Name                 | ID         |
|----------------------|------------|
| Jihane Essakhi       | 24004461   |
| Merjen Porrykova     | 20001844   |
| Syed Fahim Hussain   | 22009863   |
| Yerkezhan Ukibayeva  | 24006721   |

---

## **Acknowledgments**
This project utilized the Heart Failure Prediction dataset provided by Kaggle. We acknowledge the use of R libraries (`caret`, `randomForest`, etc.) and collaborative tools (GitHub, ChatGPT) for guidance and productivity enhancement.

---
