-- CASE 1
-- newest 10 employees
select first_name, last_name, hire_date
from employees 
order by hire_date desc 
limit 10;

-- employeses who started after 2000
select * 
from employees 
where hire_date >= '2000-01-01';

-- employees with name John
select *
from employees 
where first_name = 'John';

--------------------------------------------------------------------------------

-- Case 2
-- employees with their departments
select e.first_name, e.last_name, d.dept_name
from dept_emp as de 
join employees as e
on de.emp_no = e.emp_no
join departments as d
on de.dept_no = d.dept_no;

-- managers with their departments
select e.first_name, e.last_name, d.dept_name
from dept_manager as dm
join employees as e
on dm.emp_no = e.emp_no
join departments as d
on dm.dept_no = d.dept_no;

-- employees current title
select e.first_name, e.last_name, t.title
from employees as e
join titles as t
on e.emp_no = t.emp_no
where t.to_date = '9999-01-01'

--------------------------------------------------------------------------------

-- CASE 3
-- num of people working in each department
select d.dept_name, count(*) as total_employees_in_dept
from dept_emp as de 
inner join departments as d
on de.dept_no = d.dept_no
group by d.dept_no;

-- average salary across company 
select AVG(average_salary) as average_salary
from(
	select emp_no, AVG(salary) as average_salary
	from salaries
	group by emp_no) as employee_average_salary;

-- top salary by dept 
with Salaries_Employees_Departments as(
	select *
	from
		departments as d
		join(
			select * from
			dept_emp as e
			join (
				select emp_no, AVG(salary) as average_salary
					from salaries
					group by emp_no) as emp_deets
			on emp_deets.emp_no = e.emp_no) as emp_salary_dept
		on d.dept_no = emp_salary_dept.dept_no)


select dept_name, MAX(average_salary) 
from Salaries_Employees_Departments
group by dept_name

--------------------------------------------------------------------------------

-- CASE D
-- employee bands
select e.emp_no, average_salary,
Case 
	when average_salary >= 80000 then 'High'
	when average_salary >= 40000 and average_salary <= 80000 then 'Medium'
	else 'Low'
	end as salary_level
from employees as e
join(
	select emp_no, AVG(salary) as average_salary
	from salaries
	group by emp_no) as average_employee_salary
on average_employee_salary.emp_no = e.emp_no;

