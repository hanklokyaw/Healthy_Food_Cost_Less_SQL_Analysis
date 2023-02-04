-- Query 1
-- Figure 1. One tail T- test on healthy foods and conventional foods 
-- dataset selected based on difference in Sugar Conscious, Low Sodium, Low Fat Columns 
WITH 
	-- this temp table to adjust misalign totalsize and totalsecondarysize
	Adjustment_Table AS (
		SELECT ID,
		-- regardless of the different weight of fluid 1ml is converted as 1g
		CASE WHEN (totalsize IS NULL OR totalsize = 0) AND secondarysizeunits IN ('g','gram','gr','gs','grams','ml','NULL') THEN totalsecondarysize
			 WHEN (totalsize IS NULL OR totalsize = 0) AND secondarysizeunits IN ('lb','lbs','pound','pounds') THEN totalsecondarysize * 453.6
			 WHEN secondarysizeunits IN ('lb','lbs','pound','pounds') THEN totalsecondarysize * 453.6
			 WHEN secondarysizeunits IN ('oz','ozs','ounce','ounze','ounces','ounzes') THEN totalsecondarysize * 28.35
			 WHEN (totalsize IS NULL OR totalsize = 0) AND secondarysizeunits IN ('oz','ozs','ounce','ounze','ounces','ounzes') THEN totalsecondarysize * 28.35
			 WHEN (totalsecondarysize IS NULL OR totalsecondarysize = 0) AND secondarysizeunits IN ('g','gram','gr','gs','grams','ml','NULL') THEN totalsize
			 WHEN (totalsecondarysize IS NULL OR totalsecondarysize = 0) AND secondarysizeunits IN ('lb','lbs','pound','pounds') THEN totalsize * 453.6
			 WHEN (totalsecondarysize IS NULL OR totalsecondarysize = 0) AND secondarysizeunits IN ('oz','ozs','ounce','ounze','ounces','ounzes') THEN totalsize * 28.35
			 WHEN secondarysizeunits IN ('lb','lbs','pound','pounds') THEN totalsize * 453.6
			 WHEN secondarysizeunits IN ('oz','ozs','ounce','ounze','ounces','ounzes') THEN totalsize * 28.35
			 ELSE totalsecondarysize END AS adjusted_weight
		FROM fmban_data),
    -- create temp table for healthy foods
    T5A AS (
		SELECT 	category,
				subcategory, 
				product, 
				sugarconscious, 
				lowsodium, 
				lowfat, 
				CONCAT('$ ',price) AS `price`,
				-- combine amount and unit as a column
				CONCAT(adjusted_weight , ' ',
				(CASE WHEN secondarysizeunits IN ('g','gram','gr','gs','grams', 'NULL') THEN 'g'
					 ELSE secondarysizeunits END)
				) AS `weight`,
				CONCAT('$ ',FORMAT(price/100/adjusted_weight,4)) AS `healthy_foods`
		FROM fmban_data
		LEFT JOIN Adjustment_Table
		USING (ID)
		WHERE sugarconscious = 1
		AND lowsodium = 1
		AND lowfat = 1
		AND price!= 0
		-- exclude the categories not related to helathy or conventional foods
		AND category NOT IN ('Beverages', 
							 'NULL', 
							 'Beer', 
							 'Wine',
							 'Desserts')
		AND subcategory NOT IN ('Ice Cream & frozen desserts', 
								'specialty', 
								'wellness-seasonal', 
								'sports-nutrition-weight-management', 
								'functional',
								'childrens-health',
								'vitamin-mineral')),
    -- Create temp table for conventional foods
    T5B AS (
		SELECT 	category,
				subcategory, 
				product, 
				sugarconscious, 
				lowsodium, 
				lowfat, 
				CONCAT('$ ',price) AS `price`, 
				-- combine amount and unit as a column
				CONCAT(adjusted_weight, ' ',
				(CASE WHEN secondarysizeunits IN ('g','gram','gr','gs','grams', 'NULL') THEN 'g'
				ELSE secondarysizeunits END)
				) AS `weight`,
				CONCAT('$ ',FORMAT(price/100/adjusted_weight,4)) AS `conventional_foods`
		FROM fmban_data
		LEFT JOIN Adjustment_Table
		USING (ID)
		WHERE sugarconscious = 0
		AND lowsodium = 0
		AND lowfat = 0
		AND price!= 0
		-- exlcude categories not regard as healthy or conventional foods
		AND category NOT IN ('Beverages', 
							 'NULL', 
							 'Beer', 
							 'Wine',
							 'Desserts')
		AND subcategory NOT IN ('Ice Cream & frozen desserts', 
								'specialty', 
								'wellness-seasonal', 
								'sports-nutrition-weight-management', 
								'functional',
								'childrens-health',
								'vitamin-mineral')
								),
	-- alias cannot call, so using the default table to calcualte mean
    -- calculate mean fro healthy foods
	Mean_Healthy AS (
		SELECT AVG(price/100/adjusted_weight) OVER() AS healthy_foods_mean
		FROM fmban_data
		LEFT JOIN Adjustment_Table
		USING (ID)   
		WHERE sugarconscious = 1
		AND lowsodium = 1
		AND lowfat = 1
		AND price!= 0
		-- exclude the categories not related to helathy or conventional foods
		AND category NOT IN ('Beverages', 
							 'NULL', 
							 'Beer', 
							 'Wine',
							 'Desserts')
		AND subcategory NOT IN ('Ice Cream & frozen desserts', 
								'specialty', 
								'wellness-seasonal', 
								'sports-nutrition-weight-management', 
								'functional',
								'childrens-health',
								'vitamin-mineral')),
		
