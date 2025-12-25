=============================================================================
EXAMPLE DATA FILES - Description
=============================================================================

This directory contains sample CSV files for testing and demonstration
purposes of the R Data Analysis System.

-----------------------------------------------------------------------------
1. vendite.csv (Sales Data)
-----------------------------------------------------------------------------
Contains sample sales transactions with the following columns:

- ID: Unique transaction identifier
- data: Transaction date (YYYY-MM-DD format)
- categoria: Product category (Elettronica, Abbigliamento, Casa)
- prodotto: Product name
- quantita: Quantity sold
- prezzo_unitario: Unit price
- importo: Total amount (quantity × unit price)
- cliente_id: Customer ID (links to clienti.csv)
- regione: Geographic region (Nord, Sud, Centro)

Delimiter: , (comma)
Encoding: UTF-8
Records: 30 sample transactions from January-February 2024

-----------------------------------------------------------------------------
2. clienti.csv (Customer Data)
-----------------------------------------------------------------------------
Contains customer master data with the following columns:

- cliente_id: Unique customer identifier
- nome: First name
- cognome: Last name
- email: Email address
- telefono: Phone number (Italian format)
- citta: City
- cap: Postal code
- data_registrazione: Registration date
- tipo_cliente: Customer type (Premium, Standard)

Delimiter: ; (semicolon)
Encoding: UTF-8
Records: 17 sample customers

NOTE: This file uses semicolon as delimiter to demonstrate handling
different CSV formats.

-----------------------------------------------------------------------------
3. prodotti.csv (Product Catalog)
-----------------------------------------------------------------------------
Contains product catalog information with the following columns:

- prodotto_id: Unique product identifier
- nome_prodotto: Product name
- categoria: Product category
- marca: Brand name
- prezzo_listino: List price
- stock: Available stock quantity
- fornitore: Supplier name
- data_aggiunta: Date added to catalog

Delimiter: , (comma)
Encoding: UTF-8
Records: 30 sample products

-----------------------------------------------------------------------------
USAGE EXAMPLES
-----------------------------------------------------------------------------

Example 1: Import single file
```r
source("sql_server_data_analysis.R")
vendite <- import_csv("data/examples/vendite.csv")
```

Example 2: Import file with different delimiter
```r
clienti <- import_csv("data/examples/clienti.csv", delimiter = ";")
```

Example 3: Import all CSV files from directory
```r
all_data <- import_multiple_csv("data/examples", combine = FALSE)
```

Example 4: Join sales with customer data
```r
vendite <- import_csv("data/examples/vendite.csv")
clienti <- import_csv("data/examples/clienti.csv", delimiter = ";")
vendite_complete <- dplyr::left_join(vendite, clienti, by = "cliente_id")
```

-----------------------------------------------------------------------------
DATA CHARACTERISTICS
-----------------------------------------------------------------------------

The sample data is designed to demonstrate:

1. Different delimiters (comma vs semicolon)
2. Date handling (multiple date formats)
3. Numeric data (prices, quantities)
4. Categorical data (categories, regions, customer types)
5. Relationships between tables (cliente_id foreign key)
6. Italian language content (to test encoding)
7. Real-world data patterns (sales trends, customer segments)

-----------------------------------------------------------------------------
TESTING SCENARIOS
-----------------------------------------------------------------------------

Use this data to test:

✓ CSV import with different encodings
✓ Delimiter detection and handling
✓ Data cleaning and validation
✓ Statistical analysis (descriptive stats, grouping)
✓ Data visualization (distributions, categories, time series)
✓ Data joining and combination
✓ Missing value handling
✓ Export functionality
✓ Pipeline integration (CSV → Clean → Analyze → Visualize)

-----------------------------------------------------------------------------
MODIFICATIONS
-----------------------------------------------------------------------------

Feel free to modify these files to test edge cases:

- Add missing values (NA, NULL, empty strings)
- Introduce duplicates
- Add malformed records
- Change encodings
- Test with larger datasets
- Add additional columns

-----------------------------------------------------------------------------

For more information, see the main README.md file.
