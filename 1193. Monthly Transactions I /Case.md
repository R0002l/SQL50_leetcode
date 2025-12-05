# 📅 SQL Case Study: Monthly Transactions I
> **Category:** Aggregation / Date Handling  
> **Difficulty:** Medium  
> **Tags:** `SQL`, `GROUP BY`, `DATE_FORMAT`, `CASE WHEN`, `SUM IF`

## 1. Problem Description
**Goal:** Generate a monthly transaction report.

For each **month** and **country**, we need to calculate four specific metrics:
1.  **trans_count:** Total number of transactions.
2.  **approved_count:** Number of transactions where state is 'approved'.
3.  **trans_total_amount:** Total amount of all transactions.
4.  **approved_total_amount:** Total amount of 'approved' transactions.

### Table `Transactions`
| Column Name | Type | Description |
| :--- | :--- | :--- |
| `id` | int | Primary Key |
| `country` | varchar | Country Code (e.g., US, DE) |
| `state` | enum | 'approved' or 'declined' |
| `amount` | int | Transaction amount |
| `trans_date` | date | Date of transaction |

### Example Input
| id | country | state | amount | trans_date |
| :--- | :--- | :--- | :--- | :--- |
| 121 | US | **approved** | 1000 | **2018-12**-18 |
| 122 | US | declined | 2000 | **2018-12**-19 |
| 123 | US | **approved** | 2000 | **2019-01**-01 |
| 124 | DE | **approved** | 2000 | **2019-01**-07 |

### Expected Output
| month | country | trans_count | approved_count | trans_total_amount | approved_total_amount |
| :--- | :--- | :--- | :--- | :--- | :--- |
| 2018-12 | US | 2 | 1 | 3000 | 1000 |
| 2019-01 | US | 1 | 1 | 2000 | 2000 |
| 2019-01 | DE | 1 | 1 | 2000 | 2000 |

**Explanation:**
* **2018-12, US:**
    * Total rows: 2 (IDs 121, 122). $\rightarrow$ Count: 2, Amount: $1000+2000=3000$.
    * Approved: 1 (ID 121). $\rightarrow$ Count: 1, Amount: 1000.

---

## 💡 Thought Process

### 1. Grouping Strategy
The output requires one row per Month per Country.
* **Action:** `GROUP BY month, country`.
* **Date Handling:** The `trans_date` is a full date (YYYY-MM-DD), but we need just the month (YYYY-MM).
    * In MySQL: `DATE_FORMAT(trans_date, '%Y-%m')`.
    * Alternative: `LEFT(trans_date, 7)`.

### 2. Conditional Aggregation (The Core Challenge)
We need to calculate totals for "Everything" vs. "Approved Only" in the same query.
* **Total:** Simple `COUNT(id)` and `SUM(amount)`.
* **Approved Only:** We cannot use `WHERE state = 'approved'` because that would filter out the 'declined' transactions needed for the *Total* columns.
* **Solution:** Use `CASE WHEN` inside the aggregate function.
    * Count Approved: `SUM(CASE WHEN state = 'approved' THEN 1 ELSE 0 END)`
    * Sum Approved: `SUM(CASE WHEN state = 'approved' THEN amount ELSE 0 END)`

---

## 2. Solutions & Implementation

### ✅ Approach 1: DATE_FORMAT + CASE WHEN 
This is the most explicit and readable way to solve this.

```sql
SELECT 
    DATE_FORMAT(trans_date, '%Y-%m') AS month,
    country,
    COUNT(id) AS trans_count,
    SUM(CASE WHEN state = 'approved' THEN 1 ELSE 0 END) AS approved_count,
    SUM(amount) AS trans_total_amount,
    SUM(CASE WHEN state = 'approved' THEN amount ELSE 0 END) AS approved_total_amount
FROM 
    Transactions
GROUP BY 
    month, country; -- Note: Grouping by alias 'month' works in MySQL
```

### 🔹 Approach 2: LEFT() + IF() (Short Syntax)
If you prefer concise syntax (specific to MySQL), you can use `LEFT` for string manipulation and `IF` instead of `CASE`.

```sql
SELECT 
    LEFT(trans_date, 7) AS month,
    country,
    COUNT(id) AS trans_count,
    SUM(IF(state = 'approved', 1, 0)) AS approved_count,
    SUM(amount) AS trans_total_amount,
    SUM(IF(state = 'approved', amount, 0)) AS approved_total_amount
FROM 
    Transactions
GROUP BY 
    month, country;
```

---

## 3. ⚖️ Comparative Analysis

| Approach | Date Logic | Condition Logic | Pros & Cons |
| :--- | :--- | :--- | :--- |
| **1. DATE_FORMAT / CASE** | `DATE_FORMAT` | `CASE WHEN` | ⭐⭐⭐ **High Portability.** `CASE WHEN` is standard SQL. Easier to maintain if logic gets complex. |
| **2. LEFT / IF** | `LEFT(str, 7)` | `IF(cond, val, val)` | ⭐⭐ **Concise.** Faster to write, but `IF` is MySQL specific. `LEFT` assumes the date format never changes (strings). |

---

## 4. 🔍 Deep Dive

#### 1. Why `SUM` for counting?
When calculating `approved_count`, why do we use `SUM(...)` instead of `COUNT(...)`?
* **`SUM(CASE ... THEN 1 ELSE 0 END)`**: We add 1 for every approved row and 0 for declined. Result is the count of approved.
* **`COUNT(CASE ... THEN 1 ELSE NULL END)`**: This also works! `COUNT` ignores NULLs.
* *Common Mistake:* `COUNT(CASE ... THEN 1 ELSE 0 END)`. Since `COUNT` counts *non-null values*, and 0 is not null, this would count *every* row, returning the same result as total transactions.

#### 2. Group By Alias
In standard SQL execution order, `SELECT` happens *after* `GROUP BY`. Therefore, you usually cannot use the alias `month` in the `GROUP BY` clause (you'd have to repeat `DATE_FORMAT(...)`). However, MySQL and PostgreSQL allow using the alias for convenience.

---

## 5. ⏱️ Time Complexity Analysis

Let $N$ be the number of rows in the `Transactions` table.

| Phase | Operation | Complexity | Note |
| :--- | :--- | :--- | :--- |
| **1. Formatting** | Date conversion | $O(N)$ | Runs on every row. |
| **2. Grouping** | `GROUP BY` | $O(N)$ | The database scans and hashes/sorts rows into (Month, Country) buckets. |
| **3. Aggregation** | `SUM/COUNT` | $O(N)$ | Calculations happen during the scan. |

**Total Complexity:** $O(N)$.
