SELECT
    first_name,
    last_name
FROM
    customer
ORDER BY
    first_name ASC,
    last_name DESC;

SELECT
    first_name,
    LENGTH(first_name) len 
FROM
    customer
ORDER BY
    len DESC;

CREATE TABLE sort_demo(num INT);

INSERT INTO sort_demo(num)
VALUES
    (1),
    (2),
    (3),
    (null);

SELECT
  num
FROM
  sort_demo
ORDER BY
  num DESC NULLS FIRST;

