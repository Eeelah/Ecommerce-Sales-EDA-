-- Eploratory Data Analysis on Sample super store dataset

--Business Task
--Product Analysis -- Provide insight on sales & profit performance per product
--Store location Analysis -- Analyse sales and profit performance on products across all stores
--Time series Analysis -- Explore sales and profit trends over time
--shipping service efficiency Analysis
--RFM Analysis




-- Exploring the dataset

SELECT TOP(5) *
 FROM ecommerce..sampelsales;

 SELECT TOP(5) *
 FROM ecommerce..samplelocation;

 SELECT TOP(5) *
 FROM ecommerce..sampleshipment;

 -- Converting the data objects to its appropiate types
ALTER TABLE ecommerce..sampleshipment ALTER COLUMN ShipDate DateTime
ALTER TABLE ecommerce..sampleshipment ALTER COLUMN OrderDate DateTime


--Check Inique Values
SELECT DISTINCT Category FROM ecommerce..sampelsales
SELECT DISTINCT SubCategory FROM ecommerce..sampelsales
SELECT DISTINCT ShipMode FROM ecommerce..sampleshipment
SELECT DISTINCT Region FROM ecommerce..samplelocation


SELECT TOP(5) Category AS product_category, Subcategory, 
  (SELECT SUM(Sales)) AS Totalsales
  FROM ecommerce..sampelsales                       -- calculating total sales per product category and subcategory
GROUP BY Category, SubCategory                      -- The best selling productline are phones in  technology product category 
ORDER BY Totalsales DESC


SELECT TOP(5) Category AS product_category, SubCategory,
  (SELECT SUM(Profit)) AS Totalprofit
    FROM ecommerce..sampelsales                   
GROUP BY Category, SubCategory                      -- Calculating total profit by category and subcategory
ORDER BY Totalprofit DESC                           -- The  most profitable productline are the Copiers from technology product category


; WITH sales_trend as
(
SELECT     
       OrderID,
	   Sales,                                      
	   DATEPART(yyyy, OrdeDate) AS yearly_sales
FROM ecommerce..sampelsales
GROUP BY    OrdeDate, OrderID, Sales           
                                                                     --2017 had the most sales
																	 --2015 Had the least sales
),
Revenue AS
(
SELECT
	   yearly_sales,
	   COUNT(orderID) AS sales_frequency,
	   SUM(Sales) AS Totalsales
	   FROM sales_trend
       GROUP BY  yearly_sales 
)
SELECT  *
FROM Revenue
ORDER BY Totalsales DESC


--2017 had the most sales, what month generated the most revenue
SELECT SUM(Sales) AS Totalsales, Category, SubCategory,
DATEPART(MM, OrdeDate) Monthly_sales
FROM ecommerce..sampelsales
WHERE OrdeDate BETWEEN '2017-01-11' AND '2017-12-31'   --The most revenue in 2017 were generated in march by Copiers product line.
GROUP BY  OrdeDate, Category, SubCategory
HAVING SUM(Sales) > 10000
ORDER BY Totalsales DESC


--How do we maximize sales for this high performing products? Are they profitable?
SELECT  Category, SubCategory, COUNT(orderID) AS sales_freq, DATEPART(MM, OrdeDate) AS montly_sales, DATEPART(WW, OrdeDate) AS weekly_sales,
  (SELECT SUM(Sales)) AS Totalsales,
     (SELECT SUM(Profit)) AS Totalprofit
	 FROM ecommerce..sampelsales   
	WHERE SubCategory LIKE'%Copiers%'           -- for maintaing the shop inventory and maximizing sales and profit , copiers are likely sold from March to December
GROUP BY Category, SubCategory, OrdeDate                    
ORDER BY Totalsales  DESC, Totalprofit DESC

--Sales performance by location
SELECT loc.State, loc.Region, sam.Sales 
,SUM(Sales) OVER(PARTITION by State) sales_by_region
FROM ecommerce..sampelsales AS sam
INNER JOIN ecommerce..samplelocation AS loc     --The best selling stores are those in California at the Western part of the country.
ON sam.orderID = loc.OrderID
GROUP BY loc.State, loc.Region, Sales 
ORDER BY sales_by_region DESC;
  

; WITH Shipping_elapasetime  as
(
SELECT
		ShipMode,
		OrderDate,
		ShipDate,
		AVG(DATEDIFF(DD,  OrderDate, ShipDate )) AS avg_elapse_time
FROM ecommerce..sampleshipment
GROUP BY ShipMode, OrderDate, ShipDate

),
Delivery AS                                       -- The most preferred shipping service is the standard class.
(                                                 -- To increase customer satisfaction, the elapse time(days) between order date and shipping, can be improved  since the maximun elsapse time from order to shipping is about 7 days.
	SELECT 
	ShipMode,
	COUNT(Shipmode) AS shipping_frequency,
	Avg_elapse_time
	FROM Shipping_elapasetime
	GROUP BY ShipMode, avg_elapse_time
	
)
SELECT 
  *
FROM Delivery
ORDER BY  shipping_frequency DESC, Avg_elapse_time desc

--RFM Analysis
--Recemcy
--frequency
--MonetaryValue

DROP TABLE IF EXISTS #rfm
;WITH rfm_seg as 
(
SELECT 
		CustomeName, 
		SUM(Sales) MonetaryValue,
		AVG(Sales) AvgMonetaryValue,
		COUNT(OrderID) Frequency,
		MAX(OrdeDate) last_order_date,  --Maximum orderdata of each customer
		(SELECT MAX(OrdeDate) FROM ecommerce..sampelsales) max_order_date, --over all maximum orderdate 
		DATEDIFF(DD, max(OrdeDate), (SELECt max(OrdeDate) FROM ecommerce..sampelsales)) Recency
	FROM ecommerce..sampelsales
	GROUP BY CustomeName
),
rfm_partition as 
(
    SELECT r.*,
            NTILE(4) OVER (ORDER BY Recency DESC) rfm_recency,
            NTILE(4) OVER (ORDER BY Frequency) rfm_frequency,   --Distributes rows of an ordered partion into an approximately equal number of groups or buckets
            NTILE(4) OVER (ORDER BY MonetaryValue) rfm_monetary 
        FROM rfm_seg r
)
SELECT
	c.*, CAST(rfm_recency AS varchar)+ CAST(rfm_frequency AS varchar) + CAST(rfm_monetary AS varchar)rfm_result
INTO  #rfm -- Creating temp table to view results
FROM rfm_partition c

-- Creating case statement for customer segmentation
SELECT CustomeName , rfm_recency, rfm_frequency, rfm_monetary, rfm_result,
	case 
		when rfm_result in (111, 112 ,113, 121, 122, 123,131 ,132, 211, 212, 114, 141) then 'lost_customers'  --lost customers
		when rfm_result in ( 124, 133, 134, 143, 244, 334, 343, 344, 144) then 'slipping away, but make hage purchase' -- (Big spenders who haven’t purchased lately) slipping away
		when rfm_result in (314, 324, 234, 421) then 'should be nugged to make purchase'
		when rfm_result in (311,342, 411, 331, 423) then 'new customers' --Customers who have only made a couple purchases
		when rfm_result in (222, 223, 231,232, 233, 322, 213) then 'potential churners'
		when rfm_result in (323, 333,321, 422, 332, 432, 442,342) then 'active' --(Customers who buy often & recently, but at low price points)
		when rfm_result in (433, 434, 443, 444) then 'loyal'
	end rfm_segment

FROM #rfm










 





 



  









  







