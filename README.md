# HadoopHiveHue
Hadoop , Hive, Hue setup pseudo distributed  environment  using docker compose
# Hive Employee Data Analysis

## 💌 Project Overview

This project analyzes employee data using **Apache Hive**. It involves:

- **Loading and cleaning** employee data into a partitioned Hive table.
- **Executing queries** to extract insights.
- **Automating execution** using HQL scripts.
- **Saving results** and pushing them to **GitHub**.

---

## 💂️ Dataset Details

### **1. employees.csv**

| Column Name | Description                                                      |
| ----------- | ---------------------------------------------------------------- |
| emp\_id     | Unique employee ID                                               |
| name        | Employee's full name                                             |
| age         | Employee's age                                                   |
| job\_role   | Designation of the employee                                      |
| salary      | Annual salary of the employee                                    |
| project     | Assigned project (One of: Alpha, Beta, Gamma, Delta, Omega)      |
| join\_date  | Date when the employee joined                                    |
| department  | Department to which the employee belongs (Used for partitioning) |

### **2. departments.csv**

| Column Name      | Description                |
| ---------------- | -------------------------- |
| dept\_id         | Unique department ID       |
| department\_name | Name of the department     |
| location         | Location of the department |

---

## 🚀 Steps to Execute

### **Step 1: Start Hadoop & Hive Containers**

```sh
docker start hive-server  # Start Hive server container
docker exec -it hive-server /bin/bash  # Access Hive server container
hive  # Start Hive CLI
```

---

### **Step 2: Setup HDFS & Load Data**

#### **(A) Create Directories in HDFS**

```sh
docker exec -it namenode /bin/bash  
hdfs dfs -mkdir -p /data/employee_data  # Create HDFS directory
mkdir -p /data/employee_data  # Create local directory
exit  
```

#### **(B) Copy CSV Files to Namenode**

```sh
docker cp employees.csv namenode:/data/employee_data/employees.csv 
docker cp departments.csv namenode:/data/employee_data/departments.csv
```

#### **(C) Upload CSV Files to HDFS**

```sh
docker exec -it namenode /bin/bash  
hdfs dfs -put /data/employee_data/employees.csv /data/employee_data/  
hdfs dfs -put /data/employee_data/departments.csv /data/employee_data/  
hdfs dfs -ls /data/employee_data/  # Verify upload
exit  
```

---

### **Step 3: Create & Load Hive Tables**

#### **(A) Create Employees Table**

```sql
CREATE EXTERNAL TABLE IF NOT EXISTS employees (
    emp_id INT,
    name STRING,
    age INT,
    job_role STRING,
    salary DOUBLE,
    project STRING,
    join_date STRING
)
PARTITIONED BY (department STRING)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION '/data/employee_data';
```

#### **(B) Create Departments Table**

```sql
CREATE EXTERNAL TABLE IF NOT EXISTS departments (
    dept_id INT,
    department_name STRING,
    location STRING
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION '/data/employee_data';
```

#### **(C) Enable Dynamic Partitioning**

```sql
SET hive.exec.dynamic.partition=true;
SET hive.exec.dynamic.partition.mode=nonstrict;
```

#### **(D) Create Staging Table & Load Data**

```sql
CREATE EXTERNAL TABLE IF NOT EXISTS employees_staging (
    emp_id INT,
    name STRING,
    age INT,
    job_role STRING,
    salary DOUBLE,
    project STRING,
    join_date STRING,
    department STRING
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
LOCATION '/data/employee_data';
```

```sql
LOAD DATA INPATH '/data/employee_data/employees.csv' INTO TABLE employees_staging;
```

```sql
INSERT OVERWRITE TABLE employees PARTITION (department)
SELECT emp_id, name, age, job_role, salary, project, join_date, department
FROM employees_staging;
```

```sql
SHOW PARTITIONS employees;
```

#### **(E) Load Data into Departments Table**

```sql
LOAD DATA INPATH '/data/employee_data/departments.csv' INTO TABLE departments;
```

---

### **Step 4: Clean & Prepare Data**

```sql
CREATE TABLE employees_cleaned LIKE employees;
```

```sql
INSERT OVERWRITE TABLE employees_cleaned PARTITION (department)
SELECT emp_id, name, age, job_role, salary, project, join_date, department
FROM employees
WHERE department IS NOT NULL;
```

```sql
SHOW PARTITIONS employees_cleaned;
```

```sql
ALTER TABLE employees DROP PARTITION (department='department');
ALTER TABLE employees DROP PARTITION (department='HIVE_DEFAULT_PARTITION');
```

---

### **Step 5: Store Queries in an HQL File**

```sh
touch hql_queries.hql  # Create an HQL file
nano hql_queries.hql  # Open file in an editor
```

Copy the following queries into `hql_queries.hql`:

```sql
-- Query 1: Employees who joined after 2015
SELECT * FROM employees_cleaned WHERE CAST(SUBSTRING(join_date, 1, 4) AS INT) > 2015;

-- Query 2: Average salary per department
SELECT department, AVG(salary) AS avg_salary FROM employees_cleaned GROUP BY department;

-- Query 3: Employees in 'Alpha' project
SELECT * FROM employees_cleaned WHERE project = 'Alpha';

-- Query 4: Employee count by job role
SELECT job_role, COUNT(*) FROM employees_cleaned GROUP BY job_role;

-- Query 5: Employees earning above department average
SELECT e.* FROM employees_cleaned e JOIN (SELECT department, AVG(salary) AS avg_salary FROM employees_cleaned GROUP BY department) dept_avg ON e.department = dept_avg.department WHERE e.salary > dept_avg.avg_salary;

-- Query 6: Department with the most employees
SELECT department, COUNT(*) FROM employees_cleaned GROUP BY department ORDER BY COUNT(*) DESC LIMIT 1;

-- Query 7: Check for NULL values
SELECT COUNT(*) FROM employees_cleaned WHERE emp_id IS NULL OR name IS NULL OR age IS NULL OR job_role IS NULL OR salary IS NULL OR project IS NULL OR join_date IS NULL OR department IS NULL;

-- Query 8: Join Employees with Departments
SELECT e.*, d.location FROM employees_cleaned e JOIN departments d ON e.department = d.department_name;

-- Query 9: Rank Employees by Salary per Department
SELECT *, RANK() OVER (PARTITION BY department ORDER BY salary DESC) AS salary_rank FROM employees_cleaned;

-- Query 10: Top 3 highest-paid employees per department
SELECT * FROM (SELECT *, DENSE_RANK() OVER (PARTITION BY department ORDER BY salary DESC) AS rank FROM employees_cleaned) ranked WHERE rank <= 3;
```

---

### **Step 6: Execute Queries & Save Output**

```sh
docker cp hql_queries.hql hive-server:/opt/hql_queries.hql  
docker exec -it hive-server hive -f /opt/hql_queries.hql | tee /opt/hql_output.txt  
docker cp hive-server:/opt/hql_output.txt hql_output.txt  
ls -l  # Verify output
```

---

## 📊 **Final Output**

- **hql_queries.hql** → Contains all SQL queries.
- **hql_output.txt** → Stores query execution results.

This README provides a **step-by-step guide** from **loading data to executing queries** in Hive. 🚀

