library(RSQLite)
library(DBI)
library(lubridate)

# Connect to database
connection <- dbConnect(RSQLite::SQLite(), dbname= 'project_dm.db')


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
email.customer <- dbGetQuery(connection, query_emails.customer)
# Apply the function to check email format
email_validity.customer <- sapply(email.customer, check_email_format)

# Print their validity
cust.email.validity <- data.frame(Email = email.customer, Valid = email_validity.customer)

invalid.email <- subset(cust.email.validity, cust_email.1 == FALSE)
print(paste("Number of invalid customer emails:",nrow(invalid.email)))


# Phone number validation
query_phone.customer <- "SELECT cust_phone FROM customer"

phone.customer <- dbGetQuery(connection, query_phone.customer)

phone_validity.customer <- sapply(phone.customer, check_phone_format)

cust.phone.validity <- data.frame(Phone = phone.customer, Valid = phone_validity.customer)

invalid.phone <- subset(cust.phone.validity, cust_phone.1 == FALSE)
print(paste("Number of invalid customer phone numbers:",nrow(invalid.phone)))

#Date validation
query_date.customer <- "SELECT cust_birthday FROM customer"

date.customer <- dbGetQuery(connection, query_date.customer)

date_validity.customer <- sapply(date.customer, check_date_format)

cust.date.validity <- data.frame(Date=date.customer, Valid=date_validity.customer)

invalid.date <- subset(cust.date.validity, cust_birthday.1==FALSE)
print(paste("Number of invalid customer birthdays:",nrow(invalid.date)))

#Postcode validation
query_postcode.customer <- "SELECT cust_postcode FROM customer"

postcode.customer <- dbGetQuery(connection, query_postcode.customer)

postcode_validity.customer <- sapply(postcode.customer, check_postcode_format)

cust.postcode.validity <- data.frame(postcode=postcode.customer, Valid=postcode_validity.customer)

invalid.post <- subset(cust.postcode.validity, cust_postcode.1==FALSE)
print(paste("Number of invalid customer postcodes:",nrow(invalid.post)))

#Age Validation
query_age.customer <- "SELECT cust_birthday FROM customer"

age.customer <- dbGetQuery(connection, query_age.customer)

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
  duplicates.customer <- dbGetQuery(connection, check_duplicates.customer)
  
print(paste("Number of duplicates in customer table:",nrow(duplicates.customer)))





#Supplier Table
#Email 
query_emails.supplier <- "SELECT supplier_email FROM supplier"

email.supplier <- dbGetQuery(connection, query_emails.supplier)

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
duplicates.supplier <- dbGetQuery(connection, check_duplicates.supplier)
print(paste("Number of duplicates in supplier :",nrow(duplicates.supplier)))


#Product Table
#Price Validation
query_price.product <- "SELECT product_price FROM product"

price.product <- dbGetQuery(connection, query_price.product)

price_validity.product <- sapply(price.product, price_range_check)

product.price.validity <- data.frame(price = price.product, Valid = price_validity.product)

invalid.price.product <- subset(product.price.validity, product_price.1==FALSE)
print(paste("Number of invalid product prices:",nrow(invalid.price.product)))

#Stock validation
query_stock.product <- "SELECT product_stock FROM product"

stock.product <- dbGetQuery(connection, query_stock.product)

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
duplicates.product <- dbGetQuery(connection, check_duplicates.product)
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
dbExecute(connection, query.categoryid)      
dbExecute(connection, query.supplierid)  
dbExecute(connection, query.discountid)  


## Shipment Table
# Date format validation
query_shippingdate.shipment <- "SELECT shipping_date FROM shipment"

shippingdate.shipment <- dbGetQuery(connection, query_shippingdate.shipment)

shippingdate_validity.shipment <- sapply(shippingdate.shipment, check_date_format)

shipment.shipmentdate.validity <- data.frame(shippingdate = shippingdate.shipment, Valid = shippingdate_validity.shipment)

invalid.shippingdate <- subset(shipment.shipmentdate.validity, shipping_date.1==FALSE)
print(paste("Number of invalid shipping date:",nrow(invalid.shippingdate)))