-- alias cannot call, so using the default table to calcualte mean
-- calculate mean for conventional foods                            
Mean_Conventional AS (
    SELECT AVG(price/100/adjusted_weight) OVER() AS conventional_foods_mean
	FROM fmban_data
    LEFT JOIN Adjustment_Table
    USING (ID)   
    WHERE sugarconscious = 0
	AND lowsodium = 0
	AND lowfat = 0
    AND price!= 0
    -- exclude the categories not related to helathy or conventional foods
    AND category NOT IN ('Beverages', 
						 'NULL', 
						 'Beer', 
                         'Wine',
                         'Desserts')
    AND subcategory NOT IN ('Ice Cream & frozen desserts', 
							'specialty', 
							'wellness-seasonal', 
                            'sports-nutrition-weight-management', 
                            'functional',
                            'childrens-health',
                            'vitamin-mineral')),
   -- calculate variance for healthy foods                         
Variance_Healthy AS (
	SELECT VARIANCE(price/100/adjusted_weight) AS healthy_foods_variance
    FROM fmban_data
    LEFT JOIN Adjustment_Table
    USING (ID)   
    WHERE sugarconscious = 0
	AND lowsodium = 1
	AND lowfat = 1
    AND price!= 1
    -- exclude the categories not related to helathy or conventional foods
    AND category NOT IN ('Beverages', 
						 'NULL', 
						 'Beer', 
                         'Wine',
                         'Desserts')
    AND subcategory NOT IN ('Ice Cream & frozen desserts', 
							'specialty', 
							'wellness-seasonal', 
                            'sports-nutrition-weight-management', 
                            'functional',
                            'childrens-health',
                            'vitamin-mineral')),

-- calculate variance for conventional foods                            
Variance_Conventional AS (
	SELECT VARIANCE(price/100/adjusted_weight) AS conventional_foods_variance
    FROM fmban_data
    LEFT JOIN Adjustment_Table
    USING (ID)   
    WHERE sugarconscious = 0
	AND lowsodium = 0
	AND lowfat = 0
    AND price!= 0
    -- exclude the categories not related to helathy or conventional foods
    AND category NOT IN ('Beverages', 
						 'NULL', 
						 'Beer', 
                         'Wine',
                         'Desserts')
    AND subcategory NOT IN ('Ice Cream & frozen desserts', 
							'specialty', 
							'wellness-seasonal', 
                            'sports-nutrition-weight-management', 
                            'functional',
                            'childrens-health',
                            'vitamin-mineral')
),
-- Observation for healthyfoods
Observation_Healthy AS (
	SELECT COUNT(*) OVER() AS healthy_foods_observation
    FROM T5A
),
-- Observation for conventional foods
Observation_Conventional AS (
    SELECT COUNT(*) OVER() AS conventional_foods_observation
    FROM T5B
),
-- calculate standard deviation of healthy foods
StdDev_Healthy AS (
	SELECT STDDEV(price/100/adjusted_weight) AS healthy_foods_stddev
    FROM fmban_data
    LEFT JOIN Adjustment_Table
    USING (ID)   
    WHERE sugarconscious = 0
	AND lowsodium = 0
	AND lowfat = 0
    AND price!= 0
    -- exclude the categories not related to helathy or conventional foods
    AND category NOT IN ('Beverages', 
						 'NULL', 
						 'Beer', 
                         'Wine',
                         'Desserts')
    AND subcategory NOT IN ('Ice Cream & frozen desserts', 
							'specialty', 
							'wellness-seasonal', 
                            'sports-nutrition-weight-management', 
                            'functional',
                            'childrens-health',
                            'vitamin-mineral')
),
-- calculate standard deviation of conventional foods
StdDev_Conventional AS (
	SELECT STDDEV(price/100/adjusted_weight) AS conventional_foods_stddev
    FROM fmban_data
    LEFT JOIN Adjustment_Table
    USING (ID)   
    WHERE sugarconscious = 0
	AND lowsodium = 0
	AND lowfat = 0
    AND price!= 0
    -- exclude the categories not related to helathy or conventional foods
    AND category NOT IN ('Beverages', 
						 'NULL', 
						 'Beer', 
                         'Wine',
                         'Desserts')
    AND subcategory NOT IN ('Ice Cream & frozen desserts', 
							'specialty', 
							'wellness-seasonal', 
                            'sports-nutrition-weight-management', 
                            'functional',
                            'childrens-health',
                            'vitamin-mineral')
),
-- calculate degree of freedom
Degree_of_Freedom AS (
	SELECT healthy_foods_observation + conventional_foods_observation - 2 AS df
    FROM Observation_Healthy
    CROSS JOIN Observation_Conventional
    ),
