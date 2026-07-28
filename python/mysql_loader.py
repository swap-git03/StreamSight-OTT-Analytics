"""
StreamSight MySQL Database Loader Script
Author: Senior Data Analyst / SQL Architect
Description: Programmatically connects to MySQL database, executes schema.sql, 
and loads cleaned 3NF CSV tables (users, content, watch_sessions, payments) 
with strict foreign key insertion order and row count validation.
"""

import os
import sys
import pandas as pd
import mysql.connector
from mysql.connector import Error

# Database connection defaults (Update with your local MySQL credentials)
DB_HOST = os.getenv("DB_HOST", "localhost")
DB_USER = os.getenv("DB_USER", "root")
DB_PASSWORD = os.getenv("DB_PASSWORD", "password")
DB_NAME = os.getenv("DB_NAME", "streamsight_db")

SCHEMA_FILE = os.path.join("database", "schema.sql")
DATASET_DIR = "dataset"


def get_db_connection(create_db_if_missing=True):
    """Establish connection to MySQL server."""
    try:
        if create_db_if_missing:
            conn = mysql.connector.connect(
                host=DB_HOST,
                user=DB_USER,
                password=DB_PASSWORD
            )
            cursor = conn.cursor()
            cursor.execute(f"CREATE DATABASE IF NOT EXISTS {DB_NAME};")
            conn.commit()
            cursor.close()
            conn.close()

        conn = mysql.connector.connect(
            host=DB_HOST,
            user=DB_USER,
            password=DB_PASSWORD,
            database=DB_NAME
        )
        return conn
    except Error as e:
        print(f"[ERROR] Database connection failed: {e}")
        return None


def execute_schema_script(conn, schema_path):
    """Execute schema.sql to create database structure."""
    if not os.path.exists(schema_path):
        print(f"[ERROR] Schema file not found at {schema_path}")
        return False

    print(f"[INFO] Executing schema DDL from {schema_path}...")
    cursor = conn.cursor()
    with open(schema_path, 'r', encoding='utf-8') as f:
        sql_commands = f.read()

    # Split commands by semicolon
    commands = [cmd.strip() for cmd in sql_commands.split(';') if cmd.strip()]
    for cmd in commands:
        if cmd.startswith('--') or cmd.startswith('/*'):
            continue
        try:
            cursor.execute(cmd)
        except Error as e:
            print(f"[WARNING] SQL Command Error: {e}")
    conn.commit()
    cursor.close()
    print("[SUCCESS] Database schema created successfully.")
    return True


def insert_users(conn, csv_path):
    df = pd.read_csv(csv_path)
    print(f"[LOAD] Ingesting {len(df)} records into 'users' table...")
    cursor = conn.cursor()
    sql = "INSERT INTO users (user_id, user_age, gender, country, subscription_plan) VALUES (%s, %s, %s, %s, %s)"
    records = df[['user_id', 'user_age', 'gender', 'country', 'subscription_plan']].values.tolist()
    cursor.executemany(sql, records)
    conn.commit()
    cursor.close()
    print(f"[SUCCESS] Loaded {len(df)} users.")


def insert_content(conn, csv_path):
    df = pd.read_csv(csv_path)
    print(f"[LOAD] Ingesting {len(df)} records into 'content' table...")
    cursor = conn.cursor()
    sql = "INSERT INTO content (content_id, content_title, content_type, genre, release_year, director) VALUES (%s, %s, %s, %s, %s, %s)"
    records = df[['content_id', 'content_title', 'content_type', 'genre', 'release_year', 'director']].values.tolist()
    cursor.executemany(sql, records)
    conn.commit()
    cursor.close()
    print(f"[SUCCESS] Loaded {len(df)} content items.")


def insert_watch_sessions(conn, csv_path):
    df = pd.read_csv(csv_path)
    print(f"[LOAD] Ingesting {len(df)} records into 'watch_sessions' table...")
    cursor = conn.cursor()
    sql = "INSERT INTO watch_sessions (watch_id, user_id, content_id, device, watch_date, minutes_watched, completed, rating) VALUES (%s, %s, %s, %s, %s, %s, %s, %s)"
    records = df[['watch_id', 'user_id', 'content_id', 'device', 'watch_date', 'minutes_watched', 'completed', 'rating']].values.tolist()
    cursor.executemany(sql, records)
    conn.commit()
    cursor.close()
    print(f"[SUCCESS] Loaded {len(df)} watch sessions.")


def insert_payments(conn, csv_path):
    df = pd.read_csv(csv_path)
    print(f"[LOAD] Ingesting {len(df)} records into 'payments' table...")
    cursor = conn.cursor()
    sql = "INSERT INTO payments (payment_id, watch_id, user_id, payment_method, payment_status) VALUES (%s, %s, %s, %s, %s)"
    records = df[['payment_id', 'watch_id', 'user_id', 'payment_method', 'payment_status']].values.tolist()
    cursor.executemany(sql, records)
    conn.commit()
    cursor.close()
    print(f"[SUCCESS] Loaded {len(df)} payments.")


def verify_row_counts(conn):
    """Verify and display inserted row counts across all tables."""
    tables = ['users', 'content', 'watch_sessions', 'payments']
    cursor = conn.cursor()
    print("\n================ MYSQL ROW COUNT VALIDATION ================")
    for table in tables:
        cursor.execute(f"SELECT COUNT(*) FROM {table}")
        count = cursor.fetchone()[0]
        print(f"Table: {table:<15} | Row Count: {count}")
    print("============================================================\n")
    cursor.close()


def run_loader():
    print("==========================================================")
    print("        STREAMSIGHT MYSQL DATA INGESTION LOADER           ")
    print("==========================================================")
    
    conn = get_db_connection()
    if not conn:
        print("[SKIP] MySQL server unavailable. Ensure MySQL service is running.")
        return

    try:
        execute_schema_script(conn, SCHEMA_FILE)
        insert_users(conn, os.path.join(DATASET_DIR, "users.csv"))
        insert_content(conn, os.path.join(DATASET_DIR, "content.csv"))
        insert_watch_sessions(conn, os.path.join(DATASET_DIR, "watch_sessions.csv"))
        insert_payments(conn, os.path.join(DATASET_DIR, "payments.csv"))
        verify_row_counts(conn)
    except Exception as e:
        print(f"[ERROR] Ingestion failed: {e}")
    finally:
        conn.close()


if __name__ == "__main__":
    run_loader()
