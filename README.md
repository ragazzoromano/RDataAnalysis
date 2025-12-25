# R Data Analysis System

Complete system for data analysis in R with support for SQL Server databases and CSV files. Import, clean, analyze, and visualize data from multiple sources with an integrated, easy-to-use framework.

![R Version](https://img.shields.io/badge/R-%E2%89%A54.0-blue)
![License](https://img.shields.io/badge/license-MIT-green)

## 🌟 Features

- **📊 SQL Server Integration**: Complete DatabaseManager class for managing multiple database connections
- **📁 CSV Import**: Advanced CSV import with encoding detection, multiple delimiters, and filtering
- **🧹 Data Cleaning**: Automatic data cleaning with missing value handling
- **📈 Statistical Analysis**: Descriptive statistics and group analysis functions
- **📉 Visualizations**: Professional charts with ggplot2
- **💾 Export**: Export results to CSV, RDS, and Excel formats
- **🔗 Data Integration**: Seamlessly combine data from CSV files and databases

---

## 📋 Table of Contents

- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Database Connections](#database-connections)
- [CSV Import](#csv-import)
- [Data Cleaning & Analysis](#data-cleaning--analysis)
- [Visualizations](#visualizations)
- [Complete Pipeline Example](#complete-pipeline-example)
- [Troubleshooting](#troubleshooting)
- [Examples](#examples)

---

## ⚙️ Prerequisites

### System Requirements

- **R** version 4.0 or higher
- **RStudio** (recommended)

### SQL Server ODBC Driver (for database functionality)

#### Windows
Usually pre-installed. If not, download from:
- [Microsoft ODBC Driver 17 for SQL Server](https://docs.microsoft.com/en-us/sql/connect/odbc/download-odbc-driver-for-sql-server)

#### Linux (Ubuntu/Debian)
```bash
sudo apt-get install unixodbc-dev
sudo apt-get install odbcinst
```

Then install the Microsoft ODBC Driver:
```bash
curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add -
curl https://packages.microsoft.com/config/ubuntu/20.04/prod.list > /etc/apt/sources.list.d/mssql-release.list
sudo apt-get update
sudo ACCEPT_EULA=Y apt-get install msodbcsql17
```

#### macOS
```bash
brew install unixodbc
brew tap microsoft/mssql-release
brew install msodbcsql17
```

---

## 📦 Installation

### 1. Clone the Repository

```bash
git clone https://github.com/ragazzoromano/RDataAnalysis.git
cd RDataAnalysis
```

### 2. Install Required R Packages

Open R or RStudio and run:

```r
# Load the system and install packages automatically
source("sql_server_data_analysis.R")
load_packages()
```

Or install manually:

```r
install.packages(c(
  "DBI",           # Database interface
  "odbc",          # ODBC connections
  "dplyr",         # Data manipulation
  "tidyr",         # Data tidying
  "readr",         # Fast CSV reading
  "ggplot2",       # Visualizations
  "janitor",       # Data cleaning
  "R6"             # Object-oriented programming
))
```

---

## 🚀 Quick Start

### Minimal Example (CSV Only)

```r
# Load the system
source("sql_server_data_analysis.R")
load_packages()

# Import CSV
data <- import_csv("data/examples/vendite.csv")

# Clean
data_clean <- clean_data(data)

# Analyze
stats <- descriptive_stats(data_clean)

# Visualize
plot <- plot_distribution(data_clean, "importo", "Sales Distribution")
print(plot)
```

### Run Example Scripts

```r
# CSV import and analysis example
source("examples/example_csv_import.R")

# CSV + Database integration example
source("examples/example_csv_database_combined.R")
```

---

## 🗄️ Database Connections

### Initialize Database Manager

```r
# Load system
source("sql_server_data_analysis.R")
load_packages()

# Create database manager
db_mgr <- DatabaseManager$new()
```

### Windows Authentication (Recommended)

```r
db_mgr$add_connection(
  name = "sales_db",
  server = "localhost",              # or IP/hostname
  database = "SalesDatabase",
  trusted = TRUE,                    # Windows authentication
  port = 1433                        # Default SQL Server port
)
```

### SQL Server Authentication

```r
db_mgr$add_connection(
  name = "crm_db",
  server = "192.168.1.100",
  database = "CRM",
  username = "sql_user",
  password = "your_password",
  trusted = FALSE,
  port = 1433
)
```

### Azure SQL Database

```r
db_mgr$add_connection(
  name = "azure_db",
  server = "myserver.database.windows.net",
  database = "MyAzureDB",
  username = "azure_admin",
  password = "Azure_Password",
  trusted = FALSE,
  port = 1433
)
```

### Execute Queries

```r
# Simple query
data <- query_database(db_mgr, "sales_db", "SELECT * FROM Orders WHERE Year = 2024")

# Get entire table
customers <- get_table(db_mgr, "crm_db", "Customers")

# Complex query
query <- "
  SELECT 
    o.OrderID,
    c.CustomerName,
    o.OrderDate,
    SUM(od.Quantity * od.Price) as Total
  FROM Orders o
  JOIN Customers c ON o.CustomerID = c.CustomerID
  JOIN OrderDetails od ON o.OrderID = od.OrderID
  WHERE o.OrderDate >= '2024-01-01'
  GROUP BY o.OrderID, c.CustomerName, o.OrderDate
  ORDER BY Total DESC
"
results <- query_database(db_mgr, "sales_db", query)
```

### Manage Connections

```r
# List all connections
db_mgr$list_connections()

# Close specific connection
db_mgr$close_connection("sales_db")

# Close all connections
db_mgr$close_all()
```

---

## 📁 CSV Import

### Basic Import

```r
# Simple import with defaults (UTF-8, comma delimiter)
data <- import_csv("data/myfile.csv")
```

### Different Encodings

```r
# UTF-8 (default)
data <- import_csv("data/file.csv", encoding = "UTF-8")

# Latin1 / ISO-8859-1 (common in Europe)
data <- import_csv("data/file.csv", encoding = "Latin1")

# Windows-1252 (Windows default)
data <- import_csv("data/file.csv", encoding = "Windows-1252")
```

### Different Delimiters

```r
# Comma (default)
data <- import_csv("data/file.csv", delimiter = ",")

# Semicolon (common in European Excel exports)
data <- import_csv("data/file.csv", delimiter = ";")

# Tab-separated
data <- import_csv("data/file.tsv", delimiter = "\t")

# Pipe-separated
data <- import_csv("data/file.txt", delimiter = "|")
```

### Advanced Options

```r
# Skip header rows
data <- import_csv("data/file.csv", skip = 2)

# Custom NA strings
data <- import_csv("data/file.csv", na_strings = c("", "NA", "NULL", "N/A", "missing"))
```

### Import Multiple Files

```r
# Import all CSV files from directory
all_data <- import_multiple_csv(
  directory = "data/sales",
  pattern = "\\.csv$",
  combine = TRUE,           # Combine into single data frame
  recursive = FALSE         # Don't search subdirectories
)

# Keep files separate (returns list)
data_list <- import_multiple_csv(
  directory = "data/sales",
  combine = FALSE
)

# Access individual files
january_data <- data_list[["sales_january.csv"]]
```

### Advanced Import with Filtering

```r
# Import with column selection and date conversion
data <- import_csv_advanced(
  file_path = "data/sales.csv",
  select_cols = c("ID", "Date", "Amount", "Customer"),
  date_cols = "Date",
  date_format = "%Y-%m-%d",
  numeric_cols = c("Amount"),
  preview_rows = 5
)

# Import with filtering function
large_orders <- import_csv_advanced(
  file_path = "data/orders.csv",
  filter_function = function(x) x$Amount > 1000,
  date_cols = "OrderDate"
)
```

### Validate CSV Data

```r
# Validate imported data
validation <- validate_csv(
  data,
  required_cols = c("ID", "Date", "Amount"),
  check_duplicates = TRUE
)

# Check validation result
if (validation$valid) {
  message("Data validation passed!")
} else {
  message("Validation issues found:")
  print(validation$issues)
}
```

---

## 🔗 Combining CSV and Database Data

### Simple Row Binding

```r
# Combine data with same structure
csv_data <- import_csv("data/external_sales.csv")
db_data <- query_database(db_mgr, "sales_db", "SELECT * FROM Sales")

combined <- combine_csv_database(csv_data, db_data, join_by = NULL)
```

### Join on Key

```r
# Inner join on customer ID
csv_data <- import_csv("data/customer_details.csv")
db_data <- query_database(db_mgr, "crm_db", "SELECT * FROM Customers")

combined <- combine_csv_database(
  csv_data,
  db_data,
  join_by = "CustomerID",
  join_type = "inner"
)
```

### Different Join Types

```r
# Left join (keep all CSV records)
combined <- combine_csv_database(csv_data, db_data, join_by = "ID", join_type = "left")

# Right join (keep all database records)
combined <- combine_csv_database(csv_data, db_data, join_by = "ID", join_type = "right")

# Full join (keep all records from both)
combined <- combine_csv_database(csv_data, db_data, join_by = "ID", join_type = "full")
```

### Real-World Integration Example

```r
# Import sales from CSV
sales_csv <- import_csv("data/external_sales.csv")

# Query customers from database
customers_db <- query_database(db_mgr, "crm_db", "SELECT * FROM Customers")

# Combine sales with customer information
sales_enriched <- dplyr::left_join(sales_csv, customers_db, by = "CustomerID")

# Analyze by customer segment
by_segment <- sales_enriched %>%
  dplyr::group_by(CustomerSegment) %>%
  dplyr::summarise(
    TotalSales = sum(Amount, na.rm = TRUE),
    OrderCount = n(),
    AvgOrderValue = mean(Amount, na.rm = TRUE)
  )
```

---

## 🧹 Data Cleaning & Analysis

### Automatic Cleaning

```r
# Clean data (standardize names, remove empty rows/columns)
data_clean <- clean_data(
  data,
  remove_empty_cols = TRUE,
  remove_empty_rows = TRUE,
  clean_names = TRUE        # Standardize column names
)
```

### Handle Missing Values

```r
# Report missing values
data <- handle_missing_values(data, strategy = "report")

# Remove rows with missing values
data_complete <- handle_missing_values(data, strategy = "remove")

# Impute with mean
data_imputed <- handle_missing_values(data, strategy = "impute_mean")

# Impute with median
data_imputed <- handle_missing_values(data, strategy = "impute_median")

# Handle specific columns only
data <- handle_missing_values(
  data, 
  strategy = "impute_mean",
  columns = c("Price", "Quantity")
)
```

### Descriptive Statistics

```r
# Calculate statistics for numeric columns
stats <- descriptive_stats(data)

# Statistics include: n, missing, mean, median, sd, min, max
print(stats)
```

### Group Analysis

```r
# Count by category
by_category <- group_analysis(data, "Category")

# Sum by category
sales_by_cat <- group_analysis(data, "Category", "Amount", fun = "sum")

# Average by region
avg_by_region <- group_analysis(data, "Region", "Sales", fun = "mean")

# Multiple grouping with dplyr
detailed_analysis <- data %>%
  dplyr::group_by(Region, Category) %>%
  dplyr::summarise(
    TotalSales = sum(Amount, na.rm = TRUE),
    Count = n(),
    AvgSale = mean(Amount, na.rm = TRUE),
    .groups = "drop"
  )
```

---

## 📊 Visualizations

### Distribution Histogram

```r
# Basic histogram
p <- plot_distribution(data, "Amount")
print(p)

# Customized histogram
p <- plot_distribution(
  data,
  variable = "Amount",
  title = "Sales Amount Distribution",
  bins = 30
)
ggsave("distribution.png", p, width = 10, height = 6, dpi = 300)
```

### Category Bar Charts

```r
# Count by category
p <- plot_category_bars(data, "Category")
print(p)

# Sum values by category
p <- plot_category_bars(
  data,
  category_var = "Category",
  value_var = "Amount",
  title = "Total Sales by Category",
  top_n = 10
)
ggsave("sales_by_category.png", p, width = 10, height = 6)
```

### Time Series

```r
# Prepare time series data
daily_sales <- data %>%
  dplyr::group_by(Date) %>%
  dplyr::summarise(DailySales = sum(Amount, na.rm = TRUE))

# Plot time series
p <- plot_time_series(
  daily_sales,
  date_var = "Date",
  value_var = "DailySales",
  title = "Daily Sales Trend"
)
print(p)
ggsave("time_series.png", p, width = 12, height = 6)
```

### Advanced Visualizations with ggplot2

```r
# Faceted plot by category
p <- ggplot2::ggplot(data, ggplot2::aes(x = Amount)) +
  ggplot2::geom_histogram(bins = 20, fill = "steelblue") +
  ggplot2::facet_wrap(~Category, scales = "free") +
  ggplot2::theme_minimal() +
  ggplot2::labs(title = "Sales Distribution by Category")

# Scatter plot with trend line
p <- ggplot2::ggplot(data, ggplot2::aes(x = Quantity, y = Amount)) +
  ggplot2::geom_point(alpha = 0.5) +
  ggplot2::geom_smooth(method = "lm", color = "red") +
  ggplot2::theme_minimal() +
  ggplot2::labs(title = "Quantity vs Amount")
```

---

## 💾 Export Results

### CSV Export

```r
export_results(data, "output/results.csv", format = "csv")
```

### RDS Export (R native format)

```r
# Faster loading, preserves R data types
export_results(data, "output/results.rds", format = "rds")

# Load back
data <- readRDS("output/results.rds")
```

### Excel Export

```r
export_results(data, "output/results.xlsx", format = "excel")
```

### Export Multiple Sheets to Excel

```r
# Using writexl package
library(writexl)
data_list <- list(
  Sales = sales_data,
  Customers = customer_data,
  Summary = summary_stats
)
writexl::write_xlsx(data_list, "output/complete_report.xlsx")
```

---

## 🔄 Complete Pipeline Example

### End-to-End Analysis Pipeline

```r
# Load system
source("sql_server_data_analysis.R")
load_packages()

# ====================
# 1. IMPORT DATA
# ====================

# From CSV
sales_csv <- import_csv("data/external_sales.csv", encoding = "UTF-8")
customers_csv <- import_csv("data/customers.csv", delimiter = ";")

# From Database (if available)
# db_mgr <- DatabaseManager$new()
# db_mgr$add_connection("crm", "server", "CRM_DB", trusted = TRUE)
# orders_db <- query_database(db_mgr, "crm", "SELECT * FROM Orders")

# ====================
# 2. VALIDATE & CLEAN
# ====================

# Validate
validate_csv(sales_csv, required_cols = c("ID", "Date", "Amount"))

# Clean
sales_clean <- clean_data(sales_csv)
sales_clean <- handle_missing_values(sales_clean, strategy = "report")

# ====================
# 3. COMBINE DATA
# ====================

# Merge sales with customers
sales_complete <- dplyr::left_join(
  sales_clean,
  customers_csv,
  by = "CustomerID"
)

# If using database data:
# sales_all <- combine_csv_database(sales_clean, orders_db, join_by = "OrderID")

# ====================
# 4. ANALYZE
# ====================

# Descriptive statistics
stats <- descriptive_stats(sales_complete)

# Group analysis
by_category <- group_analysis(sales_complete, "Category", "Amount", "sum")
by_region <- group_analysis(sales_complete, "Region", "Amount", "sum")
by_customer_type <- group_analysis(sales_complete, "CustomerType", "Amount", "sum")

# Custom analysis
monthly_summary <- sales_complete %>%
  dplyr::mutate(Month = format(as.Date(Date), "%Y-%m")) %>%
  dplyr::group_by(Month, Category) %>%
  dplyr::summarise(
    TotalSales = sum(Amount, na.rm = TRUE),
    OrderCount = n(),
    AvgOrderValue = mean(Amount, na.rm = TRUE),
    .groups = "drop"
  )

# ====================
# 5. VISUALIZE
# ====================

# Create output directory
dir.create("output/grafici", recursive = TRUE, showWarnings = FALSE)

# Distribution
p1 <- plot_distribution(sales_complete, "Amount", "Sales Amount Distribution", bins = 30)
ggsave("output/grafici/distribution.png", p1, width = 10, height = 6, dpi = 300)

# Category bars
p2 <- plot_category_bars(sales_complete, "Category", "Amount", "Sales by Category")
ggsave("output/grafici/by_category.png", p2, width = 10, height = 6, dpi = 300)

# Time series
daily_sales <- sales_complete %>%
  dplyr::group_by(Date) %>%
  dplyr::summarise(DailySales = sum(Amount, na.rm = TRUE))

p3 <- plot_time_series(daily_sales, "Date", "DailySales", "Daily Sales Trend")
ggsave("output/grafici/time_series.png", p3, width = 12, height = 6, dpi = 300)

# ====================
# 6. EXPORT RESULTS
# ====================

# Export data
export_results(sales_complete, "output/sales_complete.csv", "csv")
export_results(sales_complete, "output/sales_complete.rds", "rds")

# Export analysis
export_results(stats, "output/statistics.csv", "csv")
export_results(by_category, "output/by_category.csv", "csv")
export_results(by_region, "output/by_region.csv", "csv")
export_results(monthly_summary, "output/monthly_summary.csv", "csv")

# Export to Excel with multiple sheets
library(writexl)
report_data <- list(
  Summary = stats,
  ByCategory = by_category,
  ByRegion = by_region,
  MonthlySummary = monthly_summary,
  RawData = sales_complete
)
writexl::write_xlsx(report_data, "output/complete_report.xlsx")

# ====================
# 7. CLEANUP
# ====================

# Close database connections if used
# db_mgr$close_all()

message("Analysis complete! Check the output/ directory for results.")
```

---

## 🔧 Troubleshooting

### Common CSV Import Issues

#### Encoding Problems

**Problem**: Characters appear as � or gibberish

**Solutions**:
```r
# Try different encodings
data <- import_csv("file.csv", encoding = "Latin1")
data <- import_csv("file.csv", encoding = "Windows-1252")
data <- import_csv("file.csv", encoding = "ISO-8859-1")

# Check file encoding in terminal
# system("file -i myfile.csv")
```

#### Wrong Delimiter

**Problem**: All data appears in one column

**Solutions**:
```r
# Try different delimiters
data <- import_csv("file.csv", delimiter = ";")
data <- import_csv("file.csv", delimiter = "\t")  # Tab
data <- import_csv("file.csv", delimiter = "|")

# Inspect file manually
readLines("file.csv", n = 2)
```

#### Column Type Issues

**Problem**: Numeric columns imported as character

**Solutions**:
```r
# Force numeric conversion
data <- import_csv_advanced(
  "file.csv",
  numeric_cols = c("Amount", "Quantity", "Price")
)

# Or manually convert after import
data$Amount <- as.numeric(gsub(",", ".", data$Amount))  # Handle European decimals
```

### Database Connection Issues

#### ODBC Driver Not Found

**Problem**: Error about ODBC Driver 17

**Solution**:
```r
# Check available drivers
odbc::odbcListDrivers()

# If ODBC Driver 17 not found, try:
# - Install from Microsoft website
# - Or modify connection string to use available driver:

db_mgr$add_connection(
  name = "db",
  server = "server",
  database = "DB",
  trusted = TRUE
)
# The function will try "ODBC Driver 17 for SQL Server"
```

#### Connection Timeout

**Problem**: Connection takes too long or times out

**Solutions**:
```r
# Verify server is accessible
# ping server-name

# Check firewall settings (port 1433)
# Test with SQL Server Management Studio first

# Verify SQL Server Browser service is running (for named instances)
```

#### Authentication Failed

**Problem**: Login failed for user

**Solutions**:
```r
# For Windows Authentication:
# - Ensure SQL Server allows Windows authentication
# - Run R/RStudio with appropriate Windows credentials

# For SQL Authentication:
# - Verify username and password
# - Ensure SQL Server allows mixed mode authentication
# - Check user permissions on database

# Test connection
db_mgr$add_connection(
  name = "test",
  server = "localhost",
  database = "master",  # Try master database first
  trusted = TRUE
)
```

### Memory Issues with Large Files

**Problem**: R runs out of memory with large CSV files

**Solutions**:
```r
# Use chunked reading (advanced)
library(readr)
file_conn <- readr::read_csv_chunked(
  "large_file.csv",
  callback = DataFrameCallback$new(function(x, pos) x),
  chunk_size = 10000
)

# Select only needed columns
data <- import_csv_advanced(
  "large_file.csv",
  select_cols = c("ID", "Date", "Amount")  # Only needed columns
)

# Filter during import
data <- import_csv_advanced(
  "large_file.csv",
  filter_function = function(x) x$Year == 2024  # Only recent data
)
```

---

## 📚 Examples

### Example Files Included

The repository includes complete example files:

- **`data/examples/vendite.csv`**: Sample sales data (30 transactions)
- **`data/examples/clienti.csv`**: Customer master data (17 customers)
- **`data/examples/prodotti.csv`**: Product catalog (30 products)
- **`examples/example_csv_import.R`**: Complete CSV import and analysis example
- **`examples/example_csv_database_combined.R`**: CSV + Database integration example

### Run Examples

```r
# CSV import example (no database required)
source("examples/example_csv_import.R")

# CSV + Database example
source("examples/example_csv_database_combined.R")
```

### Learning Path

1. **Start with CSV examples**: Run `example_csv_import.R` to understand CSV import, cleaning, and analysis
2. **Explore database functionality**: Configure `config_template.R` and test database connections
3. **Combine data sources**: Use `example_csv_database_combined.R` as a template
4. **Customize for your data**: Adapt the examples to your specific data and requirements
5. **Build your pipeline**: Create your own end-to-end analysis scripts

---

## 📖 Function Reference

### Database Functions

| Function | Description |
|----------|-------------|
| `DatabaseManager$new()` | Create database manager |
| `add_connection()` | Add database connection |
| `get_connection()` | Get connection by name |
| `list_connections()` | List all connections |
| `close_connection()` | Close specific connection |
| `close_all()` | Close all connections |
| `query_database()` | Execute SQL query |
| `get_table()` | Get entire table |

### CSV Import Functions

| Function | Description |
|----------|-------------|
| `import_csv()` | Basic CSV import |
| `import_multiple_csv()` | Import multiple files |
| `import_csv_advanced()` | Advanced import with filtering |
| `validate_csv()` | Validate data quality |
| `combine_csv_database()` | Combine CSV and database data |

### Cleaning Functions

| Function | Description |
|----------|-------------|
| `clean_data()` | Automatic data cleaning |
| `handle_missing_values()` | Handle NA values |

### Analysis Functions

| Function | Description |
|----------|-------------|
| `descriptive_stats()` | Descriptive statistics |
| `group_analysis()` | Group-by analysis |

### Visualization Functions

| Function | Description |
|----------|-------------|
| `plot_distribution()` | Histogram |
| `plot_category_bars()` | Bar chart |
| `plot_time_series()` | Time series line chart |

### Export Functions

| Function | Description |
|----------|-------------|
| `export_results()` | Export to CSV/RDS/Excel |

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

---

## 📄 License

This project is licensed under the MIT License.

---

## 👤 Author

**Romano**

- GitHub: [@ragazzoromano](https://github.com/ragazzoromano)

---

## 🙏 Acknowledgments

- Built with [R](https://www.r-project.org/)
- Data manipulation with [dplyr](https://dplyr.tidyverse.org/) and [tidyr](https://tidyr.tidyverse.org/)
- Visualizations with [ggplot2](https://ggplot2.tidyverse.org/)
- Fast CSV reading with [readr](https://readr.tidyverse.org/)
- Database connectivity with [DBI](https://dbi.r-dbi.org/) and [odbc](https://github.com/r-dbi/odbc)

---

## 📞 Support

If you encounter any problems or have questions:

1. Check the [Troubleshooting](#troubleshooting) section
2. Review the example scripts in `examples/`
3. Open an issue on GitHub

---

**Happy Analyzing! 📊✨**