-- calculate t-stat
T_test_one_tail AS (
	SELECT  (healthy_foods_mean - conventional_foods_mean)
			/
            (SQRT((POWER(healthy_foods_stddev,2) / healthy_foods_observation)
            +
            (POWER(conventional_foods_stddev,2) / conventional_foods_observation)))
            AS t_stat
	FROM Mean_Healthy
    CROSS JOIN Mean_Conventional
    CROSS JOIN StdDev_Healthy
    CROSS JOIN StdDev_Conventional
    CROSS JOIN Observation_Healthy
    CROSS JOIN Observation_Conventional
)
-- create result tables
-- insert header and line break
SELECT 'Definition of "Healthy" and "Cost"','','','','','','','',''
UNION
SELECT '','','','','','','','',''
UNION
-- table 5A begin
SELECT 'Table 5A. Healthy Foods','','','','','','','',''
UNION
SELECT 'Category','Subcategory','Product Name','Sugar Conscious','Low Sodium','Low Fat','Price/100g','Net Weight', 'Price/Gram'
UNION
SELECT 
    category,
	subcategory, 
	product, 
	sugarconscious, 
	lowsodium, 
	lowfat, 
	`price`, 
	`weight`,
    `healthy_foods`
FROM T5A 
-- table 5a end here
UNION
SELECT ' ','','','','','','','',''
UNION

-- table 5b begin
SELECT 'Table 5B. Conventional Foods','','','','','','','',''
UNION
SELECT 
    category,
	subcategory, 
	product, 
	sugarconscious, 
	lowsodium, 
	lowfat, 
	`price`, 
	`weight`,
    `conventional_foods`
FROM T5B
-- table 5b end here

-- figure 1 begin
-- perform one tail t-test using the table created above
UNION
SELECT '   ','','','','','','','',''
UNION
-- header
SELECT 'Figure 1. T-Test One tail','','','','','','','',''
UNION
-- Define Hypothesis
SELECT 'H0 : Healthy Foods - Conventional Foods >= 0','','','','','','','',''
UNION
SELECT 'HA : Healthy Foods - Conventional Foods < 0','','','','','','','',''
UNION
SELECT '   ',' ','','','','','','',''
UNION
SELECT '','Healthy Foods','Conventional Foods','','','','','',''
UNION
SELECT 'Mean',FORMAT(healthy_foods_mean,4),FORMAT(conventional_foods_mean,4),'','','','','',''
FROM Mean_Healthy
CROSS JOIN Mean_Conventional
UNION
SELECT 'Variance',FORMAT(healthy_foods_variance,4),FORMAT(conventional_foods_variance,4),'','','','','',''
FROM Variance_Healthy
CROSS JOIN Variance_Conventional
UNION
SELECT 'Observations',healthy_foods_observation,conventional_foods_observation,'','','','','',''
FROM Observation_Healthy
CROSS JOIN Observation_Conventional
UNION
-- Since there is the mean difference is 0, we will hard code 0 in the value
SELECT 'Hypothesized Mean Difference','0','','','','','','',''
UNION
SELECT 'Degree of Freedom (df)',df,'','','','','','',''
FROM Degree_of_Freedom
UNION
SELECT 't Stat',FORMAT(t_stat,4),'','','','','','',''
FROM T_test_one_tail
UNION
-- critical value for t-distribution by By Jim Frost https://statisticsbyjim.com/hypothesis-testing/t-distribution-table/
SELECT 't Critical one-tail',1.671,'','','','','','',''
UNION
SELECT 'Rejection region: < -1.671',' ','','','','','','',''
UNION
SELECT 't-Stat is more than cut-off point',' ','','','','','','',''
UNION
SELECT 'Failed to reject Null Hypothesis',' ','','','','','','',''
UNION
SELECT 'Healthy Foods >= Conventional Foods',' ','','','','','','',''
;





