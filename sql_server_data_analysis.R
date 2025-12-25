# ==============================================================================
# SQL Server Data Analysis System
# Complete system for data import, cleaning, analysis and visualization
# ==============================================================================

# Required packages
required_packages <- c(
  "DBI",           # Database interface
  "odbc",          # ODBC database connections
  "dplyr",         # Data manipulation
  "tidyr",         # Data tidying
  "readr",         # Fast CSV reading
  "ggplot2",       # Visualizations
  "janitor",       # Data cleaning
  "R6"             # Object-oriented programming
)

# Function to install and load packages
load_packages <- function() {
  for (pkg in required_packages) {
    if (!requireNamespace(pkg, quietly = TRUE)) {
      message(sprintf("Installing package: %s", pkg))
      install.packages(pkg, repos = "https://cloud.r-project.org")
    }
    suppressPackageStartupMessages(library(pkg, character.only = TRUE))
  }
  message("All required packages loaded successfully!")
}

# ==============================================================================
# DATABASE MANAGEMENT
# ==============================================================================

#' DatabaseManager Class
#' 
#' R6 class for managing multiple SQL Server database connections
#' 
#' @field connections List of database connections
#' @field connection_info Information about each connection
#' 
#' @examples
#' \dontrun{
#' db_mgr <- DatabaseManager$new()
#' db_mgr$add_connection("db1", "localhost", "MyDatabase", trusted = TRUE)
#' data <- query_database(db_mgr, "db1", "SELECT * FROM table")
#' db_mgr$close_all()
#' }
DatabaseManager <- R6::R6Class(
  "DatabaseManager",
  public = list(
    connections = NULL,
    connection_info = NULL,
    
    #' @description Initialize DatabaseManager
    initialize = function() {
      self$connections <- list()
      self$connection_info <- list()
      message("DatabaseManager initialized")
    },
    
    #' @description Add a new database connection
    #' @param name Connection name
    #' @param server Server name or IP
    #' @param database Database name
    #' @param username Username (NULL for Windows auth)
    #' @param password Password (NULL for Windows auth)
    #' @param trusted Use Windows authentication
    #' @param port Port number (default: 1433)
    add_connection = function(name, server, database, 
                            username = NULL, password = NULL,
                            trusted = TRUE, port = 1433) {
      tryCatch({
        # Build connection string
        if (trusted) {
          conn_string <- sprintf(
            "Driver={ODBC Driver 17 for SQL Server};Server=%s,%s;Database=%s;Trusted_Connection=yes;",
            server, port, database
          )
        } else {
          if (is.null(username) || is.null(password)) {
            stop("Username and password required for SQL Server authentication")
          }
          conn_string <- sprintf(
            "Driver={ODBC Driver 17 for SQL Server};Server=%s,%s;Database=%s;UID=%s;PWD=%s;",
            server, port, database, username, password
          )
        }
        
        # Establish connection
        conn <- DBI::dbConnect(odbc::odbc(), .connection_string = conn_string)
        
        # Store connection
        self$connections[[name]] <- conn
        self$connection_info[[name]] <- list(
          server = server,
          database = database,
          connected_at = Sys.time()
        )
        
        message(sprintf("Connection '%s' established successfully to %s/%s", 
                       name, server, database))
        invisible(self)
      }, error = function(e) {
        stop(sprintf("Failed to connect to %s/%s: %s", server, database, e$message))
      })
    },
    
    #' @description Get a connection by name
    #' @param name Connection name
    get_connection = function(name) {
      if (!(name %in% names(self$connections))) {
        stop(sprintf("Connection '%s' not found", name))
      }
      self$connections[[name]]
    },
    
    #' @description List all connections
    list_connections = function() {
      if (length(self$connections) == 0) {
        message("No connections available")
        return(invisible(NULL))
      }
      
      cat("\nActive Connections:\n")
      cat(strrep("-", 60), "\n")
      for (name in names(self$connections)) {
        info <- self$connection_info[[name]]
        cat(sprintf("  %s: %s/%s (connected at %s)\n", 
                   name, info$server, info$database, 
                   format(info$connected_at, "%Y-%m-%d %H:%M:%S")))
      }
      cat(strrep("-", 60), "\n")
      invisible(self)
    },
    
    #' @description Close a specific connection
    #' @param name Connection name
    close_connection = function(name) {
      if (name %in% names(self$connections)) {
        DBI::dbDisconnect(self$connections[[name]])
        self$connections[[name]] <- NULL
        self$connection_info[[name]] <- NULL
        message(sprintf("Connection '%s' closed", name))
      } else {
        warning(sprintf("Connection '%s' not found", name))
      }
      invisible(self)
    },
    
    #' @description Close all connections
    close_all = function() {
      for (name in names(self$connections)) {
        self$close_connection(name)
      }
      message("All connections closed")
      invisible(self)
    }
  )
)

