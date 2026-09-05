"""
generate_sharepoint_files.py
Generates the two cloud Excel files for SharePoint Online / OneDrive integration:
1. Targets.xlsx       - Monthly targets by Region, Category (2024–2026)
2. UserSecurity.xlsx  - Dynamic RLS mapping table (Email -> Region/Territory/Role)
"""

import os
import random
from datetime import date
import pandas as pd

OUTPUT_DIR = os.path.join(os.path.dirname(__file__), "..", "sharepoint-sources")
os.makedirs(OUTPUT_DIR, exist_ok=True)

REGIONS = ["North", "South", "West", "East"]
CATEGORIES = ["Beverages", "Personal Care", "Home Care", "Packaged Foods", "Snacks & Confectionery"]

TERRITORIES_BY_REGION = {
    "North": ["Delhi NCR", "Punjab", "UP West"],
    "South": ["Karnataka", "Tamil Nadu", "Telangana"],
    "West": ["Maharashtra", "Gujarat", "Goa"],
    "East": ["West Bengal", "Odisha", "Assam"]
}

def generate_targets_file():
    """Generates monthly sales targets per Region and Category from Jan 2024 to Dec 2026."""
    random.seed(101)
    rows = []
    
    # 36 months (2024-01 to 2026-12)
    start_year = 2024
    for year in range(start_year, start_year + 3):
        for month in range(1, 13):
            target_date = date(year, month, 1)
            # Baseline seasonal multiplier
            seasonal = 1.0 + 0.15 * (1 if month in [10, 11, 12, 3] else (-0.1 if month in [6, 7] else 0.0))
            yearly_growth = 1.0 + (year - 2024) * 0.12  # 12% YoY growth

            for region in REGIONS:
                reg_weight = {"North": 1.25, "West": 1.30, "South": 1.15, "East": 0.85}[region]
                for cat in CATEGORIES:
                    cat_base = {
                        "Beverages": 6_500_000,
                        "Packaged Foods": 8_000_000,
                        "Personal Care": 5_500_000,
                        "Home Care": 4_800_000,
                        "Snacks & Confectionery": 3_900_000
                    }[cat]
                    
                    # Random variance (+/- 5%)
                    variance = random.uniform(0.95, 1.05)
                    target_rev = round(cat_base * reg_weight * seasonal * yearly_growth * variance, 2)
                    target_units = int(target_rev / random.uniform(85, 120))
                    
                    rows.append({
                        "Target_Month": target_date,
                        "Region": region,
                        "Category": cat,
                        "Target_Revenue": target_rev,
                        "Target_Units": target_units
                    })
                    
    df = pd.DataFrame(rows)
    target_path = os.path.join(OUTPUT_DIR, "Targets.xlsx")
    with pd.ExcelWriter(target_path, engine="openpyxl") as writer:
        df.to_excel(writer, sheet_name="MonthlyTargets", index=False)
    print(f"[✔] Generated {target_path} ({len(df)} rows)")

def generate_security_file():
    """Generates Dynamic RLS mapping table for Power BI security modeling."""
    rows = [
        # Executive Level (Full Access)
        {"Email": "punit@brightline.com", "User_Name": "Punit Giri", "Role": "VP Sales / Admin", "Assigned_Region": "ALL", "Assigned_Territory": "ALL"},
        {"Email": "director.sales@brightline.com", "User_Name": "Executive Director", "Role": "Executive", "Assigned_Region": "ALL", "Assigned_Territory": "ALL"},
        
        # Regional Directors (Region-level Access)
        {"Email": "director.north@brightline.com", "User_Name": "North Regional Director", "Role": "Regional Director", "Assigned_Region": "North", "Assigned_Territory": "ALL"},
        {"Email": "director.south@brightline.com", "User_Name": "South Regional Director", "Role": "Regional Director", "Assigned_Region": "South", "Assigned_Territory": "ALL"},
        {"Email": "director.west@brightline.com", "User_Name": "West Regional Director", "Role": "Regional Director", "Assigned_Region": "West", "Assigned_Territory": "ALL"},
        {"Email": "director.east@brightline.com", "User_Name": "East Regional Director", "Role": "Regional Director", "Assigned_Region": "East", "Assigned_Territory": "ALL"},
        
        # Territory Managers & Reps (Territory-level Access)
        {"Email": "tm.delhi@brightline.com", "User_Name": "Aarav Sharma (Delhi TM)", "Role": "Territory Manager", "Assigned_Region": "North", "Assigned_Territory": "Delhi NCR"},
        {"Email": "tm.punjab@brightline.com", "User_Name": "Rohan Singh (Punjab TM)", "Role": "Territory Manager", "Assigned_Region": "North", "Assigned_Territory": "Punjab"},
        {"Email": "tm.karnataka@brightline.com", "User_Name": "Priya Reddy (Karnataka TM)", "Role": "Territory Manager", "Assigned_Region": "South", "Assigned_Territory": "Karnataka"},
        {"Email": "tm.tamilnadu@brightline.com", "User_Name": "Vikram Iyer (TN TM)", "Role": "Territory Manager", "Assigned_Region": "South", "Assigned_Territory": "Tamil Nadu"},
        {"Email": "tm.maharashtra@brightline.com", "User_Name": "Sneha Joshi (Maha TM)", "Role": "Territory Manager", "Assigned_Region": "West", "Assigned_Territory": "Maharashtra"},
        {"Email": "tm.gujarat@brightline.com", "User_Name": "Amit Patel (Gujarat TM)", "Role": "Territory Manager", "Assigned_Region": "West", "Assigned_Territory": "Gujarat"},
        {"Email": "tm.bengal@brightline.com", "User_Name": "Rahul Bose (Bengal TM)", "Role": "Territory Manager", "Assigned_Region": "East", "Assigned_Territory": "West Bengal"}
    ]
    
    df = pd.DataFrame(rows)
    sec_path = os.path.join(OUTPUT_DIR, "UserSecurity.xlsx")
    with pd.ExcelWriter(sec_path, engine="openpyxl") as writer:
        df.to_excel(writer, sheet_name="UserPermissions", index=False)
    print(f"[✔] Generated {sec_path} ({len(df)} users)")

if __name__ == "__main__":
    print("🚀 Generating SharePoint Excel Source Files...")
    generate_targets_file()
    generate_security_file()
    print("🎉 Done! Files are located in 'PBI FMCG Project/sharepoint-sources/'")
