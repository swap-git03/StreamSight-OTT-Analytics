-- ============================================================================
-- StreamSight – OTT Business Intelligence Platform
-- Phase 7: Intermediate SQL Queries
-- Topics: CASE Statements, Subqueries, Multi-Table JOINs, Views
-- ============================================================================

USE streamsight_db;

-- ----------------------------------------------------------------------------
-- Query 1: User Engagement Tier Classification using CASE
-- Business Purpose: Segment viewers into Heavy, Medium, and Light streaming tiers.
-- ----------------------------------------------------------------------------
SELECT 
    u.user_id,
    u.country,
    u.subscription_plan,
    SUM(w.minutes_watched) AS total_minutes,
    CASE 
        WHEN SUM(w.minutes_watched) >= 1000 THEN 'Heavy Binge Viewer'
        WHEN SUM(w.minutes_watched) BETWEEN 400 AND 999 THEN 'Moderate Viewer'
        ELSE 'Casual Viewer'
    END AS viewer_category
FROM users u
JOIN watch_sessions w ON u.user_id = w.user_id
GROUP BY u.user_id, u.country, u.subscription_plan
ORDER BY total_minutes DESC;

-- ----------------------------------------------------------------------------
-- Query 2: Subquery to find users who watched more than the platform average watch time
-- Business Purpose: Target above-average users for loyalty reward programs.
-- ----------------------------------------------------------------------------
SELECT 
    u.user_id,
    u.country,
    u.subscription_plan,
    ROUND(AVG(w.minutes_watched), 2) AS user_avg_minutes
FROM users u
JOIN watch_sessions w ON u.user_id = w.user_id
GROUP BY u.user_id, u.country, u.subscription_plan
HAVING AVG(w.minutes_watched) > (
    SELECT AVG(minutes_watched) FROM watch_sessions
)
ORDER BY user_avg_minutes DESC;

-- ----------------------------------------------------------------------------
-- Query 3: Multi-Table JOIN for Payment Method Failure Analysis
-- Business Purpose: Monitor payment failure impact on completed streaming sessions.
-- ----------------------------------------------------------------------------
SELECT 
    p.payment_method,
    p.payment_status,
    w.completed,
    COUNT(w.watch_id) AS total_sessions,
    ROUND(AVG(w.minutes_watched), 2) AS avg_minutes
FROM payments p
JOIN watch_sessions w ON p.watch_id = w.watch_id
JOIN users u ON p.user_id = u.user_id
GROUP BY p.payment_method, p.payment_status, w.completed
ORDER BY p.payment_method, total_sessions DESC;

-- ----------------------------------------------------------------------------
-- View 1: Executive KPI Summary View
-- Business Purpose: Reusable database view powering Power BI dashboards.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW vw_executive_kpi_summary AS
SELECT 
    u.country,
    u.subscription_plan,
    c.content_type,
    c.genre,
    w.device,
    COUNT(w.watch_id) AS total_sessions,
    SUM(w.minutes_watched) AS total_minutes_watched,
    ROUND(SUM(w.minutes_watched) / 60.0, 2) AS total_hours_watched,
    ROUND(AVG(w.rating), 2) AS avg_user_rating,
    SUM(CASE WHEN w.completed = 'Yes' THEN 1 ELSE 0 END) AS completed_sessions,
    ROUND((SUM(CASE WHEN w.completed = 'Yes' THEN 1 ELSE 0 END) / COUNT(w.watch_id)) * 100, 2) AS completion_rate_pct
FROM watch_sessions w
JOIN users u ON w.user_id = u.user_id
JOIN content c ON w.content_id = c.content_id
GROUP BY u.country, u.subscription_plan, c.content_type, c.genre, w.device;