#' Execute a query on a database connection
#' 
#' @param db_manager DatabaseManager object
#' @param connection_name Name of the connection
#' @param query SQL query string
#' @return Data frame with query results
#' 
#' @export
query_database <- function(db_manager, connection_name, query) {
  tryCatch({
    conn <- db_manager$get_connection(connection_name)
    result <- DBI::dbGetQuery(conn, query)
    message(sprintf("Query executed successfully: %d rows returned", nrow(result)))
    return(result)
  }, error = function(e) {
    stop(sprintf("Query failed: %s", e$message))
  })
}

#' Get table from database
#' 
#' @param db_manager DatabaseManager object
#' @param connection_name Name of the connection
#' @param table_name Name of the table
#' @return Data frame with table contents
#' 
#' @export
get_table <- function(db_manager, connection_name, table_name) {
  query <- sprintf("SELECT * FROM %s", table_name)
  query_database(db_manager, connection_name, query)
}

# ==============================================================================
# CSV IMPORT FUNCTIONS
# ==============================================================================

#' Import CSV file with advanced options
#' 
#' @param file_path Path to CSV file
#' @param encoding File encoding (UTF-8, Latin1, Windows-1252)
#' @param delimiter Field delimiter
#' @param col_types Column type specification (NULL for auto-detection)
#' @param skip Number of lines to skip
#' @param na_strings Strings to interpret as NA
#' @return Data frame with imported data
#' 
#' @export
import_csv <- function(file_path, 
                      encoding = "UTF-8",
                      delimiter = ",",
                      col_types = NULL,
                      skip = 0,
                      na_strings = c("", "NA", "NULL")) {
  
  tryCatch({
    # Validate file exists
    if (!file.exists(file_path)) {
      stop(sprintf("File not found: %s", file_path))
    }
    
    # Import data
    message(sprintf("Importing CSV: %s", basename(file_path)))
    message(sprintf("  Encoding: %s, Delimiter: '%s'", encoding, delimiter))
    
    data <- readr::read_delim(
      file_path,
      delim = delimiter,
      locale = readr::locale(encoding = encoding),
      col_types = col_types,
      skip = skip,
      na = na_strings,
      show_col_types = FALSE
    )
    
    # Report import success
    message(sprintf("✓ Import successful: %d rows, %d columns", nrow(data), ncol(data)))
    message(sprintf("  Columns: %s", paste(names(data), collapse = ", ")))
    
    return(data)
    
  }, error = function(e) {
    warning(sprintf("Failed to import %s: %s", file_path, e$message))
    return(NULL)
  })
}

#' Import multiple CSV files from a directory
#' 
#' @param directory Directory path containing CSV files
#' @param pattern Regex pattern for file matching
#' @param combine If TRUE, combine all files into one data frame
#' @param recursive Search subdirectories
#' @return Data frame or list of data frames
#' 
#' @export
import_multiple_csv <- function(directory,
                               pattern = "\\.csv$",
                               combine = TRUE,
                               recursive = FALSE) {
  
  tryCatch({
    # Find CSV files
    files <- list.files(directory, pattern = pattern, 
                       full.names = TRUE, recursive = recursive)
    
    if (length(files) == 0) {
      warning(sprintf("No CSV files found in %s", directory))
      return(NULL)
    }
    
    message(sprintf("Found %d CSV file(s) in %s", length(files), directory))
    
    # Import all files
    data_list <- list()
    for (file in files) {
      file_name <- basename(file)
      data <- import_csv(file)
      
      if (!is.null(data)) {
        # Add source file column for traceability
        data$source_file <- file_name
        data_list[[file_name]] <- data
      }
    }
    
    # Combine if requested
    if (combine && length(data_list) > 0) {
      message("Combining all files...")
      combined_data <- dplyr::bind_rows(data_list)
      message(sprintf("✓ Combined data: %d total rows", nrow(combined_data)))
      return(combined_data)
    }
    
    return(data_list)
    
  }, error = function(e) {
    warning(sprintf("Error in multiple import: %s", e$message))
    return(NULL)
  })
}

