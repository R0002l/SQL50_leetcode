# 🎬 SQL Case Study: Not Boring Movies
> **Category:** Data Filtering / Sorting  
> **Difficulty:** Easy  
> **Tags:** `SQL`, `Filtering`, `Modulo Operator`, `Sorting`

## 1. Problem Description
**Goal:** Retrieve specific movies based on their ID and description, then rank them by rating.

We need to find movies that meet **two specific criteria**:
1.  The `id` must be an **odd** number.
2.  The `description` must **not** be "boring".

The final result must be sorted by `rating` from highest to lowest.

### Table `Cinema`
| Column Name | Type | Description |
| :--- | :--- | :--- |
| `id` | int | Primary Key |
| `movie` | varchar | Name of the movie |
| `description` | varchar | Genre or description |
| `rating` | float | Rating (0-10) |

### Example Input
| id | movie | description | rating |
| :--- | :--- | :--- | :--- |
| 1 | War | great 3D | 8.9 |
| 2 | Science | fiction | 8.5 |
| 3 | irish | boring | 6.2 |
| 4 | Ice song | Fantacy | 8.6 |
| 5 | House card | Interesting | 9.1 |

### Expected Output
| id | movie | description | rating |
| :--- | :--- | :--- | :--- |
| 5 | House card | Interesting | 9.1 |
| 1 | War | great 3D | 8.9 |

**Explanation:**
* **ID 2 & 4:** Skipped because they are even numbers.
* **ID 3:** Skipped because the description is "boring".
* **ID 5 & 1:** Kept. ID 5 is listed first because its rating (9.1) is higher than ID 1 (8.9).

---

## 💡 Thought Process
To solve this, we need to filter the rows (`WHERE`) and then organize the output (`ORDER BY`).

**The Challenge:**
The main logical challenge is mathematically identifying "Odd" numbers within a database query.

**The Strategy:**
1.  **Filter Odd IDs:** We use the **Modulo** operator. In mathematics, an odd number divided by 2 always leaves a remainder of 1.
    * Formula: $x \pmod 2 = 1$
2.  **Filter Description:** We need a standard inequality check. We want rows where `description` is **not equal** to 'boring'.
3.  **Sort:** The problem requests the highest ratings at the top, which means Descending order (`DESC`).

---

## 2. Solutions & Implementation

### ✅ Approach 1: The Standard Solution (Modulo Operator)
This is the most common and readable way to solve the problem using standard SQL operators.

```sql
SELECT 
    *
FROM 
    Cinema
WHERE 
    id % 2 = 1              -- Condition 1: Remainder of division by 2 is 1 (Odd)
    AND description <> 'boring' -- Condition 2: Not equal to 'boring'
ORDER BY 
    rating DESC;            -- Sort: Highest rating first
```

### 🔹 Approach 2: Using the MOD() Function
Some SQL dialects (like Oracle or older versions of SQL Server) prefer the functional syntax `MOD(n, m)` over the `%` symbol.

```sql
SELECT 
    id, movie, description, rating
FROM 
    Cinema
WHERE 
    MOD(id, 2) = 1          -- Functional approach for Modulo
    AND description != 'boring' -- Alternate syntax for "Not Equal"
ORDER BY 
    rating DESC;
```

---

## 3. ⚖️ Comparative Analysis of Solutions

| Approach | Syntax | Portability | Readability | Pros & Cons |
| :--- | :--- | :--- | :--- | :--- |
| **1** | **Operator (`%`)** | High (MySQL, Postgres, SQL Server) | ⭐⭐⭐ High | **Best for standard queries.** Concise and mathematically standard in programming. |
| **2** | **Function (`MOD()`)** | Medium (Oracle, MySQL, IBM DB2) | ⭐⭐ Medium | **Best for explicit clarity.** Useful in environments where `%` might be reserved or unsupported. |

---

## 4. 🔍 Deep Dive

#### 1. The Modulo Operator (Mathematical Logic)
The modulo operation finds the remainder or signed remainder of a division.
For determining parity (even vs. odd):
* **Even Numbers:** $n \pmod 2 = 0$ (e.g., $4 / 2 = 2$ with remainder $0$)
* **Odd Numbers:** $n \pmod 2 = 1$ (e.g., $5 / 2 = 2$ with remainder $1$)

In some rare bitwise implementations, you can also check for odd numbers using `id & 1`. If the last binary bit is 1, the number is odd.
* `WHERE (id & 1)` (This is very fast but less readable).

#### 2. Inequality Operators: `<>` vs `!=`
You will see both used in SQL.
* `<>` is the **ISO Standard** SQL operator for "not equal". It is guaranteed to work on almost all compliant databases.
* `!=` is a common shortcut borrowed from C-style programming languages. While most modern databases (MySQL, Postgres) support it, strict SQL parsers may reject it.
* **Best Practice:** Stick to `<>` for maximum compatibility.

#### 3. Execution Order
It is important to remember the order in which the database executes this query:
1.  **FROM:** Scans the `Cinema` table.
2.  **WHERE:** Filters out the even IDs and "boring" descriptions. (This reduces the dataset size immediately).
3.  **SELECT:** Retrieves the columns.
4.  **ORDER BY:** Sorts the remaining small result set.

*Because the sorting happens **after** the filtering, the query is efficient; the database only has to sort the few "interesting, odd-numbered" movies, rather than the entire library.*
