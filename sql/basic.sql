-- ============================================================================
-- StreamSight – OTT Business Intelligence Platform
-- Phase 7: Basic SQL Queries
-- Topics: SELECT, WHERE, ORDER BY, GROUP BY, HAVING, INNER JOIN
-- ============================================================================

USE streamsight_db;

-- ----------------------------------------------------------------------------
-- Query 1: Total users count by country and gender
-- Business Purpose: Demographic audience breakdown for marketing targeting.
-- ----------------------------------------------------------------------------
SELECT 
    country,
    gender,
    COUNT(user_id) AS total_users
FROM users
GROUP BY country, gender
ORDER BY country, total_users DESC;

-- ----------------------------------------------------------------------------
-- Query 2: Top 10 longest streaming sessions with content titles
-- Business Purpose: Identify binge-watching sessions for peak server allocation.
-- ----------------------------------------------------------------------------
SELECT 
    w.watch_id,
    u.user_id,
    c.content_title,
    c.genre,
    w.device,
    w.minutes_watched,
    ROUND(w.minutes_watched / 60.0, 2) AS watch_hours
FROM watch_sessions w
JOIN users u ON w.user_id = u.user_id
JOIN content c ON w.content_id = c.content_id
ORDER BY w.minutes_watched DESC
LIMIT 10;

-- ----------------------------------------------------------------------------
-- Query 3: Average content rating per genre having at least 50 streams
-- Business Purpose: Evaluate genre quality filter out low-volume statistical noise.
-- ----------------------------------------------------------------------------
SELECT 
    c.genre,
    COUNT(w.watch_id) AS total_streams,
    ROUND(AVG(w.rating), 2) AS avg_genre_rating,
    SUM(w.minutes_watched) AS total_minutes
FROM watch_sessions w
JOIN content c ON w.content_id = c.content_id
GROUP BY c.genre
HAVING COUNT(w.watch_id) >= 50
ORDER BY avg_genre_rating DESC;

-- ----------------------------------------------------------------------------
-- Query 4: Total streaming sessions per device type for Premium subscribers
-- Business Purpose: Device optimization for high-paying premium members.
-- ----------------------------------------------------------------------------
SELECT 
    w.device,
    COUNT(w.watch_id) AS total_sessions,
    ROUND(AVG(w.minutes_watched), 2) AS avg_session_minutes
FROM watch_sessions w
JOIN users u ON w.user_id = u.user_id
WHERE u.subscription_plan = 'Premium'
GROUP BY w.device
ORDER BY total_sessions DESC;
