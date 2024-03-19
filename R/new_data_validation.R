library(RSQLite)

# connect to database
my_connection <- dbConnect(RSQLite::SQLite(),"project_dm.db")

# Loading using `read_excel`
customer <- readxl::read_excel("data_upload/Customer/Customer_table.xlsx")
category <- readxl::read_excel("data_upload/Category/Category_table.xlsx")
discount <- readxl::read_excel("data_upload/Discount/Discount_table.xlsx")
order <- readxl::read_excel("data_upload/Order/Order_table.xlsx")
product <- readxl::read_excel("data_upload/Product/Product_table.xlsx")
shipment <- readxl::read_excel("data_upload/Shipment/Shipment_table.xlsx")
supplier <- readxl::read_excel("data_upload/Supplier/Supplier_table.xlsx")

# Change date format
customer$cust_birthday <- as.character(customer$cust_birthday)
order$order_purchased_date <- as.character(order$order_purchased_date)
shipment$shipping_date <- as.character(shipment$shipping_date)
shipment$delivered_date <- as.character(shipment$delivered_date)

# Write them to the database
RSQLite::dbWriteTable(my_connection,"customer",customer, append = TRUE)
RSQLite::dbWriteTable(my_connection,"category",category,append=TRUE)
RSQLite::dbWriteTable(my_connection,"discount",discount,append=TRUE)
RSQLite::dbWriteTable(my_connection,"product",product,append=TRUE)
RSQLite::dbWriteTable(my_connection,"order",order,append=TRUE)
RSQLite::dbWriteTable(my_connection,"shipment",shipment,append=TRUE)

# primary key check for customer data
all_files <- list.files("data_upload/Customer/")
for (variable in all_files) {
  this_filepath <- paste0("data_upload/Customer/",variable)
  this_file_contents <- readr::read_csv(this_filepath)
  number_of_rows <- nrow(this_file_contents)
  
  print(paste0("Checking for: ",variable))
  
  print(paste0(" is ",nrow(unique(this_file_contents[,1]))==number_of_rows))
}

# primary key check for category data
all_files <- list.files("data_upload/Category/")
for (variable in all_files) {
  this_filepath <- paste0("data_upload/Category/",variable)
  this_file_contents <- readr::read_csv(this_filepath)
  number_of_rows <- nrow(this_file_contents)
  
  print(paste0("Checking for: ",variable))
  
  print(paste0(" is ",nrow(unique(this_file_contents[,1]))==number_of_rows))
}

# primary key check for discount data
all_files <- list.files("data_upload/Discount/")
for (variable in all_files) {
  this_filepath <- paste0("data_upload/Discount/",variable)
  this_file_contents <- readr::read_csv(this_filepath)
  number_of_rows <- nrow(this_file_contents)
  
  print(paste0("Checking for: ",variable))
  
  print(paste0(" is ",nrow(unique(this_file_contents[,1]))==number_of_rows))
}

# primary key check for order data
all_files <- list.files("data_upload/Order/")
for (variable in all_files) {
  this_filepath <- paste0("data_upload/Order/",variable)
  this_file_contents <- readr::read_csv(this_filepath)
  number_of_rows <- nrow(this_file_contents)
  
  print(paste0("Checking for: ",variable))
  
  print(paste0(" is ",nrow(unique(this_file_contents[,1]))==number_of_rows))
}

# primary key check for product data
all_files <- list.files("data_upload/Product/")
for (variable in all_files) {
  this_filepath <- paste0("data_upload/Product/",variable)
  this_file_contents <- readr::read_csv(this_filepath)
  number_of_rows <- nrow(this_file_contents)
  
  print(paste0("Checking for: ",variable))
  
  print(paste0(" is ",nrow(unique(this_file_contents[,1]))==number_of_rows))
}

# primary key check for shipment data
all_files <- list.files("data_upload/Shipment/")
for (variable in all_files) {
  this_filepath <- paste0("data_upload/Shipment/",variable)
  this_file_contents <- readr::read_csv(this_filepath)
  number_of_rows <- nrow(this_file_contents)
  
  print(paste0("Checking for: ",variable))
  
  print(paste0(" is ",nrow(unique(this_file_contents[,1]))==number_of_rows))
}

