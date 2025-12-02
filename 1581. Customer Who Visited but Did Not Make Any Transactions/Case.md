# 🛍️ SQL Case Study: Customer Visits Without Transactions
> **Category:** Join Types / Filtering / Aggregation  
> **Difficulty:** Easy  
> **Tags:** `SQL`, `Left Join`, `IS NULL`, `NOT IN`, `NOT EXISTS`

## 1. Problem Description
**Goal:** Identify customers who visited the mall but did **not** make any transactions, and count how many times this happened.

We have two tables:
1.  `Visits`: Logs every visit a customer makes.
2.  `Transactions`: Logs transactions associated with specific visits.

We need to find rows in `Visits` that do **not** have a corresponding match in `Transactions`.

### Table `Visits`
| Column Name | Type | Description |
| :--- | :--- | :--- |
| `visit_id` | int | Primary Key |
| `customer_id` | int | ID of the customer |

### Table `Transactions`
| Column Name | Type | Description |
| :--- | :--- | :--- |
| `transaction_id` | int | Primary Key |
| `visit_id` | int | Foreign Key to Visits |
| `amount` | int | Transaction amount |

### Example Input
**Visits Table**
| visit_id | customer_id |
| :--- | :--- |
| 1 | 23 |
| 2 | 9 |
| 4 | 30 |
| 5 | 54 |
| 6 | 96 |
| 7 | 54 |
| 8 | 54 |

**Transactions Table**
| transaction_id | visit_id | amount |
| :--- | :--- | :--- |
| 2 | 5 | 310 |
| 3 | 5 | 300 |
| 9 | 5 | 200 |
| 12 | 1 | 910 |
| 13 | 2 | 970 |

### Expected Output
| customer_id | count_no_trans |
| :--- | :--- |
| 54 | 2 |
| 30 | 1 |
| 96 | 1 |

---

## 💡 Thought Process

### 1. The Logic: "Find What Is Missing"
This is a classic "Set Difference" problem. We have a set of All Visits ($A$) and a set of Visits with Transactions ($B$). We want $A - B$.

Common strategies for finding missing records:
1.  **LEFT JOIN + IS NULL:** Keep all visits, try to attach a transaction. If no transaction sticks, the transaction columns will be `NULL`.
2.  **NOT IN:** Select visits where the ID is not in the list of transaction visit IDs.
3.  **NOT EXISTS:** Select visits where a correlated subquery finds no transaction.

### 2. The Aggregation
Once we filter down to only the "Ghost Visits" (visits with no transaction), we simply `GROUP BY customer_id` and count the rows.

---

## 2. Solutions & Implementation

### ✅ Approach 1: LEFT JOIN (The Standard "Exclusion Join")
This is generally preferred for readability and performance in many SQL engines.

```sql
SELECT 
    v.customer_id, 
    COUNT(v.visit_id) AS count_no_trans
FROM 
    Visits v
LEFT JOIN 
    Transactions t ON v.visit_id = t.visit_id
WHERE 
    t.transaction_id IS NULL  -- The "Exclusion" Filter
GROUP BY 
    v.customer_id;
```

### 🔹 Approach 2: NOT IN (Subquery)
Logically intuitive ("Select ID where ID is not in this list"), but can be slower or problematic if the subquery returns NULLs.

```sql
SELECT 
    customer_id, 
    COUNT(visit_id) AS count_no_trans
FROM 
    Visits
WHERE 
    visit_id NOT IN (SELECT visit_id FROM Transactions)
GROUP BY 
    customer_id;
```

### 🔹 Approach 3: NOT EXISTS (Correlated Subquery)
Often the most performant on large datasets because it stops checking as soon as it finds a single match.

```sql
SELECT 
    customer_id, 
    COUNT(visit_id) AS count_no_trans
FROM 
    Visits v
WHERE 
    NOT EXISTS (
        SELECT 1 
        FROM Transactions t 
        WHERE t.visit_id = v.visit_id
    )
GROUP BY 
    customer_id;
```

---

## 3. ⚖️ Comparative Analysis

| Approach | Syntax | Performance | Pros & Cons |
| :--- | :--- | :--- | :--- |
| **1. LEFT JOIN** | `IS NULL` | ⭐⭐⭐ High | **Standard & Safe.** Most optimizers handle joins very efficiently. Safe against NULL values in the data. |
| **2. NOT IN** | `Subquery` | ⭐⭐ Medium | **Risky with NULLs.** If the subquery (`Transactions`) contains *any* NULL `visit_id`, the result will be empty (Zero rows). Performance can be worse on older engines. |
| **3. NOT EXISTS** | `Correlated` | ⭐⭐⭐ High | **Best for "Existence Checks".** Often faster than `LEFT JOIN` on huge datasets because it stops scanning as soon as the *first* match is found. |

---

## 4. 🔍 Deep Dive

#### 1. Why `t.transaction_id IS NULL`?
When you perform a `LEFT JOIN` from `Visits` to `Transactions`:
* If a match is found, `t.transaction_id` will have a value (e.g., 12).
* If **no match** is found, the database fills the columns for `Transactions` with `NULL`.
* Therefore, checking for `NULL` on the right-side table specifically targets the rows that failed to join.



#### 2. Count Logic
* We use `COUNT(v.visit_id)` or `COUNT(*)` **after** filtering.
* The `WHERE` clause runs **before** the `GROUP BY`. By the time we start counting, we have already thrown away the visits that resulted in a purchase.

---

## 5. ⏱️ Time Complexity Analysis

Let $V$ be the number of rows in `Visits` and $T$ be the number of rows in `Transactions`.

| Phase | Operation | Complexity | Note |
| :--- | :--- | :--- | :--- |
| **1. Joining / Filtering** | `LEFT JOIN` or `NOT EXISTS` | $O(V)$ or $O(V \log T)$ | Depends on indexing. If `visit_id` is indexed in `Transactions`, `NOT EXISTS` and `JOIN` are very fast. |
| **2. Aggregation** | `GROUP BY` | $O(V)$ | We group the remaining visits (at most $V$). |

**Total Complexity:** $O(V + T)$ (Assuming Hash Join) or $O(V \log T)$ (Assuming Index Lookup).
