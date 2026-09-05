# Brightline Analytics — Enterprise Power BI & Fabric Deployment Architecture

## 1. Executive Summary & Purpose
Brightline Distribution Pvt. Ltd. is a national FMCG distributor across India (North, South, West, East). This architecture blueprint establishes a robust, auditable 3-tier enterprise deployment pipeline across Power BI Desktop, Microsoft Fabric / Power BI Service, Azure DevOps, and On-Premises PostgreSQL ERP databases.

---

## 2. 3-Tier Environment Topology

```
┌─────────────────────────┐    ┌─────────────────────────┐    ┌─────────────────────────┐
│     DEV ENVIRONMENT     │    │    TEST / UAT STAGE     │    │    PROD ENVIRONMENT     │
├─────────────────────────┤    ├─────────────────────────┤    ├─────────────────────────┤
│ Workspace:              │    │ Workspace:              │    │ Workspace:              │
│  BL-Sales-DEV           │    │  BL-Sales-TEST          │    │  BL-Sales-PROD          │
│                         │    │                         │    │                         │
│ Content Source:         │    │ Content Source:         │    │ Content Source:         │
│  Fabric Git (main)      │    │  Deployment Pipeline    │    │  Deployment Pipeline    │
│                         │    │  (DEV -> TEST)          │    │  (TEST -> PROD)         │
│                         │    │                         │    │                         │
│ Database:               │    │ Database:               │    │ Database:               │
│  brightline_dev         │    │  brightline_test        │    │  brightline_prod        │
│  (250k rows, 6 months)  │    │  (2.5M rows, 36 months) │    │  (2.5M rows, 36 months) │
│                         │    │                         │    │                         │
│ Deployment Rule:        │    │ Deployment Rule:        │    │ Deployment Rule:        │
│  Default Parameter      │    │  Swap DB Parameter      │    │  Swap DB Parameter      │
│                         │    │  -> brightline_test     │    │  -> brightline_prod     │
│                         │    │                         │    │                         │
│ Gateway Connection:     │    │ Gateway Connection:     │    │ Gateway Connection:     │
│  BL-PG-DEV              │    │  BL-PG-TEST             │    │  BL-PG-PROD             │
└─────────────────────────┘    └─────────────────────────┘    └─────────────────────────┘
```

---

## 3. Hybrid Data Source Architecture

Brightline utilizes a **mixed-source data model** combining on-premises relational databases with cloud spreadsheets:

1. **On-Premises Relational ERP (PostgreSQL 16):**
   - **Schema:** `erp`
   - **Tables:** `products` (44 SKUs), `stores` (78 Stores), `customers` (210 Accounts), `sales_reps` (17 Reps), `sales_transactions` (250K DEV / 2.5M TEST & PROD).
   - **Connectivity:** Imported via Power Query SQL Connector with query folding on `txn_date` and `last_modified`. Refreshed in Service via On-premises Data Gateway (Standard Mode).

2. **Cloud Source (SharePoint / OneDrive for Business):**
   - **Targets.xlsx:** Monthly sales revenue and unit quotas across 4 regions, 5 product categories, and 36 months (720 records).
   - **UserSecurity.xlsx:** Role-based security matrix mapping user email addresses (UPNs) to Region and Territory authorization levels for Dynamic Row-Level Security (RLS).
   - **Connectivity:** Power Query `Web.Contents()` with clean URL (stripped `?web=1`). Refreshes directly in cloud without gateway routing.

---

## 4. Authentication, Service Principal (SPN) & Security

- **Service Principal (SPN):** `Brightline-Fabric-Deployer` registered in Microsoft Entra ID with Power BI Service Admin read/write API permissions.
- **Why SPN for CI/CD:** Eliminates human user password expiration, avoids Interactive Multi-Factor Authentication (MFA) blocks in automated Azure DevOps pipelines, and isolates deployment permissions to dedicated service credentials.
- **Row-Level Security (RLS):** 
  - Dynamic RLS evaluated against `USERPRINCIPALNAME()`.
  - Filter propagation: User Email -> `UserSecurity` table -> `stores` / `sales_transactions` via 1-to-many relationship with bidirectional security filtering.
- **Object-Level Security (OLS):** Restricts `unit_cost` and `total_cogs` from unauthorized store managers.

---

## 5. Deployment Lifecycle & Promotion Flow

1. **Authoring (Phase 1):** Developed in Power BI Desktop using PBIP format with TMDL metadata.
2. **Version Control (Phase 7):** Committed to Azure DevOps Git repository (`main` branch) and synced to `BL-Sales-DEV` workspace via Fabric Git integration.
3. **CI/CD Quality Gate (Phase 8):** Tabular Editor Best Practice Analyzer (BPA) checks run in Azure Pipelines prior to pull request merge.
4. **Promotion (Phase 6):** Fabric Deployment Pipeline promotes verified artifacts from `DEV` -> `TEST` (UAT verification with deployment rules applied) -> `PROD` (Certified App distribution).
