/*=========================================================================
Ahora existen únicamente las tablas que hemos creado manualmente. Con ellas, podemos hacer
consultas que resulten de interés para explorar el dataset
=========================================================================*/
use proyecto_sql;
/*
Lo primero es entender los datos que tenemos entre manos. Para ello,
voy a comprobar de qué fecha a qué fecha van los datos, cuánto se ha gastado en ese tiempo, etc.
*/

-- 1. Rango de fechas
select 
max(purchase_date) as ultima_fecha,
min(purchase_date) as primera_fecha
from ventas;
-- Desde septiembre de 2016 hasta septiembre de 2018, 2 años

-- 2. Gasto total
select 
sum(price) as Gasto
from ventas;

-- 3. ¿Cuántos compradores, vendedores y compras hay?
select 
count(distinct(v.order_id)) as total_compras,
count(distinct(cl.customer_id)) as total_compradores, 
count(distinct(ve.seller_id)) as total_vendedores
from ventas v 
join clientes cl on v.customer_id=cl.customer_id
join vendedores ve on v.seller_id=ve.seller_id;

-- 4. Rango de precios
select 
max(price) as precio_maximo, 
min(price) as precio_minimo
from ventas;
-- Desde 0.85 hasta 6735

-- 5. Rango de pesos de productos
select 
max(product_weight_g) as peso_maximo,
min(product_weight_g) as peso_minimo
from productos;
/*
Entendido esto, podemos comenzar con consultas que nos den más información
sobre el dataset
*/

-- 1. Análisis de ventas por año y mes. Aquí será de utilidad el índice
select 
year(purchase_date) as anio,
month(purchase_date) as mes,
count(order_id) as numero_ventas,
round(sum(price), 2) as ingresos_mensuales
from ventas
group by anio, mes
order by anio, mes;

/*
En general, los ingresos han crecido con el paso del tiempo,
por lo que el negocio online evoluciona favorablemnete.
*/

-- 2. Precio medio por compra (incluyendo envío)
select 
round(avg(total_por_pedido), 2) as ticket_medio
from (
    select order_id, sum(price) as total_por_pedido
    from ventas
	group by order_id) as subquery;

-- 3. Top 10 vendedores con más valor de ventas
select 
    v.seller_id, 
    count(distinct(vt.order_id)) as total_pedidos,
    round(sum(vt.price), 2) as facturacion_total
from vendedores v
inner join ventas vt on v.seller_id = vt.seller_id
group by v.seller_id
order by facturacion_total desc
limit 10;

-- 4. Media de ventas por vendedor
select 
	count(distinct(vt.order_id))/count(distinct(v.seller_id)) as media
from vendedores v 
left join ventas vt on v.seller_id=vt.seller_id;

-- 5. Clasificación de productos según su volumen de ventas
select 
    p.product_category_name,
    count(v.order_id) as numero_ventas,
    case 
		when count(v.order_id) < 1000 then 'bajo'
        when count(v.order_id) > 5000 then 'alto'
        else 'normal'
    end as volumen_ventas
from ventas v
inner join productos p on v.product_id = p.product_id
group by p.product_category_name;

-- 6. Clientes más fieles
select 
    c.customer_unique_id, 
    count(distinct(v.order_id)) as total_compras,
    round(sum(v.price), 2) as gasto_total
from ventas v
join clientes c on v.customer_id = c.customer_id
group by c.customer_unique_id
having total_compras > 1
order by total_compras desc
limit 10;

-- 7. Clientes por estado
select 
    g.state as estado,
    count(distinct v.customer_id) as numero_clientes
from ventas v
inner join clientes c on v.customer_id = c.customer_id
inner join geolocalizacion g on c.customer_zip_code_prefix = g.zip_code_prefix
group by g.state;

-- 8. Ranking ventas por estado
with ventas_estado as (
    select 
        g.state,
        p.product_category_name,
        count(distinct(v.order_id)) as total
    from ventas v
    join productos p on v.product_id = p.product_id
    join clientes c on v.customer_id=c.customer_id
    join geolocalizacion g on c.customer_zip_code_prefix = g.zip_code_prefix
    group by g.state, p.product_category_name
)
select 
    state as estado,
    product_category_name as categoría,
    total,
    rank() over (partition by state order by total desc) as ranking
from ventas_estado;


-- 9. Tipos de paquetes más rentables
select 
    rango_peso(p.product_weight_g) as peso,
    sum(v.price) as ingresos_totales,
    count(v.order_id) as cantidad_pedidos,
    round(avg(v.price), 2) as precio_medio_producto,
    round(avg(v.freight_value), 2) as gasto_envio_medio,
    round((avg(v.freight_value)/ (avg(v.price)+avg(v.freight_value))) * 100, 2) as porcentaje_envio
from ventas v
join productos p on v.product_id = p.product_id
group by peso
order by cantidad_pedidos desc;