# primary key check for supplier data
all_files <- list.files("data_upload/Supplier/")
for (variable in all_files) {
  this_filepath <- paste0("data_upload/Supplier/",variable)
  this_file_contents <- readr::read_csv(this_filepath)
  number_of_rows <- nrow(this_file_contents)
  
  print(paste0("Checking for: ",variable))
  
  print(paste0(" is ",nrow(unique(this_file_contents[,1]))==number_of_rows))
}

# Function to list Excel files in a folder
list_excel_files <- function(folder_path) {
  files <- list.files(path = folder_path, pattern = "\\.xlsx$", full.names = TRUE)
  return(files)
}

folder_table_mapping <- list(
  "Customer" = "customer",
  "Supplier" = "supplier",
  "Category" = "category",
  "Product" = "product",
  "Order" = "order",
  "Discount" = "discount",
  "Shipment" = "shipment"
)

convert_column_types <- function(data, column_types) {
  for (col_name in names(column_types)) {
    if (col_name %in% names(data)) {
      col_type <- column_types[[col_name]]
      if (col_type == "character") {
        data[[col_name]] <- as.character(data[[col_name]])
      } else if (col_type == "date") {
        data[[col_name]] <- as.Date(data[[col_name]], format = "%Y/%m/%d")
        data[[col_name]] <- as.character(data[[col_name]])
      }
    }
  }
  return(data)
}

# Data type mapping for each table's columns
column_types_mapping <- list(
  "Category" = c("category_id" = "character", "p_category_id" = "character"),
  "Customer" = c("cust_id" = "character", "cust_birthday" = "character"),
  "Supplier" = c("supplier_id" = "character"),
  "Discount" = c("discount_id" = "character"),
  "Product" = c("product_id" = "character", "supplier_id" = "character", 
                "category_id" = "character", "discount_id" = "character"),
  "Shipment" = c("shipping_id" = "character"),
  "Order" = c("order_id" = "character", "customer_id" = "character", 
              "product_id" = "character", "shipping_id" = "character")
)

# Path to the main folder containing subfolders (e.g., data_upload)
main_folder <- "data_upload"

# Process each subfolder (table)
for (folder_name in names(folder_table_mapping)) {
  folder_path <- file.path(main_folder, folder_name)
  if (dir.exists(folder_path)) {
    cat("Processing folder:", folder_name, "\n")
    # List Excel files in the subfolder
    excel_files <- list_excel_files(folder_path)
    
    # Get the corresponding table name from the mapping
    table_name <- folder_table_mapping[[folder_name]]
    
    # Append data from Excel files to the corresponding table
    for (excel_file in excel_files) {
      cat("Appending data from:", excel_file, "\n")
      tryCatch({
        # Read Excel file
        file_contents <- readxl::read_excel(excel_file)
        
        # Convert column data types
        file_contents <- convert_column_types(file_contents, column_types_mapping[[table_name]])
        
        # Append data to the table in SQLite
        RSQLite::dbWriteTable(my_connection, table_name, file_contents, append = TRUE)
        cat("Data appended to table:", table_name, "\n")
      }, error = function(e) {
        cat("Error appending data:", excel_file, "\n")
        #cat("Error message:", e$message, "\n")
      })
    }
  } else {
    cat("Folder does not exist:", folder_path, "\n")
  }
}

# List tables to confirm data appending
tables <- RSQLite::dbListTables(my_connection)
print(tables)

# Check table
customer <- dbGetQuery(my_connection, "SELECT * FROM customer")
supplier <- dbGetQuery(my_connection, "SELECT * FROM supplier")
discount <- dbGetQuery(my_connection, "SELECT * FROM discount")
product <- dbGetQuery(my_connection, "SELECT * FROM product")
orders <- dbGetQuery(my_connection, "SELECT * FROM 'order'")
shipment <- dbGetQuery(my_connection, "SELECT * FROM shipment")
category <- dbGetQuery(my_connection, "SELECT * FROM category")
