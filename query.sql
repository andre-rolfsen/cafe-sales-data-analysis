
create table cafe_sales_staging like dirty_cafe_sales;

insert cafe_sales_staging
select *
from dirty_cafe_sales;

-- checando duplicatas

WITH duplicates_cte AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY transaction_id
            ORDER BY transaction_id
        ) AS row_num
    FROM cafe_sales_staging
)
select * FROM duplicates_cte WHERE row_num > 1;

create table cafe_sales_staging2 like cafe_sales_staging;

insert cafe_sales_staging2
select *
from cafe_sales_staging;

-- tratando erros e unknown como null
UPDATE cafe_sales_staging
SET transaction_id = NULL
WHERE transaction_id IN ('ERROR', 'UNKNOWN', '');

select distinct transaction_id from cafe_sales_staging;

UPDATE cafe_sales_staging
SET item = NULL
WHERE item IN ('ERROR', 'UNKNOWN', '');

select distinct item from cafe_sales_staging;

UPDATE cafe_sales_staging
SET quantity = NULL
WHERE quantity IN ('ERROR', 'UNKNOWN', '');


select distinct quantity from cafe_sales_staging;

UPDATE cafe_sales_staging
SET total_spent = NULL
WHERE total_spent IN ('ERROR', 'UNKNOWN', '');

select distinct total_spent from cafe_sales_staging;

UPDATE cafe_sales_staging
SET payment_method = NULL
WHERE payment_method IN ('ERROR', 'UNKNOWN', '');

select distinct payment_method from cafe_sales_staging;

UPDATE cafe_sales_staging
SET location = NULL
WHERE location IN ('ERROR', 'UNKNOWN', '');

select distinct location from cafe_sales_staging;

select distinct transaction_date from cafe_sales_staging;

UPDATE cafe_sales_staging
SET price_per_unit = NULL
WHERE price_per_unit IN ('ERROR', 'UNKNOWN', '');

select distinct price_per_unit from cafe_sales_staging;

UPDATE cafe_sales_staging
SET transaction_date = NULL
WHERE transaction_date IN ('ERROR', 'UNKNOWN', '');

select distinct transaction_date from cafe_sales_staging;

create table prices(
    item text null ,
    price text null
);

insert into prices SELECT item,
                    price_per_unit AS price

             FROM cafe_sales_staging
             WHERE price_per_unit IS NOT NULL
               AND item IS NOT NULL
             GROUP BY item, price_per_unit;

select * from prices;

-- deleta precos iguais, para fazer um preenchimento nao-ambiguo
DELETE FROM prices
WHERE price IN (
    SELECT price
    FROM (
        SELECT price
        FROM prices
        GROUP BY price
        HAVING COUNT(*) > 1
    ) AS cte
);

-- preenchendo price_per_unit com total_spend/quantity

update cafe_sales_staging
set price_per_unit = total_spent/quantity
where quantity is not null
and total_spent is not null
and price_per_unit is null;

-- preenchendo item com valores que tem price_per_unity

UPDATE cafe_sales_staging c
JOIN prices p ON c.price_per_unit = p.price
SET c.item = p.item
WHERE c.item IS NULL;

-- preenchendo price_per_unity com valores que tem o item
UPDATE cafe_sales_staging c
JOIN prices p ON c.item = p.item
SET c.price_per_unit = p.price
WHERE c.price_per_unit IS NULL;

-- preenchendo total_spent com price_per_unity * quantity

update cafe_sales_staging
set total_spent = price_per_unit * quantity
where quantity is not null
and price_per_unit is not null
and total_spent is null;

-- preenchendo quantity com price_per_unity/total_spent

update cafe_sales_staging
set quantity = total_spent / price_per_unit
where total_spent is not null
and price_per_unit is not null
and quantity is null;

-- analise exploratoria

-- periodo de analise
select min(transaction_date) as start,
       max(transaction_date) as end
from cafe_sales_staging;

-- ganhos diarios

with daily_recipe as (
    select
        sum(total_spent) as recipe,
        DATEDIFF( MAX(transaction_date), MIN(transaction_date)) AS time_period
    from cafe_sales_staging
) SELECT
    recipe,
    time_period,
    recipe / NULLIF(time_period * 1.0, 0) AS recipe_per_day
FROM daily_recipe;

WITH error_data AS (
    SELECT COUNT(*) AS total_error_rows
    FROM cafe_sales_staging2
    WHERE transaction_id = 'ERROR'
       OR item = 'ERROR'
       OR quantity = 'ERROR'
       OR price_per_unit = 'ERROR'
       OR total_spent = 'ERROR'
       OR payment_method = 'ERROR'
       OR location = 'ERROR'
       OR transaction_date = 'ERROR'
),
null_data AS (
    SELECT
        (SELECT total_error_rows FROM error_data) AS errors,
        COUNT(CASE WHEN transaction_id IS NULL
                     OR item IS NULL
                     OR quantity IS NULL
                     OR price_per_unit IS NULL
                     OR total_spent IS NULL
                     OR payment_method IS NULL
                     OR location IS NULL
                     OR transaction_date IS NULL THEN 1 END) AS missing,
        COUNT(*) AS blank_data
    FROM cafe_sales_staging
)
SELECT
    errors,
    IF(blank_data = 0, 0, (errors / blank_data)) AS error_percentage,
    missing,
    IF(blank_data = 0, 0, (missing / blank_data)) AS missing_percentage
FROM null_data;

-- ganhos mensais

SELECT
    MONTH(transaction_date) AS month,
    SUM(total_spent) AS recipe
FROM cafe_sales_staging
group by month
order by month;

-- ganhos por produto

select item, sum(total_spent) as recipe
from cafe_sales_staging
group by item
order by recipe desc;

-- ganhos por local

select location, sum(total_spent) as recipe
from cafe_sales_staging
group by location
order by recipe desc;