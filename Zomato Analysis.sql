CREATE DATABASE ZOMATO;
USE ZOMATO;
CREATE TABLE ZOMATO_WORLD (
    Eatery_Id INT,
    Eatery_Name VARCHAR(60),
    City VARCHAR(30),
    Country_Code INT,
    Cuisines VARCHAR(20),
    Price_Range INT,
    Average_Cost_For_Two INT,
    Online_Delivery VARCHAR(10),
    Deliverying_Available VARCHAR(10),
    Table_Booking_Available VARCHAR(10),
    Aggregate_Rating FLOAT,
    Rating_Text VARCHAR(20),
    Votes INT,
    Currency VARCHAR(10)
);
DESCRIBE ZOMATO_WORLD;

select * 
from zomato_world;

set sql_safe_updates = 0;


UPDATE ZOMATO_WORLD
SET Online_Delivery = CASE 
	WHEN Online_Delivery = 1 THEN 'Yes'
    WHEN Online_Delivery = 0 THEN 'No'
End;

UPDATE ZOMATO_WORLD
SET Deliverying_Available = CASE 
	WHEN Deliverying_Available = 1 THEN 'Yes'
    WHEN Deliverying_Available = 0 THEN 'No'
End;

UPDATE ZOMATO_WORLD
SET Table_Booking_Available = CASE 
	WHEN Table_Booking_Available = 1 THEN 'Yes'
    WHEN Table_Booking_Available = 0 THEN 'No'
End;

CREATE INDEX idx_city on Zomato_World(City);
CREATE INDEX idx_online_delivery ON ZOMATO_WORLD (Online_Delivery);
CREATE INDEX idx_table_booking ON ZOMATO_WORLD (Table_Booking_Available);
CREATE INDEX idx_price_range ON ZOMATO_WORLD (Price_Range);
CREATE INDEX idx_aggregate_rating ON ZOMATO_WORLD (Aggregate_Rating);
CREATE INDEX idx_votes ON ZOMATO_WORLD (Votes);
CREATE INDEX idx_city_delivery ON ZOMATO_WORLD (City, Online_Delivery);
CREATE INDEX idx_city_price ON ZOMATO_WORLD (City, Price_Range);
CREATE INDEX idx_cuisines_rating ON ZOMATO_WORLD (Cuisines, Aggregate_Rating);
CREATE INDEX idx_country_code on Country(Country_Code);

ALTER TABLE ZOMATO_WORLD 
ADD PRIMARY KEY(Eatery_Id, Cuisines);

-- CHECKING FOR DUPLICATES
SELECT EATERY_ID,CUISINES, COUNT(*) AS DUPLICATE_COUNT
FROM ZOMATO_WORLD
GROUP BY EATERY_ID,CUISINES
HAVING COUNT(*) > 1;

-- FINDING TOTAL NO OF DUPLICATES
SELECT SUM(DUPLICATE_COUNT-1) AS TOTAL_DUPLICATES
FROM(
SELECT EATERY_ID,CUISINES, COUNT(*) AS DUPLICATE_COUNT
FROM ZOMATO_WORLD
GROUP BY EATERY_ID,CUISINES
HAVING COUNT(*) > 1) AS DUPLICATE_GROUPS;

-- REMOVING DUPLICATES 
WITH RANKED_EATERIES AS (
SELECT EATERY_ID,CUISINES,
ROW_NUMBER() OVER(PARTITION BY EATERY_ID, CUISINES ORDER BY EATERY_ID) AS ROW_NUM
FROM ZOMATO_WORLD)
DELETE FROM ZOMATO_WORLD
WHERE (EATERY_ID,CUISINES) IN(SELECT EATERY_ID,CUISINES 
FROM RANKED_EATERIES 
WHERE ROW_NUM > 1);

SELECT DISTINCT CURRENCY 
FROM ZOMATO_WORLD;

-- TOTAL NO OF EATERY AVAILABLE
SELECT COUNT(DISTINCT EATERY_ID) AS NO_OF_EATERIES
FROM ZOMATO_WORLD;

-- How many EATERIES are there in each COUNTRY?
SELECT C.COUNTRY_NAME, COUNT(DISTINCT Z.EATERY_ID)AS NO_OF_EATERIES
FROM ZOMATO_WORLD Z INNER JOIN COUNTRY C ON Z.COUNTRY_CODE = C.COUNTRY_CODE
GROUP BY C.COUNTRY_NAME
ORDER BY NO_OF_EATERIES DESC;


-- How many restaurants are there in each city OF INDIA?
SELECT Z.CITY , COUNT(DISTINCT Z.EATERY_ID)AS NO_OF_EATERIES
FROM ZOMATO_WORLD Z INNER JOIN COUNTRY C ON Z.COUNTRY_CODE = C.COUNTRY_CODE
WHERE C.COUNTRY_NAME = 'India'
GROUP BY Z.CITY
ORDER BY NO_OF_EATERIES DESC;

