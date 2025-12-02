# 🧑‍🤝‍🧑 SQL Case Study: Find Customer Referee
> **Category:** Data Filtering / NULL Handling  
> **Difficulty:** Easy  
> **Tags:** `SQL`, `Filtering`, `NULL logic`, `Three-Valued Logic`

## 1. Problem Description
**Goal:** Find the names of customers who were **NOT** referred by the customer with `id = 2`.

This includes:
1.  Customers referred by someone else (e.g., id 1, 3, etc.).
2.  Customers who were **not referred by anyone** (i.e., `referee_id` is NULL).

### Table `Customer`
| Column Name | Type | Description |
| :--- | :--- | :--- |
| `id` | int | Primary Key |
| `name` | varchar | Customer Name |
| `referee_id` | int | ID of the referrer (Nullable) |

### Example Input
| id | name | referee_id |
| :--- | :--- | :--- |
| 1 | Will | **NULL** |
| 2 | Jane | **NULL** |
| 3 | Alex | 2 |
| 4 | Bill | **NULL** |
| 5 | Zack | 1 |
| 6 | Mark | 2 |

### Expected Output
| name |
| :--- |
| Will |
| Jane |
| Bill |
| Zack |

**Explanation:**
* **Alex (3) & Mark (6):** `referee_id` is 2. (Exclude)
* **Zack (5):** `referee_id` is 1. (Keep: $1 \neq 2$)
* **Will, Jane, Bill:** `referee_id` is NULL. (Keep: They were not referred by 2).

---

## 💡 Thought Process

### 1. The Trap: "Not Equals"
The intuitive logic is to write `WHERE referee_id != 2`.
However, in SQL, **NULL is not a value**; it represents "Unknown".

* Comparison: `1 != 2` $\rightarrow$ **True**
* Comparison: `2 != 2` $\rightarrow$ **False**
* Comparison: `NULL != 2` $\rightarrow$ **Unknown**

Since the `WHERE` clause only keeps rows that result in **True**, the rows with `NULL` will be filtered out if we only check `!= 2`.

### 2. The Solution
We must explicitly tell the database to include the "Unknowns" (NULLs).
Logic: "Referrer is NOT 2" **OR** "Referrer does not exist".

---

## 2. Solutions & Implementation

### ✅ Approach 1: Explicit NULL Check (Standard)
This is the most standard and widely supported method.

```sql
SELECT 
    name
FROM 
    Customer
WHERE 
    referee_id != 2 
    OR 
    referee_id IS NULL;
```

### 🔹 Approach 2: Using COALESCE / IFNULL
We can convert `NULL` values to a dummy value (like 0) that is guaranteed not to be 2, and then compare.

```sql
SELECT 
    name
FROM 
    Customer
WHERE 
    COALESCE(referee_id, 0) <> 2;
```

---

## 3. ⚖️ Comparative Analysis

| Approach | Syntax | Readability | Pros & Cons |
| :--- | :--- | :--- | :--- |
| **1. OR IS NULL** | `!= OR IS NULL` | ⭐⭐⭐ High | **Best Practice.** Explicitly shows intent. Generally allows indexes to be used (depending on the engine). |
| **2. COALESCE** | `COALESCE(col, val)` | ⭐⭐ Medium | **Cleaner Syntax.** Good for quick queries. However, applying a function to a column (`COALESCE`) often prevents the database from using an index on that column (Non-SARGable), leading to slower performance on large tables. |

---

## 4. 🔍 Deep Dive: SQL Three-Valued Logic (3VL)

This problem illustrates the core difference between SQL and other programming languages.

In C++, Java, or Python:
* `null != 2` might return `true` or throw an exception.

In SQL:
* `NULL` means "Information Missing".
* Asking "Is the missing information not equal to 2?" results in "I don't know" (**NULL**).

| Value A | Operator | Value B | Result | Effect in WHERE |
| :--- | :--- | :--- | :--- | :--- |
| 1 | `!=` | 2 | **TRUE** | ✅ Keep |
| 2 | `!=` | 2 | **FALSE** | ❌ Discard |
| NULL | `!=` | 2 | **UNKNOWN** | ❌ Discard |
| NULL | `IS NULL` | - | **TRUE** | ✅ Keep |

**Takeaway:** Whenever you use inequality operators (`!=`, `<>`) on a nullable column, you **must** remember to handle `NULL` separately if you want to include those rows.

---

## 5. ⏱️ Time Complexity Analysis

Let $N$ be the number of customers.

| Phase | Operation | Complexity | Note |
| :--- | :--- | :--- | :--- |
| **1. Filtering** | `WHERE` | $O(N)$ | The database must scan rows to check the condition. |

* If an index exists on `referee_id`, Approach 1 (`OR IS NULL`) *might* use it, but since we are looking for inequality ("everything except 2"), the database often defaults to a Full Table Scan anyway because it has to fetch the majority of the table.
