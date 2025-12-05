# SQL Logical Execution Order & Clause Constraints Cheat Sheet

## 1. Execution Order vs. Coding Order
Understanding the **Logical Execution Order** is the key to understanding why certain functions (like Window Functions or Aliases) cannot be used in `WHERE` or `GROUP BY` clauses.

| Step | Coding Order (How you write it) | Logical Execution Order (How DB processes it) | What happens here? |
| :--- | :--- | :--- | :--- |
| 1 | `SELECT` | **FROM / JOIN** | Gather data source (Tables). |
| 2 | `FROM` | **WHERE** | Filter rows (Row-level). |
| 3 | `JOIN` | **GROUP BY** | Group rows into buckets. |
| 4 | `WHERE` | **HAVING** | Filter groups (Aggregate-level). |
| 5 | `GROUP BY` | **SELECT** | Calculate expressions & Window Functions. |
| 6 | `HAVING` | **DISTINCT** | Remove duplicates. |
| 7 | `ORDER BY` | **ORDER BY** | Sort the final result. |
| 8 | `LIMIT` | **LIMIT / TOP** | Restrict row count. |

---


## 2. SQL Constraints & Behaviors by Clause

Understanding the **Logical Execution Order** is the key to understanding these constraints:
> **FROM & JOIN** ➔ **WHERE** ➔ **GROUP BY** ➔ **HAVING** ➔ **SELECT** ➔ **DISTINCT** ➔ **ORDER BY** ➔ **LIMIT**

### A. FROM & JOIN Clause
*Determines the source tables and links data.*

| Type | Status | Note |
| :--- | :--- | :--- |
| **Subqueries / Derived Tables** | ✅ Allowed | Essential for pre-aggregating data before joining. |
| **Common Table Expressions (CTE)** | ✅ Allowed | Defined separately (`WITH ...`) but referenced here. |
| **Correlated Subqueries** | ✅ Allowed | Can reference columns from the outer query (Note: performance cost). |
| **Aggregate Functions** | ❌ **FORBIDDEN** | Cannot join directly on `SUM(col)`. Calculate it in a subquery first. |
| **Window Functions** | ❌ **FORBIDDEN** | Cannot join on `RANK()`. Calculate in a CTE/subquery first. |
| **Lateral Joins** | ⚠️ New Feature | Allowed in MySQL 8.0+ / Postgres (`LATERAL`). Allows joining a table to a subquery that references the table. |

### B. WHERE Clause
*Filters raw rows **before** grouping occurs.*

| Type | Status | Note |
| :--- | :--- | :--- |
| **Raw Columns** | ✅ Allowed | e.g., `WHERE age > 18` |
| **Scalar Functions** | ✅ Allowed | e.g., `WHERE YEAR(date) = 2023` |
| **Subqueries** | ✅ Allowed | e.g., `WHERE id IN (SELECT ...)` |
| **Aggregate Functions** | ❌ **FORBIDDEN** | Use `HAVING`. The database hasn't grouped the data yet to calculate a sum. |
| **Window Functions** | ❌ **FORBIDDEN** | Use a **CTE** or **Subquery** if you need to filter by rank/row_number. |
| **SELECT Aliases** | ❌ **FORBIDDEN** | The alias is defined *later* in the `SELECT` phase. |

### C. GROUP BY Clause
*Compresses rows into unique groups based on dimensions.*

| Type | Status | Note |
| :--- | :--- | :--- |
| **Raw Columns** | ✅ Allowed | Standard usage. |
| **Expressions** | ✅ Allowed | e.g., `GROUP BY YEAR(order_date)` |
| **Aggregate Functions** | ❌ **FORBIDDEN** | You cannot group by a sum of itself. |
| **Window Functions** | ❌ **FORBIDDEN** | Window functions operate *after* grouping. |
| **Aliases** | ⚠️ Varies | **MySQL/Postgres**: ✅ Allowed.<br>**SQL Server/Oracle**: ❌ Forbidden (must repeat the expression). |

### D. HAVING Clause
*Filters groups **after** aggregation.*

| Type | Status | Note |
| :--- | :--- | :--- |
| **Aggregate Functions** | ✅ **Main Usage** | e.g., `HAVING SUM(amount) > 1000` |
| **Grouping Columns** | ✅ Allowed | e.g., `HAVING user_id = 5` (Though usually better/faster in `WHERE`). |
| **Non-Grouped Columns** | ❌ **FORBIDDEN** | **Strict Mode (ONLY_FULL_GROUP_BY)**: You cannot reference a raw column (e.g., `email`) if it's not in `GROUP BY` and not wrapped in an aggregate (e.g., `MAX(email)`). |
| **Window Functions** | ❌ **FORBIDDEN** | Window functions are calculated in the next step (`SELECT`). |

