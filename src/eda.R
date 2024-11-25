library(data.table)
library(ggplot2)
library(dplyr)
library(GGally)
library(FactoMineR)
library(factoextra)
library(corrplot)
library(Rtsne)
library(heatmaply)
library(gridExtra)
library(RColorBrewer)

heart_data <- fread("data/raw/heart.csv")

num_na <- sum(is.na(heart_data))
num_duplicates <- nrow(heart_data) - nrow(unique(heart_data))
cat("Number of NA values:", num_na, "\n")
cat("Number of duplicate rows:", num_duplicates, "\n")

output_dir <- "report"
image_dir <- file.path(output_dir, "img")
dir.create(image_dir, recursive = TRUE, showWarnings = FALSE)

heart_data[, FastingBS := factor(FastingBS, labels = c("Normal (≤120 mg/dL)", "High (>120 mg/dL)"))]
heart_data[, HeartDisease := factor(HeartDisease, labels = c("No Heart Disease", "Heart Disease"))]
heart_data[, ExerciseAngina := factor(ExerciseAngina, labels = c("No", "Yes"))]

categorical_columns <- c("Sex", "ChestPainType", "RestingECG", "ExerciseAngina", "ST_Slope", "FastingBS", "HeartDisease")
numeric_columns <- c("Age", "RestingBP", "Cholesterol", "MaxHR", "Oldpeak")

descriptive_stats <- heart_data %>%
  summarise(across(all_of(numeric_columns), 
                   list(mean = ~mean(., na.rm = TRUE), 
                        sd = ~sd(., na.rm = TRUE), 
                        min = ~min(., na.rm = TRUE), 
                        max = ~max(., na.rm = TRUE))))
descriptive_stats_df <- as.data.frame(descriptive_stats)

freq_tables <- list()
for (col in categorical_columns) {
  freq_table <- heart_data[, .N, by = col]
  freq_table[, Percentage := round(N / sum(N) * 100, 2)]
  freq_tables[[col]] <- freq_table
}

for (col in numeric_columns) {
  p <- ggplot(heart_data, aes_string(x = "HeartDisease", y = col, fill = "HeartDisease")) +
    geom_boxplot(outlier.color = "red", outlier.shape = 16, notch = TRUE) +
    labs(title = paste("Boxplot of", col, "by Heart Disease Status"),
         x = "Heart Disease", y = col) +
    theme_minimal() +
    theme(legend.position = "none") +
    scale_fill_manual(values = c("No Heart Disease" = "steelblue", "Heart Disease" = "salmon"))
  ggsave(filename = file.path(image_dir, paste0("boxplot_", col, ".png")), plot = p)
}

correlation_matrix <- cor(heart_data[, ..numeric_columns], use = "complete.obs")
corrplot(correlation_matrix, method = "color", type = "upper", 
         tl.col = "black", tl.srt = 45, addCoef.col = "black")
ggsave(filename = file.path(image_dir, "correlation_matrix.png"))

heatmaply_cor(
  x = correlation_matrix,
  xlab = "Features", ylab = "Features",
  file = file.path(image_dir, "correlation_heatmap.html")
)

scaled_data <- scale(heart_data[, ..numeric_columns])
pca_result <- PCA(scaled_data, graph = FALSE)
p <- fviz_eig(pca_result, addlabels = TRUE, ylim = c(0, 50))
ggsave(filename = file.path(image_dir, "pca_eigenvalues.png"), plot = p)

pca_ind <- as.data.frame(pca_result$ind$coord)
pca_ind$HeartDisease <- heart_data$HeartDisease
p <- ggplot(pca_ind, aes(x = Dim.1, y = Dim.2, color = HeartDisease)) +
  geom_point(alpha = 0.8) +
  labs(title = "PCA Visualization", x = "Principal Component 1", y = "Principal Component 2") +
  theme_minimal()
ggsave(filename = file.path(image_dir, "pca_scatterplot.png"), plot = p)

explained_variance <- (pca_result$eig[, "eigenvalue"])
explained_variance_ratio <- explained_variance / sum(explained_variance)
cumulative_variance <- cumsum(explained_variance_ratio)

variance_df <- data.frame(
  PC = seq_along(explained_variance_ratio),
  ExplainedVariance = explained_variance_ratio,
  CumulativeVariance = cumulative_variance
)

