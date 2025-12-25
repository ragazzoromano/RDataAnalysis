# ==============================================================================
# Example: CSV Import and Analysis
# ==============================================================================
# 
# This script demonstrates how to import CSV files, clean data, perform
# statistical analysis, and create visualizations.
#
# ==============================================================================

# Load the analysis system
source("sql_server_data_analysis.R")

# Load required packages
load_packages()

# ==============================================================================
# EXAMPLE 1: Basic CSV Import
# ==============================================================================

message("\n", strrep("=", 70))
message("EXAMPLE 1: Basic CSV Import")
message(strrep("=", 70), "\n")

# Import sales data
vendite <- import_csv("data/examples/vendite.csv")

# Preview the data
message("\nFirst few rows:")
print(head(vendite))

# ==============================================================================
# EXAMPLE 2: Import with Different Delimiter
# ==============================================================================

message("\n", strrep("=", 70))
message("EXAMPLE 2: Import with Semicolon Delimiter")
message(strrep("=", 70), "\n")

# Import customer data (uses semicolon delimiter)
clienti <- import_csv(
  "data/examples/clienti.csv",
  delimiter = ";"
)

message("\nCustomer data preview:")
print(head(clienti, 3))

# ==============================================================================
# EXAMPLE 3: Import All CSV Files from Directory
# ==============================================================================

message("\n", strrep("=", 70))
message("EXAMPLE 3: Import Multiple Files")
message(strrep("=", 70), "\n")

# Import all CSV files (returns list)
all_files <- import_multiple_csv(
  "data/examples",
  combine = FALSE
)

message("\nFiles imported:")
print(names(all_files))

# ==============================================================================
# EXAMPLE 4: Data Cleaning
# ==============================================================================

message("\n", strrep("=", 70))
message("EXAMPLE 4: Data Cleaning")
message(strrep("=", 70), "\n")

# Clean the sales data
vendite_clean <- clean_data(vendite)

# Handle missing values (just report them)
vendite_clean <- handle_missing_values(vendite_clean, strategy = "report")

# ==============================================================================
# EXAMPLE 5: Data Validation
# ==============================================================================

message("\n", strrep("=", 70))
message("EXAMPLE 5: Data Validation")
message(strrep("=", 70), "\n")

# Validate sales data
validation_result <- validate_csv(
  vendite_clean,
  required_cols = c("ID", "data", "importo", "cliente_id"),
  check_duplicates = TRUE
)

# ==============================================================================
# EXAMPLE 6: Descriptive Statistics
# ==============================================================================

message("\n", strrep("=", 70))
message("EXAMPLE 6: Descriptive Statistics")
message(strrep("=", 70), "\n")

# Calculate statistics for numeric columns
stats <- descriptive_stats(vendite_clean)

# ==============================================================================
# EXAMPLE 7: Group Analysis
# ==============================================================================

message("\n", strrep("=", 70))
message("EXAMPLE 7: Group Analysis")
message(strrep("=", 70), "\n")

# Analyze sales by category
per_categoria <- group_analysis(
  vendite_clean,
  "categoria",
  "importo",
  fun = "sum"
)

# Analyze by region
per_regione <- group_analysis(
  vendite_clean,
  "regione",
  "importo",
  fun = "sum"
)

# ==============================================================================
# EXAMPLE 8: Data Visualization
# ==============================================================================

message("\n", strrep("=", 70))
message("EXAMPLE 8: Creating Visualizations")
message(strrep("=", 70), "\n")

# Create output directory for charts
if (!dir.exists("output/grafici")) {
  dir.create("output/grafici", recursive = TRUE)
}

# Plot 1: Distribution of amounts
p1 <- plot_distribution(
  vendite_clean,
  "importo",
  "Distribuzione degli Importi delle Vendite",
  bins = 20
)
print(p1)
ggsave("output/grafici/distribuzione_importi.png", p1, width = 10, height = 6, dpi = 300)
message("✓ Saved: output/grafici/distribuzione_importi.png")

