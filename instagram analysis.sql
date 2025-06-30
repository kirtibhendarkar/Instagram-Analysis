-- 1. How many unique post types are found in the 'fact_content' table

	SELECT COUNT(DISTINCT `post_type`) AS unique_post_types
	FROM fact_content;

-- 2. What are the highest and lowest recorded impressions for each post type?

	SELECT 
		`post_type`,
		MAX(impressions) AS highest_impressions,
		MIN(impressions) AS lowest_impressions
	FROM 
		fact_content
	GROUP BY 
		`post_type`;
    
-- 3.Filter all the posts that were published on a weekend in the month of March and April and export them to a separate csv file.

	SELECT fc.*
	FROM fact_content fc
	JOIN dim_dates dd ON fc.Date = dd.Date
	WHERE dd.`weekday_or_weekend` = 'Weekend'
	  AND dd.`month_name` IN ('March', 'April');
      
-- 4. Create a report to get the statistics for the account. The final output includes the following fields:• month_name, • total_profile_visits,• total_new_followers
	
	SELECT 
		dd.`month_name` AS month_name,
		SUM(fa.`profile_visits`) AS total_profile_visits,
		SUM(fa.`new_followers`) AS total_new_followers
	FROM 
		fact_account fa
	JOIN 
		dim_dates dd ON fa.Date = dd.Date
	GROUP BY 
		dd.`month_name`;
        
-- 5. Write a CTE that calculates the total number of 'likes’ for each 'post_category' during the month of 'July' and subsequently, arrange the 'post_category' values in descending order according to their total likes.

	WITH category_likes_in_july AS (
    SELECT 
        fc.`post_category` AS post_category,
        SUM(fc.likes) AS total_likes
    FROM 
        fact_content fc
    JOIN 
        dim_dates dd ON fc.Date = dd.Date
    WHERE 
        dd.`month_name` = 'July'
    GROUP BY 
        fc.`post_category`
	)

	SELECT * 
	FROM category_likes_in_july
	ORDER BY total_likes DESC;
    
-- 6. Create a report that displays the unique post_category names alongside their respective counts for each month. The output should have three columns:•month_name •post_category_names •post_category_count

	SELECT 
    dd.`month_name` AS month_name,
    GROUP_CONCAT(DISTINCT fc.`post_category` ORDER BY fc.`post_category`) AS post_category_names,
    COUNT(fc.`post_category`) AS post_category_count
	FROM 
		fact_content fc
	JOIN 
		dim_dates dd ON fc.Date = dd.Date
	GROUP BY 
		dd.`month_name`;
        
-- 7. What is the percentage breakdown of total reach by post type? The final output includes the following fields: • post_type • total_reach • reach_percentage

	WITH reach_by_post_type AS (
    SELECT 
        `post_type` AS post_type,
        SUM(reach) AS total_reach
    FROM 
        fact_content
    GROUP BY 
        `post_type`
	),
	total_reach_all AS (
		SELECT SUM(reach) AS grand_total_reach
		FROM fact_content
	)

	SELECT 
		r.post_type,
		r.total_reach,
		ROUND((r.total_reach / t.grand_total_reach) * 100, 2) AS reach_percentage
	FROM 
		reach_by_post_type r, total_reach_all t
	ORDER BY 
		reach_percentage DESC;
        
-- 8. Create a report that includes the quarter, total comments, and total saves recorded for each post category. Assign the following quarter groupings:

	SELECT 
		fc.`post_category` AS post_category,
		CASE dd.`month_name`
			WHEN 'January' THEN 'Q1'
			WHEN 'February' THEN 'Q1'
			WHEN 'March' THEN 'Q1'
			WHEN 'April' THEN 'Q2'
			WHEN 'May' THEN 'Q2'
			WHEN 'June' THEN 'Q2'
			WHEN 'July' THEN 'Q3'
			WHEN 'August' THEN 'Q3'
			WHEN 'September' THEN 'Q3'
			ELSE 'Other'
		END AS quarter,
		SUM(fc.comments) AS total_comments,
		SUM(fc.saves) AS total_saves
	FROM 
		fact_content fc
	JOIN 
		dim_dates dd ON fc.Date = dd.Date
	GROUP BY 
		post_category, quarter
	ORDER BY 
		quarter, post_category;
        
-- 9. List the top three dates in each month with the highest number of new followers. The final output should include the following columns:• month • date • new_followers

	WITH ranked_followers AS (
		SELECT 
			dd.`month_name` AS month,
			fa.Date,
			fa.`new_followers` AS new_followers,
			RANK() OVER (PARTITION BY dd.`month_name` ORDER BY fa.`new_followers` DESC) AS rank_in_month
		FROM 
			fact_account fa
		JOIN 
			dim_dates dd ON fa.Date = dd.Date
	)

	SELECT 
		month,
		Date,
		new_followers
	FROM 
		ranked_followers
	WHERE 
		rank_in_month <= 3
	ORDER BY 
		FIELD(month, 'January', 'February', 'March', 'April', 'May', 'June',
					 'July', 'August', 'September', 'October', 'November', 'December'),
		rank_in_month,
		Date;
        
-- 10. Create a stored procedure that takes the 'Week_no' as input and generates a report displaying the total shares for each 'Post_type'. The output of the procedure should consist of two columns: • post_type • total_shares

	CREATE DEFINER=`root`@`localhost` PROCEDURE `GetSharesByPostTypeForWeek`(IN input_week_no varchar(5))
    BEGIN
    SELECT 
        fc.`post_type` AS post_type,
        SUM(fc.shares) AS total_shares
    FROM 
        fact_content fc
    JOIN 
        dim_dates dd ON fc.Date = dd.Date
    WHERE 
        dd.`week_no` = input_week_no
    GROUP BY 
        fc.`post_type`
    ORDER BY 
        total_shares DESC;
    END