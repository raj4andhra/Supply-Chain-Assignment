use supply_db ;

/*  Question: Month-wise NIKE sales

	Description:
		Find the combined month-wise sales and quantities sold for all the Nike products. 
        The months should be formatted as ‘YYYY-MM’ (for example, ‘2019-01’ for January 2019). 
        Sort the output based on the month column (from the oldest to newest). The output should have following columns :
			-Month
			-Quantities_sold
			-Sales
		HINT:
			Use orders, ordered_items, and product_info tables from the Supply chain dataset.
*/SELECT DATE_FORMAT(Order_Date,'%Y-%m') AS Month,
SUM(Quantity) AS Quantities_Sold,
SUM(Sales) AS Sales
FROM
orders AS ord
LEFT JOIN
ordered_items AS ord_itm
ON ord.Order_Id = ord_itm.Order_Id
LEFT JOIN
product_info AS prod_info
ON ord_itm.Item_Id=prod_info.Product_Id
WHERE LOWER(Product_Name) LIKE '%nike%'
GROUP BY 1
ORDER BY 1;		





-- **********************************************************************************************************************************
/*

Question : Costliest products

Description: What are the top five costliest products in the catalogue? Provide the following information/details:
-Product_Id
-Product_Name
-Category_Name
-Department_Name
-Product_Price

Sort the result in the descending order of the Product_Price.

HINT:
Use product_info, category, and department tables from the Supply chain dataset.


*/SELECT
prod_info.Product_Id,
prod_info.Product_Name,
cat.Name AS Category_Name,
dept.Name AS Department_Name,
prod_info.Product_Price
FROM
product_info AS prod_info
LEFT JOIN
category AS cat
ON prod_info.Category_Id =cat.Id
LEFT JOIN
department AS dept
ON prod_info.Department_Id=dept.Id
ORDER BY prod_info.Product_Price DESC
LIMIT 5;

-- **********************************************************************************************************************************

/*

Question : Cash customers

Description: Identify the top 10 most ordered items based on sales from all the ‘CASH’ type orders. 
Provide the Product Name, Sales, and Distinct Order count for these items. Sort the table in descending
 order of Order counts and for the cases where the order count is the same, sort based on sales (highest to
 lowest) within that group.
 
HINT: Use orders, ordered_items, and product_info tables from the Supply chain dataset.


*/SELECT pi.Product_Name, SUM(oi.Quantity) AS sales, COUNT(DISTINCT o.Order_id) AS order_count
FROM orders o
JOIN ordered_items oi ON o.Order_Id = oi.Order_Id
JOIN product_info pi ON oi.Item_Id = pi.Product_Id
WHERE o.Type = 'CASH'
GROUP BY pi.Product_Name
ORDER BY order_count DESC, sales DESC
LIMIT 10;

-- **********************************************************************************************************************************
/*
Question : Customers from texas

Obtain all the details from the Orders table (all columns) for customer orders in the state of Texas (TX),
whose street address contains the word ‘Plaza’ but not the word ‘Mountain’. The output should be sorted by the Order_Id.

HINT: Use orders and customer_info tables from the Supply chain dataset.

*/SELECT o.*
FROM orders o
JOIN customer_info c ON o.Customer_Id = c.Id
WHERE c.State = 'TX'
AND c.Street LIKE '%Plaza%'
AND c.Street NOT LIKE '%Mountain%'
ORDER BY o.Order_ID;

-- **********************************************************************************************************************************
/*
 
Question: Home office

For all the orders of the customers belonging to “Home Office” Segment and have ordered items belonging to
“Apparel” or “Outdoors” departments. Compute the total count of such orders. The final output should contain the 
following columns:
-Order_Count

*/SELECT COUNT(DISTINCT o.order_id) AS Order_Count
FROM orders o
JOIN customer_info c ON o.Customer_Id = c.Id
JOIN ordered_items oi ON o.order_id = oi.Order_Id
JOIN product_info p ON oi.Item_Id = p.Product_Id
JOIN department d ON p.Department_id = d.Id
WHERE c.Segment = 'Home Office'
AND d.Name IN ('Apparel', 'Outdoors');

-- **********************************************************************************************************************************
/*

Question : Within state ranking
 
For all the orders of the customers belonging to “Home Office” Segment and have ordered items belonging
to “Apparel” or “Outdoors” departments. Compute the count of orders for all combinations of Order_State and Order_City. 
Rank each Order_City within each Order State based on the descending order of their order count (use dense_rank). 
The states should be ordered alphabetically, and Order_Cities within each state should be ordered based on their rank. 
If there is a clash in the city ranking, in such cases, it must be ordered alphabetically based on the city name. 
The final output should contain the following columns:
-Order_State
-Order_City
-Order_Count
-City_rank

HINT: Use orders, ordered_items, product_info, customer_info, and department tables from the Supply chain dataset.

*/WITH CityOrderCounts AS (
	SELECT o.Order_State, o.Order_City, COUNT(o.Order_ID) AS Order_Count
	FROM orders o
	JOIN customer_info c ON o.Customer_ID = c.ID
	JOIN ordered_items oi ON o.Order_ID = oi.Order_ID
	JOIN product_info pi ON oi.Item_ID = pi.Product_ID
	JOIN department d ON pi.Department_ID = d.ID
	WHERE c.Segment = 'Home Office'
	AND d.Name IN ('Apparel', 'Outdoors')
	GROUP BY o.Order_State, o.Order_City
	),
	RankedCities AS (
    SELECT coc.Order_State, coc.Order_City, coc.Order_Count,
    DENSE_RANK() OVER(PARTITION BY coc.Order_State ORDER BY coc.Order_Count DESC, coc.Order_City) AS City_rank
	FROM CityOrderCounts coc
)
SELECT
    rc.Order_State,
    rc.Order_City,
    rc.Order_Count,
    rc.City_rank
FROM
    RankedCities rc
ORDER BY
    rc.Order_State,
    rc.City_rank,
    rc.Order_City;

-- **********************************************************************************************************************************
/*
Question : Underestimated orders

Rank (using row_number so that irrespective of the duplicates, so you obtain a unique ranking) the 
shipping mode for each year, based on the number of orders when the shipping days were underestimated 
(i.e., Scheduled_Shipping_Days < Real_Shipping_Days). The shipping mode with the highest orders that meet 
the required criteria should appear first. Consider only ‘COMPLETE’ and ‘CLOSED’ orders and those belonging to 
the customer segment: ‘Consumer’. The final output should contain the following columns:
-Shipping_Mode,
-Shipping_Underestimated_Order_Count,
-Shipping_Mode_Rank

HINT: Use orders and customer_info tables from the Supply chain dataset.


*/SELECT Shipping_Mode, Shipping_Underestimated_Order_Count,
DENSE_RANK() OVER (ORDER BY Shipping_Underestimated_Order_Count DESC) AS Shipping_Mode_Rank
FROM (
SELECT o.Shipping_Mode, COUNT(o.Order_Status) AS Shipping_Underestimated_Order_Count
FROM orders o
JOIN customer_info c ON o.Customer_ID = c.ID
WHERE o.Order_Status IN ('COMPLETE', 'CLOSED')
AND c.Segment = 'Consumer'
AND o.Scheduled_Shipping_Days < o.Real_Shipping_Days
GROUP BY o.Shipping_Mode
) 
ranked_shipments;


-- **********************************************************************************************************************************





