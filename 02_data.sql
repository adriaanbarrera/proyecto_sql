/*===================================================================
Una vez creadas las tablas, las rellenamos con la información
de las tablas anteriormente descargadas
====================================================================*/

insert ignore into Geolocalizacion (zip_code_prefix,state, lat, lng)
select 
    geolocation_zip_code_prefix, 
    geolocation_state,
    avg(geolocation_lat), 
    avg(geolocation_lng)
from olist_geolocation_dataset
group by geolocation_zip_code_prefix, geolocation_state;
/*
	Se usan las medias de latitud y longitud como latitud y longitud
    representativas de cada código postal
*/

insert ignore into productos (product_id, product_category_name,
 product_weight_g)
select 
    product_id, 
    coalesce(product_category_name, 'General'),
    product_weight_g
from olist_products_dataset;
/*	
	Usando coalesce, me aseguro de que en lugar de null haya
    una palabra
*/

insert ignore into clientes (customer_id, customer_unique_id, customer_zip_code_prefix,
customer_city)
select 
    customer_id, 
    customer_unique_id,
    customer_zip_code_prefix,
    customer_city
from olist_customers_dataset
where customer_zip_code_prefix in (select zip_code_prefix from geolocalizacion);
/*
Me aseguro de que el código postal esté dentro de mi rango
*/

insert ignore into vendedores (seller_id, seller_zip_code_prefix,
seller_city)
select 
    seller_id, 
    seller_zip_code_prefix,
    seller_city
from olist_sellers_dataset
where seller_zip_code_prefix in (select zip_code_prefix from geolocalizacion);

/*============================================================
Para crear la tabla de ventas, iniciaré una transacción, 
asegurándome de que se crea con toda la información correctamente.
Esto es necesario para que los joins y las referencias de unas tablas a 
otras funcionen bien.
============================================================*/
start transaction;

insert into ventas (
    order_id, 
    order_item_id, 
    customer_id, 
    product_id, 
    seller_id, 
    price, 
    freight_value, 
    purchase_date
)
select 
    i.order_id,
    i.order_item_id,
    o.customer_id,
    i.product_id,
    i.seller_id,
    i.price,
    i.freight_value,
    o.order_purchase_timestamp
from olist_order_items_dataset i
join olist_orders_dataset o on i.order_id = o.order_id
join clientes c on o.customer_id = c.customer_id
join productos p on i.product_id = p.product_id
join vendedores v on i.seller_id = v.seller_id;

/*
Uso los joins como filtros para asegurar que no añado pedidos 
faltos de información y no cause errores
*/
-- comparar ventas
select 
    (select count(*) from olist_order_items_dataset) as total_csv,
    (select count(*) from ventas) as total_ventas;

-- Si todo ok
commit;
-- Si se han insertado 0 filas o hay una diferencia sustancial
-- rollback;

/*
Es normal que el número de filas sea ligeramente inferior, pues se
descartan filas incompletas
*/

/*==============================================
Ya rellenadas, podemos desechar las anteriores 
para así limpiar el dataset, no sin antes traducir los nombres
de las categorías de los productos del portugués al inglés.
===============================================*/

-- Traducción
set sql_safe_updates = 0;

update productos p
join product_category_name_translation t 
  on p.product_category_name = t.product_category_name
set p.product_category_name = t.product_category_name_english;

update productos 
set product_category_name = 'General'
where product_category_name not in (
    select product_category_name_english 
    from product_category_name_translation
);

set sql_safe_updates = 1;

-- Elimino las tablas

drop table if exists olist_customers_dataset;
drop table if exists olist_geolocation_dataset;
drop table if exists olist_order_items_dataset;
drop table if exists olist_order_payments_dataset;
drop table if exists olist_order_reviews_dataset;
drop table if exists olist_orders_dataset;
drop table if exists olist_products_dataset;
drop table if exists olist_sellers_dataset;
drop table if exists product_category_name_translation;