-- Query 2
-- Figure 2. Food Price Comparison Between Healthy Food in database with Conventional Food in database as well as USDA projected average grocery cost
WITH 
	-- this temp table to adjust misalign totalsize and totalsecondarysize
	Adjustment_Table AS (
		SELECT ID,
		-- regardless of the different weight of fluid 1ml is converted as 1g
		CASE WHEN (totalsize IS NULL OR totalsize = 0) AND secondarysizeunits IN ('g','gram','gr','gs','grams','ml','NULL') THEN totalsecondarysize
			 WHEN (totalsize IS NULL OR totalsize = 0) AND secondarysizeunits IN ('lb','lbs','pound','pounds') THEN totalsecondarysize * 453.6
			 WHEN secondarysizeunits IN ('lb','lbs','pound','pounds') THEN totalsecondarysize * 453.6
			 WHEN secondarysizeunits IN ('oz','ozs','ounce','ounze','ounces','ounzes') THEN totalsecondarysize * 28.35
			 WHEN (totalsize IS NULL OR totalsize = 0) AND secondarysizeunits IN ('oz','ozs','ounce','ounze','ounces','ounzes') THEN totalsecondarysize * 28.35
			 WHEN (totalsecondarysize IS NULL OR totalsecondarysize = 0) AND secondarysizeunits IN ('g','gram','gr','gs','grams','ml','NULL') THEN totalsize
			 WHEN (totalsecondarysize IS NULL OR totalsecondarysize = 0) AND secondarysizeunits IN ('lb','lbs','pound','pounds') THEN totalsize * 453.6
			 WHEN (totalsecondarysize IS NULL OR totalsecondarysize = 0) AND secondarysizeunits IN ('oz','ozs','ounce','ounze','ounces','ounzes') THEN totalsize * 28.35
			 WHEN secondarysizeunits IN ('lb','lbs','pound','pounds') THEN totalsize * 453.6
			 WHEN secondarysizeunits IN ('oz','ozs','ounce','ounze','ounces','ounzes') THEN totalsize * 28.35
			 ELSE totalsecondarysize END AS adjusted_weight
		FROM fmban_data),
    -- Lowest conventional foods in the database
    -- lowest vegetable in the database
	Low_Vege AS (
		SELECT 	ID AS low_vege_id, 
				product AS low_vege_product, 
                FORMAT(price/100/adjusted_weight,3) AS low_vege_per_gram, 
                FORMAT((price/100/adjusted_weight)*128,3) AS low_vege_per_meal
		FROM fmban_data
		LEFT JOIN Adjustment_Table
		USING (ID)
        -- use subquery to match the lowest price prouct then find out the ID 
        -- all subqesuence products would use similar subquery to match ID
		WHERE ID = (
				SELECT ID 
				FROM fmban_data 
				LEFT JOIN Adjustment_Table 
				USING (ID) 
				WHERE (price/100/adjusted_weight) = (
													SELECT MIN(price/100/adjusted_weight)
													FROM fmban_data 
													LEFT JOIN Adjustment_Table 
													USING (ID) 
													WHERE subcategory LIKE '%vegetables%'
													-- since banana is fruit rather than vegetable, move to next cheapest vegetable
													AND product NOT LIKE '%banana%'))),
	-- lowest fruit in the database
    Low_Fruit AS (
		SELECT ID AS low_fruit_id, product AS low_fruit_product, FORMAT(price/100/adjusted_weight,3) AS low_fruit_per_gram, FORMAT((price/100/adjusted_weight)*85,3) AS low_fruit_per_meal
		FROM fmban_data
		LEFT JOIN Adjustment_Table
		USING (ID)
		WHERE ID = (
				SELECT ID 
				FROM fmban_data 
				LEFT JOIN Adjustment_Table 
				USING (ID) 
				WHERE (price/100/adjusted_weight) = (
													SELECT MIN(price/100/adjusted_weight)
													FROM fmban_data 
													LEFT JOIN Adjustment_Table 
													USING (ID) 
													WHERE subcategory LIKE '%vegetable%'
													-- lemon is cheaper than banana but provide enough calories,
													-- move to the next chepeast thing which is banana back to the list
													-- under vegetable list rather than fruit list
													AND product NOT LIKE '%lemon%'))),
    -- lowest grain (bread) in the database
    Low_Grain AS (
		SELECT 	ID AS low_grain_id, 
				product AS low_grain_product, 
                FORMAT(price/100/adjusted_weight,3) AS low_grain_per_gram, 
                FORMAT((price/100/adjusted_weight)*341,3) AS low_grain_per_meal
		FROM fmban_data
		LEFT JOIN Adjustment_Table
		USING (ID)
		WHERE ID = (
				SELECT ID 
				FROM fmban_data 
				LEFT JOIN Adjustment_Table 
				USING (ID) 
				WHERE (price/100/adjusted_weight) = (
													SELECT MIN(price/100/adjusted_weight)
													FROM fmban_data 
													LEFT JOIN Adjustment_Table 
													USING (ID) 
													WHERE category LIKE '%bread%'
													))),
    -- lowest dairy product in the database
    Low_Dairy AS (
		SELECT  ID AS low_dairy_id, 
				product AS low_dairy_product, 
                FORMAT(price/100/adjusted_weight,3) AS low_dairy_per_gram, 
                FORMAT((price/100/adjusted_weight)*128,3) AS low_dairy_per_meal
		FROM fmban_data
		LEFT JOIN Adjustment_Table
		USING (ID)
		WHERE ID = (
				SELECT ID 
				FROM fmban_data 
				LEFT JOIN Adjustment_Table 
				USING (ID) 
				WHERE (price/100/adjusted_weight) = (
													SELECT MIN(price/100/adjusted_weight)
													FROM fmban_data 
													LEFT JOIN Adjustment_Table 
													USING (ID) 
													WHERE category LIKE '%dairy%'
													))),
	-- lowest meat product in the database
    Low_Protein AS (
		SELECT 	ID AS low_protein_id, 
				product AS low_protein_product, 
                FORMAT(price/100/adjusted_weight,3) AS low_protein_per_gram, 
                FORMAT((price/100/adjusted_weight)*61,3) AS low_protein_per_meal
		FROM fmban_data
		LEFT JOIN Adjustment_Table
		USING (ID)
		WHERE ID = (
				SELECT ID 
				FROM fmban_data 
				LEFT JOIN Adjustment_Table 
				USING (ID) 
				WHERE (price/100/adjusted_weight) = (
													SELECT MIN(price/100/adjusted_weight)
													FROM fmban_data 
													LEFT JOIN Adjustment_Table 
													USING (ID) 
													WHERE category LIKE '%meat%'
													))),
	-- Low sodium, low sugar, low fat vegetable in the database
    Health_Vege AS (
		SELECT 	ID AS health_vege_id, 
				product AS health_vege_product, 
                FORMAT(price/100/adjusted_weight,3) AS health_vege_per_gram, 
                FORMAT((price/100/adjusted_weight)*128,4) AS health_vege_per_meal
		 FROM fmban_data
		 LEFT JOIN Adjustment_Table
		 USING (ID)
		 WHERE ID = (
					SELECT ID 
                    FROM fmban_data 
                    LEFT JOIN Adjustment_Table 
					USING (ID) 
                    WHERE (price/100/adjusted_weight) = (
														SELECT MIN(price/100/adjusted_weight)
														FROM fmban_data 
                                                        LEFT JOIN Adjustment_Table 
                                                        USING (ID) 
                                                        WHERE subcategory LIKE '%vegetables%'
                                                        -- since banana is fruit rather than vegetable, move to next cheapest vegetable
                                                        AND lowfat = 1
                                                        AND lowsodium = 1
                                                        AND sugarconscious = 1))),
	-- Low sodium, low sugar, low fat fruit in the database
    Health_Fruit AS (
		SELECT 	ID AS health_fruit_id, 
				product AS health_fruit_product,
                FORMAT(price/100/adjusted_weight,3) AS health_fruit_per_gram, 
                FORMAT((price/100/adjusted_weight)*85,3) AS health_fruit_per_meal
		FROM fmban_data
		LEFT JOIN Adjustment_Table
		USING (ID)
		WHERE ID = (
				SELECT ID 
				FROM fmban_data 
				LEFT JOIN Adjustment_Table 
				USING (ID) 
				WHERE (price/100/adjusted_weight) = (
													SELECT MIN(price/100/adjusted_weight)
													FROM fmban_data 
													LEFT JOIN Adjustment_Table 
													USING (ID) 
													WHERE subcategory LIKE '%fruit%'
													-- lemon and lime are cheape but does not provide enough calories
                                                    -- remove the duplicated ones from vegetable 'floret'
                                                    AND product NOT LIKE '%lemon%'
                                                    AND product NOT LIKE '%floret%'
                                                    AND product NOT LIKE '%lime%'
													AND lowfat = 1
													AND lowsodium = 1
													AND sugarconscious = 1))),
    -- Low sodium, low sugar, low fat grain (bread) in the database
    Health_Grain AS (
		SELECT 	ID AS health_grain_id, 
				product AS health_grain_product, 
                FORMAT(price/100/adjusted_weight,3) AS health_grain_per_gram, 
                FORMAT((price/100/adjusted_weight)*341,3) AS health_grain_per_meal
		FROM fmban_data
		LEFT JOIN Adjustment_Table
		USING (ID)
		WHERE ID = (
				SELECT ID 
				FROM fmban_data 
				LEFT JOIN Adjustment_Table 
				USING (ID) 
				WHERE (price/100/adjusted_weight) = (
													SELECT MIN(price/100/adjusted_weight)
													FROM fmban_data 
													LEFT JOIN Adjustment_Table 
													USING (ID) 
													WHERE category LIKE '%bread%'
                                                    AND lowfat = 1
													AND lowsodium = 1
													AND sugarconscious = 1
													))),
    -- Low sodium, low sugar, low fat dairy in the database
    Health_Dairy AS (
		SELECT 	ID AS health_dairy_id, 
				product AS health_dairy_product, 
				FORMAT(price/100/adjusted_weight,3) AS health_dairy_per_gram, 
                FORMAT((price/100/adjusted_weight)*128,3) AS health_dairy_per_meal
		FROM fmban_data
		LEFT JOIN Adjustment_Table
		USING (ID)
		WHERE ID = (
				SELECT ID 
				FROM fmban_data 
				LEFT JOIN Adjustment_Table 
				USING (ID) 
				WHERE (price/100/adjusted_weight) = (
													SELECT MIN(price/100/adjusted_weight)
													FROM fmban_data 
													LEFT JOIN Adjustment_Table 
													USING (ID) 
													WHERE category LIKE '%dairy%'
                                                    AND lowfat = 1
													AND lowsodium = 1
													AND sugarconscious = 1
													))),
	-- Low sodium, low sugar, low fat meat product in the database
    Health_Protein AS (
		SELECT 	ID AS health_protein_id, 
				product AS health_protein_product, 
				FORMAT(price/100/adjusted_weight,3) AS health_protein_per_gram, 
				FORMAT((price/100/adjusted_weight)*61,3) AS health_protein_per_meal
		FROM fmban_data
		LEFT JOIN Adjustment_Table
		USING (ID)
		WHERE ID = (
				SELECT ID 
				FROM fmban_data 
				LEFT JOIN Adjustment_Table 
				USING (ID) 
				WHERE (price/100/adjusted_weight) = (
													SELECT MIN(price/100/adjusted_weight)
													FROM fmban_data 
													LEFT JOIN Adjustment_Table 
													USING (ID) 
													WHERE category LIKE '%meat%'
													AND lowfat = 1
													AND lowsodium = 1
													AND sugarconscious = 1
													)))