#' Advanced CSV import with filtering and transformation
#' 
#' @param file_path Path to CSV file
#' @param select_cols Vector of column names to select (NULL for all)
#' @param filter_function Function to filter rows during import
#' @param date_cols Vector of column names to convert to dates
#' @param date_format Date format string
#' @param numeric_cols Vector of column names to convert to numeric
#' @param preview_rows Number of rows to preview after import
#' @return Data frame with imported and processed data
#' 
#' @export
import_csv_advanced <- function(file_path,
                               select_cols = NULL,
                               filter_function = NULL,
                               date_cols = NULL,
                               date_format = "%Y-%m-%d",
                               numeric_cols = NULL,
                               preview_rows = 5) {
  
  tryCatch({
    # Import base data
    data <- import_csv(file_path)
    
    if (is.null(data)) {
      return(NULL)
    }
    
    original_rows <- nrow(data)
    
    # Select specific columns
    if (!is.null(select_cols)) {
      missing_cols <- setdiff(select_cols, names(data))
      if (length(missing_cols) > 0) {
        warning(sprintf("Columns not found: %s", paste(missing_cols, collapse = ", ")))
      }
      available_cols <- intersect(select_cols, names(data))
      data <- dplyr::select(data, dplyr::all_of(available_cols))
      message(sprintf("  Selected %d columns", length(available_cols)))
    }
    
    # Apply filter
    if (!is.null(filter_function)) {
      data <- dplyr::filter(data, filter_function(.))
      message(sprintf("  Filter applied: %d rows remaining (%.1f%%)", 
                     nrow(data), 100 * nrow(data) / original_rows))
    }
    
    # Convert date columns
    if (!is.null(date_cols)) {
      for (col in date_cols) {
        if (col %in% names(data)) {
          data[[col]] <- as.Date(data[[col]], format = date_format)
          message(sprintf("  Converted '%s' to date", col))
        }
      }
    }
    
    # Convert numeric columns
    if (!is.null(numeric_cols)) {
      for (col in numeric_cols) {
        if (col %in% names(data)) {
          data[[col]] <- as.numeric(data[[col]])
          message(sprintf("  Converted '%s' to numeric", col))
        }
      }
    }
    
    # Preview data
    if (preview_rows > 0 && nrow(data) > 0) {
      message(sprintf("\nPreview (first %d rows):", min(preview_rows, nrow(data))))
      print(head(data, preview_rows))
    }
    
    return(data)
    
  }, error = function(e) {
    warning(sprintf("Advanced import failed: %s", e$message))
    return(NULL)
  })
}

