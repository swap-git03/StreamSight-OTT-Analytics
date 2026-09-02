# StreamSight – OTT Business Intelligence Platform

[![Python](https://img.shields.io/badge/Python-3.10%2B-blue.svg)](https://www.python.org/)
[![SQL](https://img.shields.io/badge/SQL-MySQL-00758F.svg)](https://www.mysql.com/)
[![Pandas](https://img.shields.io/badge/Pandas-2.0%2B-150458.svg)](https://pandas.pydata.org/)
[![NumPy](https://img.shields.io/badge/NumPy-1.24%2B-013243.svg)](https://numpy.org/)
[![Power BI](https://img.shields.io/badge/Power_BI-Dashboard-F2C811.svg)](https://powerbi.microsoft.com/)

An end-to-end OTT analytics platform designed to analyze streaming subscriber behavior, content performance, and business KPIs.

---

## 📌 Project Summary (As Per Resume)

> **Developed an end-to-end OTT analytics platform to analyze streaming subscriber behavior, content performance, and business KPIs. Designed a normalized 3NF MySQL database, built automated Python ETL pipelines for data cleaning and feature engineering, performed advanced SQL analysis (CTEs, Window Functions, Views, Joins), and created interactive Power BI dashboards for executive decision-making.**

---

## 🛠 Tech Stack

- **Python**: Automated ETL scripting & pipeline execution.
- **SQL**: Database design, DDL/DML, CTEs, Window Functions, Views, Joins.
- **Pandas**: Data cleaning, sanitization, 3NF table extraction.
- **NumPy**: Numerical processing and feature engineering support.
- **Power BI**: Interactive executive dashboards for business metrics.

---

## 📁 Clean Repository Structure

```text
StreamSight-OTT-Analytics/
│
├── dataset/
│   ├── StreamSight_OTT_Analytics_Dataset.csv   # Raw streaming log dataset
│   ├── cleaned_streamsight_data.csv            # Cleaned master dataset
│   ├── users.csv                               # 3NF Users dimension table
│   ├── content.csv                             # 3NF Content dimension table
│   ├── watch_sessions.csv                      # 3NF Watch Sessions fact table
│   └── payments.csv                           # 3NF Payments transaction table
│
├── database/
│   └── schema.sql                             # Normalized 3NF MySQL schema DDL & indexes
│
├── python/
│   ├── clean_data.py                          # Automated Python ETL pipeline
│   ├── helper.py                             # Reusable data cleaning & feature engineering helper
│   └── mysql_loader.py                        # Automated MySQL data loader script
│
├── sql/
│   ├── basic.sql                              # Basic queries (SELECT, GROUP BY, HAVING, Joins)
│   ├── intermediate.sql                       # Intermediate queries (CASE, Subqueries, Views)
│   ├── advanced.sql                           # Advanced queries (CTEs, Window Functions, Running Totals)
│   └── business_questions.sql                 # Executive business decision queries
│
├── powerbi/
│   └── dashboard.pbix                         # Interactive Power BI dashboard report
│
├── README.md                                  # Project documentation
└── requirements.txt                           # Core dependencies (pandas, numpy, mysql-connector-python)
```

---

## 🗄 1. Database Design (Normalized 3NF MySQL)

Defined in [`database/schema.sql`](file:///e:/CDAC/Projects/StreamSight-OTT-Analytics/database/schema.sql):
- **`users`**: Dimension table (`user_id` PK, `user_age`, `gender`, `country`, `subscription_plan`).
- **`content`**: Dimension table (`content_id` PK, `content_title`, `content_type`, `genre`, `release_year`, `director`).
- **`watch_sessions`**: Fact table (`watch_id` PK, `user_id` FK, `content_id` FK, `device`, `watch_date`, `minutes_watched`, `completed`, `rating`).
- **`payments`**: Transaction table (`payment_id` PK, `watch_id` FK, `user_id` FK, `payment_method`, `payment_status`).
- **Indexes**: B-Tree performance indexes created on `country`, `subscription_plan`, `genre`, `watch_date`, `device`, `payment_status`.

---

## 🐍 2. Automated Python ETL Pipelines

Executed via [`python/clean_data.py`](file:///e:/CDAC/Projects/StreamSight-OTT-Analytics/python/clean_data.py) and [`python/helper.py`](file:///e:/CDAC/Projects/StreamSight-OTT-Analytics/python/helper.py):
- **Data Cleaning**: Stripped whitespace, handled string formats, validated zero nulls/duplicates, cast dates to `datetime64[ns]`.
- **Feature Engineering**: Engineered `watch_hours`, `age_group` cohorts, temporal date parts (`watch_month_name`, `is_weekend`), and `content_age_years`.
- **Relational Extraction**: Programmatically extracted 4 normalized CSV datasets for MySQL ingestion.
- **MySQL Data Ingestion**: [`python/mysql_loader.py`](file:///e:/CDAC/Projects/StreamSight-OTT-Analytics/python/mysql_loader.py) automates DDL schema creation and batch table loading into MySQL.

---

## 💻 3. Advanced SQL Analysis

Structured scripts in `sql/`:
- **CTEs & Window Functions ([`sql/advanced.sql`](file:///e:/CDAC/Projects/StreamSight-OTT-Analytics/sql/advanced.sql))**:
  - `DENSE_RANK() OVER (PARTITION BY genre)` to rank top titles per genre.
  - Cumulative running totals via `SUM() OVER ()`.
  - Frequency gap analysis via `LAG()` to calculate days between sessions.
  - Quartile segmentation using `NTILE(4)`.
- **Views & Joins ([`sql/intermediate.sql`](file:///e:/CDAC/Projects/StreamSight-OTT-Analytics/sql/intermediate.sql))**:
  - Materialized database view `vw_executive_kpi_summary`.
  - Multi-table JOINs and conditional `CASE` classifications.
- **Executive Business Queries ([`sql/business_questions.sql`](file:///e:/CDAC/Projects/StreamSight-OTT-Analytics/sql/business_questions.sql))**:
  - Completion rate analysis by subscription tier.
  - Payment failure impact on session retention.
  - Top director scores and regional Movies vs. Series preferences.

---

## 📊 4. Interactive Power BI Dashboard

Located in [`powerbi/`](file:///e:/CDAC/Projects/StreamSight-OTT-Analytics/powerbi/):
- Executive KPI cards: Total Watch Hours, Completion Rate %, Avg Rating, Payment Failure Rate %.
- Interactive visual slicers for Country, Subscription Plan, Device, Content Type, and Genre.
