# 🎓 SQL Case Study: Number of Unique Subjects Taught by Each Teacher
> **Category:** Aggregation / Grouping  
> **Difficulty:** Easy  
> **Tags:** `SQL`, `GROUP BY`, `COUNT`, `DISTINCT`

## 1. Problem Description
**Goal:** Calculate the number of **unique** subjects each teacher teaches.

The tricky part of this problem is that a teacher might teach the *same* subject but in *different* departments. We need to count the subject itself, not the number of classes/departments.

### Table `Teacher`
| Column Name | Type | Description |
| :--- | :--- | :--- |
| `teacher_id` | int | ID of the teacher |
| `subject_id` | int | ID of the subject |
| `dept_id` | int | ID of the department |

*(subject_id, dept_id) is the Primary Key.*

### Example Input
| teacher_id | subject_id | dept_id |
| :--- | :--- | :--- |
| 1 | 2 | 3 |
| 1 | 2 | 4 |
| 1 | 3 | 3 |
| 2 | 1 | 1 |
| 2 | 2 | 1 |
| 2 | 3 | 1 |
| 2 | 4 | 1 |

### Expected Output
| teacher_id | cnt |
| :--- | :--- |
| 1 | 2 |
| 2 | 4 |

**Explanation:**
* **Teacher 1:**
    * Teaches Subject 2 (in Dept 3).
    * Teaches Subject 2 (in Dept 4). -> **Duplicate Subject!**
    * Teaches Subject 3 (in Dept 3).
    * *Unique Subjects:* [2, 3]. Count = **2**.
* **Teacher 2:**
    * Teaches Subjects 1, 2, 3, 4.
    * *Unique Subjects:* [1, 2, 3, 4]. Count = **4**.

---

## 💡 Thought Process

### 1. Grouping Strategy
We need one result row per teacher.
* **Action:** `GROUP BY teacher_id`.

### 2. The Duplicate Trap
If we simply use `COUNT(subject_id)`, Teacher 1 would have a count of **3** (because there are 3 rows).
* Row 1: Subject 2
* Row 2: Subject 2
* Row 3: Subject 3

However, the problem asks for the number of **unique** subjects.
* **Action:** We must use `DISTINCT` inside the count function to eliminate duplicates before counting.

---

## 2. Solutions & Implementation

### ✅ Approach 1: COUNT DISTINCT (Standard Solution)
This is the most efficient and standard way to solve this problem.

```sql
SELECT 
    teacher_id, 
    COUNT(DISTINCT subject_id) AS cnt
FROM 
    Teacher
GROUP BY 
    teacher_id;
```

### 🔹 Approach 2: Subquery (Conceptual Alternative)
Alternatively, you could first remove duplicates using a subquery (or CTE), and then count. This is verbose but shows the logic clearly.

```sql
SELECT 
    teacher_id, 
    COUNT(subject_id) AS cnt
FROM (
    -- Step 1: Get unique teacher-subject pairs
    SELECT DISTINCT teacher_id, subject_id 
    FROM Teacher
) AS unique_pairs
GROUP BY 
    teacher_id;
```

---

## 3. ⚖️ Comparative Analysis

| Approach | Syntax | Complexity | Pros & Cons |
| :--- | :--- | :--- | :--- |
| **1. COUNT(DISTINCT)** | `COUNT(DISTINCT col)` | Low | **Best Practice.** Concise, readable, and optimized by the database engine. |
| **2. Subquery** | `SELECT DISTINCT` + `COUNT` | Medium | **Overkill.** Does the same thing but requires more code and potentially an extra pass (creating a temporary table) depending on the optimizer. |

---

## 4. 🔍 Deep Dive

#### 1. Why is `DISTINCT` necessary here?
The table's primary key is `(subject_id, dept_id)`. This implies that `subject_id` alone is **NOT unique**.
A subject (e.g., "Math 101") can be taught in multiple departments (e.g., "Engineering Dept" and "Science Dept"). The teacher is the same, the subject is the same, but the department is different. Since we only care about the *count of subjects*, we must de-duplicate.

#### 2. Execution Order
1.  **FROM Teacher:** Access the table.
2.  **GROUP BY teacher_id:** Bucket rows by teacher.
    * *Bucket 1:* `{Subj:2, Dept:3}, {Subj:2, Dept:4}, {Subj:3, Dept:3}`
3.  **SELECT COUNT(DISTINCT subject_id):**
    * Inside Bucket 1: Look at subjects `[2, 2, 3]`.
    * Apply Distinct: `[2, 3]`.
    * Count: `2`.

---

## 5. ⏱️ Time Complexity Analysis

Let $N$ be the number of rows in the `Teacher` table.

| Phase | Operation | Complexity | Note |
| :--- | :--- | :--- | :--- |
| **1. Grouping** | `GROUP BY` | $O(N)$ | The database scans the table to group records. |
| **2. Deduplication** | `DISTINCT` | $O(N \log N)$ or $O(N)$ | The database usually uses **Sorting** or **Hashing** to find unique values within each group. |

**Total Complexity:** $O(N \log N)$ or $O(N)$ (depending on Hash vs. Sort implementation).
