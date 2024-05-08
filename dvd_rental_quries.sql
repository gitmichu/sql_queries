-- Joins

SELECT *
FROM actor a
         JOIN film_actor fa
              ON a.actor_id = fa.actor_id
WHERE a.first_name LIKE 'Nick';


-- Window functions

-- Average money spend per customer in dvd rental

SELECT distinct first_name,
                last_name,
                ROUND(AVG(amount) OVER (PARTITION BY customer_id), 2) AS avg_amount_per_customer
FROM payment
         JOIN customer USING (customer_id)
ORDER BY avg_amount_per_customer DESC;

-- From which country customers rents the most DVDs

SELECT c.first_name,
       c.last_name,
       cou.country,
       rank() OVER (partition by cou.country order by count(distinct c.customer_id))
FROM customer c
         left join address a on c.address_id = a.address_id
         left join city ci on a.city_id = ci.city_id
         left join country cou on ci.country_id = cou.country_id;

-- Longest film by category

SELECT f.title,
       cat.name,
       f.length,
       dense_rank() OVER (partition by cat.name order by f.length DESC)
FROM film f
         left join film_category fc using (film_id)
         left join category cat using (category_id);

--

--  CTE-s

WITH action_films AS (SELECT f.title,
                             f.length
                      FROM film f
                               INNER JOIN film_category fc on f.film_id = fc.film_id
                               inner join category c on c.category_id = fc.category_id
                      WHERE c.name = 'Action')

SELECT *
FROM action_films;

WITH cte_rental AS (select staff_id,
                           COUNT(rental_id) rental_count
                    from rental
                    group by staff_id)

SELECT s.staff_id,
       first_name,
       last_name,
       rental_count
FROM staff s
         inner join cte_rental using (staff_id)

WITH film_stats AS (
    -- CTE 1: Calculate film statistics
    SELECT AVG(rental_rate) as avg_rental_rate,
           MAX(length)      AS max_length,
           MIN(length)      AS min_length
    FROM film),
     customer_stats AS (
         -- CTE 2: Calculate customer statistics
         SELECT COUNT(DISTINCT customer_id) AS total_customers,
                SUM(amount)                 AS total_payments
         FROM payment)

-- Main query using the CTEs
SELECT ROUND((SELECT avg_rental_rate FROM film_stats), 2) AS avg_film_rental_rate,
       (SELECT max_length FROM film_stats)                as max_film_length,
       (SELECT min_length FROM film_stats)                as min_film_length,
       (SELECT total_customers FROM customer_stats)       AS total_customers,
       (SELECT total_payments FROM customer_stats)        AS total_payments;


-- Recursive CTE

WITH RECURSIVE suboridantes AS (select employee_id,
                                       manager_id,
                                       full_name
                                FROM employees
                                WHERE employee_id = 2
                                UNION
                                SELECT e.employee_id,
                                       e.manager_id,
                                       e.full_name
                                FROM employees e
                                         inner join suboridantes s ON s.employee_id = e.manager_id)

SELECT *
FROM suboridantes;


-- Most rented films in each category

WITH film_rental_count AS (SELECT film.*, COUNT(rental.*) AS rental_count
                           FROM film
                                    join inventory using (film_id)
                                    join rental using (inventory_id)
                           GROUP BY film.film_id),
     category_rankings AS (SELECT category.name                                     AS category_name,
                                  row_number() over (PARTITION BY category.category_id
                                      ORDER BY film_rental_count.rental_count DESC) AS category_rank,
                                  film_rental_count.title                           as film_title,
                                  film_rental_count.rental_count                    AS rental_count
                           FROM film_rental_count
                                    JOIN film_category using (film_id)
                                    join category using (category_id))
SELECT c.name,
       dense_rank() OVER (PARTITION BY c.category_id ORDER BY fcr.rental_count DESC) AS category_rank,
       fcr.title,
       fcr.rental_count
FROM film_rental_count fcr
         join film_category fc using (film_id)
         join category c using (category_id)
order by c.name, rental_count DESC;

-- 3 most popular film in each category

WITH film_rental_count AS (SELECT film.*, COUNT(rental.*) AS rental_count
                           FROM film
                                    join inventory using (film_id)
                                    join rental using (inventory_id)
                           GROUP BY film.film_id),
     category_rankings AS (SELECT category.name                                     AS category_name,
                                  row_number() over (PARTITION BY category.category_id
                                      ORDER BY film_rental_count.rental_count DESC) AS category_rank,
                                  film_rental_count.title                           as film_title,
                                  film_rental_count.rental_count                    AS rental_count
                           FROM film_rental_count
                                    JOIN film_category using (film_id)
                                    join category using (category_id))
SELECT *
FROM category_rankings
WHERE category_rank <= 3
ORDER BY category_name;

-- window clause

WITH film_with_rental_count AS (SELECT film.*, COUNT(rental.*) AS rental_count
                                FROM film
                                         JOIN inventory USING (film_id)
                                         JOIN rental USING (inventory_id)
                                GROUP BY film.film_id)
SELECT category.name,
       ROW_NUMBER() OVER w AS row_number,
       DENSE_RANK() OVER w AS dense_rank,
       RANK() OVER w       AS rank,
       film_with_rental_count.title,
       film_with_rental_count.rental_count
FROM film_with_rental_count
         JOIN film_category USING (film_id)
         JOIN category USING (category_id)
WINDOW w AS (
        PARTITION BY category.category_id
        ORDER BY film_with_rental_count.rental_count DESC
        )
ORDER BY category.name;


-- The amount of payments were made on a given day
-- and a cumulative sum of payments which resets each month in a given date range.

WITH days_with_payment AS (SELECT day, coalesce(sum(payment.amount), 0) AS payment_amount
                           FROM generate_series('2007-02-14', '2007-03-23', '1 day':: interval) day
                                    left join payment on payment.payment_date::date = day
                           GROUP BY day)
SELECT day,
       payment_amount,
       sum(payment_amount) OVER (partition by extract(MONTH FROM (day))
           ORDER BY day ) as cumulative_payment_amount
from days_with_payment
order by day;

-- What disks (i.e., inventory table rows) spent the most time in the rental shop

WITH films_with_stale_duration AS (SELECT film.title AS film_title,
                                          inventory_id,
                                          rental_date - LAG(return_date) OVER (
                                              PARTITION BY inventory_id
                                              ORDER BY rental_date
                                              )      AS stale_duration
                                   FROM rental
                                            JOIN inventory USING (inventory_id)
                                            JOIN film USING (film_id)
                                   WHERE return_date IS NOT NULL)
SELECT inventory_id, film_title, stale_duration
FROM films_with_stale_duration
ORDER BY stale_duration DESC NULLS LAST
LIMIT 10;





