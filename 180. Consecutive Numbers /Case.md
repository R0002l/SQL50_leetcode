# 1️⃣1️⃣1️⃣ SQL Case Study: Consecutive Numbers
> **Category:** Self-Join / Window Functions  
> **Difficulty:** Medium  
> **Tags:** `SQL`, `Self-Join`, `LEAD/LAG`, `DISTINCT`, `Gaps and Islands`

## 1. Problem Description
**Goal:** Find all numbers that appear at least **three times consecutively**.

"Consecutive" means:
1.  The IDs are sequential (e.g., 1, 2, 3).
2.  The `num` values are identical in those rows.

### Table `Logs`
| Column Name | Type | Description |
| :--- | :--- | :--- |
| `id` | int | Primary Key (Autoincrement) |
| `num` | varchar | The number log |

### Example Input
| id | num | Check |
| :--- | :--- | :--- |
| 1 | **1** | Start of sequence |
| 2 | **1** | Match (Prev: 1) |
| 3 | **1** | Match (Prev: 1) $\rightarrow$ **Found 3!** |
| 4 | 2 | Break |
| 5 | 1 | New Start |
| 6 | 2 | Break |
| 7 | 2 | New Start |

### Expected Output
| ConsecutiveNums |
| :--- |
| 1 |

*(Note: If the input was `1, 1, 1, 1`, the number `1` is still the only result. We must return distinct numbers, not every matching instance.)*

---

## 💡 Thought Process

### 1. The Logic: "Yesterday, Today, Tomorrow"
To determine if a number appears 3 times in a row, we need to look at three adjacent rows simultaneously.
* **Row A:** `id = x`, `num = N`
* **Row B:** `id = x+1`, `num = N`
* **Row C:** `id = x+2`, `num = N`

### 2. Handling Duplicates
If the input is `1, 1, 1, 1`, a simple check might find two sets of triplets:
* Rows 1, 2, 3 (Value 1)
* Rows 2, 3, 4 (Value 1)
The result would list `1` twice.
* **Action:** We must use `SELECT DISTINCT` to ensure unique results.

---

## 2. Solutions & Implementation

### ✅ Approach 1: Self-Join (The 3-Way Join)
We simulate "looking at next rows" by joining the table to itself 3 times. This works universally in all SQL versions.

```sql
SELECT DISTINCT 
    l1.num AS ConsecutiveNums
FROM 
    Logs l1
JOIN 
    Logs l2 ON l1.id = l2.id - 1
JOIN 
    Logs l3 ON l2.id = l3.id - 1
WHERE 
    l1.num = l2.num 
    AND 
    l2.num = l3.num;
```

### 🔹 Approach 2: Window Functions (LEAD/LAG)
If your database supports modern SQL (MySQL 8.0+, Postgres, SQL Server), using `LEAD` (Look Ahead) is cleaner and often faster as it avoids creating a massive Cartesian product of joins.

```sql
SELECT DISTINCT 
    num AS ConsecutiveNums
FROM (
    SELECT 
        num,
        LEAD(num, 1) OVER (ORDER BY id) AS next_1,
        LEAD(num, 2) OVER (ORDER BY id) AS next_2,
        id,
        LEAD(id, 1) OVER (ORDER BY id) AS next_id_1,
        LEAD(id, 2) OVER (ORDER BY id) AS next_id_2
    FROM 
        Logs
) AS window_table
WHERE 
    num = next_1 
    AND num = next_2
    -- Optional: Strict check for ID continuity (if IDs might have gaps)
    AND next_id_1 = id + 1 
    AND next_id_2 = id + 2;
```

---

## 3. ⚖️ Comparative Analysis

| Approach | Syntax | Performance | Pros & Cons |
| :--- | :--- | :--- | :--- |
| **1. Self-Join** | `JOIN` x 3 | ⭐ Medium | **Universal.** Works in very old databases. However, joining a large table to itself 3 times can create a lot of intermediate rows. |
| **2. Window Func** | `LEAD()` | ⭐⭐⭐ High | **Efficient.** Scans the table once. Much more scalable if the requirement changes to "5 consecutive times" (you don't want to write 5 joins). |

---

## 4. 🔍 Deep Dive

#### 1. The "ID Gap" Problem
Does "Consecutive" mean the IDs must be `1, 2, 3`? Or just that the rows are next to each other (e.g., `1, 2, 5` with 3 and 4 deleted)?
* **Strict Interpretation (LeetCode Standard):** Usually implies `id`, `id+1`, `id+2`. Approach 1 enforces this strictly.
* **Loose Interpretation:** If rows `1, 2, 5` have the same number, and no other rows exist between them, are they consecutive? If so, Approach 2 needs to remove the `next_id` check, or we use a "Gaps and Islands" algorithm (Row_Number difference).

#### 2. Why `l1.id = l2.id - 1`?
In the join condition:
* `l2.id - 1` means "The ID before L2".
* So `l1.id = l2.id - 1` effectively aligns L1 to be the "Previous Row" of L2.
* Visually:
    * L1: ID 1
    * L2: ID 2 (Joins to L1 because 2-1 = 1)
    * L3: ID 3 (Joins to L2 because 3-1 = 2)

---

## 5. ⏱️ Time Complexity Analysis

Let $N$ be the number of rows in `Logs`.

| Phase | Operation | Complexity | Note |
| :--- | :--- | :--- | :--- |
| **1. Scanning** | `JOIN` | $O(N)$ | With an index on `id` (Primary Key), the join lookups are constant time $O(1)$ per row. |
| **2. Filtering** | `WHERE` | $O(N)$ | Checks the value equality. |
| **3. Deduplication** | `DISTINCT` | $O(M)$ | Where $M$ is the number of matches found. |

**Total Complexity:** $O(N)$.
