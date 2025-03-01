SELECT * 
FROM employees_cleaned 
WHERE CAST(SUBSTRING(join_date, 1, 4) AS INT) > 2015;


SELECT department, AVG(salary) AS avg_salary
FROM employees_cleaned
GROUP BY department;


SELECT * 
FROM employees_cleaned
WHERE project = 'Alpha';


SELECT job_role, COUNT(*) AS total_employees
FROM employees_cleaned
GROUP BY job_role;


SELECT e.*
FROM employees_cleaned e
JOIN (
    SELECT department, AVG(salary) AS avg_salary
    FROM employees_cleaned
    GROUP BY department
) dept_avg
ON e.department = dept_avg.department
WHERE e.salary > dept_avg.avg_salary;


SELECT department, COUNT(*) AS total_employees
FROM employees_cleaned
GROUP BY department
ORDER BY total_employees DESC
LIMIT 1;


SELECT COUNT(*) 
FROM employees_cleaned 
WHERE emp_id IS NULL 
   OR name IS NULL 
   OR age IS NULL 
   OR job_role IS NULL 
   OR salary IS NULL 
   OR project IS NULL 
   OR join_date IS NULL 
   OR department IS NULL;



SELECT e.*, d.location
FROM employees_cleaned e
JOIN departments d
ON e.department = d.department_name;



SELECT *, 
       RANK() OVER (PARTITION BY department ORDER BY salary DESC) AS salary_rank
FROM employees_cleaned;



SELECT * 
FROM (
    SELECT *, 
           DENSE_RANK() OVER (PARTITION BY department ORDER BY salary DESC) AS rank
    FROM employees_cleaned
) ranked_employees
WHERE rank <= 3;