p <- ggplot(variance_df, aes(x = PC)) +
  geom_bar(aes(y = ExplainedVariance), stat = "identity", fill = "steelblue", alpha = 0.7) +
  geom_line(aes(y = CumulativeVariance), color = "red", size = 1) +
  geom_point(aes(y = CumulativeVariance), color = "red", size = 2) +
  labs(
    title = "Variance Explained by Principal Components (Heart Dataset)",
    x = "Principal Component",
    y = "Variance Explained"
  ) +
  theme_minimal()
ggsave(filename = file.path(image_dir, "variance_explained.png"), plot = p)

set.seed(42)
scaled_data_no_dup <- unique(scaled_data)
tsne_result <- Rtsne(scaled_data_no_dup, dims = 2, perplexity = 30, verbose = TRUE, max_iter = 500)
tsne_data <- data.frame(tsne_result$Y, HeartDisease = heart_data$HeartDisease[1:nrow(tsne_result$Y)])
p <- ggplot(tsne_data, aes(x = X1, y = X2, color = HeartDisease)) +
  geom_point(alpha = 0.8) +
  labs(title = "t-SNE Visualization", x = "t-SNE Dimension 1", y = "t-SNE Dimension 2") +
  theme_minimal()
ggsave(filename = file.path(image_dir, "tsne_visualization.png"), plot = p)
print(p)
heart_data[, `:=`(MaleFemaleHeart = paste(Sex, HeartDisease, sep = " - "))]
gender_heart_data <- heart_data[, .N, by = MaleFemaleHeart]
gender_heart_data[, Percentage := round(N / sum(N) * 100, 2)]
gender_heart_data_df <- as.data.frame(gender_heart_data)

p <- ggplot(gender_heart_data, aes(x = MaleFemaleHeart, y = N, fill = MaleFemaleHeart)) +
  geom_bar(stat = "identity", color = "black") +
  geom_text(aes(label = paste0(N, " (", Percentage, "%)")), vjust = -0.5, size = 3) +
  labs(title = "Count of Males and Females with and without Heart Disease", x = "Category", y = "Count") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
  scale_fill_brewer(palette = "Paired")
ggsave(filename = file.path(image_dir, "gender_heart_count.png"), plot = p)

plots <- list()
for (col in categorical_columns) {
  plot <- ggplot(heart_data, aes_string(x = col, fill = "HeartDisease")) +
    geom_bar(position = "dodge", color = "black") +
    geom_text(stat = "count", aes(label = after_stat(count)), position = position_dodge(width = 0.9), vjust = -0.5, size = 3) +
    labs(title = paste("Count of", col, "grouped by HeartDisease"), x = col, y = "Count") +
    theme_minimal() +
    theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
    scale_fill_brewer(palette = "Set2")
  plots[[col]] <- plot
}

png(file.path(image_dir, "combined_categorical_plots.png"), width = 14, height = 12, units = "in", res = 300)
grid.arrange(
  plots[["Sex"]], 
  plots[["ChestPainType"]], 
  plots[["RestingECG"]], 
  plots[["ExerciseAngina"]], 
  plots[["ST_Slope"]], 
  plots[["FastingBS"]], 
  ncol = 2
)
dev.off()

for (col in numeric_columns) {
  p <- ggplot(heart_data, aes_string(x = col)) +
    geom_histogram(aes(y = ..density..), bins = 30, fill = "steelblue", alpha = 0.7) +
    geom_density(color = "red", size = 1) +
    labs(title = paste("Distribution of", col), x = col, y = "Density") +
    theme_minimal()
  ggsave(filename = file.path(image_dir, paste0("distribution_", col, ".png")), plot = p)
}

saveRDS(descriptive_stats_df, file.path(output_dir, "descriptive_stats_df.rds"))
saveRDS(freq_tables, file.path(output_dir, "freq_tables.rds"))
saveRDS(variance_df, file.path(output_dir, "variance_df.rds"))
saveRDS(gender_heart_data_df, file.path(output_dir, "gender_heart_data_df.rds"))
saveRDS(tsne_data, file.path(output_dir, "tsne_data.rds"))
saveRDS(pca_ind, file.path(output_dir, "pca_ind.rds"))
summary(heart_data)