#' Validate CSV data quality
#' 
#' @param data Data frame to validate
#' @param required_cols Vector of required column names
#' @param check_duplicates Check for duplicate rows
#' @return List with validation results
#' 
#' @export
validate_csv <- function(data, 
                        required_cols = NULL, 
                        check_duplicates = TRUE) {
  
  validation_report <- list(
    valid = TRUE,
    issues = c()
  )
  
  message("\n=== CSV Data Validation ===")
  
  # Check required columns
  if (!is.null(required_cols)) {
    missing_cols <- setdiff(required_cols, names(data))
    if (length(missing_cols) > 0) {
      validation_report$valid <- FALSE
      issue <- sprintf("Missing required columns: %s", paste(missing_cols, collapse = ", "))
      validation_report$issues <- c(validation_report$issues, issue)
      warning(issue)
    } else {
      message("✓ All required columns present")
    }
  }
  
  # Check for empty data
  if (nrow(data) == 0) {
    validation_report$valid <- FALSE
    validation_report$issues <- c(validation_report$issues, "Data frame is empty")
    warning("Data frame is empty")
  } else {
    message(sprintf("✓ Data contains %d rows", nrow(data)))
  }
  
  # Check for duplicates
  if (check_duplicates) {
    n_duplicates <- sum(duplicated(data))
    if (n_duplicates > 0) {
      issue <- sprintf("Found %d duplicate rows (%.1f%%)", 
                      n_duplicates, 100 * n_duplicates / nrow(data))
      validation_report$issues <- c(validation_report$issues, issue)
      warning(issue)
    } else {
      message("✓ No duplicate rows found")
    }
  }
  
  # Check for missing values
  na_summary <- sapply(data, function(x) sum(is.na(x)))
  cols_with_na <- na_summary[na_summary > 0]
  
  if (length(cols_with_na) > 0) {
    message("\nColumns with missing values:")
    for (col in names(cols_with_na)) {
      pct_na <- 100 * cols_with_na[[col]] / nrow(data)
      message(sprintf("  %s: %d missing (%.1f%%)", col, cols_with_na[[col]], pct_na))
    }
  } else {
    message("✓ No missing values found")
  }
  
  # Overall validation result
  if (validation_report$valid) {
    message("\n✓ Validation passed")
  } else {
    message("\n✗ Validation failed - see issues above")
  }
  
  return(validation_report)
}

#' Combine CSV data with database data
#' 
#' @param csv_data Data frame from CSV
#' @param db_data Data frame from database
#' @param join_by Column name(s) to join on
#' @param join_type Type of join (inner, left, right, full)
#' @return Combined data frame
#' 
#' @export
combine_csv_database <- function(csv_data, db_data, 
                                 join_by = NULL, 
                                 join_type = "inner") {
  
  tryCatch({
    message("\n=== Combining CSV and Database Data ===")
    message(sprintf("CSV data: %d rows, %d columns", nrow(csv_data), ncol(csv_data)))
    message(sprintf("DB data: %d rows, %d columns", nrow(db_data), ncol(db_data)))
    
    # If no join key specified, try to bind rows
    if (is.null(join_by)) {
      message("No join key specified - binding rows...")
      result <- dplyr::bind_rows(csv_data, db_data)
      message(sprintf("✓ Combined: %d total rows", nrow(result)))
      return(result)
    }
    
    # Perform join
    result <- switch(
      join_type,
      "inner" = dplyr::inner_join(csv_data, db_data, by = join_by),
      "left" = dplyr::left_join(csv_data, db_data, by = join_by),
      "right" = dplyr::right_join(csv_data, db_data, by = join_by),
      "full" = dplyr::full_join(csv_data, db_data, by = join_by),
      stop(sprintf("Invalid join type: %s", join_type))
    )
    
    message(sprintf("✓ %s join completed: %d rows", 
                   tools::toTitleCase(join_type), nrow(result)))
    
    return(result)
    
  }, error = function(e) {
    stop(sprintf("Failed to combine data: %s", e$message))
  })
}

# ==============================================================================
# DATA CLEANING FUNCTIONS
# ==============================================================================

#' Automatic data cleaning
#' 
#' @param data Data frame to clean
#' @param remove_empty_cols Remove columns with all NA values
#' @param remove_empty_rows Remove rows with all NA values
#' @param clean_names Standardize column names
#' @return Cleaned data frame
#' 
#' @export
clean_data <- function(data, 
                      remove_empty_cols = TRUE,
                      remove_empty_rows = TRUE,
                      clean_names = TRUE) {
  
  tryCatch({
    message("\n=== Cleaning Data ===")
    original_rows <- nrow(data)
    original_cols <- ncol(data)
    
    # Clean column names
    if (clean_names) {
      data <- janitor::clean_names(data)
      message("✓ Column names standardized")
    }
    
    # Remove empty columns
    if (remove_empty_cols) {
      data <- janitor::remove_empty(data, which = "cols")
      removed_cols <- original_cols - ncol(data)
      if (removed_cols > 0) {
        message(sprintf("✓ Removed %d empty column(s)", removed_cols))
      }
    }
    
    # Remove empty rows
    if (remove_empty_rows) {
      data <- janitor::remove_empty(data, which = "rows")
      removed_rows <- original_rows - nrow(data)
      if (removed_rows > 0) {
        message(sprintf("✓ Removed %d empty row(s)", removed_rows))
      }
    }
    
    message(sprintf("Cleaning complete: %d rows, %d columns", nrow(data), ncol(data)))
    
    return(data)
    
  }, error = function(e) {
    warning(sprintf("Cleaning failed: %s", e$message))
    return(data)
  })
}

