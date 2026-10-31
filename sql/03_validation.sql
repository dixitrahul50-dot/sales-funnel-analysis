-- =============================================================================
-- 03_validation.sql
-- Run after 01_clean_data.sql. Returns every check in ONE result table.
-- Every row in the "status" column should say PASS.
-- =============================================================================

WITH checks AS (
    SELECT 'Raw rows loaded' AS check_name,
           (SELECT COUNT(*) FROM leads_raw) AS actual, 2060 AS expected
    UNION ALL
    SELECT 'Unique leads in raw data',
           (SELECT COUNT(DISTINCT lead_id) FROM leads_raw), 2000
    UNION ALL
    SELECT 'Rows in clean table (duplicates removed)',
           (SELECT COUNT(*) FROM leads), 2000
    UNION ALL
    SELECT 'Duplicate lead_ids left in clean table',
           (SELECT COUNT(*) FROM (SELECT lead_id FROM leads GROUP BY 1 HAVING COUNT(*) > 1)), 0
    UNION ALL
    SELECT 'Distinct lead sources after standardising',
           (SELECT COUNT(DISTINCT lead_source) FROM leads), 7
    UNION ALL
    SELECT 'Leads with an unrecognised source ("Other")',
           (SELECT COUNT(*) FROM leads WHERE lead_source = 'Other'), 0
    UNION ALL
    SELECT 'Leads with unknown country',
           (SELECT COUNT(*) FROM leads WHERE country = 'Unknown'), 125
    UNION ALL
    SELECT 'Won leads',
           (SELECT COUNT(*) FROM leads WHERE status = 'Won'), 210
    UNION ALL
    SELECT 'Lost leads',
           (SELECT COUNT(*) FROM leads WHERE status = 'Lost'), 1688
    UNION ALL
    SELECT 'Open leads',
           (SELECT COUNT(*) FROM leads WHERE status = 'Open'), 102
    UNION ALL
    SELECT 'Won leads without a deal value',
           (SELECT COUNT(*) FROM leads WHERE status = 'Won' AND deal_value IS NULL), 0
    UNION ALL
    SELECT 'Lost or open leads that have a deal value',
           (SELECT COUNT(*) FROM leads WHERE status <> 'Won' AND deal_value IS NOT NULL), 0
    UNION ALL
    SELECT 'Open leads that have a closed date',
           (SELECT COUNT(*) FROM leads WHERE status = 'Open' AND closed_date IS NOT NULL), 0
    UNION ALL
    SELECT 'Stage dates out of order',
           (SELECT COUNT(*) FROM leads
            WHERE qualified_date   < created_date
               OR proposal_date    < qualified_date
               OR negotiation_date < proposal_date
               OR closed_date      < COALESCE(negotiation_date, proposal_date, qualified_date, created_date)), 0
    UNION ALL
    SELECT 'Total revenue (USD)',
           (SELECT ROUND(SUM(deal_value), 0) FROM leads), 1363900
)
SELECT check_name,
       actual,
       expected,
       CASE WHEN actual = expected THEN 'PASS' ELSE 'CHECK' END AS status
FROM checks;
