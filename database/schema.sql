-- ============================================================================
-- StreamSight – OTT Business Intelligence Platform
-- Database Schema Definition (MySQL)
-- Architecture: 3rd Normal Form (3NF) Relational Database
-- ============================================================================

-- Create Database if not exists
CREATE DATABASE IF NOT EXISTS streamsight_db;
USE streamsight_db;

-- Drop existing tables in reverse dependency order to avoid foreign key errors
DROP TABLE IF EXISTS payments;
DROP TABLE IF EXISTS watch_sessions;
DROP TABLE IF EXISTS content;
DROP TABLE IF EXISTS users;

-- ----------------------------------------------------------------------------
-- 1. Users Table (Dimension)
-- Stores demographic & subscription tier information for each registered viewer.
-- ----------------------------------------------------------------------------
CREATE TABLE users (
    user_id INT PRIMARY KEY,
    user_age INT NOT NULL CHECK (user_age >= 0 AND user_age <= 120),
    gender VARCHAR(20) NOT NULL,
    country VARCHAR(100) NOT NULL,
    subscription_plan VARCHAR(50) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ----------------------------------------------------------------------------
-- 2. Content Table (Dimension)
-- Stores metadata for all streaming titles (Movies and TV Series).
-- ----------------------------------------------------------------------------
CREATE TABLE content (
    content_id INT PRIMARY KEY,
    content_title VARCHAR(255) NOT NULL,
    content_type VARCHAR(50) NOT NULL, -- 'Movie', 'Series'
    genre VARCHAR(100) NOT NULL,
    release_year INT NOT NULL CHECK (release_year >= 1900 AND release_year <= 2100),
    director VARCHAR(255) NOT NULL
);

-- ----------------------------------------------------------------------------
-- 3. Watch Sessions Table (Fact)
-- Stores individual viewing activity logs, duration, completion, and rating.
-- ----------------------------------------------------------------------------
CREATE TABLE watch_sessions (
    watch_id INT PRIMARY KEY,
    user_id INT NOT NULL,
    content_id INT NOT NULL,
    device VARCHAR(50) NOT NULL, -- 'Mobile', 'Laptop', 'Smart TV', etc.
    watch_date DATE NOT NULL,
    minutes_watched INT NOT NULL CHECK (minutes_watched >= 0),
    completed VARCHAR(10) NOT NULL CHECK (completed IN ('Yes', 'No')),
    rating INT NOT NULL CHECK (rating >= 1 AND rating <= 5),
    CONSTRAINT fk_watch_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    CONSTRAINT fk_watch_content FOREIGN KEY (content_id) REFERENCES content(content_id) ON DELETE CASCADE
);

-- ----------------------------------------------------------------------------
-- 4. Payments Table (Fact / Transaction)
-- Stores billing transaction status associated with viewing sessions.
-- ----------------------------------------------------------------------------
CREATE TABLE payments (
    payment_id INT AUTO_INCREMENT PRIMARY KEY,
    watch_id INT NOT NULL,
    user_id INT NOT NULL,
    payment_method VARCHAR(50) NOT NULL, -- 'UPI', 'NetBanking', 'Card'
    payment_status VARCHAR(20) NOT NULL, -- 'Success', 'Failed'
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_payment_watch FOREIGN KEY (watch_id) REFERENCES watch_sessions(watch_id) ON DELETE CASCADE,
    CONSTRAINT fk_payment_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- Indexes for performance optimization on frequent JOIN & WHERE queries
CREATE INDEX idx_users_country ON users(country);
CREATE INDEX idx_users_plan ON users(subscription_plan);
CREATE INDEX idx_content_genre ON content(genre);
CREATE INDEX idx_watch_date ON watch_sessions(watch_date);
CREATE INDEX idx_watch_device ON watch_sessions(device);
CREATE INDEX idx_payment_status ON payments(payment_status);
