-- This configuration sets the materialization of the model to a table and specifies the schema name.
{{ config(materialized='table',schema = 'Mmwiti')}}

-- CTE to count the number of facilities per city and country.
WITH facility_count AS (
    SELECT
        CITY,
        COUNTRY,
        COUNT(FACILITY_ID) AS total_facilities
    FROM {{source('RAW_DATA','SALES_DATA')}}
    GROUP BY CITY, COUNTRY
),
-- CTE to filter sales data for cities with more than 3 facilities and sales within the last year.
filtered_sales AS (
    SELECT
        s.COUNTRY,
        s.API_SOLD_PRODUCT AS Product_Name,
        s.QUANTITY_SOLD AS Total_Sold,
        s.UNIT_PRICE,
        s.SOLD_PRODUCT_CREATED_AT
    FROM {{source('RAW_DATA','SALES_DATA')}} s
    INNER JOIN facility_count f
    ON s.CITY = f.CITY AND s.COUNTRY = f.COUNTRY
    WHERE f.total_facilities > 3 AND SOLD_PRODUCT_CREATED_AT >= DATEADD(YEAR, -1, CURRENT_DATE())
),
-- CTE to aggregate sales data by country and product, calculating total sold, average price, and sale dates.
aggregated_sales AS (
    SELECT
        COUNTRY,
        Product_Name,
        SUM(Total_Sold) AS Total_Sold,
        AVG(UNIT_PRICE) AS Average_Price,
        MIN(SOLD_PRODUCT_CREATED_AT) AS First_Sale,
        MAX(SOLD_PRODUCT_CREATED_AT) AS Most_Recent_Sale
    FROM filtered_sales
    GROUP BY COUNTRY, Product_Name
)
-- Final selection from the aggregated sales data.
SELECT
    *
FROM aggregated_sales
