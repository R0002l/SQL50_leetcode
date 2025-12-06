# 🏫 SQL Case Study: Classes More Than 5 Students
> **Category:** Aggregation / Grouping  
> **Difficulty:** Easy  
> **Tags:** `SQL`, `GROUP BY`, `HAVING`, `COUNT`

## 1. Problem Description
**Goal:** Identify classes that have **at least five** students enrolled.

We need to count the number of students in each class and return the class names where that count is 5 or greater.

### Table `Courses`
| Column Name | Type | Description |
| :--- | :--- | :--- |
| `student` | varchar | Name of the student |
| `class` | varchar | Name of the class |

*(student, class) is the Primary Key. This guarantees a student cannot be enrolled in the exact same class twice.*

### Example Input
| student | class |
| :--- | :--- |
| A | **Math** |
| B | English |
| C | **Math** |
| D | Biology |
| E | **Math** |
| F | Computer |
| G | **Math** |
| H | **Math** |
| I | **Math** |

### Expected Output
| class |
| :--- |
| Math |

**Explanation:**
* **Math:** 6 students (A, C, E, G, H, I). Condition $\ge 5$ met.
* **English:** 1 student.
* **Biology:** 1 student.
* **Computer:** 1 student.

---

## 💡 Thought Process

### 1. The Strategy: Grouping
The unit of analysis is the **Class**. We don't care about individual student names, just the *count* of students associated with each class.
* **Action:** `GROUP BY class`.

### 2. The Filter: HAVING vs WHERE
We need to filter based on the *result* of the count (an aggregate value), not the raw data rows.
* **`WHERE`**: Filters rows **before** grouping (e.g., "Find students named Alice").
* **`HAVING`**: Filters groups **after** grouping (e.g., "Find classes with > 5 students").
* **Action:** Use `HAVING COUNT(student) >= 5`.

---

## 2. Solutions & Implementation

### ✅ Approach 1: Group By + Having (Standard)
This is the canonical way to filter aggregated data in SQL.

```sql
SELECT 
    class
FROM 
    Courses
GROUP BY 
    class
HAVING 
    COUNT(student) >= 5;
```

---

## 3. ⚖️ Comparative Analysis

| Feature | `COUNT(student)` | `COUNT(DISTINCT student)` |
| :--- | :--- | :--- |
| **Logic** | Counts all rows in the group. | Counts unique students in the group. |
| **In this Problem** | **Valid & Fast.** Because `(student, class)` is the Primary Key, duplicates are impossible. | **Valid but Slower.** The database performs an extra deduplication step, which is redundant here due to the PK constraint. |

---

## 4. 🔍 Deep Dive

#### 1. Why `HAVING`?
A common mistake for beginners is writing:
```sql
SELECT class FROM Courses WHERE COUNT(student) >= 5 ... -- Wrong!
```
This fails because the database processes the query in this order:
1.  `FROM` (Load table)
2.  `WHERE` (Filter rows) $\leftarrow$ At this point, the "Count" doesn't exist yet!
3.  `GROUP BY` (Make buckets)
4.  `HAVING` (Filter buckets) $\leftarrow$ Now we know the count.
5.  `SELECT` (Return columns)

#### 2. Index Optimization
If the `Courses` table is huge (millions of rows), counting can be slow.
* **Index Strategy:** An index on the `class` column allows the database to count entries for "Math", "English", etc., very quickly without scanning the entire table.

---

## 5. ⏱️ Time Complexity Analysis

Let $N$ be the number of rows in the `Courses` table.

| Phase | Operation | Complexity | Note |
| :--- | :--- | :--- | :--- |
| **1. Grouping** | `GROUP BY` | $O(N)$ | Linearly scans the table to bucket students into classes. |
| **2. Filtering** | `HAVING` | $O(C)$ | Where $C$ is the number of unique classes. |

**Total Complexity:** $O(N)$.
