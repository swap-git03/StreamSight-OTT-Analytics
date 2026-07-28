-- ============================================================================
-- StreamSight – OTT Business Intelligence Platform
-- Phase 7: Business Problem Queries
-- Solving real-world streaming business questions for executive decision-making.
-- ============================================================================

USE streamsight_db;

-- ----------------------------------------------------------------------------
-- Question 1: Which subscription plans have the highest completion rate and user retention?
-- Business Decision: Optimize tier pricing and promotional offers.
-- ----------------------------------------------------------------------------
SELECT 
    u.subscription_plan,
    COUNT(DISTINCT u.user_id) AS total_users,
    COUNT(w.watch_id) AS total_sessions,
    ROUND(SUM(w.minutes_watched) / 60.0, 2) AS total_watch_hours,
    ROUND(AVG(w.rating), 2) AS avg_user_rating,
    ROUND((SUM(CASE WHEN w.completed = 'Yes' THEN 1 ELSE 0 END) / COUNT(w.watch_id)) * 100, 2) AS completion_rate_pct
FROM users u
JOIN watch_sessions w ON u.user_id = w.user_id
GROUP BY u.subscription_plan
ORDER BY completion_rate_pct DESC;

-- ----------------------------------------------------------------------------
-- Question 2: Does payment gateway failure correlate with lower stream completion?
-- Business Decision: Evaluate gateway reliability with payment partners.
-- ----------------------------------------------------------------------------
SELECT 
    p.payment_method,
    p.payment_status,
    COUNT(p.payment_id) AS transaction_count,
    ROUND((SUM(CASE WHEN w.completed = 'Yes' THEN 1 ELSE 0 END) / COUNT(w.watch_id)) * 100, 2) AS completion_rate_pct,
    ROUND(AVG(w.minutes_watched), 2) AS avg_session_duration
FROM payments p
JOIN watch_sessions w ON p.watch_id = w.watch_id
GROUP BY p.payment_method, p.payment_status
ORDER BY p.payment_method, p.payment_status;

-- ----------------------------------------------------------------------------
-- Question 3: Who are the top 5 directors with highest average rating and >= 10 titles?
-- Business Decision: License acquisition priorities for future original content.
-- ----------------------------------------------------------------------------
SELECT 
    c.director,
    COUNT(DISTINCT c.content_id) AS titles_produced,
    COUNT(w.watch_id) AS total_streams,
    ROUND(AVG(w.rating), 2) AS avg_director_rating,
    ROUND(SUM(w.minutes_watched) / 60.0, 2) AS total_watch_hours
FROM content c
JOIN watch_sessions w ON c.content_id = w.content_id
GROUP BY c.director
HAVING COUNT(DISTINCT c.content_id) >= 2
ORDER BY avg_director_rating DESC, total_watch_hours DESC
LIMIT 5;

-- ----------------------------------------------------------------------------
-- Question 4: Regional preference breakdown: Movies vs. TV Series consumption by country
-- Business Decision: Tailor regional content catalog marketing campaigns.
-- ----------------------------------------------------------------------------
SELECT 
    u.country,
    c.content_type,
    COUNT(w.watch_id) AS total_streams,
    ROUND(SUM(w.minutes_watched) / 60.0, 2) AS total_hours,
    ROUND(AVG(w.minutes_watched), 2) AS avg_session_mins
FROM users u
JOIN watch_sessions w ON u.user_id = w.user_id
JOIN content c ON w.content_id = c.content_id
GROUP BY u.country, c.content_type
ORDER BY u.country, total_hours DESC;