### E. SELECT Clause
*Defines the final output columns and calculations.*

| Type | Status | Note |
| :--- | :--- | :--- |
| **Aggregate Functions** | ✅ Allowed | Requires `GROUP BY` unless aggregating the entire table. |
| **Window Functions** | ✅ Allowed | e.g., `RANK() OVER (PARTITION BY ...)` |
| **Scalar Functions** | ✅ Allowed | e.g., `UPPER(name)` |
| **Sibling Aliases** | ❌ **FORBIDDEN** | Cannot refer to an alias defined in the same `SELECT` line (e.g., `SELECT price * 2 AS new_price, new_price + 5`). |
| **Non-Aggregated Columns** | ⚠️ Restricted | In `GROUP BY` queries, only grouped columns are allowed (unless using loose MySQL modes). |

### F. ORDER BY Clause
*Sorts the final result set.*

| Type | Status | Note |
| :--- | :--- | :--- |
| **SELECT Aliases** | ✅ Allowed | Because `ORDER BY` runs after `SELECT`. |
| **Aggregate Functions** | ✅ Allowed | Sort by calculated totals (e.g., `ORDER BY COUNT(*) DESC`). |
| **Window Functions** | ✅ Allowed | Sort by window logic not shown in result. |
| **Hidden Columns** | ⚠️ **Conditional** | **Standard**: Allowed.<br>❌ **Exception**: If `SELECT DISTINCT` is used, you generally **cannot** sort by columns not present in the `SELECT` list. |

---

### G. Special Topic: NULL Behavior Across Clauses
*How `NULL` is treated differently depending on the context.*

| Clause / Context | Behavior | Explanation |
| :--- | :--- | :--- |
| **Comparison** | **Unknown** | `NULL = NULL` is False (Unknown). **Must use** `IS NULL` or `IS NOT NULL`. |
| **WHERE / HAVING** | **Filtered Out** | Rows where the condition evaluates to `NULL` (unknown) are dropped. |
| **GROUP BY** | **Grouped Together** | All `NULL` values are treated as a single, distinct group. |
| **ORDER BY** | **Varies** | **MySQL**: `NULL`s come first in ASC.<br>**Postgres**: `NULL`s come last in ASC (unless `NULLS FIRST` is specified).<br>**Oracle/SQL Server**: `NULL`s come last in ASC. |
| **Aggregates** | **Ignored** | `SUM(col)`, `AVG(col)`, `COUNT(col)` **ignore** NULLs.<br>⚠️ **Exception**: `COUNT(*)` counts rows with NULLs. |
| **DISTINCT** | **Single Row** | `SELECT DISTINCT col` returns only one `NULL` row, even if multiple exist. |

---

### H. Set Operators (UNION, INTERSECT, EXCEPT)
*Combines results from multiple SELECT statements.*

| Type | Status | Note |
| :--- | :--- | :--- |
| **Column Count** | ⚠️ **Strict** | All queries must have the same number of columns. |
| **Data Types** | ⚠️ **Strict** | Corresponding columns must have compatible data types. |
| **ORDER BY** | ⚠️ **Restricted** | Applies to the **final** combined result. (Use subqueries to sort individual parts). |
| **Duplicates** | **Removed** | `UNION` removes duplicates (slower); `UNION ALL` keeps them (faster). |

### I. LIMIT & OFFSET Constraints
*Restricts the number of returned rows.*

| Type | Status | Note |
| :--- | :--- | :--- |
| **Without ORDER BY** | ⚠️ **Unreliable** | Returns arbitrary rows. Always use `ORDER BY` with `LIMIT` for determinism. |
| **Large OFFSET** | ⚠️ **Slow** | `LIMIT 10 OFFSET 1000000` scans 1,000,010 rows and drops the first million. Use "Keyset Pagination" (e.g., `WHERE id > last_seen_id`) instead. |

---


### Key Takeaway on "DISTINCT vs ORDER BY"
If you use `SELECT DISTINCT name FROM users ORDER BY age`, most databases will throw an error:
> **Error:** For `SELECT DISTINCT`, ORDER BY expressions must appear in select list.

**Reason:** If there are two "John" rows, one aged 20 and one aged 50, the database compresses them into one "John". It does not know whether to sort "John" using 20 or 50.