-- the following script will create a table with select and union statements.    
SELECT 'Lowest Foods From Conventional List','','',''
UNION
SELECT 'ID', 'Conventional Foods', 'Price/Gram', 'Price/Meal'
UNION
SELECT low_vege_id, low_vege_product, low_vege_per_gram, low_vege_per_meal
FROM Low_Vege
UNION
SELECT low_fruit_id, low_fruit_product, low_fruit_per_gram, low_fruit_per_meal
FROM Low_Fruit
UNION
SELECT low_grain_id, low_grain_product, low_grain_per_gram, low_grain_per_meal
FROM Low_Grain
UNION
SELECT low_dairy_id, low_dairy_product, low_dairy_per_gram, low_dairy_per_meal
FROM Low_Dairy
UNION
SELECT low_protein_id, low_protein_product, low_protein_per_gram, low_protein_per_meal
FROM Low_Protein
UNION
SELECT '','','Total',CONCAT('$ ',FORMAT(SUM(low_vege_per_meal + 
											low_fruit_per_meal + 
                                            low_grain_per_meal + 
                                            low_dairy_per_meal + 
                                            low_protein_per_meal),2))
FROM Low_Vege
CROSS JOIN Low_Fruit
CROSS JOIN Low_Grain
CROSS JOIN Low_Dairy
CROSS JOIN Low_Protein
UNION
SELECT '','','USDA Liberal Food Plan','$ 4.25'
UNION
SELECT '','','Conventional Food in database','is slightly higher than USDA rate'
UNION
SELECT '','','',''
UNION 
SELECT 'Lowest Foods From Healthy List','','',''
UNION
SELECT 'ID', 'Healthy Foods', 'Price/Gram', 'Price/Meal'
UNION
SELECT health_vege_id, health_vege_product, health_vege_per_gram, health_vege_per_meal
FROM Health_Vege
UNION
SELECT health_fruit_id, health_fruit_product, health_fruit_per_gram, health_fruit_per_meal
FROM Health_Fruit
UNION
SELECT health_grain_id, health_grain_product, health_grain_per_gram, health_grain_per_meal
FROM Health_Grain
UNION
SELECT health_dairy_id, health_dairy_product, health_dairy_per_gram, health_dairy_per_meal
FROM Health_Dairy
UNION
SELECT health_protein_id, health_protein_product, health_protein_per_gram, health_protein_per_meal
FROM Health_Protein
UNION
SELECT '','','Total',CONCAT('$ ',FORMAT(SUM(health_vege_per_meal + 
											health_fruit_per_meal + 
                                            health_grain_per_meal + 
                                            health_dairy_per_meal + 
                                            health_protein_per_meal),2))