-- How many restaurants offer online delivery across different countries?
SELECT COUNTRY_NAME , COUNT(DISTINCT Z.EATERY_ID)AS NO_OF_EATERIES
FROM ZOMATO_WORLD Z INNER JOIN COUNTRY C ON Z.COUNTRY_CODE = C.COUNTRY_CODE
WHERE Z.ONLINE_DELIVERY = 'YES'
GROUP BY C.COUNTRY_NAME
ORDER BY NO_OF_EATERIES DESC;

-- How many restaurants does not offer online delivery across different countries?
SELECT C.COUNTRY_NAME , COUNT(DISTINCT Z.EATERY_ID)AS NO_OF_EATERIES
FROM ZOMATO_WORLD Z INNER JOIN COUNTRY C ON Z.COUNTRY_CODE = C.COUNTRY_CODE
WHERE Z.ONLINE_DELIVERY = 'NO'
GROUP BY C.COUNTRY_NAME
ORDER BY NO_OF_EATERIES DESC;

-- How many restaurants provide table booking across different countries?
SELECT C.COUNTRY_NAME, COUNT(DISTINCT Z.EATERY_ID) AS Total_Eateries_With_Booking
FROM ZOMATO_WORLD Z INNER JOIN COUNTRY C ON Z.COUNTRY_CODE = C.COUNTRY_CODE
WHERE Z.Table_Booking_Available = 'Yes'
GROUP BY C.COUNTRY_NAME
ORDER BY Total_Eateries_With_Booking DESC;

SELECT C.COUNTRY_NAME , COUNT(DISTINCT Z.EATERY_ID) AS Total_Eateries_Without_Booking
FROM ZOMATO_WORLD Z INNER JOIN COUNTRY C ON Z.COUNTRY_CODE = C.COUNTRY_CODE
WHERE Z.Table_Booking_Available = 'NO'
GROUP BY C.COUNTRY_NAME
ORDER BY Total_Eateries_Without_Booking DESC;

-- What is the average rating of restaurants in each city IN INDIA?
SELECT Z.CITY , ROUND(AVG(Z.Aggregate_Rating),2) AS AVERAGE_RATING
FROM ZOMATO_WORLD Z INNER JOIN COUNTRY C ON Z.COUNTRY_CODE = C.COUNTRY_CODE
WHERE C.COUNTRY_NAME IN( 'INDIA')
GROUP BY Z.CITY
ORDER BY AVERAGE_RATING DESC;

-- Which restaurants have received the highest number of votes (customer engagement)?
SELECT DISTINCT EATERY_NAME , VOTES 
FROM ZOMATO_WORLD 
ORDER BY VOTES DESC
LIMIT 10;

-- Which restaurants have received the LOWEST number of votes (customer engagement)?
SELECT DISTINCT EATERY_NAME , VOTES 
FROM ZOMATO_WORLD 
ORDER BY VOTES ASC
LIMIT 10;

-- What are the top cuisines by rating and price range?
SELECT 
    Cuisines, 
    CASE 
        WHEN Price_Range = 1 THEN 'LOW'
        WHEN Price_Range = 2 THEN 'MEDIUM'
        WHEN Price_Range = 3 THEN 'HIGH'
        WHEN Price_Range = 4 THEN 'PREMIUM'
    END AS Price_Category,
    AVG(Aggregate_Rating) AS Avg_Rating
FROM 
    ZOMATO_WORLD
GROUP BY 
    Cuisines, Price_Range
HAVING 
    AVG(Aggregate_Rating) IS NOT NULL
ORDER BY 
    Price_Category DESC, Avg_Rating DESC
LIMIT 10;

-- How does customer engagement (votes) vary across different cities?
SELECT 
    City,
    COUNT(Eatery_Id) AS Total_Restaurants,
    SUM(Votes) AS Total_Votes,
    AVG(Votes) AS Average_Votes_Per_Restaurant
FROM 
    zomato_world
GROUP BY 
    City
ORDER BY 
    Total_Votes DESC;

-- What is the average rating, total votes, and average cost for each country?
SELECT C.COUNTRY_NAME , AVG(Z.Aggregate_Rating) AS AVERAGE_RATTINGS, SUM(Z.VOTES) AS TOTAL_VOTES , Z.CURRENCY,AVG(Average_Cost_For_Two) AS AVERAGE_COST_FOR_TWO_PEOPLE
FROM COUNTRY C INNER JOIN ZOMATO_WORLD Z ON C.COUNTRY_CODE = Z.COUNTRY_CODE
GROUP BY C.COUNTRY_NAME, Z.CURRENCY;

-- Which cuisine types receive the best ratings on average?
SELECT DISTINCT CUISINES , AVG(Aggregate_Rating) AS AVERAGE_RATTING
FROM ZOMATO_WORLD
GROUP BY CUISINES
ORDER BY AVERAGE_RATTING DESC
LIMIT 10 ;

