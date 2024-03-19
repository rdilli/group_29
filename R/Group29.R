library(RSQLite)
library(stringr)
library(readxl)
library(openxlsx)

library(DBI)
library(lubridate)

library(dplyr)
library(ggplot2)
library(gridExtra)
library(Hmisc)
library(kableExtra)
options(width=100)


my_connection <- RSQLite::dbConnect(RSQLite::SQLite(),"project_dm.db")

RSQLite::dbExecute(my_connection,"
DROP TABLE IF EXISTS 'category';
")

RSQLite::dbExecute(my_connection,"
CREATE TABLE 'category' (
    'category_id' VARCHAR(10) PRIMARY KEY,
    'category_name' VARCHAR(255) NOT NULL,
    'p_category_id' VARCHAR(10) NOT NULL
  );
  ")

RSQLite::dbExecute(my_connection,"
CREATE INDEX idx_category_p_category_id ON category(p_category_id);
")

RSQLite::dbExecute(my_connection,"
                   DROP TABLE IF EXISTS 'customer'; 
                   ")

RSQLite::dbExecute(my_connection, "
CREATE TABLE 'customer'(
    'cust_id' VARCHAR(10) PRIMARY KEY,
    'cust_firstname' VARCHAR(255) NOT NULL,
    'cust_lastname' VARCHAR(255),
    'cust_email' VARCHAR(255) UNIQUE NOT NULL,
    'cust_phone' VARCHAR(20) UNIQUE NOT NULL,
    'cust_birthday' DATE NOT NULL,
    'cust_gender' VARCHAR(10),
    'cust_street' VARCHAR(255) NOT NULL,
    'cust_city' VARCHAR(255) NOT NULL,
    'cust_postcode' VARCHAR(20) NOT NULL
  );
  ")

RSQLite::dbExecute(my_connection, "
CREATE INDEX idx_customer_location ON customer(cust_city, cust_postcode);
")

RSQLite::dbExecute(my_connection, "DROP INDEX IF EXISTS idx_product_name;")

RSQLite::dbExecute(my_connection, "
CREATE INDEX idx_product_name ON product(product_name);
")

RSQLite::dbExecute(my_connection, "DROP INDEX IF EXISTS idx_product_stock;")

RSQLite::dbExecute(my_connection, "
CREATE INDEX idx_product_stock ON product(product_stock);
")

RSQLite::dbExecute(my_connection, "
DROP TABLE IF EXISTS 'supplier';
")

RSQLite::dbExecute(my_connection, "
CREATE TABLE 'supplier'(
    'supplier_id' VARCHAR(10) PRIMARY KEY,
    'supplier_name' VARCHAR(255) NOT NULL,
    'supplier_street' VARCHAR(255) NOT NULL,
    'supplier_city' VARCHAR(255) NOT NULL,
    'supplier_postcode' VARCHAR(20) NOT NULL,
    'supplier_email' VARCHAR(255) NOT NULL
  );
    ")

RSQLite::dbExecute(my_connection, "
CREATE INDEX idx_supplier_email ON supplier(supplier_email);
")

RSQLite::dbExecute(my_connection, "
DROP TABLE IF EXISTS 'discount';
")

RSQLite::dbExecute(my_connection, "
CREATE TABLE 'discount' (
    'discount_id' VARCHAR(10) PRIMARY KEY,
    'discount_name' VARCHAR(200) NOT NULL,
    'discount_percentage' INT NOT NULL
  );
    ")

RSQLite::dbExecute(my_connection, "
DROP TABLE IF EXISTS 'product';
")


RSQLite::dbExecute(my_connection, "
CREATE TABLE 'product'(
    'product_id' VARCHAR(10) PRIMARY KEY,
    'category_id' VARCHAR(10) NOT NULL,
    'supplier_id' VARCHAR(10) NOT NULL,
    'discount_id' VARCHAR(10) NOT NULL,
    'product_name' VARCHAR(255) NOT NULL,
    'product_price' DECIMAL(10,2) NOT NULL,
    'product_stock' INT NOT NULL,
    FOREIGN KEY ('category_id') REFERENCES category('category_id'),
    FOREIGN KEY ('discount_id') REFERENCES discount('discount_id')
  );
  ")

RSQLite::dbExecute(my_connection, "
DROP TABLE IF EXISTS 'shipment';
")

RSQLite::dbExecute(my_connection, "
CREATE TABLE 'shipment'(
    'shipping_id' VARCHAR(10) PRIMARY KEY,
    'tracking_number' INT UNIQUE,
    'shipping_date' DATE,
    'delivered_date' DATE,
    'shipment_status' VARCHAR(20)
  );
")

RSQLite::dbExecute(my_connection, "
CREATE INDEX idx_shipment_dates ON shipment(shipping_date, delivered_date);
")

RSQLite::dbExecute(my_connection, "
DROP TABLE IF EXISTS 'order';
")

RSQLite::dbExecute(my_connection, "
CREATE TABLE 'order'(
    'order_id' VARCHAR(10) NOT NULL,
    'customer_id' VARCHAR(10) NOT NULL,
    'product_id' VARCHAR(10) NOT NULL,
    'shipping_id' VARCHAR(10) NOT NULL,
    'order_purchased_date' DATE NOT NULL,
    'order_quantity' INT NOT NULL,
    'product_rating' INT,
    'payment_method' VARCHAR(20) NOT NULL,
    'payment_status' VARCHAR(10) NOT NULL,
    FOREIGN KEY ('customer_id') REFERENCES customer('cust_id'),
    FOREIGN KEY ('product_id') REFERENCES product('product_id'),
    FOREIGN KEY ('shipping_id') REFERENCES shipment('shipping_id')
  );
")

RSQLite::dbExecute(my_connection, "
CREATE INDEX idx_order_customer ON 'order'(customer_id);
")

RSQLite::dbExecute(my_connection, "
CREATE INDEX idx_order_product ON 'order'(product_id);
")

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


# Function to check email format
check_email_format <- function(email) {
  valid.email <- grepl("^[A-Za-z0-9._&%+-]+@[A-Za-z0-9.-]+\\.com$", email)
  return(valid.email)
}

# Fucntion to check phone number format
check_phone_format <- function(phone) {
  valid.phone <- grepl("\\+\\d{2} \\d{4} \\d{6}$", phone)
  return(valid.phone)
}

#Fucntion to check date
check_date_format <- function(date){
  valid.date <- grepl("^\\d{4}-\\d{2}-\\d{2}$", date)
  return(valid.date)
}

#Fucntion to check postcode
check_postcode_format <- function(post){
  valid.postcode <- grepl("^[A-Z]{1,2}\\d{1,2} \\d[A-Z]{2}$",post)
  return(valid.postcode)
}

#Fucntion to check age
check_age <- function(age){
  current_year <- year(Sys.Date())
  birth_years <- year(age)
  ages <- current_year - birth_years
  valid_age <- ages >= 18 & ages <= 60
  return(valid_age)
}

#Fucntion to check price
price_range_check <- function(price) {
  valid_price <- price >= 20 & price <= 150
  return(valid_price)
}

#Fucntion to check stock
stock_check <- function(stock){
  valid_stock <- stock >=0
  return(valid_stock)
}

## Customer Table
# Email Validation
query_emails.customer <- "SELECT cust_email FROM customer"

# Execute the query
email.customer <- dbGetQuery(my_connection, query_emails.customer)
# Apply the function to check email format
email_validity.customer <- sapply(email.customer, check_email_format)

# Print their validity
cust.email.validity <- data.frame(Email = email.customer, Valid = email_validity.customer)

invalid.email <- subset(cust.email.validity, cust_email.1 == FALSE)
print(paste("Number of invalid customer emails:",nrow(invalid.email)))


# Phone number validation
query_phone.customer <- "SELECT cust_phone FROM customer"

phone.customer <- dbGetQuery(my_connection, query_phone.customer)

phone_validity.customer <- sapply(phone.customer, check_phone_format)

cust.phone.validity <- data.frame(Phone = phone.customer, Valid = phone_validity.customer)

invalid.phone <- subset(cust.phone.validity, cust_phone.1 == FALSE)
print(paste("Number of invalid customer phone numbers:",nrow(invalid.phone)))

#Date validation
query_date.customer <- "SELECT cust_birthday FROM customer"

date.customer <- dbGetQuery(my_connection, query_date.customer)

date_validity.customer <- sapply(date.customer, check_date_format)

cust.date.validity <- data.frame(Date=date.customer, Valid=date_validity.customer)

invalid.date <- subset(cust.date.validity, cust_birthday.1==FALSE)
print(paste("Number of invalid customer birthdays:",nrow(invalid.date)))

#Postcode validation
query_postcode.customer <- "SELECT cust_postcode FROM customer"

postcode.customer <- dbGetQuery(my_connection, query_postcode.customer)

postcode_validity.customer <- sapply(postcode.customer, check_postcode_format)

cust.postcode.validity <- data.frame(postcode=postcode.customer, Valid=postcode_validity.customer)

invalid.post <- subset(cust.postcode.validity, cust_postcode.1==FALSE)
print(paste("Number of invalid customer postcodes:",nrow(invalid.post)))

#Age Validation
query_age.customer <- "SELECT cust_birthday FROM customer"

age.customer <- dbGetQuery(my_connection, query_age.customer)

age.customer$cust_birthday <- as.Date(age.customer$cust_birthday)

age.customer$age <- year(Sys.Date()) - year(age.customer$cust_birthday)

# Define thresholds for invalid ages
invalid_age_min <- 18
invalid_age_max <- 100

# Count customers under 18 and over 100
n_under_18 <- sum(age.customer$age < invalid_age_min)
n_over_100 <- sum(age.customer$age > invalid_age_max)

# Print the results
cat("Number of customers under 18:", n_under_18, "\n")
cat("Number of customers over 100:", n_over_100, "\n")

#Duplicates
check_duplicates.customer <-  "
    SELECT *
    FROM customer
    WHERE cust_id IN (
      SELECT cust_id
      FROM customer
      GROUP BY cust_id
      HAVING COUNT(*) > 1
    )
    OR cust_email IN (
      SELECT cust_email
      FROM customer
      GROUP BY cust_email
      HAVING COUNT(*) > 1
    )
    OR cust_phone IN (
      SELECT cust_phone
      FROM customer
      GROUP BY cust_phone
      HAVING COUNT(*) > 1
    )
  "

# Execute the query
duplicates.customer <- dbGetQuery(my_connection, check_duplicates.customer)

print(paste("Number of duplicates in customer table:",nrow(duplicates.customer)))





#Supplier Table
#Email 
query_emails.supplier <- "SELECT supplier_email FROM supplier"

email.supplier <- dbGetQuery(my_connection, query_emails.supplier)

email_validity.supplier <- sapply(email.supplier, check_email_format)

supplier.email.validity <- data.frame(Email = email.supplier, Valid = email_validity.supplier)

invalid.email.supplier <- subset(supplier.email.validity, supplier_email.1==FALSE)
print(paste("Number of invalid supplier emails:",nrow(invalid.email.supplier)))

#Duplicates
check_duplicates.supplier <-  "
    SELECT *
    FROM supplier
    WHERE supplier_id IN (
      SELECT supplier_id
      FROM supplier
      GROUP BY supplier_id
      HAVING COUNT(*) > 1
    )
    OR supplier_email IN (
      SELECT supplier_email
      FROM supplier
      GROUP BY supplier_email
      HAVING COUNT(*) > 1
    )
  "

# Execute the query
duplicates.supplier <- dbGetQuery(my_connection, check_duplicates.supplier)
print(paste("Number of duplicates in supplier :",nrow(duplicates.supplier)))


#Product Table
#Price Validation
query_price.product <- "SELECT product_price FROM product"

price.product <- dbGetQuery(my_connection, query_price.product)

price_validity.product <- sapply(price.product, price_range_check)

product.price.validity <- data.frame(price = price.product, Valid = price_validity.product)

invalid.price.product <- subset(product.price.validity, product_price.1==FALSE)
print(paste("Number of invalid product prices:",nrow(invalid.price.product)))

#Stock validation
query_stock.product <- "SELECT product_stock FROM product"

stock.product <- dbGetQuery(my_connection, query_stock.product)

stock_validity.product <- sapply(price.product, stock_check)

product.stock.validity <- data.frame(stock = stock.product, Valid = stock_validity.product)

invalid.stock.product <- subset(product.stock.validity, product_price==FALSE)
print(paste("Number of invalid product stocks:",nrow(invalid.stock.product)))


#Duplicates
check_duplicates.product <-  "
    SELECT *
    FROM product
    WHERE product_id IN (
      SELECT product_id
      FROM product
      GROUP BY product_id
      HAVING COUNT(*) > 1
    )
    "

# Execute the query
duplicates.product <- dbGetQuery(my_connection, check_duplicates.product)
print(paste("Number of duplicates in product :",nrow(duplicates.product)))

#Reference Integrity
query.categoryid <- "
    UPDATE product
    SET category_id = CASE
                            WHEN category_id NOT IN (SELECT category_id FROM category) THEN NULL
                            ELSE category_id
                        END;"
query.supplierid <- "
    UPDATE product
    SET supplier_id = CASE
                            WHEN supplier_id NOT IN (SELECT supplier_id FROM supplier) THEN NULL
                            ELSE supplier_id
                        END;"
query.discountid <- "
    UPDATE product
    SET discount_id = CASE
                            WHEN discount_id NOT IN (SELECT discount_id FROM discount) THEN NULL
                            ELSE discount_id
                        END;"
dbExecute(my_connection, query.categoryid)      
dbExecute(my_connection, query.supplierid)  
dbExecute(my_connection, query.discountid)  


## Shipment Table
# Date format validation
query_shippingdate.shipment <- "SELECT shipping_date FROM shipment"

shippingdate.shipment <- dbGetQuery(my_connection, query_shippingdate.shipment)

shippingdate_validity.shipment <- sapply(shippingdate.shipment, check_date_format)

shipment.shipmentdate.validity <- data.frame(shippingdate = shippingdate.shipment, Valid = shippingdate_validity.shipment)

invalid.shippingdate <- subset(shipment.shipmentdate.validity, shipping_date.1==FALSE)
print(paste("Number of invalid shipping date:",nrow(invalid.shippingdate)))

query_deliverydate.shipment <- "SELECT delivered_date FROM shipment"

deliverydate.shipment <- dbGetQuery(my_connection, query_deliverydate.shipment)

deliverydate_validity.shipment <- sapply(deliverydate.shipment, check_date_format)

shipment.deliverydate.validity <- data.frame(deliverydate = deliverydate.shipment, Valid = deliverydate_validity.shipment)

invalid.deliverydate <- subset(shipment.deliverydate.validity, delivered_date.1==FALSE)
print(paste("Number of invalid delivery dates:",nrow(invalid.deliverydate)))

#Logical date check
check_shipping_delivered_dates <- 
  shipping_dates <- as.Date(shippingdate.shipment$shipping_date)
delivered_dates <- as.Date(deliverydate.shipment$delivered_date)

is_before <- shipping_dates < delivered_dates
print(paste("Number of invalid shipment:",nrow(is_before)))


## Discount Table
# Query to identify entries with duplicate discount names or duplicate discount percentages
query.discount <- "
    SELECT discount_id, discount_name, discount_percentage, COUNT(*) AS num_duplicates
    FROM discount
    GROUP BY discount_name, discount_percentage
    HAVING COUNT(*) > 1
"
duplicate_entries <- dbGetQuery(my_connection, query.discount)
print(paste("Number of duplicate discount names or percentages:",nrow(duplicate_entries)))

# Loop over duplicate entries and remove them
for (i in 1:nrow(duplicate_entries)) {
  discount_id <- duplicate_entries[i, "discount_id"]
  discount_name <- duplicate_entries[i, "discount_name"]
  discount_percentage <- duplicate_entries[i, "discount_percentage"]
  
  # Delete entries with duplicate discount names or duplicate discount percentages
  query.discount <- "DELETE FROM discount 
            WHERE (discount_name = ? AND discount_id <> ?)
            OR (discount_percentage = ? AND discount_id <> ?)"
  dbExecute(my_connection, query.discount, params = list(discount_name, discount_id, discount_percentage, discount_id))
}


# Query to identify entries with discount percentages not within the range of 0 and 1
query.discount2 <- "
    SELECT discount_id, discount_name, discount_percentage
    FROM discount
    WHERE discount_percentage < 0 OR discount_percentage > 1
"
out_of_range_entries <- dbGetQuery(my_connection, query.discount2)
print(paste("Number of out of range discount percentages:",nrow(out_of_range_entries)))


# Loop over out-of-range entries and remove them
for (i in 1:nrow(out_of_range_entries)) {
  discount_id <- out_of_range_entries[i, "discount_id"]
  
  # Delete entries with discount percentages not within the range of 0 and 1
  query.discount2 <- "DELETE FROM discount WHERE discount_id = ?"
  dbExecute(my_connection, query.discount2, params = list(discount_id))
}


# Query to identify entries with duplicate parent category IDs and category names
query.discount3 <- "
    SELECT p_category_id, category_name, MIN(category_id) AS keep_category_id, COUNT(*) AS num_duplicates
    FROM category
    GROUP BY p_category_id, category_name
    HAVING COUNT(*) > 1
"
duplicate_entries <- dbGetQuery(my_connection, query.discount3)
print(paste("Number of duplicate parent category IDs and category names :",nrow(duplicate_entries)))

# Loop over duplicate entries and remove all but one of the duplicates
for (i in 1:nrow(duplicate_entries)) {
  p_category_id <- duplicate_entries[i, "p_category_id"]
  category_name <- duplicate_entries[i, "category_name"]
  keep_category_id <- duplicate_entries[i, "keep_category_id"]
  
  # Delete duplicate entries except for the one to keep
  query.discount3 <- "DELETE FROM category WHERE p_category_id = ? AND category_name = ? AND category_id != ?"
  dbExecute(my_connection, query.discount3, params = list(p_category_id, category_name, keep_category_id))
}


# SQL statement to update the p_category_id column based on the constraint
query.discount4 <- "
    UPDATE category
    SET p_category_id = CASE
                            WHEN category_id = p_category_id THEN NULL
                            ELSE p_category_id
                        END;
"
# Execute the SQL statement
dbExecute(my_connection, query.discount4)


## Category Table
# SQL statement to update the p_category_id column based on the constraint
query.category <- "
    UPDATE category
    SET p_category_id = CASE
                            WHEN p_category_id NOT IN (SELECT category_id FROM category) THEN ('NA')
                            ELSE p_category_id
                        END;
"

# Execute the SQL statement
dbExecute(my_connection, query.category)


## Order Table
#Reference Integrity
query.customerid<- "
    UPDATE 'order'
    SET customer_id = CASE
                            WHEN customer_id NOT IN (SELECT customer_id FROM customer) THEN NULL
                            ELSE customer_id
                        END;"
query.productid <- "
    UPDATE 'order'
    SET product_id = CASE
                            WHEN product_id NOT IN (SELECT product_id FROM product) THEN NULL
                            ELSE product_id
                        END;"

query.shippingid <- "
    UPDATE 'order'
    SET shipping_id = CASE
                            WHEN shipping_id NOT IN (SELECT shipping_id FROM shipment) THEN NULL
                            ELSE shipping_id
                        END;"

dbExecute(my_connection, query.customerid)      
dbExecute(my_connection, query.productid)  
dbExecute(my_connection, query.shippingid)  

# Quantity Validation
query.order.quantity <- "SELECT order_quantity FROM 'order'"
order.quantity <- dbGetQuery(my_connection, query.order.quantity)

quantity.validate <- order.quantity>=1 & order.quantity <=5
invalid.quantity <- subset(quantity.validate, order.quantity==FALSE)
print(paste("Number of invalid quantitiy in order:",nrow(invalid.quantity)))

#To ensure the foreign key (customer, product and shipping) in the order table is linked with each primary key
# SQL statement to delete observations
query.order1 <- "
    DELETE FROM 'order'
    WHERE customer_id NOT IN (SELECT cust_id FROM customer)
    OR product_id NOT IN (SELECT product_id FROM product)
    OR shipping_id NOT IN (SELECT shipping_id FROM shipment);
"

# Execute the SQL statement
dbExecute(my_connection, query.order1)

#To ensure for the same order ID, the customer, shipment, payment and purchased date will be the same
# SQL statement to delete observations that violate the constraint
query.order2 <- "
    DELETE FROM 'order'
    WHERE (order_id, customer_id, shipping_id, payment_method, order_purchased_date, payment_status) 
          NOT IN (
              SELECT order_id, customer_id, shipping_id, payment_method, order_purchased_date, payment_status
              FROM 'order'
              GROUP BY order_id
          );
"

# Execute the SQL statement
dbExecute(my_connection, query.order2)


#To ensure there would be no repeated product entries for the same order
# Query to identify unique combinations of order_id and product_id with duplicates
query.order3 <- "
    SELECT order_id, product_id
    FROM 'order'
    GROUP BY order_id, product_id
    HAVING COUNT(*) > 1
"
duplicate_combinations <- dbGetQuery(my_connection, query.order3)

# Loop over duplicate combinations and selectively delete duplicate observations
for (i in 1:nrow(duplicate_combinations)) {
  order_id <- duplicate_combinations[i, "order_id"]
  product_id <- duplicate_combinations[i, "product_id"]
  
  # Query to select all duplicate observations for the current combination
  query.order3 <- "
    SELECT rowid
    FROM 'order'
    WHERE order_id = ? AND product_id = ?
    ORDER BY rowid
  "
  duplicate_obs <- dbGetQuery(my_connection, query.order3, params = list(order_id, product_id))
  
  # Keep the first observation and delete the rest
  if (nrow(duplicate_obs) > 1) {
    rows_to_keep <- duplicate_obs$rowid[1]
    rows_to_delete <- duplicate_obs$rowid[-1]
    
    # Delete duplicate observations
    for (rowid in rows_to_delete) {
      query.order3 <- "DELETE FROM 'order' WHERE rowid = ?"
      dbExecute(my_connection, query.order3, params = list(rowid))
    }
  }
}


# Ensure the range of the product rating
# SQL statement to update product ratings
query.order4 <- "
    UPDATE 'order'
    SET product_rating = CASE
        WHEN product_rating < 1 THEN 1
        WHEN product_rating > 5 THEN 5
        ELSE product_rating
    END;
"

# Execute the SQL statement
dbExecute(my_connection, query.order4)

#Ensure consistent order payment method
query.order5 <- "
    UPDATE 'order'
    SET payment_method = CASE
        WHEN payment_method IN ('online banking', 'paypal', 'credit/debit card', 'gift card') THEN payment_method
        ELSE 'others'
      END;
"

dbExecute(my_connection, query.order5)


#Ensure consistent payment status
query.order6 <- "
UPDATE 'order'
SET payment_status = CASE
  WHEN payment_status IN ('complete', 'declined') THEN payment_status
  ELSE payment_status IS NULL
END;
"
dbExecute(my_connection, query.order6)


# Connect to database
my_connection <- dbConnect(RSQLite::SQLite(),"project_dm.db")

# The key metrics performance (revenue, order completion day)

# Connect to the SQLite database
conn <- dbConnect(RSQLite::SQLite(), dbname = 'project_dm.db')

# Execute the SQL query
query <- "
    SELECT o.order_purchased_date,
           SUM(o.order_quantity) AS total_order_quantity,
           SUM(o.order_quantity * p.product_price * (1 - d.discount_percentage)) AS total_sales,
           SUM(o.order_quantity * ((p.product_price * (1 - d.discount_percentage)) - p.product_price/1.4)) AS total_revenue
    FROM \"order\" o
    JOIN product p ON o.product_id = p.product_id
    LEFT JOIN discount d ON p.discount_id = d.discount_id
    WHERE o.payment_status = 'complete'
    GROUP BY o.order_purchased_date
    ORDER BY o.order_purchased_date ASC;
"
daily_revenue <- dbGetQuery(conn, query)

# Close the database connection
dbDisconnect(conn)

# Convert the order_purchased_date column to Date format
daily_revenue$order_purchased_date <- as.Date(daily_revenue$order_purchased_date)

# Create time series plot for total revenue
g1 <- ggplot(daily_revenue, aes(x = order_purchased_date, y = total_revenue)) +
  geom_line(color = "red") +
  labs(title = "Time Series of Total Revenue",
       x = "Date",
       y = "Total Revenue") +
  theme_minimal()

ggsave(plot = g1, filename = "graphs/revenue_trend.jpeg", width = 10, height=5,dpi=300)

# Completion days
# Execute the SQL query
completion_day <-RSQLite::dbGetQuery(my_connection,"SELECT AVG(julianday(s.delivered_date) - julianday(o.order_purchased_date)) AS Order_Competion_days
                                     FROM 'order'o
                                     JOIN shipment s ON o.shipping_id = s.shipping_id")
completion_day %>%
  kbl(digits = 1, caption = "Average order completion day") %>%
  kable_styling()

# Customer analysis
# Connect to the SQLite database
conn <- dbConnect(RSQLite::SQLite(), dbname = 'project_dm.db')

# Execute the SQL query
query <- "
    SELECT c.cust_gender,
       CASE 
         WHEN strftime('%Y', 'now') - strftime('%Y', c.cust_birthday) BETWEEN 18 AND 24 THEN '18-24'
         WHEN strftime('%Y', 'now') - strftime('%Y', c.cust_birthday) BETWEEN 25 AND 34 THEN '25-34'
         WHEN strftime('%Y', 'now') - strftime('%Y', c.cust_birthday) BETWEEN 35 AND 44 THEN '35-44'
         WHEN strftime('%Y', 'now') - strftime('%Y', c.cust_birthday) BETWEEN 45 AND 54 THEN '45-54'
         WHEN strftime('%Y', 'now') - strftime('%Y', c.cust_birthday) BETWEEN 55 AND 64 THEN '55-64'
         ELSE '65 and older'
       END AS age_group,
       COUNT(DISTINCT c.cust_id) AS customer_count,
       SUM(o.order_quantity * p.product_price * (1 - d.discount_percentage)) AS total_spending
  FROM \"order\" o
  JOIN product p ON o.product_id = p.product_id
  LEFT JOIN discount d ON p.discount_id = d.discount_id
  JOIN customer c ON o.customer_id = c.cust_id
  WHERE o.payment_status = 'complete'
  GROUP BY c.cust_gender, age_group
  ORDER BY c.cust_gender, MIN(strftime('%Y', 'now') - strftime('%Y', c.cust_birthday)); 
"
customer_portfolio <- dbGetQuery(conn, query)

# Close the database connection
dbDisconnect(conn)

g2<- ggplot(data=customer_portfolio, aes(x=age_group, y=total_spending, fill=cust_gender)) +
  geom_bar(stat="identity", position=position_dodge()) +
  labs(title = "Total Spending by Age Group",
       x = "Age Group",
       y = "Total Spending") +
  theme(legend.title = element_blank())

ggsave(plot = g2, filename = "graphs/Total_Spending_by_Age_Group.jpeg", width = 10, height=8,dpi=300)

# Payment method
# Connect to the SQLite database
conn <- dbConnect(RSQLite::SQLite(), dbname = 'project_dm.db')

# Execute the SQL query
query <- "
    SELECT o.payment_status,
       o.payment_method,
       COUNT(*) AS number_of_used
  FROM \"order\" o
  GROUP BY o.payment_status, o.payment_method
  ORDER BY number_of_used DESC;
"
payment_method <- dbGetQuery(conn, query)

# Close the database connection
dbDisconnect(conn)

# Separate the data into men and women
complete_payment <- payment_method[payment_method$payment_status == "complete", ]
declined_payment <- payment_method[payment_method$payment_status == "declined", ]

# Create separate plots for men and women
plot_complete <- ggplot(complete_payment, aes(x = factor(payment_method, levels = payment_method[order(-number_of_used)]), y = number_of_used)) +
  geom_bar(stat = "identity", show.legend = FALSE) +
  labs(title = "Number of used by payment method - declined",
       x = "Payment Method",
       y = "Number of Used") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        legend.title = element_blank())

plot_declined <- ggplot(declined_payment, aes(x = factor(payment_method, levels = payment_method[order(-number_of_used)]), y = number_of_used)) +
  geom_bar(stat = "identity", show.legend = FALSE) +
  labs(title = "Number of used by payment method - declined",
       x = "Payment Method",
       y = "Number of Used") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        legend.title = element_blank())

# Arrange the plots using grid.arrange
g3 <- grid.arrange(plot_complete, plot_declined, nrow = 1)

ggsave(plot = g3, filename = "graphs/payment_method.jpeg", width = 10, height=8,dpi=300)

# Category analysis
# Connect to the SQLite database
conn <- dbConnect(RSQLite::SQLite(), dbname = 'project_dm.db')

# Execute the SQL query
query <- "
    SELECT 
        parent.category_name AS parent_category,
        sub.category_name AS subcategory,
        SUM(o.order_quantity) AS total_order_quantity,
        SUM(o.order_quantity * p.product_price * (1 - d.discount_percentage)) AS total_sales,
        SUM(o.order_quantity * ((p.product_price * (1 - d.discount_percentage)) - p.product_price/1.4)) AS total_revenue
    FROM 
        'order' o
    JOIN 
        product p ON o.product_id = p.product_id
    JOIN 
        category sub ON p.category_id = sub.category_id
    LEFT JOIN 
        category parent ON sub.p_category_id = parent.category_id
    LEFT JOIN 
        discount d ON p.discount_id = d.discount_id
    WHERE o.payment_status = 'complete'
    GROUP BY 
        parent.category_name, sub.category_name
    ORDER BY 
        total_order_quantity DESC
"
category_sales <- dbGetQuery(conn, query)

# Close the database connection
dbDisconnect(conn)

# Separate the data into men and women
men_data <- category_sales[category_sales$parent_category == "Men", ]
women_data <- category_sales[category_sales$parent_category == "Women", ]

# Order the data frames by total sales in descending order
men_data <- men_data[order(-men_data$total_revenue), ]
women_data <- women_data[order(-women_data$total_revenue), ]

# Create separate plots for men and women
plot_men <- ggplot(men_data, aes(x = factor(subcategory, levels = subcategory[order(-total_revenue)]), y = total_revenue)) +
  geom_bar(stat = "identity", show.legend = FALSE) +
  labs(title = "Total Revenue by Subcategory - Men",
       x = "Subcategory",
       y = "Total Revenue") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        legend.title = element_blank())

plot_women <- ggplot(women_data, aes(x = factor(subcategory, levels = subcategory[order(-total_revenue)]), y = total_revenue)) +
  geom_bar(stat = "identity", show.legend = FALSE) +
  labs(title = "Total Revenue by Subcategory - Women",
       x = "Subcategory",
       y = "Total Revenue") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        legend.title = element_blank())

# Arrange the plots using grid.arrange
g4 <- grid.arrange(plot_men, plot_women, nrow = 1)

ggsave(plot = g4, filename = "graphs/revenue_by_category.jpeg", width = 10, height=8,dpi=300)

# Product analysis
# Execute the SQL query
p_revenue <-RSQLite::dbGetQuery(my_connection,"SELECT p.product_name,
       SUM(o.order_quantity) AS total_order_quantity,
       SUM(o.order_quantity * ((p.product_price * (1 - d.discount_percentage)) - p.product_price/1.4)) AS total_revenue
       FROM 'order' o
       JOIN product p ON o.product_id = p.product_id
       LEFT JOIN discount d ON p.discount_id = d.discount_id
       WHERE o.payment_status = 'complete'
       GROUP BY p.product_name
       ORDER BY total_revenue DESC
       LIMIT 5;")

# Use a table to present the result
p_revenue %>%
  kbl(digits = 1, caption = "Best Selling Products") %>%
  kable_styling()

# The effect of unit price to quantity
# Execute the SQL query
price_quantity <-RSQLite::dbGetQuery(my_connection,"SELECT p.product_name,
                                     p.product_price * (1 - d.discount_percentage) AS
                                     unit_price,
                                     SUM(o.order_quantity) AS quantity
                                     FROM `order` o
                                     JOIN product p ON o.product_id = p.product_id
                                     JOIN discount d ON p.discount_id = d.discount_id
                                     GROUP BY p.product_name
                                     ORDER BY quantity DESC")

# Build the regression model
m.quantity.by.price <- lm(quantity~unit_price, data=price_quantity)

# Plot the model
g5 <- ggplot(price_quantity, aes(x = unit_price, y = quantity)) +
  geom_point() +  
  geom_smooth(method = "lm", se = FALSE) +  
  labs(title = "Linear Regression: Quantity vs Unit Price",
       x = "Unit Price",
       y = "Quantity")

ggsave(plot = g5, filename = "graphs/unitprice_to_quantity.jpeg", width = 10, height=8,dpi=300)

# Customer review analysis
# Execute the SQL query
rate_quantity <-RSQLite::dbGetQuery(my_connection,"SELECT p.product_name,
                                    AVG(o.product_rating) AS avg_rating,
                                    SUM(o.order_quantity) AS quantity
                                    FROM 'order' o
                                    JOIN product p ON o.product_id = p.product_id
                                    GROUP BY p.product_name
                                    ORDER BY quantity DESC")

# Build the regression model
m.quantity.by.rate <- lm(quantity~avg_rating, data=rate_quantity)

# Plot the model
g6 <- ggplot(rate_quantity, aes(x = avg_rating, y = quantity)) +
  geom_point() +  
  geom_smooth(method = "lm", se = FALSE) +  
  labs(title = "Linear Regression: Quantity vs Avg Rating",
       x = "Avg Rating",
       y = "Quantity")

ggsave(plot = g6, filename = "graphs/rating_to_quantity.jpeg", width = 10, height=8,dpi=300)

# The effect of order completion duration to product rating
# Execute the SQL query
rate_day <-RSQLite::dbGetQuery(my_connection,"SELECT AVG(o.product_rating) AS rating,
                               AVG(julianday(s.delivered_date) -
                               julianday(o.order_purchased_date)) AS completion_day
                               FROM 'order' o
                               JOIN shipment s ON o.shipping_id = s.shipping_id
                               JOIN product p ON o.product_id = p.product_id
                               GROUP BY p.product_name")

# Build the regression model
m.rate.by.day <- lm(completion_day~rating, data=rate_day)

# Plot the model
g7 <- ggplot(rate_day, aes(x = completion_day, y = rating)) +
  geom_point() +  
  geom_smooth(method = "lm", se = FALSE) +  
  labs(title = "Linear Regression: Completion day vs Avg Rating",
       x = "Completion Day",
       y = "Rating")

ggsave(plot = g7, filename = "graphs/day_to_rate.jpeg", width = 10, height=8,dpi=300)

# Connect to the SQLite database
conn <- dbConnect(RSQLite::SQLite(), dbname = 'project_dm.db')

# Execute the SQL query
query <- "
    SELECT s.supplier_name,
       SUM(o.order_quantity) AS total_order_quantity,
       SUM(o.order_quantity * ((p.product_price * (1 - d.discount_percentage)) - p.product_price/1.4)) AS total_revenue,
       COUNT(o.product_rating) AS total_reviews,
       AVG(o.product_rating) AS average_rating
FROM \"order\" o
JOIN product p ON o.product_id = p.product_id
LEFT JOIN discount d ON p.discount_id = d.discount_id
JOIN supplier s ON p.supplier_id = s.supplier_id
WHERE o.payment_status = 'complete'
GROUP BY s.supplier_name
ORDER BY total_order_quantity DESC;
"
supplier_performance <- dbGetQuery(conn, query)

# Close the database connection
dbDisconnect(conn)

# Top 5 suppliers based on rating
top_rating <- supplier_performance[order(-supplier_performance$average_rating), ][1:5, ]

# Top 5 suppliers based on total order quantity
top_order_quantity <- supplier_performance[order(-supplier_performance$total_order_quantity), ][1:5, ]

# Top 5 suppliers based on total sales
top_revenue <- supplier_performance[order(-supplier_performance$total_revenue), ][1:5, ]

# Create plots
plot_top_rating <- ggplot(top_rating, aes(x = reorder(supplier_name, -average_rating), y = average_rating,  width = 0.7)) +
  geom_bar(stat = "identity", fill = "salmon") +
  labs(title = "Top 5 Rating",
       x = "Supplier",
       y = "Average Rating") + 
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

plot_top_order_quantity <- ggplot(top_order_quantity, aes(x = reorder(supplier_name, -total_order_quantity), y = total_order_quantity,  width = 0.7)) +
  geom_bar(stat = "identity", fill = "skyblue") +
  labs(title = "Top 5 Total Order Quantity",
       x = "Supplier",
       y = "Total Order Quantity") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

plot_top_revenue <- ggplot(top_revenue, aes(x = reorder(supplier_name, -total_revenue), y = total_revenue,  width = 0.7)) +
  geom_bar(stat = "identity", fill = "lightgreen") +
  labs(title = "Top 5 Total Revenue",
       x = "Supplier",
       y = "Total Revenue") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))


# Plot the graphs
g8 <- grid.arrange(plot_top_rating, plot_top_order_quantity, plot_top_revenue, nrow = 1)

ggsave(plot = g8, filename = "graphs/supplier.jpeg", width = 10, height=6,dpi=300)
