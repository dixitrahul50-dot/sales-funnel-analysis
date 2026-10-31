-- =============================================================================
-- 02_analysis.sql
-- Business question: which lead sources deserve more of the sales team's effort?
-- Reads from the clean `leads` table. Run each query on its own
-- (select it, then Ctrl+Enter in DB Browser for SQLite). Amounts are in USD.
--
-- Win rate = Won / (Won + Lost). Open leads are excluded from the denominator
-- because they have not had the chance to close yet.
-- =============================================================================


-- Q1. Overall funnel: how many leads reach each stage
SELECT COUNT(*) AS leads,
       COUNT(qualified_date)   AS qualified,
       COUNT(proposal_date)    AS proposals,
       COUNT(negotiation_date) AS negotiations,
       SUM(status = 'Won')     AS won
FROM leads;


-- Q2. Win rate by source
SELECT lead_source,
       COUNT(*) AS leads,
       SUM(status = 'Won') AS won,
       SUM(status IN ('Won','Lost')) AS closed,
       ROUND(100.0 * SUM(status = 'Won') / SUM(status IN ('Won','Lost')), 1) AS win_rate_pct
FROM leads
GROUP BY lead_source
ORDER BY win_rate_pct DESC;


-- Q3. Revenue, average deal and revenue share by source (window function)
SELECT lead_source,
       ROUND(SUM(deal_value)) AS revenue,
       ROUND(AVG(deal_value)) AS avg_deal,
       ROUND(100.0 * SUM(deal_value) / SUM(SUM(deal_value)) OVER (), 1) AS revenue_share_pct
FROM leads
WHERE status = 'Won'
GROUP BY lead_source
ORDER BY revenue DESC;


-- Q4. Average days from lead creation to win
SELECT lead_source,
       ROUND(AVG(julianday(closed_date) - julianday(created_date)), 1) AS avg_days_to_win
FROM leads
WHERE status = 'Won'
GROUP BY lead_source
ORDER BY avg_days_to_win;


-- Q5. Where each source loses leads: stage-to-stage conversion
SELECT lead_source,
       ROUND(100.0 * COUNT(qualified_date)   / COUNT(*), 1)              AS lead_to_qualified,
       ROUND(100.0 * COUNT(proposal_date)    / COUNT(qualified_date), 1) AS qualified_to_proposal,
       ROUND(100.0 * COUNT(negotiation_date) / COUNT(proposal_date), 1)  AS proposal_to_negotiation,
       ROUND(100.0 * SUM(status = 'Won')     / COUNT(negotiation_date), 1) AS negotiation_to_won
FROM leads
GROUP BY lead_source
ORDER BY lead_source;


-- Q6. Monthly deals won, revenue and running total (CTE + window function).
-- Grouped by the month the deal was won (closed_date).
WITH monthly AS (
    SELECT strftime('%Y-%m', closed_date) AS month,
           COUNT(*) AS deals_won,
           SUM(deal_value) AS revenue
    FROM leads
    WHERE status = 'Won'
    GROUP BY 1
)
SELECT month, deals_won, ROUND(revenue) AS revenue,
       ROUND(SUM(revenue) OVER (ORDER BY month)) AS running_revenue
FROM monthly
ORDER BY month;


-- Q7. Source scorecard ranked by revenue per lead (CTE + RANK)
WITH s AS (
    SELECT lead_source,
           COUNT(*) AS leads,
           ROUND(100.0 * SUM(status = 'Won') / SUM(status IN ('Won','Lost')), 1) AS win_rate_pct,
           ROUND(SUM(deal_value) / COUNT(*)) AS revenue_per_lead
    FROM leads
    GROUP BY lead_source
)
SELECT RANK() OVER (ORDER BY revenue_per_lead DESC) AS rank,
       lead_source, leads, win_rate_pct, revenue_per_lead
FROM s
ORDER BY rank;


-- Q8. Funnel drop-off: how many leads did not move to the next stage, overall.
-- 'did_not_advance' includes open leads that are still in progress; Q9 looks at lost leads only.
WITH f AS (
    SELECT COUNT(*) AS leads,
           COUNT(qualified_date)   AS qualified,
           COUNT(proposal_date)    AS proposals,
           COUNT(negotiation_date) AS negotiations,
           SUM(status = 'Won')     AS won
    FROM leads
)
SELECT '1) Lead -> Qualified'       AS step, leads - qualified AS did_not_advance,
       ROUND(100.0 * qualified    / leads, 1)        AS pct_reaching_next FROM f
UNION ALL
SELECT '2) Qualified -> Proposal',   qualified - proposals,
       ROUND(100.0 * proposals    / qualified, 1)    FROM f
UNION ALL
SELECT '3) Proposal -> Negotiation', proposals - negotiations,
       ROUND(100.0 * negotiations / proposals, 1)    FROM f
UNION ALL
SELECT '4) Negotiation -> Won',      negotiations - won,
       ROUND(100.0 * won          / negotiations, 1) FROM f;


