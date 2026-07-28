"""
StreamSight Data Cleaning & ETL Transformation Pipeline
Author: Senior Data Analyst / Senior Python Developer
Description: Modular script to clean raw streaming logs, handle missing values,
perform feature engineering, and export 3NF normalized tables.
"""

import sys
import os
import pandas as pd

# Add local python directory to sys.path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from helper import (
    load_dataset,
    audit_data_quality,
    clean_string_fields,
    convert_data_types,
    engineer_features,
    extract_relational_tables
)

RAW_DATA_PATH = os.path.join("dataset", "StreamSight_OTT_Analytics_Dataset.csv")
CLEAN_DATA_PATH = os.path.join("dataset", "cleaned_streamsight_data.csv")
OUTPUT_DIR = "dataset"


def run_pipeline():
    print("==========================================================")
    print("      STREAMSIGHT DATA CLEANING & ETL PIPELINE            ")
    print("==========================================================")
    
    # 1. Load Raw Data
    df_raw = load_dataset(RAW_DATA_PATH)
    
    # 2. Audit Data Quality
    audit_data_quality(df_raw)
    
    # 3. Handle Duplicates & Missing Values
    initial_rows = len(df_raw)
    df_clean = df_raw.drop_duplicates().copy()
    dropped_dups = initial_rows - len(df_clean)
    if dropped_dups > 0:
        print(f"[CLEANING] Dropped {dropped_dups} duplicate records.")
    else:
        print("[CLEANING] No duplicate rows detected.")
        
    # Fill any missing values if present (defensive code)
    if df_clean.isnull().sum().sum() > 0:
        print("[CLEANING] Handling missing values...")
        df_clean.dropna(subset=['watch_id', 'user_id', 'content_id'], inplace=True)
        df_clean.fillna({
            'director': 'Unknown',
            'country': 'Unknown',
            'payment_status': 'Unknown'
        }, inplace=True)
    else:
        print("[CLEANING] Data completeness verified. Zero null values.")
        
    # 4. Standardize Strings & Whitespace
    df_clean = clean_string_fields(df_clean)
    
    # 5. Convert Data Types
    df_clean = convert_data_types(df_clean)
    
    # 6. Feature Engineering
    print("[FEATURE ENGINEERING] Generating analytical features (watch_hours, age_group, date parts)...")
    df_clean = engineer_features(df_clean)
    
    # 7. Save Master Cleaned CSV
    print(f"[EXPORT] Saving master clean dataset to {CLEAN_DATA_PATH}...")
    df_clean.to_csv(CLEAN_DATA_PATH, index=False)
    
    # 8. Extract Relational Tables (3NF) for Database Ingestion
    print("[3NF EXTRACTION] Splitting master data into relational tables...")
    users_df, content_df, watch_sessions_df, payments_df = extract_relational_tables(df_clean)
    
    # Save Relational CSV Files
    users_df.to_csv(os.path.join(OUTPUT_DIR, "users.csv"), index=False)
    content_df.to_csv(os.path.join(OUTPUT_DIR, "content.csv"), index=False)
    watch_sessions_df.to_csv(os.path.join(OUTPUT_DIR, "watch_sessions.csv"), index=False)
    payments_df.to_csv(os.path.join(OUTPUT_DIR, "payments.csv"), index=False)
    
    print("\n================ SUMMARY OF EXPORTED TABLES ================")
    print(f"Users Table         : {len(users_df)} unique users -> {os.path.join(OUTPUT_DIR, 'users.csv')}")
    print(f"Content Table       : {len(content_df)} unique contents -> {os.path.join(OUTPUT_DIR, 'content.csv')}")
    print(f"Watch Sessions Table: {len(watch_sessions_df)} streaming logs -> {os.path.join(OUTPUT_DIR, 'watch_sessions.csv')}")
    print(f"Payments Table      : {len(payments_df)} transactions -> {os.path.join(OUTPUT_DIR, 'payments.csv')}")
    print("============================================================\n")
    print("[SUCCESS] Data Cleaning & ETL Pipeline completed successfully.")


if __name__ == "__main__":
    run_pipeline()
