-- PARTE A - Staging y dimensión de producto
DROP TABLE IF EXISTS stg_products;
CREATE TABLE stg_products (
    product_id   VARCHAR(5),
    product_name VARCHAR(150),
    category     VARCHAR(80),
    subcategory  VARCHAR(80)
);

SELECT * FROM stg_products LIMIT 10;

DROP TABLE IF EXISTS dim_product;
CREATE TABLE dim_product (
    product_key  BIGSERIAL PRIMARY KEY,          
    product_id   VARCHAR(5)   NOT NULL UNIQUE,  
    product_name VARCHAR(150) NOT NULL,
    category     VARCHAR(80)  NOT NULL,
    subcategory  VARCHAR(80)  NOT NULL
);

-- PARTE B - Modelo estrella de ventas (esquema dw_ventas)
DROP SCHEMA IF EXISTS dw_ventas CASCADE;
CREATE SCHEMA dw_ventas;

CREATE TABLE dw_ventas.stg_ventas (
    product_key_src   INTEGER,
    product_code      VARCHAR(10),
    product_name      VARCHAR(100),
    list_price        NUMERIC(12,2),
    color             VARCHAR(30),
    size              VARCHAR(30),
    category          VARCHAR(50),
    subcategory       VARCHAR(50),
    customer_key_src  INTEGER,
    birth_date        DATE,
    marital_status    VARCHAR(20),
    gender            CHAR(1),
    income            NUMERIC(12,2),
    children          SMALLINT,
    home_owner        VARCHAR(3),
    cars              SMALLINT,
    order_date_key    INTEGER,
    order_date        DATE,
    ship_date_key     INTEGER,
    ship_date         DATE,
    order_number      VARCHAR(15),
    order_line_number SMALLINT,
    quantity          INTEGER,
    unit_price        NUMERIC(12,2),
    product_cost      NUMERIC(12,2),
    sales_amount      NUMERIC(14,2)
);

-- Dimensión Producto
CREATE TABLE dw_ventas.dim_product (
    product_key      BIGSERIAL PRIMARY KEY,
    product_code     VARCHAR(10)  NOT NULL UNIQUE,   
    source_product_key INTEGER    NOT NULL,          
    product_name     VARCHAR(100) NOT NULL,
    list_price       NUMERIC(12,2) NOT NULL,
    color            VARCHAR(30)  NOT NULL,
    size             VARCHAR(30)  NOT NULL,
    category         VARCHAR(50)  NOT NULL,
    subcategory      VARCHAR(50)  NOT NULL
);

-- Dimensión Cliente
CREATE TABLE dw_ventas.dim_customer (
    customer_key   BIGSERIAL PRIMARY KEY,
    customer_id    INTEGER     NOT NULL UNIQUE,      
    birth_date     DATE        NOT NULL,
    marital_status VARCHAR(20) NOT NULL,
    gender         CHAR(1)     NOT NULL,
    income         NUMERIC(12,2) NOT NULL,
    children       SMALLINT    NOT NULL,
    home_owner     VARCHAR(3)  NOT NULL,
    cars           SMALLINT    NOT NULL
);

-- Dimensión Fecha 
CREATE TABLE dw_ventas.dim_date (
    date_key     INTEGER PRIMARY KEY,                
    full_date    DATE        NOT NULL UNIQUE,
    year         SMALLINT    NOT NULL,
    quarter      SMALLINT    NOT NULL,
    month_number SMALLINT    NOT NULL,
    month_name   VARCHAR(12) NOT NULL,
    year_month   CHAR(7)     NOT NULL,               
    day_of_month SMALLINT    NOT NULL,
    day_name     VARCHAR(12) NOT NULL
);

-- Tabla de hechos
CREATE TABLE dw_ventas.fact_sales (
    order_number      VARCHAR(15)  NOT NULL,         
    order_line_number SMALLINT     NOT NULL,         
    product_key       BIGINT       NOT NULL REFERENCES dw_ventas.dim_product(product_key),
    customer_key      BIGINT       NOT NULL REFERENCES dw_ventas.dim_customer(customer_key),
    order_date_key    INTEGER      NOT NULL REFERENCES dw_ventas.dim_date(date_key),
    ship_date_key     INTEGER      NOT NULL REFERENCES dw_ventas.dim_date(date_key),
    quantity          INTEGER      NOT NULL,
    unit_price        NUMERIC(12,2) NOT NULL,
    product_cost      NUMERIC(12,2) NOT NULL,
    sales_amount      NUMERIC(14,2) NOT NULL,
    PRIMARY KEY (order_number, order_line_number)
);