-- Q9. At which stage were the lost leads lost?
SELECT
    CASE
        WHEN qualified_date   IS NULL THEN '1) Never qualified'
        WHEN proposal_date    IS NULL THEN '2) Qualified, no proposal sent'
        WHEN negotiation_date IS NULL THEN '3) Proposal sent, no negotiation'
        ELSE                               '4) Lost in negotiation'
    END                                                          AS lost_at_stage,
    COUNT(*)                                                     AS lost_leads,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1)           AS share_of_lost_pct
FROM leads
WHERE status = 'Lost'
GROUP BY lost_at_stage
ORDER BY lost_at_stage;


-- Q10. Where does the sales cycle spend its time? Average days per step (won deals)
SELECT
    ROUND(AVG(julianday(qualified_date)   - julianday(created_date)),     1) AS days_lead_to_qualified,
    ROUND(AVG(julianday(proposal_date)    - julianday(qualified_date)),   1) AS days_qualified_to_proposal,
    ROUND(AVG(julianday(negotiation_date) - julianday(proposal_date)),    1) AS days_proposal_to_negotiation,
    ROUND(AVG(julianday(closed_date)      - julianday(negotiation_date)), 1) AS days_negotiation_to_close,
    ROUND(AVG(julianday(closed_date)      - julianday(created_date)),     1) AS total_days
FROM leads
WHERE status = 'Won';


-- Q11. Does the type of work matter? Win rate and deal size by service type
SELECT service_type,
       COUNT(*)                                                                        AS leads,
       ROUND(100.0 * SUM(status = 'Won') / SUM(status IN ('Won','Lost')), 1)           AS win_rate_pct,
       ROUND(AVG(deal_value))                                                          AS avg_deal,
       ROUND(SUM(deal_value))                                                          AS revenue
FROM leads
GROUP BY service_type
ORDER BY revenue DESC;


-- Q12. Does client size matter?
SELECT company_size,
       COUNT(*)                                                                        AS leads,
       ROUND(100.0 * SUM(status = 'Won') / SUM(status IN ('Won','Lost')), 1)           AS win_rate_pct,
       ROUND(AVG(deal_value))                                                          AS avg_deal,
       ROUND(SUM(deal_value))                                                          AS revenue
FROM leads
GROUP BY company_size
ORDER BY avg_deal DESC;


-- Q13. Sales reps: is revenue driven by win rate or by deal size?
SELECT sales_rep,
       COUNT(*)                                                                        AS leads,
       ROUND(100.0 * SUM(status = 'Won') / SUM(status IN ('Won','Lost')), 1)           AS win_rate_pct,
       ROUND(AVG(deal_value))                                                          AS avg_deal,
       ROUND(SUM(deal_value))                                                          AS revenue
FROM leads
GROUP BY sales_rep
ORDER BY revenue DESC;


-- Q14. Country view, including leads with no country recorded
SELECT country,
       COUNT(*)                                                                        AS leads,
       ROUND(100.0 * SUM(status = 'Won') / SUM(status IN ('Won','Lost')), 1)           AS win_rate_pct,
       ROUND(SUM(deal_value))                                                          AS revenue
FROM leads
GROUP BY country
ORDER BY revenue DESC;


-- Q15. Deal size bands: how much revenue sits in large deals?
SELECT
    CASE
        WHEN deal_value <  2500 THEN '1) Under $2.5K'
        WHEN deal_value <  5000 THEN '2) $2.5K to $5K'
        WHEN deal_value < 10000 THEN '3) $5K to $10K'
        ELSE                         '4) $10K and above'
    END                                                              AS deal_band,
    COUNT(*)                                                         AS deals,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1)               AS deals_share_pct,
    ROUND(SUM(deal_value))                                           AS revenue,
    ROUND(100.0 * SUM(deal_value) / SUM(SUM(deal_value)) OVER (), 1) AS revenue_share_pct
FROM leads
WHERE status = 'Won'
GROUP BY deal_band
ORDER BY deal_band;


-- Q16. How much do we discount from the quote? (won deals, by source)
SELECT lead_source,
       ROUND(SUM(quoted_value)) AS quoted,
       ROUND(SUM(deal_value))   AS won_value,
       ROUND(100.0 * (1 - SUM(deal_value) / SUM(quoted_value)), 1) AS discount_from_quote_pct
FROM leads
WHERE status = 'Won'
GROUP BY lead_source
ORDER BY discount_from_quote_pct DESC;


-- Q17. Open pipeline: leads still in progress, with quoted value where a proposal was sent
SELECT lead_source,
       COUNT(*)                                       AS open_leads,
       COUNT(proposal_date)                           AS open_with_proposal,
       ROUND(SUM(quoted_value))                       AS quoted_value_open
FROM leads
WHERE status = 'Open'
GROUP BY lead_source
ORDER BY quoted_value_open DESC;
