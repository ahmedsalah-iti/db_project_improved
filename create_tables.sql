-- SOURCE /home/as/Desktop/db_project_improved/create_tables.sql;

drop database if exists cafeteria;
create database cafeteria;
use cafeteria;

CREATE TABLE Room (
    id int AUTO_INCREMENT primary key,
    name VARCHAR(100) UNIQUE NOT NULL

);

CREATE TABLE Category(
    id int AUTO_INCREMENT primary key,
    name VARCHAR(100) UNIQUE not null
);

CREATE TABLE User (
    id INT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(100) UNIQUE not null,
    first_name VARCHAR(50) not null,
    last_name VARCHAR(50) not null,
    password VARCHAR(255) not null,
    phone VARCHAR(11) UNIQUE not null,
    profile_img VARCHAR(255),
    role ENUM('admin','customer') not null,
    room_id int
);


CREATE TABLE Wallet_Transaction(
    id int AUTO_INCREMENT primary key,
    user_id int not null,
    type ENUM('add','sub') not null,
    amount decimal(10,2) not null,
    balance_before decimal(10,2) not null,
    balance_after decimal(10,2) not null,
    status ENUM('completed','failed') DEFAULT 'failed' NOT NULL,
    made_at DATETIME DEFAULT CURRENT_TIMESTAMP not null
);

CREATE table Product (
    id int AUTO_INCREMENT primary key,
    name VARCHAR(255) not null,
    price decimal(10,2) not null,
    product_img VARCHAR(255),
    category_id int,
    status BOOLEAN DEFAULT FALSE not null
);

CREATE TABLE `Order` (
    id INT AUTO_INCREMENT PRIMARY KEY,
    status ENUM('pending', 'completed', 'canceled') NOT NULL,
    note VARCHAR(255),
    user_id INT,
    room_id INT,
    date DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE Order_Product (
    id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL,
    product_id INT,
    quantity tinyint NOT NULL CHECK (quantity > 0),
    price_at_purchase decimal(10,2) not null
);

CREATE TABLE Payment (
    id INT AUTO_INCREMENT PRIMARY KEY,
    date DATETIME DEFAULT CURRENT_TIMESTAMP,
    status ENUM('pending', 'completed', 'failed') DEFAULT 'pending' NOT NULL,
    method ENUM('cash', 'delivery', 'online') NOT NULL,
    order_id INT NOT NULL
);






-- adding FKs
ALTER TABLE User 
ADD CONSTRAINT fk_user_room_id FOREIGN KEY (room_id) REFERENCES Room(id) ON DELETE SET NULL;

ALTER TABLE Wallet_Transaction 
ADD CONSTRAINT fk_wallet_transaction_user_id FOREIGN KEY (user_id) REFERENCES User(id) ON DELETE CASCADE;

ALTER TABLE Product 
ADD CONSTRAINT fk_product_category_id FOREIGN KEY (category_id) REFERENCES Category(id) ON DELETE SET NULL;

ALTER TABLE `Order` 
ADD CONSTRAINT fk_order_user_id FOREIGN KEY (user_id) REFERENCES User(id) ON DELETE SET NULL,
ADD CONSTRAINT fk_order_room_id FOREIGN KEY (room_id) REFERENCES Room(id) ON DELETE SET NULL;

ALTER TABLE Order_Product 
ADD CONSTRAINT fk_order_product_order_id FOREIGN KEY (order_id) REFERENCES `Order`(id) ON DELETE CASCADE,
ADD CONSTRAINT fk_order_product_product_id FOREIGN KEY (product_id) REFERENCES Product(id) ON DELETE RESTRICT;

ALTER TABLE Payment 
ADD CONSTRAINT fk_payment_order_id FOREIGN KEY (order_id) REFERENCES `Order`(id) ON DELETE CASCADE;


-- Adding Indexes
-- for fast login
CREATE INDEX idx_email on User(email);

-- for fast product search
CREATE INDEX idx_product_name on Product(name);
