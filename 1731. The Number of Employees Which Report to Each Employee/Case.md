# 👔 SQL Case Study: The Number of Employees Which Report to Each Manager
> **Category:** Self-Join / Aggregation  
> **Difficulty:** Medium  
> **Tags:** `SQL`, `Self-Join`, `Group By`, `ROUND`, `Average`

## 1. Problem Description
**Goal:** Identify managers and calculate two metrics for them:
1.  The number of employees who report **directly** to them.
2.  The **average age** of these direct reports (rounded to the nearest integer).

A "Manager" is defined as an employee who has at least 1 person reporting to them.

### Table `Employees`
| Column Name | Type | Description |
| :--- | :--- | :--- |
| `employee_id` | int | Primary Key |
| `name` | varchar | Employee Name |
| `reports_to` | int | ID of the manager (Nullable) |
| `age` | int | Age of the employee |

### Example Input
| employee_id | name | reports_to | age |
| :--- | :--- | :--- | :--- |
| 9 | Hercy | null | 43 |
| 6 | Alice | **9** | 41 |
| 4 | Bob | **9** | 36 |
| 2 | Winston | null | 37 |

### Expected Output
| employee_id | name | reports_count | average_age |
| :--- | :--- | :--- | :--- |
| 9 | Hercy | 2 | 39 |

**Explanation:**
* **Hercy (9)** is listed as the `reports_to` for Alice and Bob.
* **Count:** 2 reports.
* **Average Age:** $(41 + 36) / 2 = 38.5$. Rounded to nearest integer $\rightarrow$ **39**.
* Winston has no one reporting to him, so he is excluded.

---

## 💡 Thought Process

### 1. The Data Structure: One Table, Two Roles
We need to compare employees with their managers, but they exist in the **same table**.
* **Role A (Manager):** We need their ID and Name.
* **Role B (Report):** We need their Age and to count them.

This requires a **Self-Join**. We effectively create two virtual copies of the `Employees` table:
1.  `mgr` (The Managers table)
2.  `emp` (The Subordinates table)

### 2. The Join Condition
We link them where the **Subordinate's `reports_to`** equals the **Manager's `employee_id`**.
* `ON mgr.employee_id = emp.reports_to`

### 3. Aggregation & Math
* **Count:** `COUNT(emp.employee_id)` counts the number of matches found on the subordinate side.
* **Average:** `AVG(emp.age)` calculates the mathematical average.
* **Rounding:** `ROUND(val, 0)` rounds to the nearest integer (e.g., 38.5 -> 39, 38.4 -> 38).

---

## 2. Solutions & Implementation

### ✅ Approach: Inner Self-Join
We use an `INNER JOIN` because we only care about employees who *are* managers (i.e., they have a match in the reports list). Employees with zero reports will naturally be filtered out.

```sql
SELECT 
    mgr.employee_id, 
    mgr.name, 
    COUNT(emp.employee_id) AS reports_count, 
    ROUND(AVG(emp.age), 0) AS average_age
FROM 
    Employees mgr
JOIN 
    Employees emp 
    ON mgr.employee_id = emp.reports_to
GROUP BY 
    mgr.employee_id, 
    mgr.name
ORDER BY 
    mgr.employee_id;
```

---

## 3. 🔍 Deep Dive

#### 1. Visualization of the Join
Imagine the database alignment:

| Mgr.ID | Mgr.Name | ... joined with ... | Emp.Name (Report) | Emp.reports_to | Emp.Age |
| :--- | :--- | :--- | :--- | :--- | :--- |
| 9 | Hercy | $\rightarrow$ | Alice | 9 | 41 |
| 9 | Hercy | $\rightarrow$ | Bob | 9 | 36 |

Now we Group By `Mgr.ID` (9):
* Count rows: 2
* Avg Age: $(41+36)/2 = 38.5$

#### 2. Rounding Logic
Different databases handle rounding differently, but standard SQL `ROUND(x, 0)` usually follows "Round Half Up" logic (x.5 becomes x+1).
* Note: If the problem asked to "Round Down" (truncate), we would use `FLOOR()`. If "Round Up", we would use `CEIL()`. The prompt specifically said "nearest integer", so `ROUND` is correct.

---

## 4. ⏱️ Time Complexity Analysis

Let $N$ be the number of employees.

| Phase | Operation | Complexity | Note |
| :--- | :--- | :--- | :--- |
| **1. Joining** | `Self-Join` | $O(N)$ or $O(N \log N)$ | Assuming `employee_id` (PK) and `reports_to` (FK) are indexed. The DB maps reports to managers. |
| **2. Aggregation** | `GROUP BY` | $O(N)$ | The result set is scanned to calculate counts and averages. |
| **3. Sorting** | `ORDER BY` | $O(M \log M)$ | Where $M$ is the number of managers (subset of $N$). |

**Total Complexity:** $O(N \log N)$ (Standard sort/merge join complexity).
