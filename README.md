# Global Retail: Financial Performance & Profitability Analysis

**Why hasn't revenue growth turned into profit growth?** An end-to-end analysis of margins, store operating costs and discounting for a 12-store global retailer (2023–2025), built with **Excel (Power Query), SQL (MySQL)** and, in the final phase, **Power BI**.

The short answer: **gross margin is not the problem.** It has held at about 37–38% in every category for three years. The profit gap comes from **store operating costs**, which in 2025 were more than twice the gross profit the stores generated, and from **discounting that is largely unmanaged** and does not lift volume.

---

## Table of Contents

1. [Business Context](#business-context)
2. [Key Findings](#key-findings)
3. [Repository Structure](#repository-structure)
4. [Data](#data)
5. [Methodology & Definitions](#methodology--definitions)
6. [SQL Scripts](#sql-scripts)
7. [Excel Workbook](#excel-workbook)
8. [How to Reproduce](#how-to-reproduce)
9. [Assumptions & Limitations](#assumptions--limitations)
10. [Recommendations](#recommendations)
11. [Project Status](#project-status)
12. [Tools & Author](#tools--author)

---

## Business Context

Global Retail's CFO is concerned that revenue growth over the last two years has not translated into proportional profit growth. The task is to look beneath top-line sales into cost and margin data, explain what is happening to profitability, and recommend where to focus to protect margin.

The analysis answers six business questions:

1. How has gross margin % trended over two years, overall and by product category?
2. Which stores or regions have the highest operating costs relative to revenue?
3. How much margin is given up to discounts and promotions, and is it paying off in volume?
4. Which categories are high-revenue but low-margin, and should pricing be revisited?
5. If the CFO needed to cut costs by 5% without touching headcount, where should they look first?
6. What would gross margin look like next year if current trends continue?

---

## Key Findings

All figures below come from the SQL scripts in [`/sql`](sql/) and match the Excel pivots.

### 1. Gross margin is stable, not eroding

| Year | Net Revenue | Gross Profit | Gross Margin % |
|------|------------:|-------------:|---------------:|
| 2023 | $4,288,801 | $1,619,024 | 37.75% |
| 2024 | $4,582,048 | $1,708,643 | 37.29% |
| 2025 | $4,246,540 | $1,595,778 | 37.58% |

- Revenue rose **6.8%** in 2024 and then fell **7.3%** in 2025. Margin moved by less than 0.5 percentage points throughout.
- Every category sits between **37.1% and 38.2%** in every year. The biggest single-year swing was Beauty & Personal Care (+1.14 pp in 2024), and it is a very small category.
- 2025 revenue fell most in **Home & Living (−15.1%)** and **Electronics (−5.4%)**.

### 2. Operating costs, not margin, drive the profit problem

| Year | Gross Profit | Operating Cost | Net Operating Profit | Net Operating Margin |
|------|-------------:|---------------:|---------------------:|---------------------:|
| 2024 | $1,708,643 | $3,718,953 | −$2,010,310 | −43.9% |
| 2025 | $1,595,778 | $3,711,862 | −$2,116,084 | −49.8% |

- Operating cost is flat (~$3.7M) while gross profit shrank, so operating cost was **2.33× gross profit** in 2025 (2.18× in 2024).
- **Only 2 of 12 stores** earned a positive net operating profit in 2025: **ST09** (+$121K) and **ST05** (+$2K, effectively break-even).
- Highest operating cost relative to revenue in 2025: **ST12 (268%)**, **ST10 (244%)**, **ST02 (206%)**, **ST03 (186%)**, **ST08 (158%)**. These five are classed as "structural under-utilization".
- By region (2025 operating cost ÷ revenue): **North America 149%**, **Southeast Asia 128%**, Europe 65%, West Africa 48%.
- **Rent is 54%** of total operating cost and labor 31%.

### 3. Discounts cost margin and do not buy volume

- Discounts cost about **4.3–4.6% of gross revenue** every year ($197K in 2025).
- Margin falls sharply with discount depth, while average quantity per sales line does not move:

| Discount band | Sales lines | Avg qty / line | Margin after discount |
|---------------|------------:|---------------:|----------------------:|
| 0% | 14,086 | 3.35 | 40.3% |
| 0–10% | 720 | 3.34 | 35.2% |
| 10–20% | 1,241 | 3.34 | 30.1% |
| 20%+ | 1,923 | 3.34 | **16.9%** |

- The **20%+ band alone is 70% of 2025 discount dollars** ($138.6K).
- **Measurement gap:** only **65 of the 130 logged promotions** show any realized discount in the sales data, and **96.5% of all discount value falls outside any logged promotion window**. Most discounting is happening off the promotional calendar.
- Where a discount was realized, promotion-period volume ran **+25% above the 30-day baseline**. Logged promotions with no realized discount ran 33% *below* baseline. Lift is an observational estimate, not a controlled test (see [Limitations](#assumptions--limitations)).

### 4. High-revenue, low-margin products (2025)

Four Electronics products sit in the top revenue quartile and the bottom margin quartile:

| Product | Revenue | Gross Margin |
|---------|--------:|-------------:|
| Voyager Air 13 Laptop | $293,911 | 36.0% |
| Lumen 55in 4K TV | $233,314 | 36.4% |
| Orbit S9 Mini | $176,486 | 36.4% |
| Zenith X200 Lite | $125,492 | 33.4% |

Bringing **all 31** below-benchmark products up to the company-wide 2025 margin (37.58%) is worth only about **$21K (0.5% of revenue)**. A pricing review is sensible, but it is not where the big money is.

### 5. A 5% cost cut without touching headcount

- 5% of 2025 operating cost = **$185,593**. Labor ($1.13M) is protected, which leaves $2.58M of non-labor cost, so the cut requires a **7.2% reduction in non-labor spend**.
- **Rent is 78% of non-labor cost** ($2.01M), followed by utilities (14%) and other costs (8%).
- A flat 5% cut to non-labor only would save $128.9K, or 3.5% of total cost. It does not reach the target.
- Recommended allocation: spread the cut pro-rata across the **10 loss-making stores** (protect ST05 and ST09), which is **8.26% of each store's non-labor cost**. The largest savings sit at **ST01 ($29.7K)**, **ST04 ($26.6K)**, **ST02 ($22.9K)** and **ST03 ($22.8K)**.
- Even a 5% cut only moves the company-level net operating loss from −$2.12M to −$1.93M. Cost cutting alone does not restore profitability.

### 6. 2026 gross margin forecast

- Linear trend on the three annual margins gives a **2026 forecast of 37.37%** (slope −0.09 pp per year), which is broadly stable.
- Gross profit in 2026 at that margin: **$1.51M / $1.59M / $1.67M** if revenue changes by −5% / 0% / +5%.
- Back-test (trend fitted on 2023–24 only): predicted 2025 at 36.83% against an actual 37.58%, an error of 0.75 pp. Treat the forecast as directional, since it rests on three data points.

---

## Repository Structure

```
global-retail-financial-performance/
├── README.md
├── data/
│   ├── raw/                  # Original case-study files (6 CSVs)
│   └── cleaned/              # Cleaned outputs used by SQL (6 CSVs)
├── excel/
│   └── Global_Retail_Financial_Performance.xlsx   # Phase 1: cleaning + pivots
├── sql/
│   ├── Data_Import_Script.sql
│   ├── 01_data_quality_checks.sql
│   ├── 02_gross_margin_analysis.sql
│   ├── 03_store_profitability.sql
│   ├── 04_promotion_effectiveness.sql
│   ├── 05_rolling_store_costs.sql
│   ├── 06_high_revenue_low_margin.sql
│   ├── 07_cost_reduction_scenario.sql
│   ├── 08_forecast.sql
│   └── 09_discount_band_analysis.sql
└── docs/
    └── project_brief.pdf     # Original project brief
```

---

## Data

| Table | Rows | Grain | Period |
|-------|-----:|-------|--------|
| `sales_cleaned` | 18,000 | One row per order line | Jan 2023 – Dec 2025 |
| `store_expenses` | 288 | Store × month (12 stores × 24 months) | Jan 2024 – Dec 2025 |
| `promotions` | 130 | One row per promotion | Jan 2024 – Nov 2025 |
| `dim_store` | 12 | Store (4 regions × 3 stores) | n/a |
| `dim_product` | 69 | Product (5 categories) | n/a |
| `dim_date` | 1,096 | Day | Jan 2023 – Dec 2025 |

**Regions:** North America, Europe, Southeast Asia, West Africa.
**Categories:** Electronics, Home & Living, Apparel, Beauty & Personal Care, Grocery.

### Cleaning performed in Phase 1 (Excel / Power Query)

| Step | Result |
|------|--------|
| Removed exact duplicate sales rows | 18,025 → 18,000 rows (25 removed) |
| Flagged missing unit prices | 30 rows kept and tagged `Price_Data_Quality_Flag = Missing`, then excluded from revenue and margin |
| Identified returns | 30 negative-quantity lines tagged `Transaction_Type = Return` and kept in totals |
| Reconciled store IDs | All 12 store IDs in `store_expenses` match `dim_store` |
| Added transaction-level measures | Gross revenue, discount value, net revenue, product cost, gross profit, gross margin % |
| Added expense measures | Operating cost, non-labor cost, rent share, labor share |
| Added promotion duration | `Promotion_Duration_Days` |

---

## Methodology & Definitions

| Metric | Definition |
|--------|------------|
| Net revenue | `quantity × unit_price × (1 − discount_pct)` |
| Gross profit | Net revenue − `quantity × unit_cost` (unit cost from `dim_product`) |
| Gross margin % | Gross profit ÷ net revenue |
| Operating cost | `rent + utilities + labor + other_costs` (store level) |
| Net operating profit | Gross profit − operating cost |
| Non-labor cost | `rent + utilities + other_costs` |
| Fiscal year | Calendar year (matches `dim_date.fiscal_period`) |
| Promotion baseline | Same product, all stores, the 30 days before the promotion starts |
| Observed lift | Promotion daily units ÷ baseline daily units − 1 |
| Pooled lift | Total promo daily units ÷ total baseline daily units − 1 (avoids one tiny baseline distorting an average of percentages) |
| Store economic zones | A: net operating margin ≥ 5% · B: within ±5% · C: negative margin but operating cost ≤ 150% of revenue · D: operating cost > 150% of revenue |

---

## SQL Scripts

Every script is commented, begins with `USE global_retail;` and can be re-run independently once the data is loaded.

| Script | Purpose | Business question |
|--------|---------|:-----------------:|
| `Data_Import_Script.sql` | Creates the `global_retail` database, tables, indexes and loads the cleaned CSVs | n/a |
| `01_data_quality_checks.sql` | Row counts, nulls, orphan keys, date ranges, revenue and cost reconciliation (all checks pass) | n/a |
| `02_gross_margin_analysis.sql` | Gross margin by year and category, with YoY revenue and margin change using `LAG()` | Q1 |
| `03_store_profitability.sql` | Store P&L by year, operating cost burden, economic zones, break-even revenue, cost composition | Q2 |
| `04_promotion_effectiveness.sql` | Promotion baseline vs lift, discount cost, overlap diagnostic, scorecard, measurement gap (CTEs) | Q3 |
| `05_rolling_store_costs.sql` | Rolling 3-month average operating cost per store (window functions) | Q2 / Q5 |
| `06_high_revenue_low_margin.sql` | Revenue and margin quartiles (`NTILE`) to flag high-revenue / low-margin products; margin-at-risk | Q4 |
| `07_cost_reduction_scenario.sql` | Cost structure, 5% cut scenarios, store-level allocation, cost-cut simulator | Q5 |
| `08_forecast.sql` | Linear-trend 2026 margin forecast, back-test, revenue scenarios | Q6 |
| `09_discount_band_analysis.sql` | Margin and quantity by discount depth, yearly discount leakage | Q3 |

**SQL techniques used:** CTEs, window functions (`LAG`, `NTILE`, rolling `AVG ... OVER`), conditional aggregation, correlated `EXISTS`, date-interval joins, `NULLIF` for safe division.

---

## Excel Workbook

`excel/Global_Retail_Financial_Performance.xlsx` holds the Phase 1 work.

| Sheet | Contents |
|-------|----------|
| `sales_transactions` | Raw sales data |
| `Sales_Cleaned` | Cleaned sales with per-transaction revenue, cost and margin |
| `store_expenses_cleaned` | Cleaned expenses with operating cost, non-labor cost and cost shares |
| `Sales_Store_Monthly` | Revenue and gross profit by store and month |
| `Store_Monthly_Financials` | Store-month revenue, gross profit, operating cost, net operating profit and margin |
| `promotions_clean`, `Promotions_baseline`, `Promotion_Performance` | Promotion dates, 30-day baselines, lift and discount cost per incremental unit |
| `dim_date_clean`, `dim_product_clean`, `dim_store_clean` | Cleaned dimension tables |
| `Sheet1`, `Sheet7` | Pivots: category performance by year, yearly performance, store performance, store operating cost burden |

---

## How to Reproduce

**Requirements:** MySQL 8.0+ (CTEs and window functions are required). MySQL Workbench is recommended.

1. **Clone the repo**
   ```bash
   git clone https://github.com/<your-username>/global-retail-financial-performance.git
   ```
2. **Edit the file paths** in `sql/Data_Import_Script.sql`. The six `LOAD DATA LOCAL INFILE` statements point to a folder on the original author's machine. Change each to the location of `data/cleaned/` on your computer (use forward slashes).
3. **Allow local file loading.** The script runs `SET GLOBAL local_infile = 1;`, which needs sufficient privileges. When connecting from the command line, add `--local-infile=1`. In Workbench, enable `OPT_LOCAL_INFILE=1` under the connection's *Advanced* tab.
4. **Run the import script**, then confirm the load.
   ```bash
   mysql -u <user> -p --local-infile=1 < sql/Data_Import_Script.sql
   ```
5. **Run the checks, then the analysis scripts in order**, `01` through `09`.
   ```bash
   for f in sql/0*.sql; do mysql -u <user> -p < "$f"; done
   ```
   Expected result of `01_data_quality_checks.sql`: all six row-count checks return `PASS`, revenue reconciliation difference is `0.00`, and there are zero unmatched keys.

The "Data truncated for column 'gross_margin_percentage'" notes shown during import are harmless. They come from rounding to the column's six decimal places.

---

## Assumptions & Limitations

**Assumptions**

- **No overhead allocation.** Operating costs are used exactly as recorded at store level. The dataset contains no shared or head-office cost pool, so nothing is allocated across stores.
- **Cost is the product master's `unit_cost`.** The sales file carries no cost column, so cost of goods is `quantity × dim_product.unit_cost`.
- **Missing prices excluded.** 30 sales lines with no `unit_price` are left out of revenue and margin calculations.
- **Returns included.** The 30 return lines (negative quantity) reduce revenue and gross profit.
- **Operating costs exist for 2024–2025 only,** so store profitability is assessed for those two years. 2023 is covered at gross-margin level.
- **Labor is protected** in the cost scenario, per the brief ("without touching headcount").

**Limitations**

- **Scale of the operating loss.** Under the data as provided, operating cost is 2.3× gross profit. If the 18,000-line sales file is a sample rather than the complete transaction record, store-level losses are overstated. Confirm the sales file's coverage against store expenses before presenting these figures as company results.
- **Promotion lift is observational.** It compares the 30 days before a promotion with the promotion window for the same product, with no control group. Seasonality and 14 overlapping promotions can distort individual results. The scorecard flags overlaps.
- **Promotion log and sales discounts do not line up.** Half of the logged promotions show no realized discount, and most discount value sits outside logged windows. Promotion-level ROI should be read with that in mind.
- **Quantity is per sales line,** not store traffic or basket count, so "no volume response" refers to units per line.
- **The forecast uses three annual data points.** It is a trend continuation, not a predictive model.

---

## Recommendations

1. **Treat cost structure, not gross margin, as the priority.** Margin is steady at ~37.5%; the loss comes from fixed store costs that revenue is not covering.
2. **Start the 5% cost cut with rent at ST01, ST04, ST02 and ST03.** Rent is 54% of all operating cost and 78% of the non-labor cost that can be cut. Protect the profitable stores (ST05, ST09).
3. **Review the five "structurally under-utilized" stores (ST02, ST03, ST08, ST10, ST12)**, where operating cost is 1.6–2.7× revenue. A cost cut will not fix these, so options include right-sizing space, consolidating, or a revenue recovery plan with a clear break-even target.
4. **Bring discounting under control.** Cap or require approval for discounts above 20%: they carry only a 16.9% margin, do not raise units per line, and total $138.6K, about three-quarters the size of the $185.6K cost-cut target. Log every discount against a promotion so it can be measured.
5. **Review pricing on the four flagged Electronics products,** treating it as a quick win worth about $21K rather than a turnaround lever.
6. **Plan 2026 on a flat ~37.4% gross margin** and focus on reversing the 2025 revenue decline in Home & Living and Electronics.

---

## Project Status

| Phase | Deliverable | Status |
|-------|-------------|--------|
| 1. Excel | Data cleaning, Power Query, exploratory pivots | Complete |
| 2. SQL | Nine commented, re-runnable query files | Complete |
| 3. Power BI | Star schema, DAX measures, dashboard, forecast visual | Not included in this repository yet |

---

## Tools & Author

**Tools:** Microsoft Excel (Power Query, PivotTables) · MySQL · Power BI

**Author:** Emmanuel O. Ogunniran, Statistics, Federal University of Technology, Minna (FUT Minna)

*This project uses a case-study dataset for a fictional retailer and is intended for portfolio and educational purposes.*
