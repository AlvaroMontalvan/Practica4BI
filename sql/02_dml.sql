-- 5. Validación del dataset importado 
SELECT COUNT(*) AS total_registros FROM public.stg_products;
SELECT COUNT(DISTINCT product_id) AS productos_unicos FROM public.stg_products;
SELECT COUNT(DISTINCT category) AS categorias, COUNT(DISTINCT subcategory) AS subcategorias
FROM public.stg_products;

-- 6. Limpieza
UPDATE public.stg_products
SET product_name = btrim(regexp_replace(product_name, '\s+', ' ', 'g')),
    category     = btrim(category),
    subcategory  = btrim(subcategory);

-- Identificadores duplicados / nulos 
SELECT product_id, COUNT(*) FROM public.stg_products GROUP BY product_id HAVING COUNT(*) > 1;
SELECT * FROM public.stg_products WHERE product_id IS NULL OR product_id = '';

-- 7. Carga de la dimensión
INSERT INTO public.dim_product (product_id, product_name, category, subcategory)
SELECT DISTINCT product_id, product_name, category, subcategory
FROM public.stg_products
ORDER BY product_id;

SELECT COUNT(*) AS total_dim_product FROM public.dim_product;


-- Modelo estrella de ventas

-- Validaciones de staging
SELECT COUNT(*) AS filas, COUNT(DISTINCT order_number) AS pedidos,
       COUNT(DISTINCT product_code) AS productos, COUNT(DISTINCT customer_key_src) AS clientes
FROM dw_ventas.stg_ventas;
SELECT COUNT(*) AS filas_con_nulos
FROM dw_ventas.stg_ventas s
WHERE s.product_code IS NULL OR s.customer_key_src IS NULL OR s.order_date IS NULL
   OR s.ship_date IS NULL OR s.quantity IS NULL OR s.sales_amount IS NULL;
SELECT COUNT(*) AS filas_importe_incoherente        -- esperado 0
FROM dw_ventas.stg_ventas WHERE quantity * unit_price <> sales_amount;
SELECT COUNT(*) AS envios_antes_de_orden            -- esperado 0
FROM dw_ventas.stg_ventas WHERE ship_date < order_date;

-- Limpieza de texto
UPDATE dw_ventas.stg_ventas
SET product_code   = btrim(product_code),
    product_name   = btrim(regexp_replace(product_name, '\s+', ' ', 'g')),
    color          = btrim(color),
    size           = btrim(size),
    category       = btrim(category),
    subcategory    = btrim(subcategory),
    marital_status = btrim(marital_status),
    gender         = upper(btrim(gender)),
    home_owner     = btrim(home_owner),
    order_number   = btrim(order_number);

-- Carga dim_product
INSERT INTO dw_ventas.dim_product
    (product_code, source_product_key, product_name, list_price, color, size, category, subcategory)
SELECT DISTINCT product_code, product_key_src, product_name, list_price, color, size, category, subcategory
FROM dw_ventas.stg_ventas
ORDER BY product_code;

-- Carga dim_customer
INSERT INTO dw_ventas.dim_customer
    (customer_id, birth_date, marital_status, gender, income, children, home_owner, cars)
SELECT DISTINCT customer_key_src, birth_date, marital_status, gender, income, children, home_owner, cars
FROM dw_ventas.stg_ventas
ORDER BY customer_key_src;

-- Carga dim_date 
INSERT INTO dw_ventas.dim_date
    (date_key, full_date, year, quarter, month_number, month_name, year_month, day_of_month, day_name)
SELECT to_char(d, 'YYYYMMDD')::INT,
       d::DATE,
       EXTRACT(YEAR FROM d)::INT,
       EXTRACT(QUARTER FROM d)::INT,
       EXTRACT(MONTH FROM d)::INT,
       (ARRAY['Enero','Febrero','Marzo','Abril','Mayo','Junio','Julio','Agosto',
              'Septiembre','Octubre','Noviembre','Diciembre'])[EXTRACT(MONTH FROM d)::INT],
       to_char(d, 'YYYY-MM'),
       EXTRACT(DAY FROM d)::INT,
       (ARRAY['Lunes','Martes','Miércoles','Jueves','Viernes','Sábado','Domingo'])[EXTRACT(ISODOW FROM d)::INT]
FROM generate_series(
        (SELECT MIN(LEAST(order_date, ship_date)) FROM dw_ventas.stg_ventas)::timestamp,
        (SELECT MAX(GREATEST(order_date, ship_date)) FROM dw_ventas.stg_ventas)::timestamp,
        interval '1 day') AS d;

-- Carga fact_sales
INSERT INTO dw_ventas.fact_sales
    (order_number, order_line_number, product_key, customer_key, order_date_key, ship_date_key,
     quantity, unit_price, product_cost, sales_amount)
SELECT s.order_number, s.order_line_number, p.product_key, c.customer_key,
       to_char(s.order_date, 'YYYYMMDD')::INT, to_char(s.ship_date, 'YYYYMMDD')::INT,
       s.quantity, s.unit_price, s.product_cost, s.sales_amount
FROM dw_ventas.stg_ventas s
JOIN dw_ventas.dim_product  p ON p.product_code = s.product_code
JOIN dw_ventas.dim_customer c ON c.customer_id  = s.customer_key_src;

-- Comparacion staging vs. hecho 
SELECT (SELECT COUNT(*) FROM dw_ventas.stg_ventas)  AS filas_stg,
       (SELECT COUNT(*) FROM dw_ventas.fact_sales)  AS filas_fact,
       (SELECT SUM(sales_amount) FROM dw_ventas.stg_ventas) AS ventas_stg,
       (SELECT SUM(sales_amount) FROM dw_ventas.fact_sales) AS ventas_fact;
