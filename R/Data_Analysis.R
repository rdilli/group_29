library(RSQLite)
library(ggplot2)
library(gridExtra)
library(Hmisc)
options(width=100)
library(kableExtra)
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
