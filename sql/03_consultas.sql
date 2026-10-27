-- Q1. ¿Cuántas ventas se realizaron por categoría de producto y mes?
SELECT p.category                     AS categoria,
       d.year_month                   AS mes,
       COUNT(*)                       AS num_ventas,
       SUM(f.sales_amount)            AS importe_ventas
FROM dw_ventas.fact_sales f
JOIN dw_ventas.dim_product p ON p.product_key = f.product_key
JOIN dw_ventas.dim_date    d ON d.date_key    = f.order_date_key
GROUP BY p.category, d.year_month
ORDER BY d.year_month, p.category;

-- Q2. ¿Cuál es el ingreso total (ventas) por cliente y género?
SELECT c.customer_id AS cliente, c.gender AS genero, SUM(f.sales_amount) AS ingreso_total
FROM dw_ventas.fact_sales f
JOIN dw_ventas.dim_customer c ON c.customer_key = f.customer_key
GROUP BY c.customer_id, c.gender
ORDER BY ingreso_total DESC;

-- Q3. ¿Cuál es la cantidad total vendida por producto?
SELECT p.product_code, p.product_name, SUM(f.quantity) AS cantidad_total
FROM dw_ventas.fact_sales f
JOIN dw_ventas.dim_product p ON p.product_key = f.product_key
GROUP BY p.product_code, p.product_name
ORDER BY cantidad_total DESC, p.product_code;

-- Q4. ¿Cuál fue la cantidad enviada por mes de envío?
SELECT d.year_month AS mes_envio, SUM(f.quantity) AS cantidad_enviada
FROM dw_ventas.fact_sales f
JOIN dw_ventas.dim_date d ON d.date_key = f.ship_date_key
GROUP BY d.year_month
ORDER BY d.year_month;

-- Q5. ¿Cuánto se vendió por tamaño de producto y por estado civil del cliente?
SELECT p.size AS tamano, c.marital_status AS estado_civil, SUM(f.sales_amount) AS total_vendido
FROM dw_ventas.fact_sales f
JOIN dw_ventas.dim_product  p ON p.product_key  = f.product_key
JOIN dw_ventas.dim_customer c ON c.customer_key = f.customer_key
GROUP BY p.size, c.marital_status
ORDER BY p.size, c.marital_status;
