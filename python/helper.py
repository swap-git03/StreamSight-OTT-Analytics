"""
Helper Utility Module for StreamSight Data Processing
Contains reusable functions for dataset loading, sanitization, data auditing, 
feature engineering, and splitting into relational tables.
"""

import pandas as pd
import numpy as np


def load_dataset(filepath: str) -> pd.DataFrame:
    """Load raw dataset from CSV with initial validation."""
    print(f"[INFO] Loading dataset from: {filepath}")
    df = pd.read_csv(filepath)
    print(f"[INFO] Successfully loaded {len(df)} rows and {len(df.columns)} columns.")
    return df


def audit_data_quality(df: pd.DataFrame) -> dict:
    """Audit missing values, duplicate counts, and memory usage."""
    missing_summary = df.isnull().sum()
    duplicate_count = df.duplicated().sum()
    
    audit_results = {
        "total_rows": len(df),
        "total_columns": len(df.columns),
        "duplicate_rows": int(duplicate_count),
        "missing_values_per_column": missing_summary[missing_summary > 0].to_dict()
    }
    
    print("================ DATA QUALITY AUDIT ================")
    print(f"Total Rows       : {audit_results['total_rows']}")
    print(f"Total Columns    : {audit_results['total_columns']}")
    print(f"Duplicate Rows   : {audit_results['duplicate_rows']}")
    print(f"Missing Values   : {audit_results['missing_values_per_column']}")
    print("====================================================")
    
    return audit_results


def clean_string_fields(df: pd.DataFrame) -> pd.DataFrame:
    """Strip whitespace and standardize casing for categorical text columns."""
    df_clean = df.copy()
    string_cols = df_clean.select_dtypes(include=['object']).columns
    
    for col in string_cols:
        df_clean[col] = df_clean[col].astype(str).str.strip()
        
    return df_clean


def convert_data_types(df: pd.DataFrame) -> pd.DataFrame:
    """Convert dates and numeric types to appropriate Pandas datatypes."""
    df_clean = df.copy()
    
    # Convert watch_date to datetime
    if 'watch_date' in df_clean.columns:
        df_clean['watch_date'] = pd.to_datetime(df_clean['watch_date'], errors='coerce')
        
    # Ensure numeric columns are strictly integer
    int_cols = ['watch_id', 'user_id', 'user_age', 'content_id', 'release_year', 'minutes_watched', 'rating']
    for col in int_cols:
        if col in df_clean.columns:
            df_clean[col] = pd.to_numeric(df_clean[col], errors='coerce').astype('int64')
            
    return df_clean


def engineer_features(df: pd.DataFrame) -> pd.DataFrame:
    """Engineer new business features for downstream analytics."""
    df_feat = df.copy()
    
    # 1. Watch Duration in Hours
    df_feat['watch_hours'] = (df_feat['minutes_watched'] / 60.0).round(2)
    
    # 2. User Age Grouping
    bins = [0, 24, 45, 120]
    labels = ['Youth (<25)', 'Adult (25-45)', 'Senior (>45)']
    df_feat['age_group'] = pd.cut(df_feat['user_age'], bins=bins, labels=labels, right=True)
    
    # 3. Date Features
    df_feat['watch_year'] = df_feat['watch_date'].dt.year
    df_feat['watch_month'] = df_feat['watch_date'].dt.month
    df_feat['watch_month_name'] = df_feat['watch_date'].dt.strftime('%B')
    df_feat['watch_day_name'] = df_feat['watch_date'].dt.strftime('%A')
    df_feat['is_weekend'] = df_feat['watch_date'].dt.dayofweek.isin([5, 6]).astype(int)
    
    # 4. Content Age at Streaming Time
    df_feat['content_age_years'] = df_feat['watch_year'] - df_feat['release_year']
    
    return df_feat


def extract_relational_tables(df: pd.DataFrame) -> tuple[pd.DataFrame, pd.DataFrame, pd.DataFrame, pd.DataFrame]:
    """Split clean master DataFrame into 4 normalized relational DataFrames for MySQL."""
    
    # 1. Users Dimension (Unique per user_id)
    # Taking the latest recorded user attributes per user_id
    users_df = df[['user_id', 'user_age', 'gender', 'country', 'subscription_plan']].drop_duplicates(subset=['user_id']).sort_values('user_id').reset_index(drop=True)
    
    # 2. Content Dimension (Unique per content_id)
    content_df = df[['content_id', 'content_title', 'content_type', 'genre', 'release_year', 'director']].drop_duplicates(subset=['content_id']).sort_values('content_id').reset_index(drop=True)
    
    # 3. Watch Sessions Fact
    watch_sessions_df = df[['watch_id', 'user_id', 'content_id', 'device', 'watch_date', 'minutes_watched', 'completed', 'rating']].sort_values('watch_id').reset_index(drop=True)
    
    # 4. Payments Fact
    payments_df = df[['watch_id', 'user_id', 'payment_method', 'payment_status']].sort_values('watch_id').reset_index(drop=True)
    payments_df.insert(0, 'payment_id', range(1, len(payments_df) + 1))
    
    return users_df, content_df, watch_sessions_df, payments_df