#' Handle missing values
#' 
#' @param data Data frame
#' @param strategy Strategy for handling NAs (report, remove, impute_mean, impute_median)
#' @param columns Specific columns to process (NULL for all)
#' @return Data frame with missing values handled
#' 
#' @export
handle_missing_values <- function(data, 
                                  strategy = "report",
                                  columns = NULL) {
  
  if (is.null(columns)) {
    columns <- names(data)
  }
  
  message(sprintf("\n=== Handling Missing Values (strategy: %s) ===", strategy))
  
  if (strategy == "report") {
    # Just report missing values
    for (col in columns) {
      na_count <- sum(is.na(data[[col]]))
      if (na_count > 0) {
        pct <- 100 * na_count / nrow(data)
        message(sprintf("  %s: %d missing (%.1f%%)", col, na_count, pct))
      }
    }
    
  } else if (strategy == "remove") {
    # Remove rows with any NA in specified columns
    original_rows <- nrow(data)
    data <- data[complete.cases(data[, columns]), ]
    removed <- original_rows - nrow(data)
    message(sprintf("✓ Removed %d rows with missing values", removed))
    
  } else if (strategy %in% c("impute_mean", "impute_median")) {
    # Impute numeric columns
    for (col in columns) {
      if (is.numeric(data[[col]])) {
        na_count <- sum(is.na(data[[col]]))
        if (na_count > 0) {
          if (strategy == "impute_mean") {
            data[[col]][is.na(data[[col]])] <- mean(data[[col]], na.rm = TRUE)
            message(sprintf("✓ Imputed %d missing values in '%s' with mean", na_count, col))
          } else {
            data[[col]][is.na(data[[col]])] <- median(data[[col]], na.rm = TRUE)
            message(sprintf("✓ Imputed %d missing values in '%s' with median", na_count, col))
          }
        }
      }
    }
  }
  
  return(data)
}

# ==============================================================================
# ANALYSIS FUNCTIONS
# ==============================================================================

#' Calculate descriptive statistics
#' 
#' @param data Data frame
#' @param numeric_only Only analyze numeric columns
#' @return Data frame with statistics
#' 
#' @export
descriptive_stats <- function(data, numeric_only = TRUE) {
  
  message("\n=== Descriptive Statistics ===")
  
  if (numeric_only) {
    numeric_cols <- names(data)[sapply(data, is.numeric)]
    if (length(numeric_cols) == 0) {
      warning("No numeric columns found")
      return(NULL)
    }
    data <- data[, numeric_cols, drop = FALSE]
  }
  
  stats <- data.frame(
    variable = names(data),
    n = sapply(data, function(x) sum(!is.na(x))),
    missing = sapply(data, function(x) sum(is.na(x))),
    mean = sapply(data, function(x) if(is.numeric(x)) mean(x, na.rm = TRUE) else NA),
    median = sapply(data, function(x) if(is.numeric(x)) median(x, na.rm = TRUE) else NA),
    sd = sapply(data, function(x) if(is.numeric(x)) sd(x, na.rm = TRUE) else NA),
    min = sapply(data, function(x) if(is.numeric(x)) min(x, na.rm = TRUE) else NA),
    max = sapply(data, function(x) if(is.numeric(x)) max(x, na.rm = TRUE) else NA)
  )
  
  rownames(stats) <- NULL
  
  print(stats)
  
  return(stats)
}

