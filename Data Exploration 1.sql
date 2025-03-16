select * from credit_card_transactions


--1-write a query to print top 5 cities with highest spends 
--and their percentage contribution of total credit card spends 

with cte1 as(
select sum(amount) as total_spends
from credit_card_transactions),
cte2 as(
select city,sum(amount) as total_contribution
from credit_card_transactions
group by city)
select top 5 cte2.*,round((total_contribution * 100/ total_spends),2) as percentage_contribution
from cte1,cte2
order by total_contribution desc


--2- write a query to print highest spend month and amount spent in that month for each card type

with cte1 as(
select card_type,year(transaction_date) as year,month(transaction_date) as month,sum(amount) as amount_spent
from credit_card_transactions
group by card_type,year(transaction_date),month(transaction_date)),
cte2 as(
select *,rank()over(partition by card_type order by amount_spent desc) as rn
from cte1)
select card_type,year,month,amount_spent
from cte2 
where rn=1


--3- write a query to print the transaction details(all columns from the table) for each card type when
--it reaches a cumulative of  1,000,000 total spends(We should have 4 rows in the o/p one for each card type)
with cte1 as(
select *,sum(amount) over(partition by card_type order by transaction_date,transaction_id) as total_spend
from credit_card_transactions),
cte2 as (
select *,dense_rank()over(partition by card_type order by total_spend) as rn
from cte1
where total_spend>=1000000)
select transaction_id,city,transaction_date,card_type,exp_type,gender,total_spend
from cte2
where rn=1


--4- write a query to find city which had lowest percentage spend for gold card type

with cte as (
select city,card_type,sum(amount) as amount
,sum(case when card_type='Gold' then amount end) as gold_amount
from credit_card_transactions
group by city,card_type)
select top 1
city,sum(gold_amount)*1.0/sum(amount) as gold_ratio
from cte
group by city
having sum(gold_amount) is not null
order by gold_ratio;


--5- write a query to print 3 columns:  city, highest_expense_type , lowest_expense_type (example format : Delhi , bills, Fuel)
with cte1 as(
select city,exp_type,sum(amount) as total_spend
from credit_card_transactions
group by city,exp_type),
cte2 as(
select *,dense_rank()over(partition by city order by total_spend desc) as rn_desc,
dense_rank() over(partition by city order by total_spend) as rn_asc
from cte1)
select city,max(case when rn_asc=1 then exp_type end) as lowest_expense_type,
max(case when rn_desc=1 then exp_type end) as highest_expense_type
from cte2
group by city


--6- write a query to find percentage contribution of spends by females for each expense type
select exp_type,sum(case when gender='F' then amount else 0 end)*1.0/sum(amount) as female_contribution_percentage
from credit_card_transactions
group by exp_type
order by female_contribution_percentage desc

--7- which card and expense type combination saw highest month over month growth in Jan-2014
with cte1 as(
select card_type,exp_type,year(transaction_date) as year,month(transaction_date) as month,sum(amount) as total_amount
from credit_card_transactions
group by card_type,exp_type,year(transaction_date),month(transaction_date)),
cte2 as(
select *,lag(total_amount,1)over(partition by card_type,exp_type order by year,month) as prev_month_spend
from cte1),
cte3 as(
select cte2.*,(total_amount-prev_month_spend) as mom_growth
from cte2)
select top 1 * from cte3
where year='2014' and month='1'
order by mom_growth desc

--8- during weekends which city has highest total spend to total no of transcations ratio 
select top 1 city,sum(amount)*1.0/count(*) as ratio
from credit_card_transactions
where DATEPART(weekday,transaction_date) in (1,7)
group by city
order by ratio desc

--9- which city took least number of days to reach its
--500th transaction after the first transaction in that city;

with cte as (
select *
,row_number() over(partition by city order by transaction_date,transaction_id) as rn
from credit_card_transactions)
select top 1 city,datediff(day,min(transaction_date),max(transaction_date)) as datediff1
from cte
where rn=1 or rn=500
group by city
having count(1)=2
order by datediff1 