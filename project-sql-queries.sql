/* Query 1 - Query used for first insight: 
How has the rental and spend behavior of the top 10 customers evolved between February and April 2007?   */

WITH top_customers AS (  SELECT cus.customer_id customer_id,
                                SUM(pay.amount) amount
                           FROM customer cus
                                JOIN payment pay
                                ON cus.customer_id = pay.customer_id
                       GROUP BY 1
                       ORDER BY 2 DESC
                          LIMIT 10)


  SELECT DATE_TRUNC('month', pay.payment_date) payment_month,
         CASE WHEN DATE_PART('month', pay.payment_date) = 1 THEN 'Jan'
              WHEN DATE_PART('month', pay.payment_date) = 2 THEN 'Feb'
              WHEN DATE_PART('month', pay.payment_date) = 3 THEN 'Mar'
              WHEN DATE_PART('month', pay.payment_date) = 4 THEN 'Apr'
              WHEN DATE_PART('month', pay.payment_date) = 5 THEN 'May'
              WHEN DATE_PART('month', pay.payment_date) = 6 THEN 'Jun'
              WHEN DATE_PART('month', pay.payment_date) = 7 THEN 'Jul'
              WHEN DATE_PART('month', pay.payment_date) = 8 THEN 'Aug'
              WHEN DATE_PART('month', pay.payment_date) = 9 THEN 'Sep'
              WHEN DATE_PART('month', pay.payment_date) = 10 THEN 'Oct'
              WHEN DATE_PART('month', pay.payment_date) = 11 THEN 'Nov'
              WHEN DATE_PART('month', pay.payment_date) = 12 THEN 'Dec'
              END month_2007,
         COUNT(pay.*) payment_count,
         SUM(pay.amount) revenue
    FROM customer cus
         JOIN payment pay
         ON cus.customer_id = pay.customer_id
   WHERE cus.customer_id IN (SELECT customer_id FROM top_customers)
         AND DATE_PART('year', pay.payment_date) = 2007
GROUP BY 1, 2
ORDER BY 1;


/* Query 2 - Query used for the second insight:
What was the difference in Spend for each of the top 10 customers between March and April 2007?*/

WITH top_customers AS (  SELECT cus.customer_id customer_id,
                                SUM(pay.amount) amount
                           FROM customer cus
                                JOIN payment pay
                                ON cus.customer_id = pay.customer_id
                       GROUP BY 1
                       ORDER BY 2 DESC
                          LIMIT 10),


      top_customers_transactions AS (SELECT CONCAT(cus.first_name, ' ', cus.last_name) customer_name,
                                            DATE_TRUNC('month', pay.payment_date) payment_month,
                                            COUNT(pay.*) pay_count,
                                            SUM(pay.amount) pay_amount
                                       FROM customer cus
                                            JOIN payment pay
                                            ON cus.customer_id = pay.customer_id
                                      WHERE cus.customer_id IN (SELECT customer_id FROM top_customers)
                                            AND DATE_PART('year', pay.payment_date) = 2007
                                      GROUP BY 1, 2
                                      ORDER BY 1, 2)

  SELECT customer_name,
         payment_month,
         CASE WHEN DATE_PART('month', payment_month) = 3 THEN 'Mar'
              WHEN DATE_PART('month', payment_month) = 4 THEN 'Apr'
              END month_2007,
         pay_amount,
         pay_amount - LAG (pay_amount) OVER (PARTITION BY customer_name ORDER BY payment_month) diff_prev_month
    FROM top_customers_transactions
   WHERE DATE_PART('month', payment_month) IN (3,4)
ORDER BY 2, 1;


/* Query 3 - Query used for the second insight:
How does the rental length of films within family friendly categories compares to overall rental length?*/

WITH family_rentals AS (SELECT fil.title film_title,
                               cat.name category,
                               fil.rental_duration rental_duration
                          FROM film fil
                               INNER JOIN film_category fc
                               ON fil.film_id = fc.film_id
                               INNER JOIN category cat
                               ON cat.category_id = fc.category_id
                         WHERE cat.name IN ('Animation', 'Children', 'Classics', 'Comedy', 'Family', 'Music')),

      total_rentals AS (SELECT fil.title film_title,
                               cat.name category,
                               fil.rental_duration rental_duration,
                               NTILE(4) OVER (ORDER BY rental_duration) standard_quartile
                          FROM film fil
                               INNER JOIN film_category fc
                               ON fil.film_id = fc.film_id
                               INNER JOIN category cat
                               ON cat.category_id = fc.category_id)

  SELECT CASE WHEN tr.standard_quartile = 1 THEN '1st quartile'
              WHEN tr.standard_quartile = 2 THEN '2nd quartile'
              WHEN tr.standard_quartile = 3 THEN '3rd quartile'
              WHEN tr.standard_quartile = 4 THEN '4th quartile'
              END standard_quartile,
         COUNT(fr.*) film_count
    FROM family_rentals fr
         INNER JOIN total_rentals tr
         ON fr.film_title = tr.film_title
GROUP BY 1
ORDER BY 1;

/* Query 4 - Query used for the fourth insight:
Which family friendly categories have the highest and lowest average rentals per distinct title? */

WITH family_rentals AS (SELECT fil.title film_title,
                               cat.name category,
                               ren.rental_id rental
                          FROM film fil
                               INNER JOIN film_category fc
                               ON fil.film_id = fc.film_id
                               INNER JOIN category cat
                               ON fc.category_id = cat.category_id
                               INNER JOIN inventory inv
                               ON fil.film_id = inv.film_id
                               LEFT JOIN rental ren
                               ON inv.inventory_id = ren.inventory_id
                         WHERE cat.name IN ('Animation', 'Children', 'Classics', 'Comedy', 'Family', 'Music')),

family_rentals_count AS (SELECT DISTINCT(film_title) film_title,
                                category,
                                COUNT(rental) OVER (PARTITION BY film_title) rental_count
                           FROM family_rentals
                       ORDER BY 2, 1)

  SELECT category,
         COUNT(film_title) title_count,
         SUM(rental_count) total_rentals,
         SUM(rental_count)/COUNT(film_title) avg_rental
    FROM family_rentals_count
GROUP BY 1
ORDER BY 4 DESC;
