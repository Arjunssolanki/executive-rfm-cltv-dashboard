# Executive RFM Logistics & Predictive CLTV Supply Chain Dashboard

## 📊 Project Overview
This portfolio project implements an end-to-end data engineering and predictive analytics transformation pipeline over a high-density dataset containing **32,065 rows** of raw supply chain operational logs. 

Because traditional customer identifiers are missing, this framework uses geographic coordinates (**Latitude & Longitude**) to establish a logical proxy for unique routing hubs. The backend processes historical utilization behaviors via **SQL Window Functions (RFM)**, while the predictive layer applies a robust algebraic forecasting framework in **Python** to project a **3-Month Forward-Looking Customer Lifetime Value (CLTV)** curve. The final data model is connected to an executive **Power BI Dashboard** via live bi-directional cross-filtering database views.

---

## 🛠️ Tech Stack & Architecture
* **Database Layer:** MySQL Server 8.0 (Advanced CTEs, Window Functions, Database Views, Local Infile)
* **Predictive ML Layer:** Python 3.12.2 (Pandas, SQLAlchemy, PyMySQL)
* **Visualization Layer:** Power BI Desktop (Relational Data Modeling, Bi-Directional Cross-Filtering, DAX Time Intelligence)
* **Version Control:** Git & GitHub

### 🔀 Data Flow Architecture
```text
  [ Raw CSV Dataset ] 
          │
          ▼ (LOAD DATA LOCAL INFILE)
  [ MySQL Raw Table: supply_chain_transactions ]
          │
          ├───► [ SQL View: v_executive_rfm_segmentation ] ───► [ Power BI Dashboard Canvas ]
          │                                                              ▲
          ▼ (SQLAlchemy Extract)                                         │ (Live Data Model Link)
  [ Python Engine: Local Spatial Clustering ]                             │
          │                                                              │
          ▼ (Algebraic Lifetime Forecasts)                               │
  [ MySQL Predictions Table: predicted_cltv_projections ] ───────────────┘
```

---

## 🗂️ Project Repository Structure
* **`sql/rfm_scoring.sql`**
  * Contains production-grade DDL scripts mapping the 27-column logistics dataset schema.
  * Implements `NTILE(5)` statistical window distributions over Recency, Frequency, and Monetary markers to generate executive strategy cohorts.
* **`notebooks/cltv_modeling.ipynb`**
  * Implements local geographic zone clustering (rounding coordinates to 1 decimal place to bundle delivery nodes into ~11km regional logistics zones).
  * Executes a robust corporate accounting framework to evaluate churn risk, predict future 90-day shipments, and calculate terminal 3-Month CLTV evaluations.
  * Automates writing predictions directly back to the database backend.
* **`requirements.txt`**
  * Defines clean Python environment configurations for package reproducibility.
* **`.gitignore`**
  * Restricts unnecessary runtime configurations and documentation assets (e.g., locking out localized `.doc` and `.docx` file formats) from polluting public deployments.

---

## 🔍 Database Pipeline Implementation (SQL Snippet)
The analytics backbone relies on a dynamic database view that automatically ranks location nodes based on system activity:

```sql
CREATE OR REPLACE VIEW v_executive_rfm_segmentation AS
WITH Raw_Metrics AS (
    SELECT 
        CONCAT(vehicle_gps_latitude, ', ', vehicle_gps_longitude) AS routing_hub,
        DATEDIFF((SELECT MAX(timestamp) FROM supply_chain_transactions), MAX(timestamp)) AS raw_recency,
        COUNT(*) AS raw_frequency,
        SUM(shipping_costs) AS raw_monetary
    FROM supply_chain_transactions
    WHERE vehicle_gps_latitude IS NOT NULL AND vehicle_gps_longitude IS NOT NULL
    GROUP BY vehicle_gps_latitude, vehicle_gps_longitude
),
Ranked_Scores AS (
    SELECT 
        routing_hub, raw_recency, raw_frequency, raw_monetary,
        NTILE(5) OVER (ORDER BY raw_recency DESC) AS r_score,
        NTILE(5) OVER (ORDER BY raw_frequency ASC) AS f_score,
        NTILE(5) OVER (ORDER BY raw_monetary ASC) AS m_score
    FROM Raw_Metrics
)
-- Maps numerical scores (e.g., 55, 11) into Actionable Strategic Logistics Cohorts
SELECT *,
    CASE 
        WHEN (r_score * 10) + f_score IN (55, 54, 45) THEN 'VIP High-Volume Hubs'
        WHEN (r_score * 10) + f_score IN (44, 43, 34, 33, 42) THEN 'Steady / Dependable Routes'
        WHEN (r_score * 10) + f_score IN (24, 25, 15, 14) THEN 'Critical Risk (High Volume/Dormant)'
        ELSE 'Underperforming / At Risk'
    END AS executive_cohort
FROM Ranked_Scores;
```

---

## 🚀 Key Insights & Business Impact
* **Geographic Consolidation:** Successfully clustered scattered transactional points into distinct regional shipping networks.
* **Proportional Value Mapping:** Integrated the machine learning predictions into a proportional bubble map. This allows stakeholders to instantly view a route's risk classification via **Color** and its future projected revenue value via **Bubble Size**.
* **Capital Allocation Optimization:** Built a continuous time-series trend line using custom DAX Calendar dimensions. This allows executives to forecast capital expenditure deployment thresholds three months in advance, separating thriving routes from at-risk zones.
