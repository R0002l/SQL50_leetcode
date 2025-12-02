# 🏷️ SQL Case Study: Average Selling Price
> **Category:** Data Aggregation / Date Logic  
> **Difficulty:** Easy  
> **Tags:** `SQL`, `Left Join`, `Date Range`, `Weighted Average`, `Math in SQL`

## 1. Problem Description
**Goal:** Calculate the **average selling price** for each product.

**Critical Rules:**
1.  The average selling price is **weighted** by units sold. It is NOT a simple average of the price column.
2.  Prices vary depending on the `start_date` and `end_date`. You must match the sale date to the correct price period.
3.  **Edge Case:** If a product has no sales, the average price should be **0** (not `NULL`).
4.  Result must be rounded to 2 decimal places.

### Table `Prices`
| Column Name | Type | Description |
| :--- | :--- | :--- |
| `product_id` | int | ID of the product |
| `start_date` | date | Start of the pricing period |
| `end_date` | date | End of the pricing period |
| `price` | int | Price during this period |

*(product_id, start_date, end_date) is the Primary Key.*

### Table `UnitsSold`
| Column Name | Type | Description |
| :--- | :--- | :--- |
| `product_id` | int | ID of the product |
| `purchase_date` | date | Date the units were sold |
| `units` | int | Number of units sold |

### Example Input
**Prices:** Product 1 was $5 (Feb 17-28) and $20 (Mar 1-22).
**UnitsSold:** Product 1 sold 100 units on Feb 25 and 15 units on Mar 1.

### Expected Output
| product_id | average_price |
| :--- | :--- |
| 1 | 6.96 |
| 2 | 16.96 |

**Explanation for Product 1:**
* **Sale 1:** Feb 25 falls in the $5 period. Total = $100 \times 5 = 500$
* **Sale 2:** Mar 1 falls in the $20 period. Total = $15 \times 20 = 300$
* **Total Revenue:** $500 + 300 = 800$
* **Total Units:** $100 + 15 = 115$
* **Average:** $800 / 115 = 6.9565... \approx 6.96$

---

## 💡 Thought Process

### 1. The Logic Challenge: "Bucketing" Sales
The core difficulty is that `Prices` and `UnitsSold` do not share a simple foreign key for the specific *transaction*. We only have `product_id`.
We need to figure out which price applies to a specific `purchase_date`.

* **Logic:** A sale belongs to a price record IF:
    1.  IDs match.
    2.  `purchase_date` is **between** `start_date` and `end_date`.

### 2. The Math Challenge: Weighted Average
A common mistake is `AVG(price)`. This is wrong.
* **Simple Average:** $(5 + 20) / 2 = 12.5$ (Incorrect)
* **Weighted Average:** $\frac{\sum(Price \times Units)}{\sum(Units)}$ (Correct)

### 3. The Null Challenge
The problem states: "If a product does not have any sold units... assumed to be 0."
* If we use `LEFT JOIN` (Prices $\to$ UnitsSold), products with no sales will have `NULL` units.
* Dividing by NULL results in NULL.
* We must use `IFNULL()` or `COALESCE()` to convert the final result to 0.

---

## 2. Solutions & Implementation

### ✅ Approach: Left Join on Date Range
This approach ensures we keep all products (even those with no sales) and matches the correct price period.

```sql
SELECT 
    p.product_id,
    IFNULL(
        ROUND(SUM(p.price * u.units) / SUM(u.units), 2),
        0
    ) AS average_price
FROM 
    Prices p
LEFT JOIN 
    UnitsSold u 
    ON p.product_id = u.product_id 
    AND u.purchase_date BETWEEN p.start_date AND p.end_date
GROUP BY 
    p.product_id;
```

---

## 3. 🔍 Deep Dive

#### 1. Join Condition Analysis (`BETWEEN`)
Usually, we join tables using equality (`=`). However, here we use a **Non-Equi Join** for the date.
* `ON p.product_id = u.product_id`: Ensures we look at the right product.
* `AND u.purchase_date BETWEEN p.start_date AND p.end_date`: Ensures we grab the price that was active *at that specific moment*.

#### 2. Why `LEFT JOIN`?
If we used `INNER JOIN`, a product listed in the `Prices` table but never sold (no entry in `UnitsSold`) would disappear from the result. The requirement implies we need to calculate prices for *each product*, defaulting to 0 if unsold. Therefore, `Prices` (the master list of potential products) must be on the **Left**.

#### 3. Handling the Division by Zero / Null
If a product has no sales:
* `u.units` is `NULL`.
* `SUM(u.units)` is `NULL`.
* Mathematical Result: `NULL / NULL` = `NULL`.
* Requirement: Return `0`.
* **Solution:** Wrap the entire calculation in `IFNULL(..., 0)`.

---

## 4. ⏱️ Time Complexity Analysis

Let:
* $P$ = Rows in Prices table
* $U$ = Rows in UnitsSold table

| Phase | Operation | Complexity | Note |
| :--- | :--- | :--- | :--- |
| **1. Joining** | `Range Join` | $O(P \times U)$ (Worst Case) | Without indexes, the DB compares every sale date against every price range for that product ID. |
| **2. Aggregation** | `GROUP BY` | $O(U)$ | We aggregate the joined result set. |

**Optimization Note:**
If an index exists on `(product_id, start_date, end_date)` in the Prices table, the database can perform an efficient range scan, bringing the join complexity much closer to $O(U \log P)$.
