# Data dictionary

The data is **simulated**. It mimics a CRM export from a freelance-marketplace software sales team. It was produced by `scripts/generate_crm_data.py` (fixed random seed 42, so it can be regenerated exactly) and contains no real company or client data.

## Files

| File | Rows | Description |
| --- | --- | --- |
| `data/crm_leads_raw.csv` | 2,060 | Raw export, deliberately messy: 60 duplicate rows, 23 spellings of 7 lead sources, 125 blank countries |
| `data/leads_clean.csv` | 2,000 | Output of `sql/01_clean_data.sql`: one row per lead, standardised, ready for Excel and Power BI |

## Columns

One row per lead. A blank in a stage-date column means the lead never reached that stage.

| Column | Type | Description |
| --- | --- | --- |
| lead_id | text | Unique lead identifier (`L0001` to `L2000`) |
| created_date | date | Day the lead was created (1 Jul 2025 to 30 Sep 2026) |
| lead_source | text | Channel the lead came from: Upwork, LinkedIn, Clutch, Fiverr, PPH (PeoplePerHour), Referral, Website |
| service_type | text | Web Development, Mobile App, Custom Software, UI/UX Design, Maintenance & Support |
| country | text | Client country; `Unknown` where it was blank in the raw file |
| company_size | text | Startup, SMB or Enterprise |
| sales_rep | text | Rep A to Rep D |
| qualified_date | date | Day the lead was qualified |
| proposal_date | date | Day a proposal was sent |
| negotiation_date | date | Day negotiation started |
| closed_date | date | Day the lead was won or lost; blank for open leads |
| status | text | `Won`, `Lost` or `Open` (still in progress) |
| quoted_value | number | Price in the proposal, USD; blank if no proposal was sent |
| deal_value | number | Final price of a won deal, USD; blank unless status is `Won` |

## Definitions used in the analysis

| Term | Definition |
| --- | --- |
| Win rate | Won / (Won + Lost). Open leads are excluded because they have not had the chance to close |
| Revenue | Sum of `deal_value` (won deals only) |
| Revenue per lead | Revenue divided by all leads from that source, won or not |
| Sales cycle | Days from `created_date` to `closed_date`, for won deals only |
| Discount from quote | 1 - (won deal value / quoted value), for won deals |

## Cleaning applied (`sql/01_clean_data.sql`)

| Problem in the raw file | Fix |
| --- | --- |
| 60 duplicate rows | Keep one row per `lead_id` (`ROW_NUMBER() OVER (PARTITION BY lead_id)`) |
| Source spelled 23 ways (`upwork`, `UPWORK `, `Clutch.co`, `PeoplePerHour`) | Map to 7 standard names |
| 125 blank countries | Set to `Unknown` |
| Empty text in date and value columns | Convert to real NULLs and numbers |
