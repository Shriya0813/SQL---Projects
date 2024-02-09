	 -- Zomato Data Exploration -- 

-- Q1:What is the total amount each customer spent on zomato?

select sales.userid, 
sum(product.price) as amount_spent
from sales
join product on sales.product_id = product.product_id
group by sales.userid;

-- Q2:How many days each customer visited zomato?

select userid, count(distinct created_date) days 
from sales 
group by userid;

-- Q3:What was the first product purchased by each customer?

select userid, product.product_id, 
product.product_name from
	(select *, rank() over(partition by userid 
    order by created_date asc) rnk 
	from sales) a
join product on a.product_id = product.product_id
where rnk = 1;
 
 --  ALTERNATIVE METHOD  --
with cte as(
	select userid, p.product_id, p.product_name, 
    rank() over(partition by userid order by created_date asc) rnk 
    from sales s
    join product p on s.product_id = p.product_id
    )
select * from cte where rnk = 1;

-- Q4:a) What is the most purchased item on the menu and  
-- how many times was it purchased by all customers?

select s.product_id, p.product_name, 
count(s.product_id) as p_count
from sales s
join product p on s.product_id = p.product_id
group by s.product_id, p.product_name 
order by p_count desc 
limit 1;

-- Q4:b) Find out how many times each customer bought the 
-- top-selling item.

select userid, count(product_id) as p_count 
from sales where product_id =
	(select product_id 
     from sales
	 group by product_id 
     order by count(product_id) desc 
     limit 1)
group by userid;

-- Q5: Which item was the most popular for each customer?

with cte as(
	select s.userid,s.product_id,p.product_name,
    count(s.product_id), 
	rank() over(partition by s.userid
	order by count(s.product_id) desc) as rn 
    from sales s
    join product p on s.product_id = p.product_id
	group by 1,2,3 
    order by userid asc, count(product_id) desc
    )
select * from cte where rn = 1;

-- Q6: Which item was purchased first by the customer after 
-- they became a member?

select * from
	(select s.userid, s.product_id, p.product_name,
    s.created_date, g.gold_signup_date,
	row_number() over(partition by userid 
    order by created_date asc) rn 
    from sales s
	join goldusers_signup g on g.userid = s.userid
	join product p on p.product_id = s.product_id
	where created_date >= gold_signup_date
	) a
where rn =1;

-- Q7: Which item was purchased just before the customer 
-- became a member?

select * from
	(select s.userid, s.product_id, p.product_name,
    s.created_date, g.gold_signup_date,
	row_number() over(partition by userid 
    order by created_date desc) rn 
	from sales s
	join goldusers_signup g on g.userid = s.userid
    join product p on p.product_id = s.product_id
	where created_date <= gold_signup_date
	order by userid asc, created_date desc
    ) a
where rn=1;

-- Q8: What is the total number of orders and amount spent 
-- for each member before they became a member?

select s.userid,count(s.product_id) as order_purchased,
sum(p.price) as total_amt_spent
from sales s
join goldusers_signup g on g.userid = s.userid
join product p on p.product_id = s.product_id
where created_date < gold_signup_date
group by userid 
order by userid;

-- Q9 a): If buying each product generates points for eg 5rs=2
-- zomato points and each product has different purchasing
-- points for eg p1 5rs=1 zomato point, for p2 2rs=1 zomato 
-- point and p3 5rs=1 zomato point.
-- Calculate points collected by each customers.

select userid, sum(points) points_earned,
(sum(points)*2.5) total_cashback_earned from
	(select s.userid,s.product_id,sum(p.price) amount,
	case 
		when s.product_id=1 then round(sum(p.price)/5)
		when s.product_id=2 then round(sum(p.price)/2)
		when s.product_id=3 then round(sum(p.price)/5)
		else 0
	 end as points
	 from sales s
	 join product p on s.product_id = p.product_id 
	 group by 1,2 
     order by 1 asc) a
group by userid;

-- Q9 b):For which product most zomato points have been given 
-- till now.

select product_id,sum(points) total_points from
	(select s.userid,s.product_id,sum(p.price) amount,
	case 
		when s.product_id=1 then round(sum(p.price)/5)
		when s.product_id=2 then round(sum(p.price)/2)
		when s.product_id=3 then round(sum(p.price)/5)
		else 0
	 end as points
	 from sales s
	 join product p on s.product_id = p.product_id 
	 group by 1,2 order by 1 asc) a
group by product_id 
order by total_points desc 
limit 1;

-- Q10: In the first year after a customer joins the gold
-- program(including their join date) irrespective of what
-- the customer has puchased they earn 5 zomato points for 
-- every 10rs spent, who earned more userid 1 or userid 3 and 
-- what was their points earnings in their first year?

select s.userid, s.product_id, s.created_date,
g.gold_signup_date, round(p.price/2) total_points_earned
from sales s
join goldusers_signup g on g.userid = s.userid
join product p on p.product_id = s.product_id
where created_date >= gold_signup_date 
and created_date <= date_add(gold_signup_date,interval 1 year);

-- Q11: Rank all the transactions for each member whenever 
-- they are a zomato gold member for every non gold member
-- transaction mark as na. 

select s.userid, s.product_id, s.created_date,
g.gold_signup_date,
case 
	when gold_signup_date is null then 'na' 
    else 
    (rank() over(partition by userid order by created_date desc)) 
end as rnk
from sales s
left join goldusers_signup g on s.userid = g.userid
and created_date >= gold_signup_date;
