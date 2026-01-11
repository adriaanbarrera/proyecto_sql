-- Crear la base de datos y comprobar que estoy usándola
CREATE DATABASE IF NOT EXISTS proyecto_SQL;
USE proyecto_SQL;

/* Primero creo las tablas según los csv que he descargado. Estas no serán las tablas
 finales, sino que se usarán para crear las "reales".
 */
-- 1. Clientes
CREATE TABLE IF NOT EXISTS olist_customers_dataset (
    customer_id VARCHAR(50) PRIMARY KEY,
    customer_unique_id VARCHAR(50),
    customer_zip_code_prefix INT,
    customer_city VARCHAR(100),
    customer_state CHAR(2)
);

-- 2. Geolocalización
CREATE TABLE IF NOT EXISTS olist_geolocation_dataset (
    geolocation_zip_code_prefix INT,
    geolocation_lat DECIMAL(10, 8),
    geolocation_lng DECIMAL(10, 8),
    geolocation_city VARCHAR(100),
    geolocation_state CHAR(2)
);

-- 3. Ítems de Pedidos
CREATE TABLE IF NOT EXISTS olist_order_items_dataset (
    order_id VARCHAR(50),
    order_item_id INT,
    product_id VARCHAR(50),
    seller_id VARCHAR(50),
    shipping_limit_date DATETIME,
    price DECIMAL(10, 2),
    freight_value DECIMAL(10, 2),
    PRIMARY KEY (order_id, order_item_id)
);

-- 4. Pagos de Pedidos
CREATE TABLE IF NOT EXISTS olist_order_payments_dataset (
    order_id VARCHAR(50),
    payment_sequential INT,
    payment_type VARCHAR(50),
    payment_installments INT,
    payment_value DECIMAL(10, 2)
);

-- 5. Reviews de Pedidos
CREATE TABLE IF NOT EXISTS olist_order_reviews_dataset (
    review_id VARCHAR(50),
    order_id VARCHAR(50),
    review_score INT,
    review_comment_title TEXT,
    review_comment_message TEXT,
    review_creation_date DATETIME,
    review_answer_timestamp DATETIME
);

-- 6. Pedidos (Cabecera)
CREATE TABLE IF NOT EXISTS olist_orders_dataset (
    order_id VARCHAR(50) PRIMARY KEY,
    customer_id VARCHAR(50),
    order_status VARCHAR(20),
    order_purchase_timestamp DATETIME,
    order_approved_at DATETIME,
    order_delivered_carrier_date DATETIME,
    order_delivered_customer_date DATETIME,
    order_estimated_delivery_date DATETIME
);

-- 7. Productos
CREATE TABLE IF NOT EXISTS olist_products_dataset (
    product_id VARCHAR(50) PRIMARY KEY,
    product_category_name VARCHAR(100),
    product_name_lenght INT,
    product_description_lenght INT,
    product_photos_qty INT,
    product_weight_g INT,
    product_length_cm INT,
    product_height_cm INT,
    product_width_cm INT
);

-- 8. Vendedores
CREATE TABLE IF NOT EXISTS olist_sellers_dataset (
    seller_id VARCHAR(50) PRIMARY KEY,
    seller_zip_code_prefix INT,
    seller_city VARCHAR(100),
    seller_state CHAR(2)
);

-- 9. Traducción de categorías
CREATE TABLE IF NOT EXISTS product_category_name_translation (
    product_category_name VARCHAR(100),
    product_category_name_english VARCHAR(100)
);

/*
Una vez creadas las tablas, voy a llenarlas con los datos que he descargado
*/
-- Habilitar la carga local en la sesión
SET GLOBAL local_infile = 1;

/*=========================================================
CAMBIAR LA RUTA A LA PROPIA, PARA QUE LLEVE A LOS ARCHIVOS .CSV CORRECTAMENTE
==========================================================*/
START TRANSACTION;

-- 1. Clientes
LOAD DATA LOCAL INFILE 'C:/Users/adria/OneDrive/Escritorio/Proyectos/Modulo_SQL/olist_customers_dataset.csv'
INTO TABLE olist_customers_dataset
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- 2. Geolocalización
LOAD DATA LOCAL INFILE 'C:/Users/adria/OneDrive/Escritorio/Proyectos/Modulo_SQL/olist_geolocation_dataset.csv'
INTO TABLE olist_geolocation_dataset
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- 3. Ítems de Pedidos
LOAD DATA LOCAL INFILE 'C:/Users/adria/OneDrive/Escritorio/Proyectos/Modulo_SQL/olist_order_items_dataset.csv'
INTO TABLE olist_order_items_dataset
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- 4. Pagos
LOAD DATA LOCAL INFILE 'C:/Users/adria/OneDrive/Escritorio/Proyectos/Modulo_SQL/olist_order_payments_dataset.csv'
INTO TABLE olist_order_payments_dataset
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- 5. Reviews
LOAD DATA LOCAL INFILE 'C:/Users/adria/OneDrive/Escritorio/Proyectos/Modulo_SQL/olist_order_reviews_dataset.csv'
INTO TABLE olist_order_reviews_dataset
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- 6. Pedidos (Cabecera)
LOAD DATA LOCAL INFILE 'C:/Users/adria/OneDrive/Escritorio/Proyectos/Modulo_SQL/olist_orders_dataset.csv'
INTO TABLE olist_orders_dataset
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- 7. Productos
LOAD DATA LOCAL INFILE 'C:/Users/adria/OneDrive/Escritorio/Proyectos/Modulo_SQL/olist_products_dataset.csv'
INTO TABLE olist_products_dataset
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- 8. Vendedores
LOAD DATA LOCAL INFILE 'C:/Users/adria/OneDrive/Escritorio/Proyectos/Modulo_SQL/olist_sellers_dataset.csv'
INTO TABLE olist_sellers_dataset
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- 9. Traducción de Categorías
LOAD DATA LOCAL INFILE 'C:/Users/adria/OneDrive/Escritorio/Proyectos/Modulo_SQL/product_category_name_translation.csv'
INTO TABLE product_category_name_translation
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

