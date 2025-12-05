# 📅 SQL Case Study: User Activity for the Past 30 Days
> **Category:** Aggregation / Date Logic  
> **Difficulty:** Easy  
> **Tags:** `SQL`, `GROUP BY`, `COUNT DISTINCT`, `BETWEEN`, `Date Arithmetic`

## 1. Problem Description
**Goal:** Calculate the **Daily Active Users (DAU)** count for a specific 30-day window.

**Parameters:**
* **Window Size:** 30 days.
* **End Date:** 2019-07-27 (Inclusive).
* **Definition of Active:** A user is active if they have *any* record in the table for that day.

We need to return the date (`day`) and the count of unique users (`active_users`) for each day within that period.

### Table `Activity`
| Column Name | Type | Description |
| :--- | :--- | :--- |
| `user_id` | int | User ID |
| `session_id` | int | Session ID |
| `activity_date` | date | Date of the activity |
| `activity_type` | enum | Type of action (open, scroll, etc.) |

*(This table may have duplicate rows).*

### Example Input
| user_id | session_id | activity_date | activity_type |
| :--- | :--- | :--- | :--- |
| 1 | 1 | **2019-07-20** | open_session |
| 1 | 1 | **2019-07-20** | scroll_down |
| 2 | 4 | **2019-07-20** | open_session |
| 2 | 4 | **2019-07-21** | send_message |
| 4 | 3 | **2019-06-25** | open_session |

### Expected Output
| day | active_users |
| :--- | :--- |
| 2019-07-20 | 2 |
| 2019-07-21 | 2 |

**Explanation:**
* **2019-07-20:** User 1 and User 2 were active. (Count: 2)
* **2019-06-25:** User 4 was active, but this date is **outside** the 30-day window ending on July 27. (Excluded)

---

## 💡 Thought Process

### 1. Defining the Date Range
The most critical part of this problem is correctly calculating the "30 days ending 2019-07-27".
* **End Date:** 2019-07-27
* **Start Date:** 2019-06-28 (since June has 30 days).
* **Formula:** $Date \in [End - 29 \text{ days}, End]$

### 2. Aggregation Logic
* **Grouping:** We need stats *per day*, so `GROUP BY activity_date`.
* **Counting:** One user might have multiple activities in a single day (e.g., User 1 opened, scrolled, and ended). We must count them as **1 active user**.
* **Function:** `COUNT(DISTINCT user_id)`.

### 3. Filtering
We apply the date filter in the `WHERE` clause to strictly keep rows within our 30-day window.

---

## 2. Solutions & Implementation

### ✅ Approach 1: BETWEEN (Hardcoded Date)
If you calculate the date manually, you can use a simple `BETWEEN` clause. This is very readable.

```sql
SELECT 
    activity_date AS day, 
    COUNT(DISTINCT user_id) AS active_users
FROM 
    Activity
WHERE 
    activity_date BETWEEN '2019-06-28' AND '2019-07-27'
GROUP BY 
    activity_date;
```

### 🔹 Approach 2: DATEDIFF (Dynamic Calculation)
This approach is more robust if you want to verify the logic without manually counting calendar days. We check if the difference between the End Date and the Activity Date is less than 30 days (and non-negative).

```sql
SELECT 
    activity_date AS day, 
    COUNT(DISTINCT user_id) AS active_users
FROM 
    Activity
WHERE 
    DATEDIFF('2019-07-27', activity_date) < 30 
    AND DATEDIFF('2019-07-27', activity_date) >= 0
GROUP BY 
    activity_date;
```

### 🔹 Approach 3: DATE_ADD / DATE_SUB
Another common way to express the range dynamically.

```sql
SELECT 
    activity_date AS day, 
    COUNT(DISTINCT user_id) AS active_users
FROM 
    Activity
WHERE 
    activity_date > DATE_SUB('2019-07-27', INTERVAL 30 DAY) 
    AND activity_date <= '2019-07-27'
GROUP BY 
    activity_date;
```

---

## 3. ⚖️ Comparative Analysis

| Approach | Syntax | Readability | Performance |
| :--- | :--- | :--- | :--- |
| **1. BETWEEN** | `'2019-06-28' AND '2019-07-27'` | ⭐⭐⭐ High | **Fastest.** Using constants allows the database to use indexes on the date column effectively (SARGable). |
| **2. DATEDIFF** | `DATEDIFF(...) < 30` | ⭐⭐ Medium | **Slower.** Wrapping the column `activity_date` in a function (`DATEDIFF`) prevents index usage on large tables (Non-SARGable). |
| **3. DATE_SUB** | `> DATE_SUB(...)` | ⭐⭐⭐ High | **Fast.** Similar to BETWEEN, the calculation happens once on the constant, allowing index usage on the column. |

---

## 4. 🔍 Deep Dive

#### 1. Why `COUNT(DISTINCT user_id)`?
The table records *Activity Logs*.
* User 1 logs in at 9:00 AM (Row 1).
* User 1 scrolls at 9:05 AM (Row 2).
If we use `COUNT(user_id)`, the result for this day would be **2**.
But the metric is **DAU (Daily Active Users)**, so User 1 should only count as **1** person. Thus, `DISTINCT` is mandatory.

#### 2. The "30 Days" Math Trap
"Period of 30 days ending 2019-07-27".
* Does this mean $2019-07-27 - 30$ days?
* $2019-07-27$ minus 30 days is $2019-06-27$.
* If we select `> 2019-06-27`, we get 30 days (June 28 to July 27).
* If we select `>= 2019-06-27`, we get 31 days.
* **Be careful with boundary conditions (Off-by-one errors).**

---

## 5. ⏱️ Time Complexity Analysis

Let $N$ be the number of rows in the `Activity` table.

| Phase | Operation | Complexity | Note |
| :--- | :--- | :--- | :--- |
| **1. Filtering** | `WHERE` | $O(N)$ or $O(\log N)$ | If `activity_date` is indexed and we use Approach 1 or 3, it's very fast. Approach 2 scans all rows. |
| **2. Grouping** | `GROUP BY` | $O(M)$ | Where $M$ is the number of rows remaining after filtering. |
| **3. Aggregation** | `COUNT(DISTINCT)` | $O(M)$ | Requires hashing or sorting user IDs within each day to remove duplicates. |

**Total Complexity:** $O(N)$ effectively.
