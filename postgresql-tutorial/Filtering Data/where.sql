SELECT
    last_name,
    first_name
FROM
    customer
WHERE
    first_name = 'Jamie';

SELECT
    last_name,
    first_name
FROM
    customer
WHERE
    first_name = 'Jamie'
    AND last_name = 'Rice';


SELECT
    last_name,
    first_name
FROM
    customer
WHERE
    first_name IN ('Ann', 'Anne', 'Annie')

SELECT
    last_name,
    first_name
FROM
    customer
WHERE
    first_name LIKE 'Ann%'

SELECT
    first_name,
    LENGTH(first_name) name_length
FROM
    customer
WHERE
    first_name LIKE 'A%'
    AND LENGTH(first_name) BETWEEN 3 AND 5
ORDER BY
    name_length;

SELECT
  first_name,
  last_name
FROM
  customer
WHERE
  first_name LIKE 'Bra%'
  AND last_name <> 'Motley'


CREATE TABLE t(
   message text
);

INSERT INTO t(message)
VALUES('The rents are now 10% higher than last month'),
      ('The new film will have _ in the title');


SELECT * FROM t
WHERE message LIKE '%10$%%' ESCAPE '$'; -- treat % after 10 as a regular character