#' Group analysis
#' 
#' @param data Data frame
#' @param group_var Grouping variable name
#' @param value_var Value variable name for aggregation
#' @param fun Aggregation function (mean, sum, count)
#' @return Data frame with grouped results
#' 
#' @export
group_analysis <- function(data, group_var, value_var = NULL, fun = "mean") {
  
  message(sprintf("\n=== Group Analysis by '%s' ===", group_var))
  
  if (!group_var %in% names(data)) {
    stop(sprintf("Group variable '%s' not found in data", group_var))
  }
  
  if (is.null(value_var)) {
    # Count by group
    result <- data %>%
      dplyr::group_by(across(all_of(group_var))) %>%
      dplyr::summarise(count = n(), .groups = "drop") %>%
      dplyr::arrange(desc(count))
  } else {
    if (!value_var %in% names(data)) {
      stop(sprintf("Value variable '%s' not found in data", value_var))
    }
    
    # Aggregate by function
    agg_fun <- switch(
      fun,
      "mean" = function(x) mean(x, na.rm = TRUE),
      "sum" = function(x) sum(x, na.rm = TRUE),
      "count" = function(x) n(),
      "median" = function(x) median(x, na.rm = TRUE),
      stop(sprintf("Unknown function: %s", fun))
    )
    
    result <- data %>%
      dplyr::group_by(across(all_of(group_var))) %>%
      dplyr::summarise(
        value = agg_fun(!!sym(value_var)),
        count = n(),
        .groups = "drop"
      ) %>%
      dplyr::arrange(desc(value))
  }
  
  print(result)
  
  return(result)
}

# ==============================================================================
# VISUALIZATION FUNCTIONS
# ==============================================================================

#' Plot distribution histogram
#' 
#' @param data Data frame
#' @param variable Variable to plot
#' @param title Plot title
#' @param bins Number of bins
#' @return ggplot object
#' 
#' @export
plot_distribution <- function(data, variable, title = NULL, bins = 30) {
  
  if (!variable %in% names(data)) {
    stop(sprintf("Variable '%s' not found in data", variable))
  }
  
  if (is.null(title)) {
    title <- sprintf("Distribution of %s", variable)
  }
  
  p <- ggplot2::ggplot(data, ggplot2::aes(x = .data[[variable]])) +
    ggplot2::geom_histogram(bins = bins, fill = "steelblue", color = "white") +
    ggplot2::labs(title = title, x = variable, y = "Frequency") +
    ggplot2::theme_minimal() +
    ggplot2::theme(
      plot.title = ggplot2::element_text(face = "bold", size = 14),
      axis.title = ggplot2::element_text(size = 12)
    )
  
  return(p)
}

#' Plot categorical bar chart
#' 
#' @param data Data frame
#' @param category_var Category variable
#' @param value_var Value variable (NULL for counts)
#' @param title Plot title
#' @param top_n Show only top N categories
#' @return ggplot object
#' 
#' @export
plot_category_bars <- function(data, category_var, value_var = NULL, 
                               title = NULL, top_n = 10) {
  
  if (!category_var %in% names(data)) {
    stop(sprintf("Category variable '%s' not found in data", category_var))
  }
  
  # Prepare data
  if (is.null(value_var)) {
    plot_data <- data %>%
      dplyr::count(.data[[category_var]]) %>%
      dplyr::arrange(desc(n)) %>%
      dplyr::slice_head(n = top_n)
    y_var <- "n"
    y_label <- "Count"
  } else {
    if (!value_var %in% names(data)) {
      stop(sprintf("Value variable '%s' not found in data", value_var))
    }
    plot_data <- data %>%
      dplyr::group_by(.data[[category_var]]) %>%
      dplyr::summarise(value = sum(.data[[value_var]], na.rm = TRUE), .groups = "drop") %>%
      dplyr::arrange(desc(value)) %>%
      dplyr::slice_head(n = top_n)
    y_var <- "value"
    y_label <- value_var
  }
  
  if (is.null(title)) {
    title <- sprintf("Top %d %s", top_n, category_var)
  }
  
  p <- ggplot2::ggplot(plot_data, ggplot2::aes(
    x = reorder(.data[[category_var]], .data[[y_var]]), 
    y = .data[[y_var]]
  )) +
    ggplot2::geom_bar(stat = "identity", fill = "steelblue") +
    ggplot2::coord_flip() +
    ggplot2::labs(title = title, x = category_var, y = y_label) +
    ggplot2::theme_minimal() +
    ggplot2::theme(
      plot.title = ggplot2::element_text(face = "bold", size = 14),
      axis.title = ggplot2::element_text(size = 12)
    )
  
  return(p)
}

