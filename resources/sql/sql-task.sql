--1
SELECT model,
       fare_conditions,
       Count(seat_no)
FROM   aircrafts_data
       JOIN seats using (aircraft_code)
GROUP  BY model,
          fare_conditions 

--2
SELECT model,
       Count(seat_no)
FROM   aircrafts_data
       JOIN seats USING (aircraft_code)
GROUP  BY aircraft_code
ORDER  BY Count(seat_no) DESC
LIMIT  3 

--3
SELECT *
FROM   flights
WHERE  scheduled_departure + interval '2 hour'< actual_departure
OR     scheduled_arrival   + interval '2 hour'< actual_arrival


--4
SELECT ticket_no,
       passenger_name,
       contact_data
FROM   tickets
       JOIN ticket_flights USING(ticket_no)
       JOIN bookings USING(book_ref)
WHERE  fare_conditions = 'Business'
ORDER  BY book_date DESC
LIMIT  10 

--5
SELECT *
FROM   flights
WHERE  flight_id NOT IN(SELECT DISTINCT flight_id
                        FROM   ticket_flights
                               join tickets USING(ticket_no)
                        WHERE  fare_conditions = 'Business') 


--6
SELECT airport_name,
       city
FROM   airports_data
WHERE  airport_code IN (SELECT DISTINCT departure_airport
                        FROM   flights
                        WHERE  scheduled_departure < actual_departure) 


--7
SELECT airport_name,
       Count(flight_id) AS number_of_flights
FROM   airports_data a
       join flights f
         ON a.airport_code = f.departure_airport
GROUP  BY ( airport_name )
ORDER  BY ( number_of_flights ) DESC 


--8
SELECT *
FROM   flights
WHERE  scheduled_arrival != actual_arrival 


--9
SELECT aircraft_code,
       model,
       seat_no
FROM   aircrafts_data
       join seats USING (aircraft_code)
WHERE  fare_conditions != 'Economy'
       AND model :: json ->> 'ru' = 'Аэробус A321-200'
ORDER  BY seat_no 

--10
SELECT airport_code,
       airport_name,
       a.city
FROM   airports_data AS a
       join (SELECT city,
                    Count(*)
             FROM   airports_data
             GROUP  BY city
             HAVING Count(*) > 1) c
         ON a.city = c.city

--11
SELECT passenger_name
FROM  (SELECT passenger_name,
              SUM(total_amount)
       FROM   tickets
              join bookings USING (book_ref)
       GROUP  BY passenger_name
       HAVING SUM(total_amount) > (SELECT Avg(total_amount)
                                   FROM   bookings)) t 


--12
SELECT   *
FROM     flights f
join     airports_data a
ON       f.departure_airport = a.airport_code
WHERE    a.city::json->>'ru' = 'Екатеринбург'
AND      f.status = 'On Time'
AND      f.arrival_airport IN
         (
                SELECT airport_code
                FROM   airports_data
                WHERE  city::json->>'ru' = 'Москва' )
ORDER BY f.scheduled_departure limit 1


--13
SELECT ticket_no,
       amount
FROM   tickets
       join ticket_flights USING(ticket_no)
WHERE  amount = (SELECT Max(amount)
                 FROM   ticket_flights)
        OR amount = (SELECT Min(amount)
                     FROM   ticket_flights) 

--14
CREATE TABLE IF NOT EXISTS customers
(id VARCHAR(20) PRIMARY KEY,
fist_name text NOT NULL,
last_name text NOT NULL,
email VARCHAR(255) UNIQUE,
phone VARCHAR(255) UNIQUE NOT NULL);

--15
CREATE TABLE IF NOT EXISTS orders(
id BIGSERIAL PRIMARY KEY,
customer_id VARCHAR(20) NOT NULL REFERENCES customers (id),
quantity INTEGER
CHECK ( quantity >= 0 ));

--16
INSERT INTO customers
            (
                        id,
                        first_name,
                        last_name,
                        email,
                        phone
            )
SELECT tickets.passenger_id,
       Split_part(tickets.passenger_name, ' ', 1) AS first_name,
       Split_part(tickets.passenger_name, ' ', 2) AS last_name,
       tickets.contact_data::json->>'email',
       tickets.contact_data::json->>'phone'
FROM   tickets limit 5;

INSERT INTO orders
            (customer_id,
             quantity)
SELECT id,
       Count(ticket_no)
FROM   customers c
       join tickets t
         ON c.id = t.passenger_id
GROUP  BY id; 

--17

DROP TABLE orders;
DROP TABLE customers;
