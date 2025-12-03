# 📊 SQL Case Study: Percentage of Users Attended a Contest
> **Category:** Aggregation / Subqueries / Math
> **Difficulty:** Easy
> **Tags:** `SQL`, `GROUP BY`, `Scalar Subquery`, `Rounding`, `Ordering`

## 1. Problem Description
**Goal:** Calculate the percentage of all users who registered for each contest.

The calculation formula for each contest is:
$$\text{Percentage} = \frac{\text{Users Registered for this Contest}}{\text{Total Users in the System}} \times 100$$

**Requirements:**
1.  Result rounded to **2 decimal places**.
2.  Ordered by `percentage` in **Descending** order.
3.  Tie-breaker: Order by `contest_id` in **Ascending** order.

### Table `Users`
| Column Name | Type | Description |
| :--- | :--- | :--- |
| `user_id` | int | Primary Key |
| `user_name` | varchar | User Name |

### Table `Register`
| Column Name | Type | Description |
| :--- | :--- | :--- |
| `contest_id` | int | ID of the contest |
| `user_id` | int | ID of the user registered |

*(contest_id, user_id) is the Primary Key.*

### Example Input
**Users:** Total 3 users (Alice, Bob, Alex).
**Register:**
* Contest 208: Registered by 3 users (Alice, Bob, Alex).
* Contest 215: Registered by 2 users (Alice, Alex).

### Expected Output
| contest_id | percentage |
| :--- | :--- |
| 208 | 100.00 |
| 215 | 66.67 |

**Explanation:**
* **Contest 208:** $3/3 = 100\%$
* **Contest 215:** $2/3 \approx 66.666...\% \rightarrow 66.67\%$

---

## 💡 Thought Process

### 1. The Denominator (Total Users)
The tricky part is that the "Total Users" is a constant number derived from the `Users` table, while the "Registered Users" changes per group (contest).
* We cannot simply join tables and count, as that might skew the total.
* **Strategy:** Use a **Scalar Subquery** `(SELECT COUNT(user_id) FROM Users)` to get the total number of users (e.g., 3) and use it as a constant in our formula.

### 2. The Numerator (Users per Contest)
We need to group the `Register` table by `contest_id` and count the rows in each group.

### 3. The Math & Ordering
* Multiply by `100.0` (not just 100) to ensure the database treats the calculation as a decimal (floating point) operation rather than integer division.
* Use `ROUND(..., 2)`.
* Apply the specific double sorting rule (`ORDER BY percentage DESC, contest_id ASC`).

---

## 2. Solutions & Implementation

### ✅ Approach: Group By with Scalar Subquery
This is the most direct method. We compute the total user count independently.

```sql
SELECT 
    contest_id, 
    ROUND(
        COUNT(user_id) * 100.0 / (SELECT COUNT(user_id) FROM Users), 
        2
    ) AS percentage
FROM 
    Register
GROUP BY 
    contest_id
ORDER BY 
    percentage DESC, 
    contest_id ASC;
```

---

## 3. 🔍 Deep Dive

#### 1. Why `* 100.0`?
In some databases (like SQL Server or older Postgres versions), dividing an integer by an integer results in an integer (e.g., `2 / 3 = 0`).
Multiplying by `100.0` forces the numerator to be a decimal type, ensuring the result is `0.666...` instead of `0`.
* `2 / 3 = 0` (Integer Division)
* `2 * 100.0 / 3 = 66.666...` (Float Division)

#### 2. Efficiency of Scalar Subquery
The subquery `(SELECT COUNT(user_id) FROM Users)` looks like it might be slow, but modern databases are smart. They execute this **once**, cache the result (e.g., "3"), and use that single number for every row calculation. It does **not** recount the users table for every contest.

---

## 4. ⏱️ Time Complexity Analysis

Let $R$ be the rows in `Register` and $U$ be the rows in `Users`.

| Phase | Operation | Complexity | Note |
| :--- | :--- | :--- | :--- |
| **1. Denominator** | `COUNT` on Users | $O(U)$ | Scans the Users table once to get the total. |
| **2. Grouping** | `GROUP BY` on Register | $O(R)$ | Scans the Register table to group by contest. |
| **3. Sorting** | `ORDER BY` | $O(C \log C)$ | Where $C$ is the number of unique contests. |

**Total Complexity:** $O(U + R)$. Since $R$ is typically much larger than $U$ or $C$, the complexity is dominated by the scan of the Register table.
