# 🥗 SQL Case Study: Recyclable and Low Fat Products
> **Category:** Data Filtering / Basic Syntax  
> **Difficulty:** Easy  
> **Tags:** `SQL`, `WHERE Clause`, `AND Operator`, `ENUM`

## 1. Problem Description
**Goal:** Find the IDs of products that meet **two simultaneous conditions**:
1.  The product is **low fat** (`low_fats = 'Y'`).
2.  The product is **recyclable** (`recyclable = 'Y'`).

### Table `Products`
| Column Name | Type | Description |
| :--- | :--- | :--- |
| `product_id` | int | Primary Key |
| `low_fats` | enum | 'Y' (Yes) or 'N' (No) |
| `recyclable` | enum | 'Y' (Yes) or 'N' (No) |

### Example Input
| product_id | low_fats | recyclable |
| :--- | :--- | :--- |
| 0 | Y | N |
| 1 | **Y** | **Y** |
| 2 | N | Y |
| 3 | **Y** | **Y** |
| 4 | N | N |

### Expected Output
| product_id |
| :--- |
| 1 |
| 3 |

**Explanation:**
* **Product 0:** Low fat, but not recyclable. (Fail)
* **Product 1:** Low fat AND recyclable. (Pass)
* **Product 2:** Recyclable, but not low fat. (Fail)
* **Product 3:** Low fat AND recyclable. (Pass)

---

## 💡 Thought Process

### 1. The Logic: Intersection (AND)
We are looking for rows that satisfy **Condition A** AND **Condition B** at the same time.
* In Logic: $A \land B$
* In SQL: The `AND` operator.

### 2. Handling ENUMs
The problem states the columns are `ENUM` type with values 'Y' and 'N'. In SQL queries, we treat these exactly like strings. We must wrap the values in quotes (e.g., `'Y'`).

---

## 2. Solutions & Implementation

### ✅ Approach 1: Standard Filtering (The Direct Way)
This is the most common and readable way to write this query.

```sql
SELECT 
    product_id
FROM 
    Products
WHERE 
    low_fats = 'Y' 
    AND 
    recyclable = 'Y';
```

### 🔹 Approach 2: Tuple Comparison (The Concise Way)
SQL allows us to compare multiple columns at once using tuples (row constructors). This is syntactic sugar that effectively does the same thing as `AND`.

```sql
SELECT 
    product_id
FROM 
    Products
WHERE 
    (low_fats, recyclable) = ('Y', 'Y');
```

---

## 3. ⚖️ Comparative Analysis

| Approach | Syntax | Readability | Pros & Cons |
| :--- | :--- | :--- | :--- |
| **1. Standard `AND`** | `col1 = val AND col2 = val` | ⭐⭐⭐ High | **Best Practice.** Universally supported by all SQL databases. Easy to debug and extend (e.g., adding a third condition). |
| **2. Tuple Comparison** | `(col1, col2) = (v1, v2)` | ⭐⭐ Medium | **More Concise.** Great for checking exact matches on multiple columns. However, not all older database versions support this syntax, and it's less flexible if you need mix operators (e.g., one `=` and one `>`). |

---

## 4. 🔍 Deep Dive

#### 1. ENUM Data Types
Under the hood, `ENUM` types in databases like MySQL are often stored as **Integers** (1, 2, 3...) to save space, but mapped to strings for display.
* `'Y'` might be stored as `1`.
* `'N'` might be stored as `2`.
Comparing `low_fats = 'Y'` is very fast because the database is essentially comparing small integers.

#### 2. Indexing Strategy
If this query is run frequently on a massive table (millions of products), how do we make it fast?
* **Single Index:** An index on `low_fats` alone is not very effective because roughly 50% of the table might be 'Y' (low selectivity).
* **Composite Index:** The best index would be on `(low_fats, recyclable)`. This allows the database to jump directly to the list of IDs where both are 'Y', skipping the rest of the table entirely.

---

## 5. ⏱️ Time Complexity Analysis

Let $N$ be the number of rows in the `Products` table.

| Phase | Operation | Complexity | Note |
| :--- | :--- | :--- | :--- |
| **1. Filtering** | `WHERE ... AND ...` | $O(N)$ | Without an index, the database performs a **Full Table Scan**, checking every row. |
| **2. Filtering** | With Composite Index | $O(\log N + K)$ | If indexed, it navigates the B-Tree to find the first ('Y', 'Y') entry and reads the $K$ matches. |

**Space Complexity:** $O(1)$ (No extra memory needed for sorting or hashing).