#' Plot time series
#' 
#' @param data Data frame
#' @param date_var Date variable
#' @param value_var Value variable
#' @param title Plot title
#' @return ggplot object
#' 
#' @export
plot_time_series <- function(data, date_var, value_var, title = NULL) {
  
  if (!date_var %in% names(data)) {
    stop(sprintf("Date variable '%s' not found in data", date_var))
  }
  
  if (!value_var %in% names(data)) {
    stop(sprintf("Value variable '%s' not found in data", value_var))
  }
  
  if (is.null(title)) {
    title <- sprintf("%s over time", value_var)
  }
  
  p <- ggplot2::ggplot(data, ggplot2::aes(
    x = .data[[date_var]], 
    y = .data[[value_var]]
  )) +
    ggplot2::geom_line(color = "steelblue", size = 1) +
    ggplot2::geom_point(color = "steelblue", size = 2) +
    ggplot2::labs(title = title, x = date_var, y = value_var) +
    ggplot2::theme_minimal() +
    ggplot2::theme(
      plot.title = ggplot2::element_text(face = "bold", size = 14),
      axis.title = ggplot2::element_text(size = 12),
      axis.text.x = ggplot2::element_text(angle = 45, hjust = 1)
    )
  
  return(p)
}

# ==============================================================================
# EXPORT FUNCTIONS
# ==============================================================================

#' Export results to various formats
#' 
#' @param data Data frame or object to export
#' @param file_path Output file path
#' @param format Output format (csv, rds, excel)
#' @return Invisible TRUE on success
#' 
#' @export
export_results <- function(data, file_path, format = "csv") {
  
  tryCatch({
    # Create output directory if needed
    out_dir <- dirname(file_path)
    if (!dir.exists(out_dir)) {
      dir.create(out_dir, recursive = TRUE)
      message(sprintf("Created directory: %s", out_dir))
    }
    
    # Export based on format
    if (format == "csv") {
      readr::write_csv(data, file_path)
      message(sprintf("✓ Exported to CSV: %s", file_path))
      
    } else if (format == "rds") {
      saveRDS(data, file_path)
      message(sprintf("✓ Exported to RDS: %s", file_path))
      
    } else if (format == "excel") {
      if (!requireNamespace("writexl", quietly = TRUE)) {
        message("Installing writexl package for Excel export...")
        install.packages("writexl", repos = "https://cloud.r-project.org")
      }
      writexl::write_xlsx(data, file_path)
      message(sprintf("✓ Exported to Excel: %s", file_path))
      
    } else {
      stop(sprintf("Unsupported format: %s", format))
    }
    
    invisible(TRUE)
    
  }, error = function(e) {
    warning(sprintf("Export failed: %s", e$message))
    invisible(FALSE)
  })
}

# ==============================================================================
# INITIALIZATION MESSAGE
# ==============================================================================

message("\n" , strrep("=", 70))
message("SQL Server Data Analysis System Loaded")
message(strrep("=", 70))
message("\nAvailable functions:")
message("  Database: DatabaseManager, query_database(), get_table()")
message("  CSV Import: import_csv(), import_multiple_csv(), import_csv_advanced()")
message("  Validation: validate_csv(), combine_csv_database()")
message("  Cleaning: clean_data(), handle_missing_values()")
message("  Analysis: descriptive_stats(), group_analysis()")
message("  Visualization: plot_distribution(), plot_category_bars(), plot_time_series()")
message("  Export: export_results()")
message("\nUse load_packages() to install and load required packages")
message(strrep("=", 70), "\n")
