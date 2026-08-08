SELECT
    customer_id
FROM
    payment
GROUP BY
    customer_id
ORDER BY
    customer_id;
 -- GROUP BY acts as DISTINCT here

 SELECT
    customer_id,
    SUM(amount)
FROM
    payment
GROUP BY
    customer_id
ORDER BY
    SUM(amount) DESC;

-- retrieve the total payment for each customer and display the customer name and amount:
SELECT
    first_name || ' ' || last_name full_name,
    SUM (amount) amount
FROM
    payment
    INNER JOIN customer USING (customer_id)
GROUP BY
    full_name
ORDER BY
    amount DESC;

-- count the nr of payments processed by each staff
SELECT
	staff_id,
	COUNT (payment_id)
FROM
	payment
GROUP BY
	staff_id;

-- group by with dates (casting)
SELECT
  payment_date::date payment_date,
  SUM(amount) sum
FROM
  payment
GROUP BY
  payment_date::date
ORDER BY
  payment_date DESC;