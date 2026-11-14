-- Bank Marketing SQL queries (BankDB, table dbo.bank_data)

-- 1. Subscription rate by job
SELECT job,
       COUNT(*) AS customers,
       SUM(CASE WHEN deposit = 'yes' THEN 1 ELSE 0 END) AS subscribers,
       CAST(100.0 * SUM(CASE WHEN deposit = 'yes' THEN 1 ELSE 0 END) / COUNT(*) AS DECIMAL(5,1)) AS rate_pct
FROM dbo.bank_data
GROUP BY job
ORDER BY rate_pct DESC;

-- 2. Subscription rate by age group (CTE + CASE WHEN)
WITH grouped AS (
    SELECT
        CASE
            WHEN age < 30 THEN '18-29'
            WHEN age < 45 THEN '30-44'
            WHEN age < 60 THEN '45-59'
            ELSE '60+'
        END AS age_group,
        deposit
    FROM dbo.bank_data
)
SELECT
    age_group,
    COUNT(*) AS customers,
    CAST(100.0 * SUM(CASE WHEN deposit = 'yes' THEN 1 ELSE 0 END) / COUNT(*) AS DECIMAL(5,1)) AS rate_pct
FROM grouped
GROUP BY age_group
ORDER BY rate_pct DESC;

-- 3. Top 2 jobs per marital status (ROW_NUMBER + PARTITION BY)
WITH counts AS (
    SELECT marital, job, COUNT(*) AS customers
    FROM dbo.bank_data
    GROUP BY marital, job
),
ranked AS (
    SELECT marital, job, customers,
           ROW_NUMBER() OVER (PARTITION BY marital ORDER BY customers DESC) AS rn
    FROM counts
)
SELECT marital, job, customers, rn
FROM ranked
WHERE rn <= 2
ORDER BY marital, rn;

-- 4. Percent of total and running total by job (window functions)
WITH job_stats AS (
    SELECT job, COUNT(*) AS customers
    FROM dbo.bank_data
    GROUP BY job
)
SELECT
    job,
    customers,
    CAST(100.0 * customers / SUM(customers) OVER () AS DECIMAL(5,1)) AS pct_of_total,
    SUM(customers) OVER (ORDER BY customers DESC) AS running_total
FROM job_stats
ORDER BY customers DESC;

-- 5. Duplicate check on all 17 columns (returns no rows = no duplicates)
SELECT age, job, marital, education, [default], balance, housing, loan,
       contact, day, month, duration, campaign, pdays, previous, poutcome, deposit,
       COUNT(*) AS times_seen
FROM dbo.bank_data
GROUP BY age, job, marital, education, [default], balance, housing, loan,
         contact, day, month, duration, campaign, pdays, previous, poutcome, deposit
HAVING COUNT(*) > 1
ORDER BY times_seen DESC;

-- 6. Total rows vs duplicate rows (result: 11162 and 0)
SELECT
    COUNT(*) AS total_rows,
    COUNT(*) - (SELECT COUNT(*) FROM (SELECT DISTINCT * FROM dbo.bank_data) AS d) AS duplicate_rows
FROM dbo.bank_data;

-- 7. 2nd highest balance (result: 66653)
SELECT DISTINCT balance
FROM dbo.bank_data
ORDER BY balance DESC
OFFSET 1 ROWS FETCH NEXT 1 ROWS ONLY;

-- 8. 2nd highest balance using DENSE_RANK (handles ties)
WITH ranked AS (
    SELECT balance,
           DENSE_RANK() OVER (ORDER BY balance DESC) AS rnk
    FROM dbo.bank_data
)
SELECT DISTINCT balance
FROM ranked
WHERE rnk = 2;