-- Which restaurants have a rating higher than the average rating of their country?
WITH AverageRatingIndia AS (
    SELECT Z1.COUNTRY_CODE, AVG(Z1.Aggregate_Rating) AS Average_Rating
    FROM ZOMATO_WORLD Z1
    WHERE Z1.COUNTRY_CODE = (SELECT COUNTRY_CODE FROM COUNTRY WHERE COUNTRY_NAME = 'INDIA')
    GROUP BY Z1.COUNTRY_CODE
)
SELECT DISTINCT C.COUNTRY_NAME, Z.EATERY_NAME, Z.Aggregate_Rating
FROM COUNTRY C
INNER JOIN ZOMATO_WORLD Z ON C.COUNTRY_CODE = Z.COUNTRY_CODE
INNER JOIN AverageRatingIndia A ON A.COUNTRY_CODE = Z.COUNTRY_CODE
WHERE Z.Aggregate_Rating > A.Average_Rating
  AND C.COUNTRY_NAME = 'INDIA';

-- Rank the restaurants in each city by votes and average cost for two.
WITH IndiaRestaurants AS (
    SELECT DISTINCT Z.City,Z.EATERY_NAME, Z.Votes, Z.Average_Cost_For_Two, C.COUNTRY_NAME
    FROM ZOMATO_WORLD Z
    INNER JOIN COUNTRY C ON Z.COUNTRY_CODE = C.COUNTRY_CODE
    WHERE C.COUNTRY_NAME = 'India'
)
SELECT
    DISTINCT City,
    EATERY_NAME,
    Votes,
    Average_Cost_For_Two,
    ROW_NUMBER() OVER (PARTITION BY City ORDER BY Votes DESC, Average_Cost_For_Two DESC) AS Rank_By_Votes_Cost
FROM IndiaRestaurants;


 -- Which two cities of each country have the most expensive restaurants (based on average cost for two)?
 WITH RankedCountries AS (
    SELECT
        C.COUNTRY_NAME,
        Z.City,
        Z.EATERY_NAME,Z.CURRENCY,
        Z.Average_Cost_For_Two,
        ROW_NUMBER() OVER (PARTITION BY C.COUNTRY_NAME ORDER BY Z.Average_Cost_For_Two DESC) AS Cost_Rank
    FROM ZOMATO_WORLD Z
    INNER JOIN COUNTRY C ON Z.COUNTRY_CODE = C.COUNTRY_CODE
)
SELECT COUNTRY_NAME, City, EATERY_NAME, CURRENCY ,Average_Cost_For_Two
FROM RankedCountries
WHERE Cost_Rank = 1
ORDER BY COUNTRY_NAME;

SELECT COUNT(distinct eatery_id) AS Italian_Restaurant_Count
FROM ZOMATO_WORLD
WHERE Cuisines LIKE '%Italian%';

-- top 10 eatery_name with good rating text
select distinct eatery_name , Aggregate_Rating , Rating_text
from zomato_world 
where rating_text = 'Excellent'
order by Aggregate_Rating desc
limit 10;

WITH CuisineCounts AS (
    SELECT 
        C.COUNTRY_NAME,
         Cuisines,  -- Get the first cuisine listed if multiple exist
        COUNT(*) AS Cuisine_Occurrence
    FROM ZOMATO_WORLD Z
    INNER JOIN COUNTRY C ON Z.COUNTRY_CODE = C.COUNTRY_CODE
    GROUP BY C.COUNTRY_NAME, Cuisines
),
RankedCuisines AS (
    SELECT 
        COUNTRY_NAME,
        Cuisines,
        Cuisine_Occurrence,
        ROW_NUMBER() OVER (PARTITION BY COUNTRY_NAME ORDER BY Cuisine_Occurrence DESC) AS Ranks
    FROM CuisineCounts
)
SELECT COUNTRY_NAME, Cuisines, Cuisine_Occurrence
FROM RankedCuisines
WHERE Ranks = 1
ORDER BY COUNTRY_NAME;

-- how can you retrieve a list of restaurants 
-- that offer a specified cuisine type and have an aggregate rating above a certain threshold in a given country?
DELIMITER //

CREATE PROCEDURE GetRestaurantsByCuisineAndRating(
    IN selectedCuisine VARCHAR(20),
    IN minRating FLOAT,
    IN countryName VARCHAR(30)  -- Changed from countryCode to countryName
)
BEGIN
    -- Select restaurants based on the provided cuisine, minimum rating, and country name
    SELECT 
        Z.Eatery_Name, 
        Z.Aggregate_Rating, 
        Z.City 
    FROM ZOMATO_WORLD Z
    INNER JOIN COUNTRY C ON Z.Country_Code = C.Country_Code
    WHERE Z.Cuisines = selectedCuisine 
      AND Z.Aggregate_Rating >= minRating
      AND C.Country_Name = countryName;  -- Filter by country name

END //

DELIMITER ;

CALL GetRestaurantsByCuisineAndRating('ITALIAN', 4.0, 'INDIA');
