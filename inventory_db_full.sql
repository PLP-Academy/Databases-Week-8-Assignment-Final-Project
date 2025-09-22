-- =====================================================
-- Inventory Tracking Database (DDL + DML + Test Queries)
-- =====================================================

-- Create database
CREATE DATABASE IF NOT EXISTS inventory_db
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_unicode_ci;
USE inventory_db;

-- =====================================================
-- DDL: Tables
-- =====================================================

CREATE TABLE users (
  user_id INT AUTO_INCREMENT PRIMARY KEY,
  username VARCHAR(50) NOT NULL UNIQUE,
  full_name VARCHAR(100) NOT NULL,
  email VARCHAR(100) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  role ENUM('admin','manager','clerk') NOT NULL DEFAULT 'clerk',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE suppliers (
  supplier_id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(150) NOT NULL,
  contact_name VARCHAR(100),
  phone VARCHAR(30),
  email VARCHAR(100),
  address TEXT,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE categories (
  category_id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL UNIQUE,
  description TEXT
) ENGINE=InnoDB;

CREATE TABLE products (
  product_id INT AUTO_INCREMENT PRIMARY KEY,
  sku VARCHAR(50) NOT NULL UNIQUE,
  name VARCHAR(150) NOT NULL,
  category_id INT NOT NULL,
  unit_price DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  reorder_level INT NOT NULL DEFAULT 0,
  active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_products_category FOREIGN KEY (category_id)
    REFERENCES categories(category_id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE product_details (
  product_id INT PRIMARY KEY,
  description TEXT,
  weight_kg DECIMAL(8,3),
  dimensions VARCHAR(100),
  manufacturer VARCHAR(150),
  CONSTRAINT fk_prod_details_prod FOREIGN KEY (product_id)
    REFERENCES products(product_id)
    ON DELETE CASCADE
    ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE product_suppliers (
  product_id INT NOT NULL,
  supplier_id INT NOT NULL,
  supplier_sku VARCHAR(100),
  lead_time_days INT DEFAULT 0,
  price DECIMAL(12,2) DEFAULT NULL,
  PRIMARY KEY (product_id, supplier_id),
  CONSTRAINT fk_ps_product FOREIGN KEY (product_id)
    REFERENCES products(product_id)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT fk_ps_supplier FOREIGN KEY (supplier_id)
    REFERENCES suppliers(supplier_id)
    ON DELETE CASCADE
    ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE warehouses (
  warehouse_id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(150) NOT NULL,
  address TEXT,
  phone VARCHAR(30)
) ENGINE=InnoDB;

CREATE TABLE inventory (
  inventory_id BIGINT AUTO_INCREMENT PRIMARY KEY,
  product_id INT NOT NULL,
  warehouse_id INT NOT NULL,
  quantity INT NOT NULL DEFAULT 0,
  reserved INT NOT NULL DEFAULT 0,
  min_quantity INT NOT NULL DEFAULT 0,
  max_quantity INT NOT NULL DEFAULT 0,
  last_counted DATETIME,
  UNIQUE KEY uq_inventory_product_warehouse (product_id, warehouse_id),
  CONSTRAINT fk_inv_product FOREIGN KEY (product_id)
    REFERENCES products(product_id)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT fk_inv_warehouse FOREIGN KEY (warehouse_id)
    REFERENCES warehouses(warehouse_id)
    ON DELETE CASCADE
    ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE customers (
  customer_id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(150) NOT NULL,
  contact_name VARCHAR(100),
  phone VARCHAR(30),
  email VARCHAR(100),
  billing_address TEXT,
  shipping_address TEXT,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE sales_orders (
  order_id BIGINT AUTO_INCREMENT PRIMARY KEY,
  order_number VARCHAR(50) NOT NULL UNIQUE,
  customer_id INT NOT NULL,
  order_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  status ENUM('draft','confirmed','shipped','completed','cancelled') NOT NULL DEFAULT 'draft',
  total_amount DECIMAL(14,2) NOT NULL DEFAULT 0.00,
  created_by INT,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_order_customer FOREIGN KEY (customer_id)
    REFERENCES customers(customer_id)
    ON DELETE RESTRICT
    ON UPDATE CASCADE,
  CONSTRAINT fk_order_user FOREIGN KEY (created_by)
    REFERENCES users(user_id)
    ON DELETE SET NULL
    ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE order_items (
  order_item_id BIGINT AUTO_INCREMENT PRIMARY KEY,
  order_id BIGINT NOT NULL,
  product_id INT NOT NULL,
  warehouse_id INT,
  quantity INT NOT NULL,
  unit_price DECIMAL(12,2) NOT NULL,
  line_total DECIMAL(14,2) AS (quantity * unit_price) STORED,
  CONSTRAINT fk_oi_order FOREIGN KEY (order_id)
    REFERENCES sales_orders(order_id)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT fk_oi_product FOREIGN KEY (product_id)
    REFERENCES products(product_id)
    ON DELETE RESTRICT
    ON UPDATE CASCADE,
  CONSTRAINT fk_oi_warehouse FOREIGN KEY (warehouse_id)
    REFERENCES warehouses(warehouse_id)
    ON DELETE SET NULL
    ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE purchase_orders (
  po_id BIGINT AUTO_INCREMENT PRIMARY KEY,
  po_number VARCHAR(50) NOT NULL UNIQUE,
  supplier_id INT NOT NULL,
  order_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  expected_date DATE,
  status ENUM('ordered','received','partial','cancelled') NOT NULL DEFAULT 'ordered',
  total_amount DECIMAL(14,2) NOT NULL DEFAULT 0.00,
  created_by INT,
  CONSTRAINT fk_po_supplier FOREIGN KEY (supplier_id)
    REFERENCES suppliers(supplier_id)
    ON DELETE RESTRICT
    ON UPDATE CASCADE,
  CONSTRAINT fk_po_user FOREIGN KEY (created_by)
    REFERENCES users(user_id)
    ON DELETE SET NULL
    ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE po_items (
  po_item_id BIGINT AUTO_INCREMENT PRIMARY KEY,
  po_id BIGINT NOT NULL,
  product_id INT NOT NULL,
  quantity INT NOT NULL,
  unit_price DECIMAL(12,2) NOT NULL,
  line_total DECIMAL(14,2) AS (quantity * unit_price) STORED,
  CONSTRAINT fk_poi_po FOREIGN KEY (po_id)
    REFERENCES purchase_orders(po_id)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT fk_poi_product FOREIGN KEY (product_id)
    REFERENCES products(product_id)
    ON DELETE RESTRICT
    ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE transfers (
  transfer_id BIGINT AUTO_INCREMENT PRIMARY KEY,
  transfer_number VARCHAR(50) NOT NULL UNIQUE,
  from_warehouse_id INT NOT NULL,
  to_warehouse_id INT NOT NULL,
  transfer_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  status ENUM('initiated','in_transit','completed','cancelled') NOT NULL DEFAULT 'initiated',
  created_by INT,
  CONSTRAINT fk_tr_from_wh FOREIGN KEY (from_warehouse_id)
    REFERENCES warehouses(warehouse_id)
    ON DELETE RESTRICT
    ON UPDATE CASCADE,
  CONSTRAINT fk_tr_to_wh FOREIGN KEY (to_warehouse_id)
    REFERENCES warehouses(warehouse_id)
    ON DELETE RESTRICT
    ON UPDATE CASCADE,
  CONSTRAINT fk_tr_user FOREIGN KEY (created_by)
    REFERENCES users(user_id)
    ON DELETE SET NULL
    ON UPDATE CASCADE,
  CONSTRAINT chk_diff_warehouses CHECK (from_warehouse_id <> to_warehouse_id)
) ENGINE=InnoDB;

CREATE TABLE transfer_items (
  transfer_item_id BIGINT AUTO_INCREMENT PRIMARY KEY,
  transfer_id BIGINT NOT NULL,
  product_id INT NOT NULL,
  quantity INT NOT NULL,
  CONSTRAINT fk_ti_transfer FOREIGN KEY (transfer_id)
    REFERENCES transfers(transfer_id)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT fk_ti_product FOREIGN KEY (product_id)
    REFERENCES products(product_id)
    ON DELETE RESTRICT
    ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE inventory_audit (
  audit_id BIGINT AUTO_INCREMENT PRIMARY KEY,
  inventory_id BIGINT,
  product_id INT NOT NULL,
  warehouse_id INT NOT NULL,
  change INT NOT NULL,
  reason VARCHAR(255),
  changed_by INT,
  changed_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_audit_inventory FOREIGN KEY (inventory_id)
    REFERENCES inventory(inventory_id)
    ON DELETE SET NULL
    ON UPDATE CASCADE,
  CONSTRAINT fk_audit_product FOREIGN KEY (product_id)
    REFERENCES products(product_id)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT fk_audit_warehouse FOREIGN KEY (warehouse_id)
    REFERENCES warehouses(warehouse_id)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT fk_audit_user FOREIGN KEY (changed_by)
    REFERENCES users(user_id)
    ON DELETE SET NULL
    ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE product_images (
  image_id BIGINT AUTO_INCREMENT PRIMARY KEY,
  product_id INT NOT NULL,
  filename VARCHAR(255) NOT NULL,
  alt_text VARCHAR(255),
  is_primary BOOLEAN NOT NULL DEFAULT FALSE,
  uploaded_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_img_product FOREIGN KEY (product_id)
    REFERENCES products(product_id)
    ON DELETE CASCADE
    ON UPDATE CASCADE
) ENGINE=InnoDB;

-- =====================================================
-- DML: Sample Data
-- =====================================================

INSERT INTO users (username, full_name, email, password_hash, role)
VALUES 
('admin', 'System Admin', 'admin@example.com', 'hashed_pw1', 'admin'),
('jdoe', 'John Doe', 'jdoe@example.com', 'hashed_pw2', 'manager');

INSERT INTO categories (name, description)
VALUES 
('Electronics', 'Electronic devices'),
('Office Supplies', 'Supplies for office use');

INSERT INTO suppliers (name, contact_name, phone, email)
VALUES 
('Alpha Supplies', 'Alice Alpha', '123-456-7890', 'alice@alpha.com'),
('Beta Wholesale', 'Bob Beta', '987-654-3210', 'bob@beta.com');

INSERT INTO products (sku, name, category_id, unit_price, reorder_level)
VALUES 
('ELEC001', 'Laptop', 1, 1200.00, 10),
('ELEC002', 'Smartphone', 1, 800.00, 15),
('OFF001', 'Printer Paper', 2, 5.50, 50);

INSERT INTO product_details (product_id, description, weight_kg, dimensions, manufacturer)
VALUES
(1, '15-inch laptop, 16GB RAM, 512GB SSD', 2.5, '35x24x2 cm', 'TechCorp'),
(2, '5G smartphone with 128GB storage', 0.3, '15x7x0.8 cm', 'PhoneMaker'),
(3, 'A4 size white sheets (500 pack)', 2.0, '30x21x5 cm', 'PaperWorks');

INSERT INTO warehouses (name, address, phone)
VALUES 
('Main Warehouse', '123 Main St', '555-111-2222'),
('Secondary Warehouse', '456 Side St', '555-333-4444');

INSERT INTO inventory (product_id, warehouse_id, quantity, min_quantity, max_quantity)
VALUES
(1, 1, 20, 5, 50),
(2, 1, 40, 10, 100),
(3, 2, 200, 50, 500);

INSERT INTO customers (name, contact_name, phone, email, billing_address, shipping_address)
VALUES
('Acme Corp', 'Charlie Client', '555-777-8888', 'charlie@acme.com', '10 Acme Blvd', '10 Acme Blvd');

INSERT INTO sales_orders (order_number, customer_id, status, total_amount, created_by)
VALUES
('SO1001', 1, 'confirmed', 2000.00, 2);

INSERT INTO order_items (order_id, product_id, warehouse_id, quantity, unit_price)
VALUES
(1, 1, 1, 1, 1200.00),
(1, 2, 1, 1, 800.00);

INSERT INTO purchase_orders (po_number, supplier_id, status, total_amount, created_by)
VALUES
('PO2001', 1, 'ordered', 2400.00, 2);

INSERT INTO po_items (po_id, product_id, quantity, unit_price)
VALUES
(1, 1, 2, 1200.00);

-- =====================================================
-- TEST QUERIES WITH USE CASE DEFINITIONS
-- =====================================================

-- Use Case 1: List all products with their category and available stock
SELECT p.name AS product, c.name AS category, SUM(i.quantity) AS total_stock
FROM products p
JOIN categories c ON p.category_id = c.category_id
JOIN inventory i ON p.product_id = i.product_id
GROUP BY p.product_id, c.name;

-- Use Case 2: Find all sales orders with customer names and total amounts
SELECT o.order_number, c.name AS customer, o.total_amount, o.status
FROM sales_orders o
JOIN customers c ON o.customer_id = c.customer_id;

-- Use Case 3: Find products supplied by each supplier
SELECT s.name AS supplier, p.name AS product
FROM product_suppliers ps
JOIN suppliers s ON ps.supplier_id = s.supplier_id
JOIN products p ON ps.product_id = p.product_id;

-- Use Case 4: Identify inventory items below reorder level
SELECT p.name, SUM(i.quantity) AS stock, p.reorder_level
FROM products p
JOIN inventory i ON p.product_id = i.product_id
GROUP BY p.product_id
HAVING stock < p.reorder_level;