FROM Health_Vege
CROSS JOIN Health_Fruit
CROSS JOIN Health_Grain
CROSS JOIN Health_Dairy
CROSS JOIN Health_Protein
UNION
SELECT '','','Lowest Convention Foods','$ 4.45'
UNION
SELECT '',' ','USDA Liberal Food Plan','$ 4.25'
UNION
SELECT '','','Conventional Food in database','is slightly higher than USDA rate'
UNION
SELECT '','Healthier foods cost more','not only within the database','but also with USDA price index'
UNION
SELECT '','Conclusion: Healthier foods ','cost morethan conventional ','foods'
;






-- Query 3
-- Figure 4. Meat and Meat Alternative using T-test (one tail) 
WITH 
	-- this temp table to adjust misalign totalsize and totalsecondarysize
	Adjustment_Table AS (
    SELECT ID,
    -- regardless of the different weight of fluid 1ml is converted as 1g
    CASE WHEN (totalsize IS NULL OR totalsize = 0) AND secondarysizeunits IN ('g','gram','gr','gs','grams','ml','NULL') THEN totalsecondarysize
		 WHEN (totalsize IS NULL OR totalsize = 0) AND secondarysizeunits IN ('lb','lbs','pound','pounds') THEN totalsecondarysize * 453.6
         WHEN secondarysizeunits IN ('lb','lbs','pound','pounds') THEN totalsecondarysize * 453.6
         WHEN secondarysizeunits IN ('oz','ozs','ounce','ounze','ounces','ounzes') THEN totalsecondarysize * 28.35
         WHEN (totalsize IS NULL OR totalsize = 0) AND secondarysizeunits IN ('oz','ozs','ounce','ounze','ounces','ounzes') THEN totalsecondarysize * 28.35
		 WHEN (totalsecondarysize IS NULL OR totalsecondarysize = 0) AND secondarysizeunits IN ('g','gram','gr','gs','grams','ml','NULL') THEN totalsize
         WHEN (totalsecondarysize IS NULL OR totalsecondarysize = 0) AND secondarysizeunits IN ('lb','lbs','pound','pounds') THEN totalsize * 453.6
         WHEN (totalsecondarysize IS NULL OR totalsecondarysize = 0) AND secondarysizeunits IN ('oz','ozs','ounce','ounze','ounces','ounzes') THEN totalsize * 28.35
         WHEN secondarysizeunits IN ('lb','lbs','pound','pounds') THEN totalsize * 453.6
         WHEN secondarysizeunits IN ('oz','ozs','ounce','ounze','ounces','ounzes') THEN totalsize * 28.35
		 ELSE totalsecondarysize END AS adjusted_weight
	FROM fmban_data),
	-- create temp table for meat
    T6A AS (
	SELECT 	category,
			subcategory, 
			product, 
			CONCAT('$ ',price) AS `price`,
            -- combine amount and unit as a column
			CONCAT(adjusted_weight , ' ',
			(CASE WHEN secondarysizeunits IN ('g','gram','gr','gs','grams', 'NULL') THEN 'g'
				 ELSE secondarysizeunits END)
            ) AS `weight`,
			CONCAT('$ ',FORMAT(price/100/adjusted_weight,4)) AS `meat`
	FROM fmban_data
    LEFT JOIN Adjustment_Table
    USING (ID)
	WHERE price!= 0
	AND category = 'Meat'
    AND subcategory != 'Meat Alternatives'
 -- exclude the categories not related to helathy or conventional foods
    AND category NOT IN ('Beverages', 
						 'NULL', 
						 'Beer', 
                         'Wine',
                         'Desserts')
    AND subcategory NOT IN ('Ice Cream & frozen desserts', 
							'specialty', 
							'wellness-seasonal', 
                            'sports-nutrition-weight-management', 
                            'functional',
                            'childrens-health',
                            'vitamin-mineral')),
	T6B AS (
    SELECT 	category,
			subcategory, 
			product, 
			CONCAT('$ ',price) AS `price`, 
            -- combine amount and unit as a column
			CONCAT(adjusted_weight, ' ',
			(CASE WHEN secondarysizeunits IN ('g','gram','gr','gs','grams', 'NULL') THEN 'g'
			ELSE secondarysizeunits END)
            ) AS `weight`,
			CONCAT('$ ',FORMAT(price/100/adjusted_weight,4)) AS `meat_alternative`
	FROM fmban_data
	LEFT JOIN Adjustment_Table
    USING (ID)
	WHERE price!= 0
    AND category = 'Meat'
    AND subcategory = 'Meat Alternatives'
    -- exlcude categories not regard as healthy or conventional foods
    AND category NOT IN ('Beverages', 
						 'NULL', 
						 'Beer', 
                         'Wine',
                         'Desserts')
    AND subcategory NOT IN ('Ice Cream & frozen desserts', 
							'specialty', 
							'wellness-seasonal', 
                            'sports-nutrition-weight-management', 
                            'functional',
                            'childrens-health',
                            'vitamin-mineral')
                            ),
