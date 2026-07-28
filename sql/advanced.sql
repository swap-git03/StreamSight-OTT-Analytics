-- ============================================================================
-- StreamSight – OTT Business Intelligence Platform
-- Phase 7: Advanced SQL Queries
-- Topics: CTEs (Common Table Expressions), Window Functions (RANK, DENSE_RANK, 
-- ROW_NUMBER, LAG, LEAD, NTILE), Running Totals
-- ============================================================================

USE streamsight_db;

-- ----------------------------------------------------------------------------
-- Query 1: Top 3 Most Watched Content Titles Per Genre using DENSE_RANK() & CTE
-- Business Purpose: Content licensing recommendation engine.
-- ----------------------------------------------------------------------------
WITH GenreContentWatch AS (
    SELECT 
        c.genre,
        c.content_id,
        c.content_title,
        c.content_type,
        SUM(w.minutes_watched) AS total_genre_minutes,
        COUNT(w.watch_id) AS total_streams,
        DENSE_RANK() OVER (
            PARTITION BY c.genre 
            ORDER BY SUM(w.minutes_watched) DESC
        ) AS genre_rank
    FROM watch_sessions w
    JOIN content c ON w.content_id = c.content_id
    GROUP BY c.genre, c.content_id, c.content_title, c.content_type
)
SELECT 
    genre,
    genre_rank,
    content_title,
    content_type,
    total_genre_minutes,
    total_streams
FROM GenreContentWatch
WHERE genre_rank <= 3
ORDER BY genre, genre_rank;

-- ----------------------------------------------------------------------------
-- Query 2: Monthly Cumulative Running Total of Watch Time using SUM() OVER()
-- Business Purpose: Measure platform infrastructure demand growth over time.
-- ----------------------------------------------------------------------------
WITH MonthlyWatch AS (
    SELECT 
        DATE_FORMAT(watch_date, '%Y-%m') AS watch_month,
        SUM(minutes_watched) AS monthly_minutes,
        ROUND(SUM(minutes_watched) / 60.0, 2) AS monthly_hours
    FROM watch_sessions
    GROUP BY DATE_FORMAT(watch_date, '%Y-%m')
)
SELECT 
    watch_month,
    monthly_hours,
    SUM(monthly_hours) OVER (
        ORDER BY watch_month 
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_running_watch_hours
FROM MonthlyWatch
ORDER BY watch_month;

-- ----------------------------------------------------------------------------
-- Query 3: Identifying Viewer Streaming Frequency Gaps using LAG()
-- Business Purpose: Churn prediction - calculate days elapsed since previous stream.
-- ----------------------------------------------------------------------------
WITH UserWatchLag AS (
    SELECT 
        user_id,
        watch_id,
        watch_date,
        LAG(watch_date, 1) OVER (
            PARTITION BY user_id 
            ORDER BY watch_date
        ) AS previous_watch_date
    FROM watch_sessions
)
SELECT 
    user_id,
    watch_id,
    watch_date,
    previous_watch_date,
    DATEDIFF(watch_date, previous_watch_date) AS days_since_last_session
FROM UserWatchLag
WHERE previous_watch_date IS NOT NULL
ORDER BY user_id, watch_date;

-- ----------------------------------------------------------------------------
-- Query 4: User Segmentation into Percentiles using NTILE(4)
-- Business Purpose: Quartile analysis of total customer engagement for targeted promotions.
-- ----------------------------------------------------------------------------
WITH UserWatchAgg AS (
    SELECT 
        u.user_id,
        u.subscription_plan,
        SUM(w.minutes_watched) AS total_user_minutes
    FROM users u
    JOIN watch_sessions w ON u.user_id = w.user_id
    GROUP BY u.user_id, u.subscription_plan
)
SELECT 
    user_id,
    subscription_plan,
    total_user_minutes,
    NTILE(4) OVER (ORDER BY total_user_minutes DESC) AS engagement_quartile
FROM UserWatchAgg
ORDER BY engagement_quartile, total_user_minutes DESC;
