# 🎬 SQL Case Study: Movie Rating (Dual Statistics)
> **Category:** Complex Aggregation / Union  
> **Difficulty:** Medium  
> **Tags:** `SQL`, `UNION ALL`, `ORDER BY`, `Date Filtering`, `Limit`

## 1. Problem Description
**Goal:** Write a solution to find two specific values and return them in a single column named `results`:
1.  **The User:** The name of the user who has rated the **greatest number** of movies. (Tie-breaker: Lexicographically smaller name).
2.  **The Movie:** The name of the movie with the **highest average rating** in **February 2020**. (Tie-breaker: Lexicographically smaller title).

### Table `Movies`
| Column Name | Type | Description |
| :--- | :--- | :--- |
| `movie_id` | int | Primary Key |
| `title` | varchar | Movie Name |

### Table `Users`
| Column Name | Type | Description |
| :--- | :--- | :--- |
| `user_id` | int | Primary Key |
| `name` | varchar | User Name |

### Table `MovieRating`
| Column Name | Type | Description |
| :--- | :--- | :--- |
| `movie_id` | int | Composite PK |
| `user_id` | int | Composite PK |
| `rating` | int | Rating (1-5) |
| `created_at` | date | Review Date |

### Example Input
**Data Snippet:**
* Daniel rated 3 movies. Monica rated 3 movies.
* "Frozen 2" avg rating in Feb: 3.5. "Joker" avg rating in Feb: 3.5.

### Expected Output
| results |
| :--- |
| Daniel |
| Frozen 2 |

**Explanation:**
1.  **Row 1 (User):** Daniel and Monica tied with 3 ratings. "Daniel" < "Monica" alphabetically, so we pick Daniel.
2.  **Row 2 (Movie):** Frozen 2 and Joker tied with 3.5 average. "Frozen 2" < "Joker" alphabetically, so we pick Frozen 2.

---

## 💡 Thought Process

### 1. Divide and Conquer
This problem asks for two completely different things. It is best to treat them as **two separate queries** and then glue them together.

* **Query A (User Stats):**
    * Join `Users` and `MovieRating`.
    * Group by `user_id`.
    * Count the ratings.
    * Sort by `COUNT` (Desc) then `name` (Asc).
    * Take the top 1.

* **Query B (Movie Stats):**
    * Join `Movies` and `MovieRating`.
    * **Filter:** `created_at` must be in Feb 2020.
    * Group by `movie_id`.
    * Calculate `AVG(rating)`.
    * Sort by `AVG` (Desc) then `title` (Asc).
    * Take the top 1.

### 2. The Glue: UNION ALL
Since the output requires a single table with one column, we use `UNION ALL` to stack the result of Query B under Query A.

---

## 2. Solutions & Implementation

### ✅ Approach: Union of Two Limits
We perform the two independent calculations and stack them.

```sql
(
    -- Query 1: Find the User
    SELECT 
        u.name AS results
    FROM 
        MovieRating mr
    JOIN 
        Users u ON mr.user_id = u.user_id
    GROUP BY 
        u.user_id
    ORDER BY 
        COUNT(mr.rating) DESC, -- Primary Sort: Most ratings
        u.name ASC             -- Tie-breaker: Alphabetical
    LIMIT 1
)
UNION ALL
(
    -- Query 2: Find the Movie
    SELECT 
        m.title AS results
    FROM 
        MovieRating mr
    JOIN 
        Movies m ON mr.movie_id = m.movie_id
    WHERE 
        mr.created_at BETWEEN '2020-02-01' AND '2020-02-29' -- Filter Feb 2020
    GROUP BY 
        m.movie_id
    ORDER BY 
        AVG(mr.rating) DESC,   -- Primary Sort: Best rating
        m.title ASC            -- Tie-breaker: Alphabetical
    LIMIT 1
);
```

---

## 3. 🔍 Deep Dive

#### 1. Why `UNION ALL` instead of `UNION`?
* **`UNION`** removes duplicates. If, theoretically, a user was named "Avengers" and the top movie was "Avengers", `UNION` would merge them into one row (returning only 1 row instead of 2).
* **`UNION ALL`** keeps all rows. It is also faster because the database doesn't need to perform a deduplication pass.
* *Note: In this specific problem, a user name and a movie title colliding is unlikely, but `UNION ALL` is technically more correct for "stacking" separate logic blocks.*

#### 2. Lexicographical Sorting (The Tie-Breaker)
The problem asks for the "lexicographically smaller" name in case of a tie.
* `ORDER BY score DESC` puts the highest numbers first.
* `ORDER BY name ASC` puts "A" before "B".
* Combined: `ORDER BY score DESC, name ASC` ensures that if scores are equal, "Alice" comes before "Bob".

#### 3. Date Filtering Options
Filtering for February 2020 can be done in multiple ways:
* **Standard:** `created_at BETWEEN '2020-02-01' AND '2020-02-29'` (Best for Index usage).
* **Function:** `LEFT(created_at, 7) = '2020-02'`
* **Function:** `YEAR(created_at) = 2020 AND MONTH(created_at) = 2`

---

## 4. ⏱️ Time Complexity Analysis

Let $R$ be the number of ratings, $U$ be users, and $M$ be movies.

| Phase | Operation | Complexity | Note |
| :--- | :--- | :--- | :--- |
| **1. User Query** | Group & Sort | $O(R + U \log U)$ | Scans ratings, aggregates, and sorts users. |
| **2. Movie Query** | Filter & Group | $O(R + M \log M)$ | Scans ratings (filtered by date), aggregates, and sorts movies. |
| **3. Union** | Stack Results | $O(1)$ | Simply appends the two single-row results. |

**Total Complexity:** Dominated by the sorting in both sub-queries. Indexes on `created_at` and `user_id`/`movie_id` significantly speed this up.
