# Load the RSQLite package
library(RSQLite)

# Establish connection to the SQLite database
my_connection <- dbConnect(RSQLite::SQLite(), "project_dm.db")

# Define the SQL commands
sql_commands <- c(
  "DROP TABLE IF EXISTS 'customer';",
  "CREATE TABLE 'customer'(
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
  );",
  "CREATE INDEX idx_customer_location ON customer(cust_city, cust_postcode);",
  "DROP TABLE IF EXISTS 'product';",
  "CREATE TABLE 'product'(
    'product_id' VARCHAR(10) PRIMARY KEY,
    'category_id' VARCHAR(10) NOT NULL,
    'supplier_id' VARCHAR(10) NOT NULL,
    'discount_id' VARCHAR(10) NOT NULL,
    'product_name' VARCHAR(255) NOT NULL,
    'product_price' DECIMAL(10,2) NOT NULL,
    'product_stock' INT NOT NULL,
    FOREIGN KEY ('category_id') REFERENCES category('category_id'),
    FOREIGN KEY ('discount_id') REFERENCES discount('discount_id')
  );",
  "CREATE INDEX idx_product_name ON product(product_name);",
  "CREATE INDEX idx_product_stock ON product(product_stock);",
  "DROP TABLE IF EXISTS 'category';",
  "CREATE TABLE 'category' (
    'category_id' VARCHAR(10) PRIMARY KEY,
    'category_name' VARCHAR(255) NOT NULL,
    'p_category_id' VARCHAR(10) NOT NULL
  );",
  "CREATE INDEX idx_category_p_category_id ON category(p_category_id);",
  "DROP TABLE IF EXISTS 'supplier';",
  "CREATE TABLE 'supplier'(
    'supplier_id' VARCHAR(10) PRIMARY KEY,
    'supplier_name' VARCHAR(255) NOT NULL,
    'supplier_street' VARCHAR(255) NOT NULL,
    'supplier_city' VARCHAR(255) NOT NULL,
    'supplier_postcode' VARCHAR(20) NOT NULL,
    'supplier_email' VARCHAR(255) NOT NULL
  );",
  "CREATE INDEX idx_supplier_email ON supplier(supplier_email);",
  "DROP TABLE IF EXISTS 'order';",
  "CREATE TABLE 'order'(
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
  );",
  "CREATE INDEX idx_order_customer ON order(customer_id);",
  "CREATE INDEX idx_order_product ON order(product_id);",
  "DROP TABLE IF EXISTS 'shipment';",
  "CREATE TABLE 'shipment'(
    'shipping_id' VARCHAR(10) PRIMARY KEY,
    'tracking_number' INT UNIQUE,
    'shipping_date' DATE,
    'delivered_date' DATE,
    'shipment_status' VARCHAR(20)
  );",
  "CREATE INDEX idx_shipment_dates ON shipment(shipping_date, delivered_date);",
  "DROP TABLE IF EXISTS 'discount';",
  "CREATE TABLE 'discount' (
    'discount_id' VARCHAR(10) PRIMARY KEY,
    'discount_name' VARCHAR(200) NOT NULL,
    'discount_percentage' INT NOT NULL
  );"
)

# Execute the SQL commands
for (sql_cmd in sql_commands) {
  dbExecute(my_connection, sql_cmd)
}

# Close the database connection
dbDisconnect(my_connection)