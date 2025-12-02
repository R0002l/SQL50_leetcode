# 👥 SQL Case Study: Find Followers Count
> **Category:** Aggregation / Sorting  
> **Difficulty:** Easy  
> **Tags:** `SQL`, `GROUP BY`, `COUNT`, `ORDER BY`

## 1. Problem Description
**Goal:** Calculate the total number of followers for each user.

The result must be:
1.  Grouped by `user_id`.
2.  Sorted by `user_id` in **ascending** order.

### Table `Followers`
| Column Name | Type | Description |
| :--- | :--- | :--- |
| `user_id` | int | ID of the user being followed |
| `follower_id` | int | ID of the user who is following |

*(user_id, follower_id) is the Primary Key. This guarantees there are no duplicate rows (a user cannot follow the same person twice).*

### Example Input
| user_id | follower_id |
| :--- | :--- |
| 0 | 1 |
| 1 | 0 |
| 2 | 0 |
| 2 | 1 |

### Expected Output
| user_id | followers_count |
| :--- | :--- |
| 0 | 1 |
| 1 | 1 |
| 2 | 2 |

**Explanation:**
* **User 0:** Followed by user 1. (Total: 1)
* **User 1:** Followed by user 0. (Total: 1)
* **User 2:** Followed by users 0 and 1. (Total: 2)

---

## 💡 Thought Process

### 1. The Strategy: Aggregation
We have a list of individual connections ("Who follows whom"). We want to compress this list into a summary ("How many people follow X?").
* **Operation:** `GROUP BY`. We need to bucket the rows based on the `user_id`.
* **Calculation:** `COUNT`. Once bucketed, we count how many items (rows) are in each bucket.

### 2. The Ordering
The problem explicitly asks to "Return the result table ordered by `user_id` in ascending order".
* **Operation:** `ORDER BY user_id ASC`.
* *Note:* While some databases sort implicitly when grouping, relying on this behavior is bad practice. Always be explicit.

---

## 2. Solutions & Implementation

### ✅ Approach 1: Standard Aggregation
This is the canonical way to solve this problem.

```sql
SELECT 
    user_id, 
    COUNT(follower_id) AS followers_count
FROM 
    Followers
GROUP BY 
    user_id
ORDER BY 
    user_id;
```

---

## 3. ⚖️ Comparative Analysis

| Method | Syntax | Note |
| :--- | :--- | :--- |
| **COUNT(follower_id)** | `COUNT(col)` | **Recommended.** Counts non-null values in the specific column. Since it's part of the PK, it's safe. |
| **COUNT(\*)** | `COUNT(*)` | **Also Valid.** Counts the rows in the group. Since the Primary Key ensures no duplicates, `COUNT(*)` gives the exact same result here and is often just as fast. |
| **COUNT(DISTINCT ...)** | `COUNT(DISTINCT col)` | **Unnecessary.** Because `(user_id, follower_id)` is the Primary Key, duplicates are impossible. Adding `DISTINCT` forces the database to perform an extra check, which is a waste of resources. |

---

## 4. 🔍 Deep Dive

#### 1. Primary Key Implication
The problem statement says `(user_id, follower_id)` is the primary key.
* This implies constraint **Unique**.
* You will never see a row like `user: 2, follower: 0` appear twice.
* Therefore, we can safely count rows without worrying about deduplication.

#### 2. Execution Order
1.  **FROM Followers:** Scan the table.
2.  **GROUP BY user_id:** Sort or Hash the rows into buckets (Bucket 0, Bucket 1, Bucket 2).
3.  **SELECT COUNT(...):** Calculate the size of each bucket.
4.  **ORDER BY user_id:** Ensure the final output is sorted (though the GROUP BY step might have already done this partially).

---

## 5. ⏱️ Time Complexity Analysis

Let $N$ be the number of rows in the `Followers` table.

| Phase | Operation | Complexity | Note |
| :--- | :--- | :--- | :--- |
| **1. Grouping** | `GROUP BY` | $O(N)$ or $O(N \log N)$ | Depends on whether the engine uses Hashing (Linear) or Sorting (Log-Linear) to group. |
| **2. Sorting** | `ORDER BY` | $O(K \log K)$ | Where $K$ is the number of unique users. |

**Total Complexity:** $O(N)$ (if Hash Aggregation is used) or $O(N \log N)$ (if Sort Aggregation is used).
