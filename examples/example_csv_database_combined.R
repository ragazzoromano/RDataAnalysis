# ==============================================================================
# Example: Combined CSV and Database Analysis
# ==============================================================================
# 
# This script demonstrates how to combine data from CSV files and SQL Server
# databases for comprehensive analysis.
#
# PREREQUISITES:
#   1. SQL Server accessible with appropriate credentials
#   2. Database with sales/customer data (or use CSV-only mode)
#   3. ODBC Driver 17 for SQL Server installed
#
# ==============================================================================

# Load the analysis system
source("sql_server_data_analysis.R")

# Load required packages
load_packages()

# ==============================================================================
# CONFIGURATION
# ==============================================================================

# Set to TRUE if you have a SQL Server database available
USE_DATABASE <- FALSE  # Change to TRUE if you have a database

# Database configuration (update with your settings)
DB_SERVER <- "localhost"
DB_NAME <- "SalesDB"
DB_USE_WINDOWS_AUTH <- TRUE

# ==============================================================================
# EXAMPLE 1: CSV-Only Mode (No Database Required)
# ==============================================================================

if (!USE_DATABASE) {
  message("\n", strrep("=", 70))
  message("RUNNING IN CSV-ONLY MODE (No database connection)")
  message(strrep("=", 70), "\n")
  
  # Import all CSV data
  vendite <- import_csv("data/examples/vendite.csv")
  clienti <- import_csv("data/examples/clienti.csv", delimiter = ";")
  prodotti <- import_csv("data/examples/prodotti.csv")
  
  # Combine all data sources
  message("\n=== Combining All Data Sources ===")
  
  # First join: sales with customers
  vendite_clienti <- dplyr::left_join(
    vendite,
    clienti,
    by = "cliente_id"
  )
  message(sprintf("✓ Joined sales with customers: %d rows", nrow(vendite_clienti)))
  
  # Note: For product join, we need to create prodotto_id in vendite
  # In a real scenario, vendite would have prodotto_id instead of prodotto name
  # For this demo, we'll create a simple mapping
  
  # Create product mapping (simplified)
  prodotto_mapping <- data.frame(
    prodotto = c("Laptop", "Mouse", "Giacca", "Tastiera", "Lampada", 
                "Monitor", "Scarpe", "Cuscino", "Cuffie", "Maglietta",
                "Tablet", "Tappeto", "Webcam", "Pantaloni", "Vaso",
                "Smartphone", "Cappello", "Specchio", "Stampante", "Cintura",
                "Router", "Coperta", "SSD", "Gonna", "Quadro",
                "Microfono", "Sciarpa", "Orologio", "Altoparlante", "Guanti"),
    prodotto_id = 1:30
  )
  
  # Add prodotto_id to vendite
  vendite_with_id <- dplyr::left_join(
    vendite_clienti,
    prodotto_mapping,
    by = "prodotto"
  )
  
  # Full join with product catalog
  dati_completi <- dplyr::left_join(
    vendite_with_id,
    prodotti,
    by = "prodotto_id"
  )
  
  message(sprintf("✓ Final combined dataset: %d rows, %d columns", 
                 nrow(dati_completi), ncol(dati_completi)))
  
  # Comprehensive analysis
  message("\n=== Comprehensive Analysis ===")
  
  # Sales by customer type
  analisi_tipo_cliente <- dati_completi %>%
    dplyr::group_by(tipo_cliente) %>%
    dplyr::summarise(
      vendite_totali = sum(importo, na.rm = TRUE),
      numero_ordini = n(),
      ticket_medio = mean(importo, na.rm = TRUE),
      clienti_unici = n_distinct(cliente_id),
      .groups = "drop"
    ) %>%
    dplyr::arrange(desc(vendite_totali))
  
  message("\nSales by customer type:")
  print(analisi_tipo_cliente)
  
  # Sales by brand
  analisi_marca <- dati_completi %>%
    dplyr::group_by(marca) %>%
    dplyr::summarise(
      vendite_totali = sum(importo, na.rm = TRUE),
      unita_vendute = sum(quantita, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    dplyr::arrange(desc(vendite_totali)) %>%
    dplyr::slice_head(n = 10)
  
  message("\nTop 10 brands by sales:")
  print(analisi_marca)
  
  # Regional analysis with customer details
  analisi_regionale <- dati_completi %>%
    dplyr::group_by(regione, tipo_cliente) %>%
    dplyr::summarise(
      vendite_totali = sum(importo, na.rm = TRUE),
      numero_ordini = n(),
      .groups = "drop"
    ) %>%
    dplyr::arrange(regione, desc(vendite_totali))
  
  message("\nSales by region and customer type:")
  print(analisi_regionale)
  
  # Create visualizations
  if (!dir.exists("output/grafici")) {
    dir.create("output/grafici", recursive = TRUE)
  }
  
  # Chart 1: Sales by customer type
  p1 <- ggplot2::ggplot(
    analisi_tipo_cliente,
    ggplot2::aes(x = reorder(tipo_cliente, vendite_totali), y = vendite_totali)
  ) +
    ggplot2::geom_bar(stat = "identity", fill = "steelblue") +
    ggplot2::coord_flip() +
    ggplot2::labs(
      title = "Vendite Totali per Tipo Cliente",
      x = "Tipo Cliente",
      y = "Vendite Totali (€)"
    ) +
    ggplot2::theme_minimal()
  
  ggsave("output/grafici/vendite_tipo_cliente.png", p1, width = 10, height = 6)
  message("\n✓ Saved: output/grafici/vendite_tipo_cliente.png")
  
  # Chart 2: Top brands
  p2 <- ggplot2::ggplot(
    analisi_marca,
    ggplot2::aes(x = reorder(marca, vendite_totali), y = vendite_totali)
  ) +
    ggplot2::geom_bar(stat = "identity", fill = "darkgreen") +
    ggplot2::coord_flip() +
    ggplot2::labs(
      title = "Top 10 Marche per Vendite",
      x = "Marca",
      y = "Vendite Totali (€)"
    ) +
    ggplot2::theme_minimal()
  
  ggsave("output/grafici/top_marche.png", p2, width = 10, height = 6)
  message("✓ Saved: output/grafici/top_marche.png")
  
  # Export results
  export_results(dati_completi, "output/dataset_completo.csv", "csv")
  export_results(analisi_tipo_cliente, "output/analisi_tipo_cliente.csv", "csv")
  export_results(analisi_marca, "output/analisi_marca.csv", "csv")
  export_results(analisi_regionale, "output/analisi_regionale.csv", "csv")
  
  message("\n", strrep("=", 70))
  message("CSV-ONLY ANALYSIS COMPLETE!")
  message(strrep("=", 70))
  message("\nTo enable database integration:")
  message("  1. Set USE_DATABASE <- TRUE")
  message("  2. Update DB_SERVER, DB_NAME configuration")
  message("  3. Run the script again")
  message(strrep("=", 70), "\n")
  
} else {
  
  # ==============================================================================
  # EXAMPLE 2: Database + CSV Combined Mode
  # ==============================================================================
  
  message("\n", strrep("=", 70))
  message("RUNNING IN DATABASE + CSV MODE")
  message(strrep("=", 70), "\n")
  
  # Initialize database manager
  db_mgr <- DatabaseManager$new()
  
  tryCatch({
    # Connect to database
    message("Connecting to database...")
    db_mgr$add_connection(
      name = "sales_db",
      server = DB_SERVER,
      database = DB_NAME,
      trusted = DB_USE_WINDOWS_AUTH
    )
    
    # Query data from database
    message("\n=== Fetching Data from Database ===")
    
    # Example queries (adjust table names to match your database)
    query_vendite <- "
      SELECT 
        VenditaID as ID,
        DataVendita as data,
        Categoria as categoria,
        Prodotto as prodotto,
        Quantita as quantita,
        PrezzoUnitario as prezzo_unitario,
        ImportoTotale as importo,
        ClienteID as cliente_id
      FROM Vendite
      WHERE DataVendita >= DATEADD(month, -3, GETDATE())
    "
    
    vendite_db <- query_database(db_mgr, "sales_db", query_vendite)
    
    # Import complementary data from CSV
    message("\n=== Importing CSV Data ===")
    clienti_csv <- import_csv("data/examples/clienti.csv", delimiter = ";")
    prodotti_csv <- import_csv("data/examples/prodotti.csv")
    
    # Combine database and CSV data
    message("\n=== Combining Database and CSV Data ===")
    
    dati_combinati <- combine_csv_database(
      vendite_db,
      clienti_csv,
      join_by = "cliente_id",
      join_type = "left"
    )
    
    # Clean combined data
    dati_combinati <- clean_data(dati_combinati)
    
    # Analysis on combined data
    message("\n=== Analysis on Combined Data ===")
    
    # Overall statistics
    stats <- descriptive_stats(dati_combinati)
    
    # Group analysis
    per_categoria <- group_analysis(dati_combinati, "categoria", "importo", "sum")
    per_tipo_cliente <- group_analysis(dati_combinati, "tipo_cliente", "importo", "sum")
    
    # Create visualizations
    if (!dir.exists("output/grafici")) {
      dir.create("output/grafici", recursive = TRUE)
    }
    
    p1 <- plot_category_bars(
      dati_combinati,
      "categoria",
      "importo",
      "Vendite per Categoria (DB + CSV)"
    )
    ggsave("output/grafici/vendite_categoria_combined.png", p1, width = 10, height = 6)
    
    # Export results
    export_results(dati_combinati, "output/dati_combinati_db_csv.csv", "csv")
    export_results(stats, "output/statistiche_combined.csv", "csv")
    
    # Close database connection
    db_mgr$close_all()
    
    message("\n", strrep("=", 70))
    message("DATABASE + CSV ANALYSIS COMPLETE!")
    message(strrep("=", 70), "\n")
    
  }, error = function(e) {
    message("\nError connecting to database:")
    message(e$message)
    message("\nFalling back to CSV-only mode...")
    message("Set USE_DATABASE <- FALSE to skip database connection attempts.\n")
    
    # Close any open connections
    if (exists("db_mgr")) {
      db_mgr$close_all()
    }
  })
}

# ==============================================================================
# EXAMPLE 3: Advanced Integration Patterns
# ==============================================================================

message("\n", strrep("=", 70))
message("EXAMPLE 3: Advanced Integration Patterns")
message(strrep("=", 70), "\n")

# Pattern 1: Import CSV, validate, then upload to database (pseudocode)
message("\n--- Pattern 1: CSV Validation Before Database Upload ---")
message("1. Import CSV file")
message("2. Validate data quality")
message("3. Clean and transform")
message("4. Upload to database (using DBI::dbWriteTable)")
message("5. Verify upload success")

# Pattern 2: Sync data between CSV and database
message("\n--- Pattern 2: Data Synchronization ---")
message("1. Query current database state")
message("2. Import CSV with updates")
message("3. Identify new/changed records")
message("4. Update database with changes")
message("5. Archive processed CSV files")

# Pattern 3: Backup and restore
message("\n--- Pattern 3: Backup Database to CSV ---")
message("1. Query all tables from database")
message("2. Export each table to CSV")
message("3. Compress CSV files")
message("4. Store in backup location")

message("\n", strrep("=", 70))
message("See config_template.R for database configuration options")
message(strrep("=", 70), "\n")
