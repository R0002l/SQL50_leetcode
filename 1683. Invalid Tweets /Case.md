# 🐦 SQL Case Study: Invalid Tweets
> **Category:** String Manipulation / Filtering  
> **Difficulty:** Easy  
> **Tags:** `SQL`, `LENGTH`, `CHAR_LENGTH`, `String Functions`

## 1. Problem Description
**Goal:** Identify tweets that are considered **"invalid"**.

A tweet is defined as **invalid** if the number of characters in its content is **strictly greater than 15**. We need to return the IDs of these tweets.

### Table `Tweets`
| Column Name | Type | Description |
| :--- | :--- | :--- |
| `tweet_id` | int | Primary Key |
| `content` | varchar | The text content of the tweet |

### Example Input
| tweet_id | content | Length | Status |
| :--- | :--- | :--- | :--- |
| 1 | Let us Code | 11 | Valid |
| 2 | More than fifteen chars are here! | 33 | **Invalid** (> 15) |

### Expected Output
| tweet_id |
| :--- |
| 2 |

**Explanation:**
* Tweet 1 length is 11, which is $\le 15$.
* Tweet 2 length is 33, which is $> 15$.

---

## 💡 Thought Process

### 1. The Metric: Character Count
We need to measure the length of the string in the `content` column.
* **Function:** In MySQL, the standard function to count *characters* is `CHAR_LENGTH()` (or `CHARACTER_LENGTH()`).
* **Note:** `LENGTH()` exists too, but it often counts *bytes*. For English text (ASCII), bytes equals characters. For Chinese or Emojis (UTF-8), one character might be 3 or 4 bytes. `CHAR_LENGTH` is the safer, semantically correct choice for "number of characters".

### 2. The Condition
* We want tweets strictly longer than 15.
* **Logic:** `CHAR_LENGTH(content) > 15`.

---

## 2. Solutions & Implementation

### ✅ Approach 1: CHAR_LENGTH (Best Practice)
This handles multi-byte characters correctly (though the problem says alphanumeric, it's good habit).

```sql
SELECT 
    tweet_id
FROM 
    Tweets
WHERE 
    CHAR_LENGTH(content) > 15;
```

### 🔹 Approach 2: LENGTH (Standard for ASCII)
Since the problem states the content is only "alphanumeric, '!', or ' '", `LENGTH()` will work identically to `CHAR_LENGTH()` here.

```sql
SELECT 
    tweet_id
FROM 
    Tweets
WHERE 
    LENGTH(content) > 15;
```

---

## 3. ⚖️ Comparative Analysis

| Function | Unit Measured | Example 'A' | Example '好' (UTF-8) | Note |
| :--- | :--- | :--- | :--- | :--- |
| **`CHAR_LENGTH()`** | Characters | 1 | 1 | **Preferred.** Counts the actual symbols regardless of encoding. |
| **`LENGTH()`** | Bytes | 1 | 3 | **Risky.** Use only if you specifically care about storage size or know the data is strictly ASCII. |

---

## 4. 🔍 Deep Dive

#### 1. Why strict inequality (`>`)?
The problem says "strictly greater than 15".
* If a tweet has exactly 15 characters, it is **Valid**.
* We must use `>` and not `>=`.

#### 2. Performance Note on String Functions
Using a function like `CHAR_LENGTH(content)` in the `WHERE` clause makes the query **Non-SARGable** (Search ARGument ABLE).
* This means the database generally **cannot use an index** on the `content` column to speed this up. It has to calculate the length for *every single row* (Full Table Scan).
* Ideally, if "tweet length" is a frequent query filter, you would store a separate column called `content_length` and index that.

---

## 5. ⏱️ Time Complexity Analysis

Let $N$ be the number of tweets.

| Phase | Operation | Complexity | Note |
| :--- | :--- | :--- | :--- |
| **1. Scanning** | `WHERE CHAR_LENGTH(...)` | $O(N)$ | The database must read every row and compute the string length. |

**Total Complexity:** $O(N)$.
