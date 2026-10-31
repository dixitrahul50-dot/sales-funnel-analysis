# Dashboard

Place `Sales_Funnel_Dashboard.pbix` in this folder.

**To open it:** install [Power BI Desktop](https://powerbi.microsoft.com/desktop/) (free, Windows) and double-click the file. The data is stored inside the file, so no connection is needed.

## What the report shows

**Page 1: Overview**

| Visual | Question it answers |
| --- | --- |
| KPI cards: Total Leads, Win Rate, Revenue, Avg Deal Value, Avg Sales Cycle (Days) | How is the pipeline performing overall? |
| Funnel (Leads, Qualified, Proposal, Negotiation, Won) | At which step are leads lost? |
| Revenue by lead source (bar) | Which sources produce the revenue? |
| Revenue by month (line) | How does revenue move over time? |
| Slicers: country, service type, company size | Does the picture change for a segment? |

**Page 2: Lead Source Scorecard**

| Visual | Question it answers |
| --- | --- |
| Table: leads, win rate, avg deal, sales cycle, revenue, revenue per lead by source | How do the sources compare side by side? |
| Revenue per lead by source (bar) | Which sources are worth the effort per lead? |
| Bubble chart: win rate (x), avg deal value (y), leads (size) | Which sources win often and win big? |

The measures behind every visual are in `dax/measures.dax`, each with the value it should return so you can check the report against the SQL results.