# Plot 2: Sales by category
p2 <- plot_category_bars(
  vendite_clean,
  "categoria",
  "importo",
  "Vendite per Categoria",
  top_n = 10
)
print(p2)
ggsave("output/grafici/vendite_per_categoria.png", p2, width = 10, height = 6, dpi = 300)
message("✓ Saved: output/grafici/vendite_per_categoria.png")

# Plot 3: Sales by region
p3 <- plot_category_bars(
  vendite_clean,
  "regione",
  "importo",
  "Vendite per Regione"
)
print(p3)
ggsave("output/grafici/vendite_per_regione.png", p3, width = 10, height = 6, dpi = 300)
message("✓ Saved: output/grafici/vendite_per_regione.png")

# ==============================================================================
# EXAMPLE 9: Advanced Import with Filtering
# ==============================================================================

message("\n", strrep("=", 70))
message("EXAMPLE 9: Advanced Import with Filtering")
message(strrep("=", 70), "\n")

# Import only electronics sales over 100 euros
vendite_filtered <- import_csv_advanced(
  "data/examples/vendite.csv",
  select_cols = c("ID", "data", "categoria", "prodotto", "importo"),
  date_cols = "data",
  preview_rows = 3
)

# Filter for electronics only
if (!is.null(vendite_filtered)) {
  vendite_elettronica <- vendite_filtered %>%
    dplyr::filter(categoria == "Elettronica", importo > 100)
  
  message(sprintf("\nFiltered result: %d electronics sales over €100", 
                 nrow(vendite_elettronica)))
}

# ==============================================================================
# EXAMPLE 10: Combining Data from Multiple Sources
# ==============================================================================

message("\n", strrep("=", 70))
message("EXAMPLE 10: Combining Sales with Customer Data")
message(strrep("=", 70), "\n")

# Combine sales with customer information
vendite_complete <- dplyr::left_join(
  vendite_clean,
  clienti,
  by = "cliente_id"
)

message("\nCombined data structure:")
message(sprintf("  Rows: %d", nrow(vendite_complete)))
message(sprintf("  Columns: %d", ncol(vendite_complete)))
message(sprintf("  New columns from customers: %s", 
               paste(setdiff(names(vendite_complete), names(vendite_clean)), 
                     collapse = ", ")))

# Analysis by customer type
per_tipo_cliente <- vendite_complete %>%
  dplyr::group_by(tipo_cliente) %>%
  dplyr::summarise(
    vendite_totali = sum(importo, na.rm = TRUE),
    numero_transazioni = n(),
    importo_medio = mean(importo, na.rm = TRUE),
    .groups = "drop"
  )

message("\nAnalysis by customer type:")
print(per_tipo_cliente)

# ==============================================================================
# EXAMPLE 11: Export Results
# ==============================================================================

message("\n", strrep("=", 70))
message("EXAMPLE 11: Exporting Results")
message(strrep("=", 70), "\n")

# Create output directory
if (!dir.exists("output")) {
  dir.create("output", recursive = TRUE)
}

# Export statistics to CSV
export_results(stats, "output/statistiche_descrittive.csv", "csv")

# Export grouped analysis
export_results(per_categoria, "output/vendite_per_categoria.csv", "csv")
export_results(per_regione, "output/vendite_per_regione.csv", "csv")

# Export combined data
export_results(vendite_complete, "output/vendite_complete.csv", "csv")

# Export to RDS for faster loading in R
export_results(vendite_complete, "output/vendite_complete.rds", "rds")

# ==============================================================================
# SUMMARY
# ==============================================================================

message("\n", strrep("=", 70))
message("ANALYSIS COMPLETE!")
message(strrep("=", 70))
message("\nFiles created:")
message("  - output/statistiche_descrittive.csv")
message("  - output/vendite_per_categoria.csv")
message("  - output/vendite_per_regione.csv")
message("  - output/vendite_complete.csv")
message("  - output/vendite_complete.rds")
message("  - output/grafici/distribuzione_importi.png")
message("  - output/grafici/vendite_per_categoria.png")
message("  - output/grafici/vendite_per_regione.png")
message(strrep("=", 70), "\n")

message("Next steps:")
message("  1. Open the charts in output/grafici/")
message("  2. Review the CSV exports in output/")
message("  3. Modify this script for your own data")
message("  4. See example_csv_database_combined.R for database integration\n")