COMMIT;
/*==========================================================================
Ahora crearé las tablas que usaré para hacer las consultas.
Estas serán versiones más resumidas e importantes (al menos, 
para las consultas que se harán) que las importadas.
===========================================================================*/


-- 1. Geolocalización - Dimensión
/*
Es importante crearla la primera porque se referenciará 
esta tabla tanto en Vendedores como en Compradores
*/
create table if not exists Geolocalizacion (
    zip_code_prefix INT PRIMARY KEY check (zip_code_prefix 
    between 0 and 99999),
    state char(2) not null,
    lat DECIMAL(10, 8) check (lat between -90 and 90),
    lng DECIMAL(10, 8) check (lng between -180 and 180));
/*
	PK: zip_code_prefix, define inequívocamente el código postal,
    que debe ser un número positivo y menor de 99999.
    lat y lng deben estar entre los números especificados, por definición.
*/


-- 2. Clientes - Dimensión
create table if not exists Clientes(
	customer_id varchar(100) primary key,
    customer_unique_id varchar(100) not null,
	customer_zip_code_prefix int check (customer_zip_code_prefix between 0 and 99999),
	customer_city varchar(100),
    constraint fk_cust_geo foreign key (customer_zip_code_prefix) references Geolocalizacion(zip_code_prefix));
/*
	PK: customer_id, define inequívocamente al comprador.
    - customer_zip_code_prefix, el código postal
    debe ser un número positivo y menor de 99999.
    
    FK: une Clientes con Geolocalización
    
    El customer_unique_id define realmente quién es el comprador,
    mientras que el customer_id es el que conecta con ventas (cada venta tiene
    un customer_id distinto), todo esto paraproteger la identidad del comprador.
*/


-- 3. Productos - Dimensión
create table if not exists Productos(
	product_id varchar(100) primary key,
	product_category_name varchar(100) default 'General',
	product_weight_g int check(product_weight_g>0));
/*
	PK: product_id, define inequívocamente el producto.
    product_weight_g, el peso del producto debe ser positivo.
    default 'General': por si no existe algún dato de categoría,
    no dejarlo como null.
*/


-- 4. Vendedores - Dimensión
create table if not exists Vendedores (
    seller_id varchar(100) primary key,
    seller_zip_code_prefix int check (seller_zip_code_prefix between 0 and 99999),
    seller_city varchar(100),
    constraint fk_sell_geo foreign key (seller_zip_code_prefix) references Geolocalizacion(zip_code_prefix));
/*
	PK: seller_id, define inequívocamente al vendedor.
    seller_zip_code_prefix, el código postal
    debe ser un número positivo y menor de 99999.
    FK: une Vendedores con Geolocalización
*/


-- 5. Ventas - Hechos
create table if not exists Ventas(
    order_id varchar(100),
    order_item_id int,
    customer_id varchar(100),
    product_id varchar(100),
    seller_id varchar(100),
    price decimal(10,2) not null check (price >= 0),
    freight_value decimal(10,2) check (freight_value >= 0),
    purchase_date datetime,
    primary key (order_id, order_item_id),
    constraint fk_fact_cust foreign key (customer_id) references Clientes(customer_id),
    constraint fk_fact_prod foreign key (product_id) references Productos(product_id),
    constraint fk_fact_sell foreign key (seller_id) references Vendedores(seller_id)
);
/*
	PK: order_id como principal, que identifica la compra de 
    forma inequívoca. También se usa order_item_id pues esta tabla
    se organiza por producto y no por pedido. La combinación
    order_id + order_item_id identifica inequívocamente un 
    producto dentro de una compra.
    Los precios, tanto de productos como de envío, no pueden ser negativos.
    FK: unen esta tabla con vendedores, compradores y productos.
*/

/*
Viendo la cantidad de filas que tenemos (del order de 100.000), 
sería aconsejable usar un índice.En este caso, será un índice basado
en la fecha, para las búsquedas de este tipo.
*/

create index idx_purchase_date on ventas(purchase_date);

/*
Creación de una función que devuelve la categoría de peso del 
paquete en cuestión. Evita usar constantemente CASE para clasificar
los paquetes según peso.
*/

DELIMITER //
create function rango_peso(peso_g INT) 
returns varchar(20)
deterministic
begin
    declare categoria varchar(20);
    if peso_g < 2000 then set categoria = 'Paquetería Ligera';
    elseif peso_g between 2000 and 10000 then set categoria = 'Paquetería Media';
    else set categoria = 'Paquetería Pesada';
    end if;
    return categoria;
end //
DELIMITER ;

/*
Gracias a esta función, podemos comprobar fácilmente qué tipo de
paquetes son los más rentables
*/


