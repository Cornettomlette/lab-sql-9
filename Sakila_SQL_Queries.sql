USE sakila;
/* We will be trying to predict if a customer will be renting a film this month based on their previous activity and other details. 
We will first construct a table with:

Customer ID
City
Most rented film category
Total films rented
Total money spent
How many films rented last month */


# City
CREATE VIEW `customer_city` AS SELECT customer.customer_id, city.city
FROM customer
INNER JOIN address ON customer.address_id = address.address_id
INNER JOIN city ON address.city_id = city.city_id
GROUP BY customer.customer_id
ORDER BY customer.customer_id;

# Most rented film category
CREATE VIEW `most_rented_category` AS SELECT customer_id, category_name FROM 
(SELECT rental.customer_id as customer_id, count(rental.rental_id) as total_rentals, film_category.category_id, category.name as category_name,
row_number() over (partition by rental.customer_id order by count(rental.rental_id) desc) as ranking_max_rented_category 
FROM rental
INNER JOIN inventory ON rental.inventory_id = inventory.inventory_id
INNER JOIN film_category ON inventory.film_id = film_category.film_id
INNER JOIN category ON film_category.category_id = category.category_id
GROUP BY rental.customer_id, film_category.category_id, category.name) AS table_popular_category
WHERE ranking_max_rented_category = 1
ORDER BY customer_id;

# Total films rented
CREATE VIEW `total_rented` AS SELECT customer.customer_id, count(rental_id) as total_rented
FROM customer
INNER JOIN rental ON customer.customer_id = rental.customer_id
GROUP BY customer.customer_id
ORDER BY customer.customer_id; 

# Total money spent
CREATE VIEW `total_money_spent` AS SELECT customer_id, sum(amount) AS amount_spent FROM payment
GROUP BY customer_id;  

# How many films rented last month
CREATE VIEW `films_rented_last_m` AS SELECT customer.customer_id, count(rental_id) as films_rented_last_month from rental
RIGHT OUTER JOIN customer ON 
	rental.customer_id = customer.customer_id and rental_date >= 20050515 and rental_date <= 20050530
GROUP BY customer_id
ORDER BY customer_id;

# Will rent anything this month
CREATE VIEW `will_rent_or_not` AS SELECT customer.customer_id, 
CASE
WHEN count(rental_id) > 0 THEN 'YES'
ELSE 'NO'
END AS 'rental_made_or_not'
from rental
RIGHT OUTER JOIN customer ON 
rental.customer_id = customer.customer_id AND rental_date >= 20050615 and rental_date <= 20050630
GROUP BY customer_id
ORDER BY customer_id;

# Final data frame
SELECT customer_city.customer_id, city, category_name, total_rented, amount_spent, films_rented_last_month, rental_made_or_not  FROM customer_city
JOIN most_rented_category ON customer_city.customer_id = most_rented_category.customer_id
JOIN total_rented ON total_rented.customer_id = most_rented_category.customer_id
JOIN total_money_spent ON total_rented.customer_id = total_money_spent.customer_id
JOIN films_rented_last_m ON total_money_spent.customer_id = films_rented_last_m.customer_id
JOIN will_rent_or_not ON films_rented_last_m.customer_id = will_rent_or_not.customer_id;

SELECT count(rental_made_or_not) FROM will_rent_or_not
WHERE rental_made_or_not = 'NO';
# Only 9 'NO' values are in the data set
