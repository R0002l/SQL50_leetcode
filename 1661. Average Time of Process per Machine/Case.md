# 🏭 SQL Case Study: Average Time of Process per Machine
> **Category:** Data Aggregation / Performance Metrics  
> **Difficulty:** Easy  
> **Tags:** `SQL`, `Joins`, `Conditional Aggregation`, `Math in SQL`

## 1. Problem Description
**Goal:** Calculate the average time each machine takes to complete a process.

The time to complete a process is defined as the `end` timestamp minus the `start` timestamp. The result must be rounded to 3 decimal places.

### Table `Activity`
| Column Name | Type | Description |
| :--- | :--- | :--- |
| `machine_id` | int | ID of the machine |
| `process_id` | int | ID of the process running on the machine |
| `activity_type` | enum | 'start' or 'end' |
| `timestamp` | float | Time in seconds |

*(machine_id, process_id, activity_type) is the primary key.   
activity_type is an ENUM (category) of type ('start', 'end').   
timestamp is a float representing the current time in seconds.   
'start' means the machine starts the process at the given timestamp and 'end' means the machine ends the process at the given timestamp.   
The 'start' timestamp will always be before the 'end' timestamp for every (machine_id, process_id) pair.   
It is guaranteed that each (machine_id, process_id) pair has a 'start' and 'end' timestamp.*


### Example Input
| machine_id | process_id | activity_type | timestamp |
| :--- | :--- | :--- | :--- |
| 0 | 0 | start | 0.712 |
| 0 | 0 | end | 1.520 |
| 0 | 1 | start | 3.140 |
| 0 | 1 | end | 4.120 |
| 1 | 0 | start | 0.550 |
| 1 | 0 | end | 1.550 |
| 1 | 1 | start | 0.430 |
| 1 | 1 | end | 1.420 |
| 2 | 0 | start | 4.100 |
| 2 | 0 | end | 4.512 |
| 2 | 1 | start | 2.500 |
| 2 | 1 | end | 5.000 |

### Expected Output
| machine_id | processing_time |
| :--- | :--- |
| 0 | 0.894 |
| 1 | 0.995 |
| 2 | 1.456 |


**Explanation:**
* **Machine 0:** ((1.520 - 0.712) + (4.120 - 3.140)) / 2 = 0.894
* **Machine 1:** ((1.550 - 0.550) + (1.420 - 0.430)) / 2 = 0.995
* **Machine 2:** ((4.512 - 4.100) + (5.000 - 2.500)) / 2 = 1.456


---

## 💡 Thought Process
To calculate the duration of a process, we need to subtract the `start` time from the `end` time for the same `machine_id` and `process_id`.

**The Challenge:** The start and end times are located in **different rows**. Relational databases store data row-by-row, so we cannot simply subtract Column A from Column B within a single record.

**The Strategy:**
1.  **Pivot or Join:** We need to align the 'start' and 'end' times onto the same logical row to perform the subtraction (`End - Start`).
2.  **Grouping:** Once we have the duration for every single process, we group by `machine_id`.
3.  **Aggregation:** Calculate the average (`AVG`) of these durations.
4.  **Formatting:** Round the result to 3 decimal places.

---

## 2. Solutions & Implementation

### ✅ Approach 1: Self-Join (The Intuitive Way)
We treat the `Activity` table as two separate datasets: one containing only "Start" times and one containing only "End" times. We then join them together.

```sql
SELECT 
    a1.machine_id,
    ROUND(AVG(a2.timestamp - a1.timestamp), 3) AS processing_time
FROM 
    Activity a1
JOIN 
    Activity a2 
    -- Match the same machine and the same process
    ON a1.machine_id = a2.machine_id 
    AND a1.process_id = a2.process_id
WHERE 
    a1.activity_type = 'start' 
    AND a2.activity_type = 'end'
GROUP BY 
    a1.machine_id;
```

### 🔹 Approach 2: Conditional Aggregation (The Mathematical Way)
Instead of joining (which can be expensive), we can use a mathematical property.
* $Duration = End - Start$
* Total Time = $\sum(Ends) - \sum(Starts)$
* We can turn `start` times into negative numbers and `end` times into positive numbers, sum them all up, and divide by the count of processes.

```sql
SELECT 
    machine_id,
    ROUND(
        SUM(CASE WHEN activity_type = 'start' THEN -timestamp ELSE timestamp END) 
        / COUNT(DISTINCT process_id)
    , 3) AS processing_time
FROM 
    Activity
GROUP BY 
    machine_id;
```
<br>

## 3. ⚖️ Comparative Analysis of Solutions

| Approach | Technique | Time Complexity | Readability | Pros & Cons |
| :--- | :--- | :--- | :--- | :--- |
| **1** | **Self-Join** | $O(N \log N)$ (dependent on index) | ⭐⭐⭐ High | **Best for logic clarity.** Easy to understand that we are pairing start/end times. Standard relational approach. |
| **2** | **Conditional Aggregation** | $O(N)$ | ⭐ Medium | **Best for performance.** Scans the table only once. No joining required. The logic is slightly more abstract ("Math trick"). |

---

## 🔍 Deep Dive

#### Why Approach 2 (Conditional Aggregation) is faster for Big Data
In Approach 1, the database engine has to create a Cartesian product of matches (joining the table to itself). If the table has millions of rows, the overhead of matching `id`s increases.

In Approach 2, we perform a **Single Pass** scan.
1.  The database looks at a row.
2.  Is it a start? Make it negative. Is it an end? Make it positive.
3.  Add to a running total.
4.  Finally, divide by the count.

**The Math Logic:**
$$Average = \frac{\sum(End_1 - Start_1) + \sum(End_2 - Start_2)}{Count}$$

$$Average = \frac{(\sum End_1 + \sum End_2) - (\sum Start_1 + \sum Start_2)}{Count}$$

This converts a "Row Matching" problem into a simple "Summation" problem, which databases are extremely fast at computing.
