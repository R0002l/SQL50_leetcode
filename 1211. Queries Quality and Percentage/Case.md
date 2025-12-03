# 📊 SQL Case Study: Queries Quality and Percentage
> **Category:** Aggregation / Mathematical Logic  
> **Difficulty:** Easy  
> **Tags:** `SQL`, `GROUP BY`, `AVG`, `ROUND`, `Conditional Logic`

## 1. Problem Description
**Goal:** Calculate two specific metrics for each `query_name`:
1.  **Quality:** The average of the ratio `rating / position`.
2.  **Poor Query Percentage:** The percentage of queries where the `rating` is **less than 3**.

Both results must be rounded to **2 decimal places**.

### Table `Queries`
| Column Name | Type | Description |
| :--- | :--- | :--- |
| `query_name` | varchar | The search term used |
| `result` | varchar | The result returned |
| `position` | int | Position in search results (1-500) |
| `rating` | int | User rating (1-5) |

*(This table may contain duplicates and no primary key is specified).*

### Example Input
| query_name | result | position | rating |
| :--- | :--- | :--- | :--- |
| Dog | Golden | 1 | 5 |
| Dog | German | 2 | 5 |
| Dog | Mule | 200 | 1 |
| Cat | Shirazi | 5 | 2 |

### Expected Output
| query_name | quality | poor_query_percentage |
| :--- | :--- | :--- |
| Dog | 2.50 | 33.33 |
| Cat | 0.66 | ... |

**Explanation for "Dog":**
* **Quality:** Average of $(\frac{5}{1}, \frac{5}{2}, \frac{1}{200})$.
    * $(5 + 2.5 + 0.005) / 3 = 2.5016... \rightarrow 2.50$.
* **Poor %:** Ratings are $\{5, 5, 1\}$.
    * Number of ratings < 3: **1** (the rating '1').
    * Total queries: **3**.
    * Percentage: $(1/3) \times 100 = 33.33\%$.

---

## 💡 Thought Process

### 1. Grouping
We need stats per query name, so the skeleton is:
`GROUP BY query_name`.

### 2. Metric A: Quality
* Definition: `AVG(rating / position)`.
* Note: We calculate the ratio for *each row* first, then average those ratios. We do NOT calculate `AVG(rating) / AVG(position)` (that would be mathematically wrong).

### 3. Metric B: Poor Query Percentage
* Definition: $\frac{\text{Count of Bad Queries}}{\text{Total Count}} \times 100$.
* **The Trick:** How to count only specific rows inside a group?
    * **Method 1 (Standard):** `SUM(CASE WHEN rating < 3 THEN 1 ELSE 0 END)`
    * **Method 2 (Boolean Averaging):** In MySQL, `rating < 3` returns `1` (True) or `0` (False). If we take the `AVG()` of this boolean expression, we get the decimal percentage directly!
    * Example: Ratings [5, 5, 1]. Conditions: [False, False, True] $\rightarrow$ [0, 0, 1]. Average is $1/3 = 0.333$. Multiply by 100 to get $33.3\%$.

---

## 2. Solutions & Implementation

### ✅ Approach 1: Boolean Averaging (Concise & Efficient)
This is a very common idiom in MySQL for calculating percentages based on conditions.

```sql
SELECT 
    query_name, 
    ROUND(AVG(rating / position), 2) AS quality,
    ROUND(AVG(rating < 3) * 100, 2) AS poor_query_percentage
FROM 
    Queries
WHERE
    query_name IS NOT NULL -- Safety check to exclude null query names
GROUP BY 
    query_name;
```

### 🔹 Approach 2: Standard SQL (CASE WHEN)
If you are using PostgreSQL, SQL Server, or Oracle, boolean averaging might not work directly. This is the strictly standard ANSI SQL approach.

```sql
SELECT 
    query_name, 
    ROUND(AVG(rating / position), 2) AS quality,
    ROUND(
        SUM(CASE WHEN rating < 3 THEN 1 ELSE 0 END) * 100.0 / COUNT(*)
    , 2) AS poor_query_percentage
FROM 
    Queries
WHERE
    query_name IS NOT NULL
GROUP BY 
    query_name;
```

---

## 3. 🔍 Deep Dive

#### 1. Integer Division Trap
In Approach 2, notice I used `* 100.0` instead of `* 100`.
In some databases (like SQL Server), dividing an integer by an integer results in an integer (e.g., `1 / 3 = 0`). Multiplying by a float (`100.0`) forces the database to perform floating-point division, preserving the decimals.

#### 2. The Logic of `AVG(condition)`
* `rating < 3`: Generates a column of 1s and 0s.
* `AVG(...)`: Sums them up and divides by the total count.
* Result: The fraction of rows where the condition is true.
* `* 100`: Converts the fraction (0.33) to a percentage (33.0).

---

## 4. ⏱️ Time Complexity Analysis

Let $N$ be the number of rows in the `Queries` table.

| Phase | Operation | Complexity | Note |
| :--- | :--- | :--- | :--- |
| **1. Grouping** | `GROUP BY` | $O(N)$ | The database scans the table to aggregate rows by `query_name`. |
| **2. Calculations** | `AVG`, `SUM` | $O(N)$ | The math runs once per row during the aggregation scan. |

**Total Complexity:** $O(N)$.
