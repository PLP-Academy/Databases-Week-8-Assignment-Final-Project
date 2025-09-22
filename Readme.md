````markdown
# 📦 Inventory Tracking Database (MySQL)

## 📌 Description
This project is a **relational database** for inventory tracking implemented in **MySQL**.  
It supports users, suppliers, customers, products, warehouses, sales orders, purchase orders, transfers, and inventory audits.  

The database schema, sample data, and test queries are provided in a single SQL file:  
`inventory_db_full.sql`

---

## ⚙️ Functionality
The system provides:

- **User Management**  
  - Stores system users with roles (admin, manager, clerk).  

- **Product & Category Management**  
  - Products belong to categories.  
  - Products have one-to-one detailed descriptions.  

- **Supplier Management**  
  - Many-to-Many relationship between products and suppliers.  

- **Warehouse & Inventory Management**  
  - Products stored across multiple warehouses.  
  - Stock levels tracked with min and max thresholds.  

- **Customer & Sales Orders**  
  - Customers place sales orders.  
  - Each order contains one or more items linked to products and warehouses.  

- **Purchase Orders**  
  - Products are procured from suppliers via purchase orders.  
  - Purchase order items define quantities and prices.  

- **Transfers**  
  - Products can be moved between warehouses.  
  - Each transfer has related transfer items.  

- **Audit & Logging**  
  - Inventory audits record stock adjustments by users.  
  - Product images can be stored for reference.  

---

## 🧪 Testing Cases
Test queries are included at the bottom of `inventory_db_full.sql`.  

1. **List all products with their category and available stock**
```sql
SELECT p.name AS product, c.name AS category, SUM(i.quantity) AS total_stock
FROM products p
JOIN categories c ON p.category_id = c.category_id
JOIN inventory i ON p.product_id = i.product_id
GROUP BY p.product_id, c.name;
````

2. **Find all orders with customer names and total amounts**

```sql
SELECT o.order_number, c.name AS customer, o.total_amount, o.status
FROM sales_orders o
JOIN customers c ON o.customer_id = c.customer_id;
```

3. **Products supplied by each supplier**

```sql
SELECT s.name AS supplier, p.name AS product
FROM product_suppliers ps
JOIN suppliers s ON ps.supplier_id = s.supplier_id
JOIN products p ON ps.product_id = p.product_id;
```

4. **Inventory below reorder level**

```sql
SELECT p.name, SUM(i.quantity) AS stock, p.reorder_level
FROM products p
JOIN inventory i ON p.product_id = i.product_id
GROUP BY p.product_id
HAVING stock < p.reorder_level;
```

---

## 🚀 Implementation

1. Run the script:

   ```bash
   mysql -u root -p < inventory_db_full.sql
   ```
2. The script will:

   * Create the database `inventory_db`
   * Define all tables with constraints (PRIMARY KEY, FOREIGN KEY, UNIQUE, NOT NULL)
   * Insert sample data for users, categories, products, suppliers, warehouses, customers, sales orders, and purchase orders
   * Provide test queries to validate functionality

---

## 🏛️ Architecture

The database schema is structured into **entities** and **relationships**:

### Core Tables

* `users` – system users
* `categories` – product categories
* `suppliers` – product suppliers
* `products` – product catalog
* `product_details` – one-to-one product details
* `warehouses` – storage locations
* `inventory` – stock levels per product per warehouse
* `customers` – customer details

### Transaction Tables

* `sales_orders` – customer sales orders
* `order_items` – products in each sales order
* `purchase_orders` – supplier purchase orders
* `po_items` – products in each purchase order
* `transfers` – stock movements between warehouses
* `transfer_items` – products in each transfer

### Supporting Tables

* `product_suppliers` – many-to-many link between products and suppliers
* `product_images` – optional product images
* `inventory_audit` – records of stock adjustments

---

## 📊 ER Diagram

### ASCII/Text Representation

```
[Users]

[Categories]──< Products >──[Product Details]
        │             │
        │             └──< Product Suppliers >──[Suppliers]
        │
  [Warehouses]──< Inventory >──Products
        │
   [Transfers]──< Transfer Items >──Products
        │
[Customers]──< Sales Orders >──< Order Items >──Products
        │
[Suppliers]──< Purchase Orders >──< PO Items >──Products

[Inventory Audit]──linked to Products & Users
[Product Images]──linked to Products
```

## 👨‍💻 Author

Prepared by *George*
Assignment: **Database Management System – Inventory Tracking**

```