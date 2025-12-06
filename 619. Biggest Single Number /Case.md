# 🔢 SQL Case Study: Biggest Single Number
> **Category:** Aggregation / Subqueries / NULL Handling  
> **Difficulty:** Easy  
> **Tags:** `SQL`, `GROUP BY`, `HAVING`, `MAX`, `Handling Empty Sets`

## 1. Problem Description
**Goal:** Find the **largest** number that appears **only once** in the `MyNumbers` table.

**Critical Edge Case:** If no number appears exactly once (i.e., all numbers are duplicates), the query must return `null`.

### Table `MyNumbers`
| Column Name | Type | Description |
| :--- | :--- | :--- |
| `num` | int | An integer value |

*(This table may contain duplicates. No Primary Key).*

### Example Input
**Example 1:**
| num | Note |
| :--- | :--- |
| 8 | Duplicate |
| 8 | Duplicate |
| 3 | Duplicate |
| 3 | Duplicate |
| **1** | **Single** |
| **4** | **Single** |
| **5** | **Single** |
| **6** | **Single** |

**Example 2:**
| num | Note |
| :--- | :--- |
| 8 | Duplicate |
| 8 | Duplicate |
| 7 | Duplicate |
| 7 | Duplicate |

### Expected Output
**Example 1:**
| num |
| :--- |
| 6 |
*(Single numbers are 1, 4, 5, 6. The largest is 6).*

**Example 2:**
| num |
| :--- |
| null |
*(No single numbers exist. Return NULL).*

---

## 💡 Thought Process

### 1. Identify "Single Numbers"
First, we need to isolate the numbers that appear exactly once.
* **Logic:** Group by the number and count occurrences.
* **Filter:** `HAVING COUNT(num) = 1`.

### 2. Find the Largest
From the list of single numbers, we need the maximum value.
* **Logic:** `MAX(num)`.

### 3. The "NULL" Trap (Crucial)
If we just used `ORDER BY num DESC LIMIT 1`, and the list was empty (Example 2), the database would return **0 rows** (an empty table).
* **Requirement:** The problem asks to "report null" (a table with 1 row containing NULL).
* **Solution:** Aggregate functions like `MAX()` return `NULL` when applied to an empty dataset. Therefore, using `SELECT MAX(...)` is safer than `ORDER BY ... LIMIT 1` here.

---

## 2. Solutions & Implementation

### ✅ Approach 1: Subquery with MAX() (Best Practice)
This approach naturally handles the empty set problem.

```sql
SELECT 
    MAX(num) AS num
FROM (
    -- Step 1: Find all numbers that appear exactly once
    SELECT 
        num 
    FROM 
        MyNumbers
    GROUP BY 
        num
    HAVING 
        COUNT(num) = 1
) AS unique_numbers;
```

---

## 3. ⚖️ Comparative Analysis

| Approach | Query | Result on Empty Set | Correct? |
| :--- | :--- | :--- | :--- |
| **1. MAX()** | `SELECT MAX(num) FROM (...)` | `| num  |`<br>`| null |` | ✅ **Yes.** Matches requirement. |
| **2. ORDER BY** | `SELECT num FROM (...) ORDER BY num DESC LIMIT 1` | `| num  |`<br>`(Empty)` | ❌ **No.** Returns zero rows. |

---

## 4. 🔍 Deep Dive

#### 1. Why `MAX()` returns NULL?
In SQL standard behavior, if you perform an aggregation function on an empty result set (and there is no `GROUP BY` clause in the outer query), it returns a single row with a `NULL` value.
* The inner subquery returns nothing (0 rows).
* The outer query asks for the `MAX()` of "nothing".
* The result is `NULL`.

#### 2. Alternative using `IFNULL` (If using Sorting)
If you insisted on using `ORDER BY`, you would have to wrap the entire query in another layer to force a NULL result, which is much more verbose:
```sql
SELECT (
    SELECT num 
    FROM MyNumbers 
    GROUP BY num 
    HAVING COUNT(num) = 1 
    ORDER BY num DESC 
    LIMIT 1
) AS num;
```
*Because a scalar subquery that returns no rows evaluates to NULL.*

---

## 5. ⏱️ Time Complexity Analysis

Let $N$ be the number of rows in `MyNumbers`.

| Phase | Operation | Complexity | Note |
| :--- | :--- | :--- | :--- |
| **1. Grouping** | `GROUP BY` | $O(N)$ | Scans table to count frequencies. |
| **2. Aggregation** | `MAX` | $O(M)$ | Where $M$ is the number of unique single numbers. |

**Total Complexity:** $O(N)$.