query_deliverydate.shipment <- "SELECT delivered_date FROM shipment"

deliverydate.shipment <- dbGetQuery(connection, query_deliverydate.shipment)

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
duplicate_entries <- dbGetQuery(connection, query.discount)
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
  dbExecute(connection, query.discount, params = list(discount_name, discount_id, discount_percentage, discount_id))
}

  
# Query to identify entries with discount percentages not within the range of 0 and 1
query.discount2 <- "
    SELECT discount_id, discount_name, discount_percentage
    FROM discount
    WHERE discount_percentage < 0 OR discount_percentage > 1
"
out_of_range_entries <- dbGetQuery(connection, query.discount2)
print(paste("Number of out of range discount percentages:",nrow(out_of_range_entries)))


# Loop over out-of-range entries and remove them
for (i in 1:nrow(out_of_range_entries)) {
  discount_id <- out_of_range_entries[i, "discount_id"]
  
  # Delete entries with discount percentages not within the range of 0 and 1
  query.discount2 <- "DELETE FROM discount WHERE discount_id = ?"
  dbExecute(connection, query.discount2, params = list(discount_id))
}


# Query to identify entries with duplicate parent category IDs and category names
query.discount3 <- "
    SELECT p_category_id, category_name, MIN(category_id) AS keep_category_id, COUNT(*) AS num_duplicates
    FROM category
    GROUP BY p_category_id, category_name
    HAVING COUNT(*) > 1
"
duplicate_entries <- dbGetQuery(connection, query.discount3)
print(paste("Number of duplicate parent category IDs and category names :",nrow(duplicate_entries)))

# Loop over duplicate entries and remove all but one of the duplicates
for (i in 1:nrow(duplicate_entries)) {
  p_category_id <- duplicate_entries[i, "p_category_id"]
  category_name <- duplicate_entries[i, "category_name"]
  keep_category_id <- duplicate_entries[i, "keep_category_id"]
  
  # Delete duplicate entries except for the one to keep
  query.discount3 <- "DELETE FROM category WHERE p_category_id = ? AND category_name = ? AND category_id != ?"
  dbExecute(connection, query.discount3, params = list(p_category_id, category_name, keep_category_id))
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
dbExecute(connection, query.discount4)


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
dbExecute(connection, query.category)


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

dbExecute(connection, query.customerid)      
dbExecute(connection, query.productid)  
dbExecute(connection, query.shippingid)  

# Quantity Validation
query.order.quantity <- "SELECT order_quantity FROM 'order'"
order.quantity <- dbGetQuery(connection, query.order.quantity)

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
dbExecute(connection, query.order1)

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
dbExecute(connection, query.order2)


#To ensure there would be no repeated product entries for the same order
# Query to identify unique combinations of order_id and product_id with duplicates
query.order3 <- "
    SELECT order_id, product_id
    FROM 'order'
    GROUP BY order_id, product_id
    HAVING COUNT(*) > 1
"
duplicate_combinations <- dbGetQuery(connection, query.order3)

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
  duplicate_obs <- dbGetQuery(connection, query.order3, params = list(order_id, product_id))
  
  # Keep the first observation and delete the rest
  if (nrow(duplicate_obs) > 1) {
    rows_to_keep <- duplicate_obs$rowid[1]
    rows_to_delete <- duplicate_obs$rowid[-1]
    
    # Delete duplicate observations
    for (rowid in rows_to_delete) {
      query.order3 <- "DELETE FROM 'order' WHERE rowid = ?"
      dbExecute(connection, query.order3, params = list(rowid))
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
dbExecute(connection, query.order4)

#Ensure consistent order payment method
query.order5 <- "
    UPDATE 'order'
    SET payment_method = CASE
        WHEN payment_method IN ('online banking', 'paypal', 'credit/debit card', 'gift card') THEN payment_method
        ELSE 'others'
      END;
"

dbExecute(connection, query.order5)


#Ensure consistent payment status
query.order6 <- "
UPDATE 'order'
SET payment_status = CASE
  WHEN payment_status IN ('complete', 'declined') THEN payment_status
  ELSE payment_status IS NULL
END;
"
dbExecute(connection, query.order6)

  