Mean_Meat AS (
    SELECT AVG(price/100/adjusted_weight) OVER() AS meat_mean
	FROM fmban_data
    LEFT JOIN Adjustment_Table
    USING (ID)   
    WHERE price!= 0
    AND category = 'Meat'
    AND subcategory != 'Meat Alternatives'
    -- exclude the categories not related to helathy or conventional foods
    AND category NOT IN ('Beverages', 
						 'NULL', 
						 'Beer', 
                         'Wine',
                         'Desserts')
    AND subcategory NOT IN ('Ice Cream & frozen desserts', 
							'specialty', 
							'wellness-seasonal', 
                            'sports-nutrition-weight-management', 
                            'functional',
                            'childrens-health',
                            'vitamin-mineral')),
	
    -- alias cannot call, so using the default table to calcualte mean
    -- calculate mean for conventional foods                            
Mean_Meat_Alternative AS (
    SELECT AVG(price/100/adjusted_weight) OVER() AS meat_alternative_mean
	FROM fmban_data
    LEFT JOIN Adjustment_Table
    USING (ID)   
    WHERE price!= 0
    AND category = 'Meat'
    AND subcategory = 'Meat Alternatives'
    -- exclude the categories not related to helathy or conventional foods
    AND category NOT IN ('Beverages', 
						 'NULL', 
						 'Beer', 
                         'Wine',
                         'Desserts')
    AND subcategory NOT IN ('Ice Cream & frozen desserts', 
							'specialty', 
							'wellness-seasonal', 
                            'sports-nutrition-weight-management', 
                            'functional',
                            'childrens-health',
                            'vitamin-mineral')),
	Variance_Meat AS (
	SELECT VARIANCE(price/100/adjusted_weight) AS meat_variance
    FROM fmban_data
    LEFT JOIN Adjustment_Table
    USING (ID)   
    WHERE price!= 0
    AND category = 'Meat'
    AND subcategory != 'Meat Alternatives'
    -- exclude the categories not related to helathy or conventional foods
    AND category NOT IN ('Beverages', 
						 'NULL', 
						 'Beer', 
                         'Wine',
                         'Desserts')
    AND subcategory NOT IN ('Ice Cream & frozen desserts', 
							'specialty', 
							'wellness-seasonal', 
                            'sports-nutrition-weight-management', 
                            'functional',
                            'childrens-health',
                            'vitamin-mineral')),

-- calculate variance for conventional foods                            
Variance_Meat_Alternative AS (
	SELECT VARIANCE(price/100/adjusted_weight) AS meat_alternative_variance
    FROM fmban_data
    LEFT JOIN Adjustment_Table
    USING (ID)   
    WHERE price!= 0
    AND category = 'Meat'
    AND subcategory = 'Meat Alternatives'
    -- exclude the categories not related to helathy or conventional foods
    AND category NOT IN ('Beverages', 
						 'NULL', 
						 'Beer', 
                         'Wine',
                         'Desserts')
    AND subcategory NOT IN ('Ice Cream & frozen desserts', 
							'specialty', 
							'wellness-seasonal', 
                            'sports-nutrition-weight-management', 
                            'functional',
                            'childrens-health',
                            'vitamin-mineral')
),
-- Observation for healthy and conventional foods
Observation_Meat AS (
	SELECT COUNT(*) OVER() AS meat_observation
    FROM T6A
),
Observation_Meat_Alternative AS (
    SELECT COUNT(*) OVER() AS meat_alternative_observation
    FROM T6B
),
-- calculate standard deviation of healthy foods
StdDev_Meat AS (
	SELECT STDDEV(price/100/adjusted_weight) AS meat_stddev
    FROM fmban_data
    LEFT JOIN Adjustment_Table
    USING (ID)   
    WHERE price!= 0
    AND category = 'Meat'
    AND subcategory != 'Meat Alternatives'
    -- exclude the categories not related to helathy or conventional foods
    AND category NOT IN ('Beverages', 
						 'NULL', 
						 'Beer', 
                         'Wine',
                         'Desserts')
    AND subcategory NOT IN ('Ice Cream & frozen desserts', 
							'specialty', 
							'wellness-seasonal', 
                            'sports-nutrition-weight-management', 
                            'functional',
                            'childrens-health',
                            'vitamin-mineral')
),

