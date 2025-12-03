# SQL Note: When to Use Subqueries

A **Subquery** (or nested query) is a query within another SQL query. Knowing when to use them is key to solving complex logic problems where a standard `JOIN` or `GROUP BY` is insufficient.

## 1. When Calculating "Part vs. Whole" (The Denominator Problem)
This is the most common scenario where `JOIN` cannot help you. When you need a static value (like a global total) to perform a calculation against a grouped value.

* **Scenario:** Calculate the percentage of users in a specific contest.
* **Why:** The main query is grouped by `contest_id`, but the denominator needs the count of *all* users (ungrouped).

```sql
SELECT 
    contest_id,
    -- Subquery used to get the global total independent of the group
    COUNT(user_id) * 100.0 / (SELECT COUNT(*) FROM Users) 
FROM Register
GROUP BY contest_id;
```

## 2. Filtering by Aggregated Data
You cannot use aggregate functions (like `AVG`, `MAX`, `SUM`) directly in a `WHERE` clause.

* **Scenario:** Find employees who earn *more than the average* salary.
* **Why:** The database must calculate the average *first* before it can compare individuals to it.

```sql
SELECT name, salary
FROM Employees
WHERE salary > (SELECT AVG(salary) FROM Employees);
-- WRONG: WHERE salary > AVG(salary)
```

## 3. Filtering Based on "Existence" (IN / EXISTS)
When you want to filter rows based on a list of values from another table, but you **do not need to display columns** from that other table.

* **Scenario:** Find users who have never rated a movie.
* **Why:** It is often semantically clearer than a `LEFT JOIN ... WHERE NULL`.

```sql
SELECT name 
FROM Users
WHERE user_id NOT IN (SELECT distinct user_id FROM MovieRating);
```

## 4. Creating a "Derived Table" (Subquery in FROM)
When you need to perform an aggregation *before* you can apply further logic or joins.

* **Scenario:** Find the maximum average salary across departments.
* **Why:** You first need to calculate the average per department (Step 1), and then find the max of those results (Step 2).

```sql
SELECT MAX(avg_salary)
FROM (
    -- Step 1: Calculate average per department
    SELECT department_id, AVG(salary) as avg_salary
    FROM Employees
    GROUP BY department_id
) as DeptAvg;
```

---

## Cheat Sheet: Subquery vs. JOIN

| Criteria | Subquery | JOIN |
| :--- | :--- | :--- |
| **Primary Goal** | Logic flow (Step A -> Step B), Filtering, or getting a single value. | Linking tables to retrieve **columns** from both. |
| **Performance** | Can be slower (especially "Correlated Subqueries" that run once per row). | Generally faster and better optimized by database engines. |
| **Readable?** | Great for "English-like" logic (e.g., "Where ID is in..."). | Great for visualizing data connections. |
| **Rule of Thumb**| Use when you need a **calculation** or a **filter condition**. | Use when you need to **display data** from multiple tables. |

## Pro Tip: Modern Alternative (CTE)
If your subquery is complex, hard to read, or used multiple times, use a **CTE (Common Table Expression)** with the `WITH` clause.

```sql
WITH TotalUsers AS (
    SELECT COUNT(*) as cnt FROM Users
)
SELECT 
    r.contest_id,
    COUNT(r.user_id) * 100.0 / (SELECT cnt FROM TotalUsers)
FROM Register r
GROUP BY r.contest_id;
```
