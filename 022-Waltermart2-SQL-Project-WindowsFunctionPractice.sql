USE walmart2;

/* 
"Designed and implemented advanced SQL queries using Window Functions including RANK(), DENSE_RANK(),
 ROW_NUMBER(), LAG(), LEAD(), NTILE(), and cumulative aggregations to analyze healthcare operations 
 and support strategic decision-making."
*/

-- 1. Rank all departments within each store based on their total weekly sales.
SELECT
    dept,
    SUM(weekly_sales) AS totalWeeklySales,
    RANK() OVER (
            ORDER BY SUM(weekly_sales) DESC) AS rankperDept
FROM train
GROUP BY 
    dept
ORDER BY 
    rankperDept ASC;

-- 2. Show the top 3 departments in every store according to total sales.
WITH ranking AS (
	SELECT
		store,
		dept,
		SUM(weekly_sales) AS totalSales,
		ROW_NUMBER() OVER (PARTITION BY store
					ORDER BY SUM(weekly_sales) DESC) AS rankperDept
	FROM train
	GROUP BY 
		store,
		dept
)
SELECT
	store,
    dept,
    totalSales,
    rankperDept
FROM ranking
WHERE rankperDept <= 3
ORDER BY 
	store ASC,
    rankperDept ASC;
    
-- 3. Find the bottom 5 departments in every store based on sales.
SELECT
	dept,
    SUM(weekly_sales) AS totalSales,
    ROW_NUMBER() OVER (
			ORDER BY SUM(weekly_sales) ASC) AS ranking
FROM train
GROUP BY dept
LIMIT 5;

-- 4. Calculate the cumulative weekly sales for each store over time.
WITH dailyStoreSales AS (
    SELECT
        store,
        date,
        SUM(weekly_sales) AS totalSales
    FROM train
    GROUP BY 
        store, 
        date
)
SELECT
    store,
    date,
    totalSales,
    SUM(totalSales) OVER (
        PARTITION BY date) AS cumulativeSales
FROM dailyStoreSales
ORDER BY 
    store ASC, 
    date ASC;

-- 5. Divide all stores into four performance quartiles based on total sales.
SELECT
	store,
    SUM(weekly_sales) AS totalSales,
    CASE 
		WHEN NTILE(4) OVER (ORDER BY SUM(weekly_sales))  = 1
			THEN "Low Total Sales"
		WHEN NTILE(4) OVER (ORDER BY SUM(weekly_sales))  = 2
			THEN "Medium Total Sales"
		WHEN NTILE(4) OVER (ORDER BY SUM(weekly_sales))  = 3
			THEN "High Total Sales"
		ELSE "Very High Total Sales" END AS salesLabel
FROM train
GROUP BY store
ORDER BY totalSales DESC;

-- 6. Find the department with the longest streak of increasing weekly sales.
SELECT
    store,
    dept,
    date,
    weekly_sales,
    LAG(weekly_sales) OVER (
        PARTITION BY store, dept
        ORDER BY date
    ) AS previousWeekSales
FROM train;

-- 7. Identify stores whose weekly sales are consistently above their store average.
WITH storeTotals AS (
    SELECT
        store,
        SUM(weekly_sales) AS totalSales
    FROM train
    GROUP BY store
),
averageComparison AS (
    SELECT
        store,
        totalSales,
        ROUND(AVG(totalSales) OVER(), 2) AS globalAvgTotalSales
    FROM StoreTotals
)
SELECT
    store,
    totalSales,
    globalAvgTotalSales
FROM AverageComparison
WHERE totalSales > globalAvgTotalSales
ORDER BY totalSales DESC;

-- 8. Determine the percentage contribution of each department to its store's total sales.
SELECT
    store,
    dept,
    SUM(weekly_sales) AS departmentSales,
    SUM(SUM(weekly_sales)) OVER(PARTITION BY store) AS storeTotalSales,
    ROUND(
        (SUM(weekly_sales) /
        SUM(SUM(weekly_sales)) OVER(PARTITION BY store)) * 100, 2) AS contributionPercentage
FROM train
GROUP BY 
	store, 
    dept
ORDER BY 
	store, 
    contributionPercentage DESC;
    
-- 9. Calculate an 4-week moving average for every store.
SELECT
    store,
    date,
    totalWeeklySales,
    ROUND(
        AVG(totalWeeklySales) OVER (
            PARTITION BY store
            ORDER BY date
            ROWS BETWEEN 3 PRECEDING AND CURRENT ROW),2) AS movingAvg4weeks
FROM
(
    SELECT
        store,
        date,
        SUM(weekly_sales) AS totalWeeklySales
    FROM train
    GROUP BY store, date
) AS weeklySales
ORDER BY 
	store,
    date;
    
-- 10 Identify stores whose sales fall into the top 20% every month.
WITH storeMonthlySales AS (
    SELECT
        store,
        YEAR(date) AS year_,
        MONTH(date) AS monthNum,
        SUM(weekly_sales) AS storeSales,
       PERCENT_RANK() OVER (PARTITION BY YEAR(date), MONTH(date) 
            ORDER BY SUM(weekly_sales) DESC
        ) AS salesPercentile
    FROM train
    GROUP BY store, YEAR(date), MONTH(date)
),
topStoresPerMonth AS (
    SELECT 
        store,
        year_,
        monthNum
    FROM StoreMonthlySales
    WHERE salesPercentile <= 0.20
),
totalMonths AS (
    SELECT COUNT(DISTINCT YEAR(date), MONTH(date)) AS totalMonthsCount 
    FROM train
)
SELECT 
    t.store,
    COUNT(*) AS monthsInTop20
FROM TopStoresPerMonth t
GROUP BY t.store
HAVING COUNT(*) = (SELECT totalMonthsCount FROM TotalMonths);

/* 
"Designed and implemented advanced SQL queries using Window Functions including RANK(), DENSE_RANK(),
 ROW_NUMBER(), LAG(), LEAD(), NTILE(), and cumulative aggregations to analyze healthcare operations 
 and support strategic decision-making."
*/