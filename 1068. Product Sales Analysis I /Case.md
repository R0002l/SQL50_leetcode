# 🏷️ SQL Case Study: Product Sales Analysis I
> **Category:** Join Types / Basic Retrieval  
> **Difficulty:** Easy  
> **Tags:** `SQL`, `INNER JOIN`, `Foreign Key`, `Aliasing`

## 1. Problem Description
**Goal:** Report the `product_name`, `year`, and `price` for each sale ID found in the `Sales` table.

We have two tables:
1.  **Sales:** Contains transactional data (What ID was sold, when, and for how much).
2.  **Product:** Contains dimension data (The actual name corresponding to the ID).

The `Sales` table has the `year` and `price`, but it only has `product_id`.
The `Product` table has the `product_name`.
We need to combine them.

### Table `Sales`
| Column Name | Type | Description |
| :--- | :--- | :--- |
| `sale_id` | int | Sale ID |
| `product_id` | int | Foreign Key to Product |
| `year` | int | Year of sale |
| `quantity` | int | Quantity sold |
| `price` | int | Price per unit |

### Table `Product`
| Column Name | Type | Description |
| :--- | :--- | :--- |
| `product_id` | int | Primary Key |
| `product_name` | varchar | Name of the product |

### Example Input
**Sales Table:**
| sale_id | product_id | year | price |
| :--- | :--- | :--- | :--- |
| 1 | **100** | 2008 | 5000 |
| 7 | **200** | 2011 | 9000 |

**Product Table:**
| product_id | product_name |
| :--- | :--- |
| **100** | **Nokia** |
| **200** | **Apple** |

### Expected Output
| product_name | year | price |
| :--- | :--- | :--- |
| Nokia | 2008 | 5000 |
| Apple | 2011 | 9000 |

---

## 💡 Thought Process

### 1. Identify the Source of Information
We need three columns in the output:
1.  `product_name` $\rightarrow$ Exists in **Product** table.
2.  `year` $\rightarrow$ Exists in **Sales** table.
3.  `price` $\rightarrow$ Exists in **Sales** table.

### 2. Identify the Link (Join Key)
Since information is split across two tables, we must Join them.
* Common Column: `product_id`.
* Relationship: `Sales.product_id` refers to `Product.product_id`.

### 3. Choose the Join Type
We want to report details for **each sale** in the `Sales` table.
* **`INNER JOIN`**: Retrieves records that have matching values in both tables. Since `product_id` is a Foreign Key, we assume every sale corresponds to a valid product. This is the standard choice.
* **`LEFT JOIN`**: (`Sales LEFT JOIN Product`) would also work and is safer if there's a risk of "Orphaned Sales" (sales with a product ID that doesn't exist in the Product table).

---

## 2. Solutions & Implementation

### ✅ Approach 1: INNER JOIN (Standard)
This is the most direct way to retrieve the data.

```sql
SELECT 
    p.product_name, 
    s.year, 
    s.price
FROM 
    Sales s
INNER JOIN 
    Product p ON s.product_id = p.product_id;
```

---

## 3. ⚖️ Comparative Analysis

| Approach | Syntax | Pros & Cons |
| :--- | :--- | :--- |
| **INNER JOIN** | `JOIN ... ON` | ⭐⭐⭐ **High.** Best for performance when you only want complete records. If a product ID is missing in the Product table, that sale is hidden. |
| **LEFT JOIN** | `LEFT JOIN ... ON` | ⭐⭐ **Safe.** If a sale has an invalid product ID, `LEFT JOIN` would still show the sale year and price, but `product_name` would be `NULL`. In strict schema designs (with FK constraints), this behaves identically to Inner Join. |



---

## 4. 🔍 Deep Dive

#### 1. Aliasing (`s` and `p`)
Notice we used `Sales s` and `Product p`.
* `s.year`: Explicitly tells the database to get `year` from the Sales table.
* `p.product_name`: Explicitly gets the name from the Product table.
* While not strictly required if column names are unique across tables, using aliases is **Best Practice** for readability and preventing "Ambiguous Column" errors in the future.

#### 2. Why not filtering?
The problem asks to return the result "in any order" and for "each sale_id". This means no `WHERE` clause or `GROUP BY` is needed. We are simply flattening the relational model into a single report view.

---

## 5. ⏱️ Time Complexity Analysis

Let $S$ be rows in `Sales` and $P$ be rows in `Product`.

| Phase | Operation | Complexity | Note |
| :--- | :--- | :--- | :--- |
| **1. Joining** | `JOIN` | $O(S)$ or $O(S \log P)$ | Depends on indexing. Since `product_id` is the Primary Key of `Product`, the lookup for each sale is extremely fast (Index Seek). |

**Total Complexity:** $O(S)$ (Linear relative to the number of sales).
