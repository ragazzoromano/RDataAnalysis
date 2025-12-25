# ==============================================================================
# Database Configuration Template
# ==============================================================================
# 
# Copy this file to 'db_config.R' and update with your actual credentials.
# The db_config.R file should be added to .gitignore to prevent committing
# sensitive information.
#
# ==============================================================================

# Load the main analysis system
source("sql_server_data_analysis.R")

# Load required packages
load_packages()

# ==============================================================================
# DATABASE CONFIGURATION EXAMPLES
# ==============================================================================

# Initialize Database Manager
db_manager <- DatabaseManager$new()

# ------------------------------------------------------------------------------
# Example 1: Windows Authentication (Trusted Connection)
# ------------------------------------------------------------------------------
# Use this for Windows integrated authentication (most common in corporate environments)

# db_manager$add_connection(
#   name = "sales_db",
#   server = "localhost",          # or "192.168.1.100" or "SERVERNAME\\INSTANCE"
#   database = "SalesDatabase",
#   trusted = TRUE,                # Windows authentication
#   port = 1433                    # Default SQL Server port
# )

# ------------------------------------------------------------------------------
# Example 2: SQL Server Authentication
# ------------------------------------------------------------------------------
# Use this when you have a SQL Server username and password

# db_manager$add_connection(
#   name = "crm_db",
#   server = "192.168.1.50",
#   database = "CRM",
#   username = "sql_user",
#   password = "your_password_here",
#   trusted = FALSE,               # SQL Server authentication
#   port = 1433
# )

# ------------------------------------------------------------------------------
# Example 3: Multiple Database Connections
# ------------------------------------------------------------------------------
# You can manage multiple connections simultaneously

# Production database
# db_manager$add_connection(
#   name = "prod",
#   server = "prod-server.company.com",
#   database = "Production_DB",
#   trusted = TRUE
# )

# Development database
# db_manager$add_connection(
#   name = "dev",
#   server = "dev-server.company.com",
#   database = "Development_DB",
#   trusted = TRUE
# )

# Data warehouse
# db_manager$add_connection(
#   name = "dwh",
#   server = "dwh-server.company.com",
#   database = "DataWarehouse",
#   trusted = TRUE
# )

# ------------------------------------------------------------------------------
# Example 4: Azure SQL Database
# ------------------------------------------------------------------------------
# For Azure SQL Database connections

# db_manager$add_connection(
#   name = "azure_db",
#   server = "myserver.database.windows.net",
#   database = "MyAzureDB",
#   username = "azure_admin",
#   password = "Azure_Password_123",
#   trusted = FALSE,
#   port = 1433
# )

# ==============================================================================
# USAGE EXAMPLES
# ==============================================================================

# List all active connections
# db_manager$list_connections()

# Execute a simple query
# data <- query_database(db_manager, "sales_db", "SELECT TOP 10 * FROM Orders")

# Get entire table
# customers <- get_table(db_manager, "crm_db", "Customers")

# Execute query with parameters (using parameterized queries is recommended for security)
# query <- "
#   SELECT 
#     OrderID, 
#     CustomerID, 
#     OrderDate, 
#     TotalAmount
#   FROM Orders
#   WHERE OrderDate >= '2024-01-01'
#     AND Status = 'Completed'
#   ORDER BY OrderDate DESC
# "
# orders_2024 <- query_database(db_manager, "sales_db", query)

# Close specific connection when done
# db_manager$close_connection("sales_db")

# Close all connections
# db_manager$close_all()

# ==============================================================================
# CSV IMPORT CONFIGURATION
# ==============================================================================

# Define standard paths for your CSV files
CSV_DATA_DIR <- "data/input"
CSV_OUTPUT_DIR <- "output"
CSV_ARCHIVE_DIR <- "data/archive"

# Standard encoding for your organization
# Common options: "UTF-8", "Latin1", "Windows-1252", "ISO-8859-1"
DEFAULT_ENCODING <- "UTF-8"

# Standard delimiter
# Common options: ",", ";", "\t" (tab), "|"
DEFAULT_DELIMITER <- ","

# ==============================================================================
# ANALYSIS CONFIGURATION
# ==============================================================================

# Default missing value handling strategy
DEFAULT_NA_STRATEGY <- "report"  # Options: "report", "remove", "impute_mean", "impute_median"

# Default visualization settings
VIZ_WIDTH <- 10
VIZ_HEIGHT <- 6
VIZ_DPI <- 300

# ==============================================================================
# NOTES
# ==============================================================================

# 1. SQL Server ODBC Driver Installation:
#    - Windows: Usually pre-installed
#    - Linux: sudo apt-get install unixodbc-dev odbc-postgresql
#    - macOS: brew install unixodbc
#
#    Download ODBC Driver 17 for SQL Server:
#    https://docs.microsoft.com/en-us/sql/connect/odbc/download-odbc-driver-for-sql-server

# 2. Security Best Practices:
#    - Never commit passwords to version control
#    - Use environment variables for sensitive data:
#      Sys.getenv("DB_PASSWORD")
#    - Use Windows Authentication when possible
#    - Limit database user permissions to minimum required

# 3. Connection String Troubleshooting:
#    - Verify SQL Server is accepting remote connections
#    - Check firewall settings (port 1433 must be open)
#    - Verify SQL Server Browser service is running (for named instances)
#    - Test connection with SQL Server Management Studio first

# ==============================================================================
# ENVIRONMENT VARIABLES (Recommended for sensitive data)
# ==============================================================================

# Example using environment variables:
# 
# # Set in your .Renviron file or system environment:
# # DB_SERVER=myserver.database.windows.net
# # DB_NAME=MyDatabase
# # DB_USER=myuser
# # DB_PASSWORD=mypassword
# 
# db_manager$add_connection(
#   name = "secure_db",
#   server = Sys.getenv("DB_SERVER"),
#   database = Sys.getenv("DB_NAME"),
#   username = Sys.getenv("DB_USER"),
#   password = Sys.getenv("DB_PASSWORD"),
#   trusted = FALSE
# )

message("Configuration template loaded. Copy to 'db_config.R' and customize.")
