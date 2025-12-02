# 💰 SQL Case Study: Employee Bonus
> **Category:** Data Filtering / NULL Handling  
> **Difficulty:** Easy  
> **Tags:** `SQL`, `Left Join`, `Filtering`, `NULL logic`, `Boolean Logic`

## 1. Problem Description
**Goal:** Retrieve the name and bonus amount for employees who meet **one** of the following criteria:
1.  Their bonus is strictly **less than 1000**.
2.  They received **no bonus** at all.

### Table `Employee`
| Column Name | Type | Description |
| :--- | :--- | :--- |
| `empId` | int | Primary Key |
| `name` | varchar | Employee Name |
| `supervisor`| int | Supervisor ID |
| `salary` | int | Employee Salary |

### Table `Bonus`
| Column Name | Type | Description |
| :--- | :--- | :--- |
| `empId` | int | Foreign Key to Employee |
| `bonus` | int | Bonus Amount |

*Note: The Bonus table only contains rows for employees who actually received a bonus. If an employee is missing from this table, they have no bonus.*

### Example Input
**Employee Table**
| empId | name | supervisor | salary |
| :--- | :--- | :--- | :--- |
| 3 | Brad | null | 4000 |
| 1 | John | 3 | 1000 |
| 2 | Dan | 3 | 2000 |
| 4 | Thomas | 3 | 4000 |

**Bonus Table**
| empId | bonus |
| :--- | :--- |
| 2 | 500 |
| 4 | 2000 |

### Expected Output
| name | bonus |
| :--- | :--- |
| Brad | null |
| John | null |
| Dan | 500 |

**Explanation:**
* **Brad & John:** Not in Bonus table. (Condition: No bonus $\rightarrow$ Keep).
* **Dan:** Bonus is 500. (Condition: < 1000 $\rightarrow$ Keep).
* **Thomas:** Bonus is 2000. (Condition: > 1000 $\rightarrow$ Exclude).

---

## 💡 Thought Process

### 1. The Join Strategy
We need to combine the `Employee` table (which has the names) with the `Bonus` table (which has the amounts).
* Since we need to include employees who **did not** get a bonus (like Brad and John), we **must** use a `LEFT JOIN`.
* If we used an `INNER JOIN`, Brad and John would be immediately removed from the dataset.

### 2. The "Null Trap" (Critical Concept)
After the Left Join, employees without a bonus will have `NULL` in the `bonus` column.
The condition "bonus < 1000" seems simple, but in SQL:
* `500 < 1000` is **TRUE**.
* `2000 < 1000` is **FALSE**.
* `NULL < 1000` is **UNKNOWN**.

**Important:** The `WHERE` clause only keeps rows that evaluate to **TRUE**. It discards both FALSE and UNKNOWN. Therefore, simply writing `WHERE bonus < 1000` will mistakenly **exclude** Brad and John.

### 3. The Correct Filter
We need to explicitly ask for the NULLs:
`WHERE bonus < 1000 OR bonus IS NULL`

---

## 2. Solutions & Implementation

### ✅ Approach 1: Left Join with Explicit NULL Check
This is the standard and most performant solution.

```sql
SELECT 
    e.name, 
    b.bonus
FROM 
    Employee e
LEFT JOIN 
    Bonus b ON e.empId = b.empId
WHERE 
    b.bonus < 1000  -- Condition 1: Low bonus
    OR 
    b.bonus IS NULL; -- Condition 2: No bonus
```

### 🔹 Approach 2: IFNULL / COALESCE (Alternative)
We can convert `NULL` to `0` before comparing. This makes the logic look cleaner ("0 is less than 1000"), but it can sometimes prevent the database from using an index on the bonus column.

```sql
SELECT 
    e.name, 
    b.bonus
FROM 
    Employee e
LEFT JOIN 
    Bonus b ON e.empId = b.empId
WHERE 
    IFNULL(b.bonus, 0) < 1000;
```

---

## 3. 🔍 Deep Dive: Three-Valued Logic

SQL uses **Three-Valued Logic (3VL)**. A boolean expression can result in:
1.  **True**
2.  **False**
3.  **Unknown** (NULL)

This is distinct from standard programming (like Python or Java) where `None < 1000` usually throws an error or behaves deterministically.

#### Visualization of the Logic
Imagine the intermediate table after the `LEFT JOIN`:

| name | bonus | Check: `bonus < 1000` | Result |
| :--- | :--- | :--- | :--- |
| Dan | 500 | `500 < 1000` is **True** | ✅ Keep |
| Thomas | 2000 | `2000 < 1000` is **False** | ❌ Discard |
| Brad | **NULL** | `NULL < 1000` is **Unknown** | ❌ **Discarded if we forget `OR IS NULL`** |

This is why `OR bonus IS NULL` is mandatory when filtering negative conditions on nullable columns.

---

## 4. ⏱️ Time Complexity Analysis

Let $E$ be the number of Employees and $B$ be the number of rows in the Bonus table.

| Phase | Operation | Complexity | Note |
| :--- | :--- | :--- | :--- |
| **1. Joining** | `LEFT JOIN` | $O(E)$ | Assuming `empId` is indexed (Primary Key). The DB looks up each employee in the Bonus table. |
| **2. Filtering** | `WHERE` | $O(E)$ | The DB scans the joined result (which has size $E$) to check the condition. |

**Total Complexity:** $O(E)$
(Linear complexity relative to the number of employees).
