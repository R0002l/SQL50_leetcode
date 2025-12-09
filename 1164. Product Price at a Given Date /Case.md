# 🏷️ SQL Case Study: Product Price at a Given Date
> **Category:** Logic / Subqueries / Union  
> **Difficulty:** Medium  
> **Tags:** `SQL`, `Tuple Filtering`, `MAX()`, `UNION`, `Default Value Logic`

## 1. Problem Description
**Goal:** Find the price of all products on a specific date: **2019-08-16**.

**Rules:**
1.  **Price Change:** The table records when a price *changed*.
2.  **Current Price Logic:** For any given date, the price is the value of the **latest** change that occurred on or before that date.
3.  **Default Price:** If a product has no price changes on or before the target date, its price is **10**.

### Table `Products`
| Column Name | Type | Description |
| :--- | :--- | :--- |
| `product_id` | int | Product ID |
| `new_price` | int | The new price value |
| `change_date` | date | The date the price changed |

*(product_id, change_date) is the Primary Key.*

### Example Input
**Target Date:** 2019-08-16

| product_id | new_price | change_date | Analysis |
| :--- | :--- | :--- | :--- |
| 1 | 20 | 2019-08-14 | Before target. Candidate. |
| 1 | 30 | 2019-08-15 | Before target. Candidate. |
| 1 | 35 | **2019-08-16** | **Latest on/before target.** Price is **35**. |
| 2 | 50 | **2019-08-14** | **Latest on/before target.** Price is **50**. |
| 2 | 65 | 2019-08-17 | After target. Ignore. |
| 3 | 20 | 2019-08-18 | After target. No valid records. Price is **10**. |

### Expected Output
| product_id | price |
| :--- | :--- |
| 2 | 50 |
| 1 | 35 |
| 3 | 10 |

---

## 💡 Thought Process

### 1. Two Scenarios
We need to handle two groups of products separately:
* **Group A (Has History):** Products that have at least one price change on or before `2019-08-16`. For these, we find the entry with the `MAX(change_date)`.
* **Group B (No History):** Products that have *only* future changes (or no changes at all). For these, we hardcode the price to **10**.

### 2. Strategy: Divide and Conquer (UNION)
It is often messy to handle "Find Max Date" and "Default to 10" in a single complex query. A cleaner approach is:
1.  **Query 1:** Get prices for Group A.
    * Filter `date <= '2019-08-16'`.
    * Find `(product_id, MAX(change_date))`.
    * Retrieve the price.
2.  **Query 2:** Get prices for Group B.
    * Find distinct `product_id`s that are NOT in Query 1.
    * Set price = 10.
3.  **Combine:** `UNION ALL`.

---

## 2. Solutions & Implementation

### ✅ Approach 1: Tuple Filtering + UNION (Standard)
This separates the logic clearly into "Products with valid dates" and "Products needing defaults".

```sql
-- Part 1: Products that have a price change on or before 2019-08-16
SELECT 
    product_id, 
    new_price AS price
FROM 
    Products
WHERE 
    (product_id, change_date) IN (
        SELECT 
            product_id, 
            MAX(change_date) 
        FROM 
            Products 
        WHERE 
            change_date <= '2019-08-16'
        GROUP BY 
            product_id
    )

UNION

-- Part 2: Products that have NO price change on or before 2019-08-16 (Default 10)
SELECT 
    product_id, 
    10 AS price
FROM 
    Products
GROUP BY 
    product_id
HAVING 
    MIN(change_date) > '2019-08-16';
```

### 🔹 Approach 2: Window Functions (ROW_NUMBER + LEFT JOIN)
This approach avoids `UNION`. We first rank the valid prices to find the latest one for each product, and then `RIGHT JOIN` (or `LEFT JOIN` from a list of all products) to ensure products with no history get the default price of 10.

```sql
WITH LatestChanges AS (
    -- Step 1: Find the latest price change on or before the target date
    SELECT 
        product_id, 
        new_price,
        ROW_NUMBER() OVER(PARTITION BY product_id ORDER BY change_date DESC) as rn
    FROM 
        Products
    WHERE 
        change_date <= '2019-08-16'
)
SELECT 
    p.product_id,
    IFNULL(lc.new_price, 10) AS price
FROM 
    (SELECT DISTINCT product_id FROM Products) p -- Get master list of all products
LEFT JOIN 
    LatestChanges lc 
    ON p.product_id = lc.product_id AND lc.rn = 1;


--Logic Explanation:LatestChanges CTE: Filters for dates <= 2019-08-16.
--It assigns rn=1 to the most recent change (ORDER BY change_date DESC).
--Master List p: We select DISTINCT product_id to ensure we have every product, even those excluded by the date filter in the CTE.
--LEFT JOIN & IFNULL: We join the master list with the latest prices.
--If a product has no match (meaning all its changes are in the future), lc.new_price is NULL, so IFNULL converts it to 10.
```
---


## 3. ⚖️ Comparative Analysis

| Approach | Logic | Readability | Pros & Cons |
| :--- | :--- | :--- | :--- |
| **1. UNION** | Separate "Has Change" vs "No Change" | ⭐⭐⭐ High | **Best for Interviews.** Shows you understand that the dataset is composed of two different logical groups. |
| **2. LEFT JOIN** | Join Unique IDs to Max Dates | ⭐⭐ Medium | **More Compact.** You select `DISTINCT product_id`, then `LEFT JOIN` the subquery of max dates. If null, use 10. Can be slightly slower due to distinct scans. |


---

## 4. 🔍 Deep Dive

#### 1. Why `MIN(change_date) > '2019-08-16'`?
In the second part of the query, we need products where *all* their price changes happened in the future.
* If `MIN(change_date) > Target`, it implies **every** change date is after the target.
* Therefore, valid history before the target is empty.
* Therefore, the price is 10.

#### 2. The Tuple `IN` Trick
`WHERE (product_id, change_date) IN (...)` is extremely powerful for "Groupwise Max" problems. It ensures we grab the exact row corresponding to the latest date. Without this, we might accidentally grab the wrong price if we just grouped by ID.

---

## 5. ⏱️ Time Complexity Analysis

Let $N$ be the number of rows in the `Products` table.

| Phase | Operation | Complexity | Note |
| :--- | :--- | :--- | :--- |
| **1. Subquery** | `GROUP BY` | $O(N)$ | Finds the latest date for relevant products. |
| **2. Filtering** | `IN (...)` | $O(N \log N)$ | Lookups against the subquery result. |
| **3. Second Query** | `GROUP BY` | $O(N)$ | Finds products with only future dates. |

**Total Complexity:** $O(N \log N)$.
