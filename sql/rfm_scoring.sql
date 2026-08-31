create database if not exists rfm_analytics;

use rfm_analytics;

DROP TABLE IF EXISTS supply_chain_transactions;

CREATE TABLE supply_chain_transactions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    timestamp DATETIME NOT NULL,
    vehicle_gps_latitude DECIMAL(10, 6),
    vehicle_gps_longitude DECIMAL(10, 6),
    fuel_consumption_rate DECIMAL(5, 2),
    eta_variation_hours DECIMAL(5, 2),
    traffic_congestion_level VARCHAR(50),
    warehouse_inventory_level INT,
    loading_unloading_time DECIMAL(5, 2),
    handling_equipment_availability VARCHAR(50),
    order_fulfillment_status VARCHAR(50),
    weather_condition_severity VARCHAR(50),
    port_congestion_level VARCHAR(50),
    shipping_costs DECIMAL(10, 2) NOT NULL,
    supplier_reliability_score DECIMAL(3, 2),
    lead_time_days INT,
    historical_demand INT,
    iot_temperature DECIMAL(5, 2),
    cargo_condition_status VARCHAR(50),
    route_risk_level VARCHAR(50),
    customs_clearance_time DECIMAL(5, 2),
    driver_behavior_score DECIMAL(5, 2),
    fatigue_monitoring_score DECIMAL(5, 2),
    disruption_likelihood_score DECIMAL(5, 2),
    delay_probability DECIMAL(5, 4),
    risk_classification VARCHAR(50),
    delivery_time_deviation DECIMAL(5, 2)
);

-- Check if local infile configuration is enabled
SHOW VARIABLES LIKE 'local_infile';
-- Enable local data loading capabilities for your database session
SET GLOBAL local_infile = 1;

LOAD DATA LOCAL INFILE 'D:/2026/newstudy/projects/executive-rfm-cltv-dashboard/data/dynamic_supply_chain_logistics_dataset.csv' INTO
TABLE supply_chain_transactions FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' LINES TERMINATED BY '\r\n' IGNORE 1 LINES (
    timestamp,
    vehicle_gps_latitude,
    vehicle_gps_longitude,
    fuel_consumption_rate,
    eta_variation_hours,
    traffic_congestion_level,
    warehouse_inventory_level,
    loading_unloading_time,
    handling_equipment_availability,
    order_fulfillment_status,
    weather_condition_severity,
    port_congestion_level,
    shipping_costs,
    supplier_reliability_score,
    lead_time_days,
    historical_demand,
    iot_temperature,
    cargo_condition_status,
    route_risk_level,
    customs_clearance_time,
    driver_behavior_score,
    fatigue_monitoring_score,
    disruption_likelihood_score,
    delay_probability,
    risk_classification,
    delivery_time_deviation
);

SELECT COUNT(*) FROM supply_chain_transactions;

USE rfm_analytics;

select * from supply_chain_transactions;

-- Create or overwrite the view for direct connection to our analytics tool

USE rfm_analytics;

-- Create or overwrite the view using your exact GPS columns as the routing hub identifier
CREATE OR REPLACE VIEW v_executive_rfm_segmentation AS
WITH
    Raw_Metrics AS (
        SELECT
            -- Concatenate GPS points together to identify each unique delivery node
            CONCAT(
                vehicle_gps_latitude,
                ', ',
                vehicle_gps_longitude
            ) AS routing_hub,
            -- Recency: Days from the hub's latest timestamp to the newest snapshot in the table
            DATEDIFF(
                (
                    SELECT MAX(timestamp)
                    FROM supply_chain_transactions
                ),
                MAX(timestamp)
            ) AS raw_recency,
            -- Frequency: Total count of operational shipments through this node
            COUNT(*) AS raw_frequency,
            -- Monetary: Summing up your exact financial column
            SUM(shipping_costs) AS raw_monetary
        FROM supply_chain_transactions
            -- Clean out empty or zeroed coordinates before processing metrics
        WHERE
            vehicle_gps_latitude IS NOT NULL
            AND vehicle_gps_longitude IS NOT NULL
        GROUP BY
            vehicle_gps_latitude,
            vehicle_gps_longitude
    ),
    Ranked_Scores AS (
        SELECT
            routing_hub,
            raw_recency,
            raw_frequency,
            raw_monetary,
            -- NTILE statistical distribution split (1-5 points)
            NTILE(5) OVER (
                ORDER BY raw_recency DESC
            ) AS r_score,
            NTILE(5) OVER (
                ORDER BY raw_frequency ASC
            ) AS f_score,
            NTILE(5) OVER (
                ORDER BY raw_monetary ASC
            ) AS m_score
        FROM Raw_Metrics
    ),
    RFM_Matrix AS (
        SELECT
            routing_hub,
            raw_recency,
            raw_frequency,
            raw_monetary,
            r_score,
            f_score,
            m_score,
            (r_score * 10) + f_score AS rf_composite_code
        FROM Ranked_Scores
    )
SELECT
    routing_hub,
    raw_recency,
    raw_frequency,
    raw_monetary,
    r_score,
    f_score,
    m_score,
    CASE
        WHEN rf_composite_code IN (55, 54, 45) THEN 'VIP High-Volume Hubs'
        WHEN rf_composite_code IN (44, 43, 34, 33, 42) THEN 'Steady / Dependable Routes'
        WHEN rf_composite_code IN (52, 51, 41, 31, 32) THEN 'Emerging / New Nodes'
        WHEN rf_composite_code IN (24, 25, 15, 14) THEN 'Critical Risk (High Volume/Dormant)'
        WHEN rf_composite_code IN (23, 22, 13) THEN 'Underperforming / At Risk'
        ELSE 'Inactive / Idle Nodes'
    END AS executive_cohort
FROM RFM_Matrix;

SELECT * FROM rfm_analytics.v_executive_rfm_segmentation LIMIT 5;

SELECT
    routing_hub,
    raw_recency,
    raw_frequency,
    raw_monetary,
    r_score,
    f_score,
    m_score,
    executive_cohort
FROM v_executive_rfm_segmentation
ORDER BY RAND()
LIMIT 15;