-- calculate standard deviation of conventional foods
StdDev_Meat_Alternative AS (
	SELECT STDDEV(price/100/adjusted_weight) AS meat_alternative_stddev
    FROM fmban_data
    LEFT JOIN Adjustment_Table
    USING (ID)   
    WHERE price!= 0
    AND category = 'Meat'
    AND subcategory = 'Meat Alternatives'
    -- exclude the categories not related to helathy or conventional foods
    AND category NOT IN ('Beverages', 
						 'NULL', 
						 'Beer', 
                         'Wine',
                         'Desserts')
    AND subcategory NOT IN ('Ice Cream & frozen desserts', 
							'specialty', 
							'wellness-seasonal', 
                            'sports-nutrition-weight-management', 
                            'functional',
                            'childrens-health',
                            'vitamin-mineral')
),
-- calculate degree of freedom
Degree_of_Freedom AS (
	SELECT meat_observation + meat_alternative_observation - 2 AS df
    FROM Observation_Meat
    CROSS JOIN Observation_Meat_Alternative
    ),
    -- calculate t-stat
T_test_one_tail AS (
	SELECT  (meat_mean - meat_alternative_mean)
			/
            (SQRT((POWER(meat_stddev,2) / meat_observation)
            +
            (POWER(meat_alternative_stddev,2) / meat_alternative_observation)))
            AS t_stat
	FROM Mean_Meat
    CROSS JOIN Mean_Meat_Alternative
    CROSS JOIN StdDev_Meat
    CROSS JOIN StdDev_Meat_Alternative
    CROSS JOIN Observation_Meat
    CROSS JOIN Observation_Meat_Alternative
)



-- create result tables
-- insert header and line break
SELECT 'Definition of "Meat" and "Cost"','','','','',''
UNION
SELECT '','','','','',''
UNION
-- table 5A begin
SELECT 'Table 5A. Meat','','','','',''
UNION
SELECT 'Category','Subcategory','Product Name','Price/100g','Net Weight', 'Price/Gram'
UNION
SELECT 
    category,
	subcategory, 
	product, 
	`price`, 
	`weight`,
    `meat`
FROM T6A 
-- table 5a end here

UNION
SELECT ' ','','','','',''
UNION

-- table 5b begin
SELECT 'Table 5B. Conventional Foods','','','','',''
UNION
SELECT 
    category,
	subcategory, 
	product, 
	`price`, 
	`weight`,
    `meat_alternative`
FROM T6B
-- table 5b end here

-- figure 2 begin
-- perform one tail t-test using the table created above
UNION
SELECT '   ','','','','',''
UNION
-- header
SELECT 'Figure 2. T-Test One tail','','','','',''
UNION
-- Define Hypothesis
SELECT 'H0 : Meat - Meat Alternative <= 0','','','','',''
UNION
SELECT 'HA : Meat - Meat Alternative > 0','','','','',''
UNION
SELECT '   ',' ','','','',''
UNION
SELECT '','Meat','Meat Alternative','','',''
UNION
SELECT 'Mean',FORMAT(meat_mean,4),FORMAT(meat_alternative_mean,4),'','',''
FROM Mean_Meat
CROSS JOIN Mean_Meat_Alternative
UNION
SELECT 'Variance',FORMAT(meat_variance,4), FORMAT(meat_alternative_variance,4),'','',''
FROM Variance_Meat
CROSS JOIN Variance_Meat_Alternative
UNION
SELECT 'Observations',meat_observation,meat_alternative_observation,'','',''
FROM Observation_Meat
CROSS JOIN Observation_Meat_Alternative
UNION
-- Since there is the mean difference is 0, we will hard code 0 in the value
SELECT 'Hypothesized Mean Difference','0','','','',''
UNION
SELECT 'Degree of Freedom (df)',df,'','','',''
FROM Degree_of_Freedom
UNION
SELECT 't Stat',FORMAT(t_stat,4),'','','',''
FROM T_test_one_tail
UNION
-- critical value for t-distribution by By Jim Frost https://statisticsbyjim.com/hypothesis-testing/t-distribution-table/
SELECT 't Critical one-tail',1.684,'','','',''
UNION
SELECT 'Rejection region: > 1.684',' ','','','',''
UNION
SELECT 't-Stat is outside cut-off point',' ','','','',''
UNION
SELECT 'Reject Null Hypothesis',' ','','','',''
UNION
SELECT 'Meat >= Meat Alternatives',' ','','','',''
;





-- Query 4
-- Figure 5. Meat subcategory content, Lamb proporation
SELECT 	category,
			subcategory, 
			COUNT(*)
FROM fmban_data
WHERE category = 'Meat'
GROUP BY subcategory
;

-- Query 5
-- Figure 8. Kosher badgets product proporation
SELECT DISTINCT(
				SELECT COUNT(*)
				FROM fmban_data
				WHERE kosher =1) AS 'Number of Kosher Products',
				(
				SELECT COUNT(*)
				FROM fmban_data) AS 'Total number of Products',
                CONCAT(FORMAT((
				SELECT COUNT(*)
				FROM fmban_data
                WHERE kosher =1)/
                (
				SELECT COUNT(*)
				FROM fmban_data)
                * 100,2),' %')
                AS 'Kosher proporation'
FROM fmban_data
;