/*
En cuanto a porcentaje del precio total que se va a los gastos de envío, la paquetería
de peso medio (entre 2 y 10 kg) es la más rentable
*/

/* 
También podríamos ver, dentro de cada estado, dónde está el "centro geográfico",
para así estudiar en qué ubicación exacta sería más rentable instalar un almacén.
*/

select 
    g.state,
    round(avg(g.lat), 4) as latitud_centro_demanda,
    round(avg(g.lng), 4) as longitud_centro_demanda,
    count(v.order_id) as volumen_ventas
from ventas v
join clientes c on v.customer_id = c.customer_id
join geolocalizacion g on c.customer_zip_code_prefix = g.zip_code_prefix
group by g.state
having volumen_ventas > 100
order by volumen_ventas desc;

/*
Vamos a examinar el porcentaje de clientes que vuelve a realizar una compra
para comprobar si existe un problema de retención
*/

with compras_por_cliente as (
    select 
        c.customer_unique_id, 
        count(distinct v.order_id) as num_compras
    from ventas v
    join clientes c on v.customer_id = c.customer_id
    group by c.customer_unique_id
)
select 
    count(*) as total_clientes,
    sum(case when num_compras > 1 then 1 else 0 end) as clientes_recurrentes,
    round(
        (sum(case when num_compras > 1 then 1 else 0 end) / count(*)) * 100, 
        2
    ) as porcentaje_fidelizacion
from compras_por_cliente;

/*
También resulta de interés conocer a qué hora se realiza un mayor número
de pedidos y así estar preparados para los posibles encargos. Además, previo a esta
hora deberían enviarse promociones y recordatorios.
*/
select 
    hour(purchase_date) as hora_dia,
    count(order_id) as volumen_pedidos
from ventas
group by hora_dia
order by volumen_pedidos desc;

/*====================================================================
Creamos una vista sobre la logística por estados
====================================================================*/

create or replace view logistica_estatal as
select 
    g.state,
    count(v.order_id) as total_pedidos,
    round(avg(v.price), 2) as precio_medio,
    round(avg(v.freight_value), 2) as envio_medio,
    round((avg(v.freight_value) / (avg(v.freight_value)+avg(v.price))) * 100, 2) as coste_logistico
from ventas v
join clientes c on v.customer_id = c.customer_id
join geolocalizacion g on c.customer_zip_code_prefix = g.zip_code_prefix
group by g.state;

/*
Usando cierta información obtenida previamente, podemos considerar que el 
coste logístico promedio se encuentra entre el 13% y 14%. Usando la vista anterior,
realizaremos una consulta para comprobar en qué estados es necesario optimizar
el coste logístico y en cuales no
*/
select 
    state,
    total_pedidos,
    coste_logistico,
    case 
        when coste_logistico > 16 then 'revisar transporte'
        when coste_logistico between 13.5 and 16 then 'optimizable'
        else 'eficiente'
    end as diagnostico_logistico
from logistica_estatal
where total_pedidos > 100
order by coste_logistico desc;

/*======================================================================
Por último, la tabla final con los resultados más representativos como
resumen de la información del dataset
======================================================================*/
create or replace view analisis_final as
select 
    p.product_category_name as categoria,
    count(v.order_id) as volumen_pedidos,
    round(sum(v.price), 2) as ingresos_totales,
    rango_peso(avg(p.product_weight_g)) as perfil_logistico_medio,
    round((sum(v.freight_value) / (sum(v.freight_value)+sum(v.price))) * 100, 2) as coste_envio,
    round(avg(v.price), 2) as precio_medio
from ventas v
inner join productos p on v.product_id = p.product_id
group by p.product_category_name
having volumen_pedidos > 10 
order by ingresos_totales desc;

-- Comprobamos esta última vista
select * from analisis_final;

/*
Como resumen general de mi análisis, se obtiene que el negocio está en crecimiento, aunque 
de forma geográficamente desigual. En la región de Sao Paulo, tanto la logística (con el 
menor precio) como los ingresos son datos a destacar. Por otro lado, los productos que 
más dinero mueven son los cosméticos. Cabe destacar también la correlación entre la afluencia
de pedidos y los costes de logística, siendo los productos más pedidos los mejor optimizados.
Con toda la información obtenida, podrían hacerse varias recomendaciones:

1. CENTROS LOGÍSTICOS: Construir en regiones con mayor coste logístico, reduciendo el impacto
de este.

2. FIDELIZACIÓN: Con un porcetaje de compradores que repiten de solamente un 3%, es necesario
un programa que incentive la compra reiterada (puntos, descuentos por compras, ofertas limitadas, etc).

3. PAQUETERÍA MEDIA: Enfocarse en ella incentivando la entrada de vendedores que se ajusten a 
estos criterios o mejorar la eficiencia de los envíos de categoría ligera, principalmente, pues son
los que más ingresos generan
*/