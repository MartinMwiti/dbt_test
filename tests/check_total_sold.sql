SELECT *
FROM {{ ref('data_test') }}
WHERE Total_Sold < 0 -- This checks for negative sales numbers, which shouldn't be possible