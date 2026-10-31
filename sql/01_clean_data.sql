-- =============================================================================
-- 01_clean_data.sql
-- Builds the clean `leads` table from the raw CRM export.
--
-- Expects one table, `leads_raw`, imported from data/crm_leads_raw.csv
-- (File > Import > Table from CSV file in DB Browser for SQLite).
--
-- Fixes:
--   * 60 duplicate rows            -> keep one row per lead_id
--   * 23 spellings of 7 sources    -> standardised lead_source
--   * 125 blank countries          -> 'Unknown'
--   * empty text in date/value columns -> real NULLs; values -> numbers
-- =============================================================================

DROP TABLE IF EXISTS leads;

CREATE TABLE leads AS
WITH dedup AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY lead_id ORDER BY lead_id) AS rn
    FROM leads_raw
)
SELECT
    lead_id,
    created_date,
    CASE LOWER(TRIM(lead_source))
        WHEN 'upwork'        THEN 'Upwork'
        WHEN 'linkedin'      THEN 'LinkedIn'
        WHEN 'clutch'        THEN 'Clutch'
        WHEN 'clutch.co'     THEN 'Clutch'
        WHEN 'fiverr'        THEN 'Fiverr'
        WHEN 'pph'           THEN 'PPH'
        WHEN 'peopleperhour' THEN 'PPH'
        WHEN 'referral'      THEN 'Referral'
        WHEN 'website'       THEN 'Website'
        WHEN 'web site'      THEN 'Website'
        ELSE 'Other'
    END AS lead_source,
    service_type,
    COALESCE(NULLIF(TRIM(country), ''), 'Unknown') AS country,
    company_size,
    sales_rep,
    NULLIF(qualified_date, '')   AS qualified_date,
    NULLIF(proposal_date, '')    AS proposal_date,
    NULLIF(negotiation_date, '') AS negotiation_date,
    NULLIF(closed_date, '')      AS closed_date,
    status,
    CAST(NULLIF(quoted_value, '') AS REAL) AS quoted_value,
    CAST(NULLIF(deal_value, '')  AS REAL) AS deal_value
FROM dedup
WHERE rn = 1;

CREATE INDEX idx_leads_source ON leads(lead_source);
CREATE INDEX idx_leads_status ON leads(status);
