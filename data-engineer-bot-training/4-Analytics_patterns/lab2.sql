-- use grouping sets - to perform different groups at different level in a single query and avoid union all which are most computational cost 
WITH combined AS (
SELECT 
    d.*, 
    we.*,
    CASE 
      WHEN referrer LIKE '%zachwilson%' THEN 'On Site'
      WHEN referrer LIKE '%eczachly%' THEN 'On Site'
      WHEN referrer LIKE '%dataengineer.io%' THEN 'On Site'
      WHEN referrer LIKE '%t.co%' THEN 'Twitter'
      WHEN referrer LIKE '%linkdedin%' THEN 'Linkedin'
      WHEN referrer LIKE '%instagram%' THEN 'Instagram'
      WHEN referrer IS NULL THEN 'Direct'
      ELSE 'Other' 
      END AS referrer_mapped
FROM bootcamp.web_events we 
INNER JOIN bootcamp.devices d  ON we.device_id = d.device_id  
) 
  SELECT COALESCE(referrer_mapped, '(overall)') AS referrer_mapped, 
         COALESCE(browser_type, '(overall)'), 
         COALESCE(os_type, '(overall)'),
         COUNT(1) as number_of_site_hits, 
         COUNT(CASE WHEN url = '/signup' THEN 1 END) AS number_of_signup_visits,
         COUNT(CASE WHEN url = '/contact' THEN 1 END) AS number_of_contact_visits,
         COUNT(CASE WHEN url = '/login' THEN 1 END) AS number_of_login_visits
FROM combined 
GROUP BY GROUPING SETS(
    (referrer_mapped, browser_type, os_type),
    (os_type),
    (browser_type),
    (referrer_mapped),
    () -- EMPTY FOR A GRANT TOTAL 
)

-- the lowest grain for above query referrer, browser_type and os type


-- the above query got a little bug respected to browser type and os type in some cases where 
-- are null is treated as overall 
-- so we handle the nulls 
WITH combined AS (
SELECT 
    COALESCE(d.browser_type, 'N/A') AS browser_type,
    COALESCE(d.os_type, 'N/A') AS os_type,
    CASE 
      WHEN referrer LIKE '%zachwilson%' THEN 'On Site'
      WHEN referrer LIKE '%eczachly%' THEN 'On Site'
      WHEN referrer LIKE '%dataengineer.io%' THEN 'On Site'
      WHEN referrer LIKE '%t.co%' THEN 'Twitter'
      WHEN referrer LIKE '%linkdedin%' THEN 'Linkedin'
      WHEN referrer LIKE '%instagram%' THEN 'Instagram'
      WHEN referrer IS NULL THEN 'Direct'
      ELSE 'Other' 
      END AS referrer_mapped
FROM bootcamp.web_events we 
INNER JOIN bootcamp.devices d  ON we.device_id = d.device_id  
) 
  SELECT COALESCE(referrer_mapped, '(overall)') AS referrer_mapped, 
         COALESCE(browser_type, '(overall)'), 
         COALESCE(os_type, '(overall)'),
         COUNT(1) as number_of_site_hits, 
         COUNT(CASE WHEN url = '/signup' THEN 1 END) AS number_of_signup_visits,
         COUNT(CASE WHEN url = '/contact' THEN 1 END) AS number_of_contact_visits,
         COUNT(CASE WHEN url = '/login' THEN 1 END) AS number_of_login_visits
FROM combined 
GROUP BY GROUPING SETS(
    (referrer_mapped, browser_type, os_type),
    (os_type),
    (browser_type),
    (referrer_mapped),
    () -- EMPTY FOR A GRANT TOTAL 
)


-- this turn is something like a olap cube in which is easy to perform analyticis
WITH combined AS (
SELECT 
    COALESCE(d.browser_type, 'N/A') AS browser_type,
    COALESCE(d.os_type, 'N/A') AS os_type,
    CASE 
      WHEN referrer LIKE '%zachwilson%' THEN 'On Site'
      WHEN referrer LIKE '%eczachly%' THEN 'On Site'
      WHEN referrer LIKE '%dataengineer.io%' THEN 'On Site'
      WHEN referrer LIKE '%t.co%' THEN 'Twitter'
      WHEN referrer LIKE '%linkdedin%' THEN 'Linkedin'
      WHEN referrer LIKE '%instagram%' THEN 'Instagram'
      WHEN referrer IS NULL THEN 'Direct'
      ELSE 'Other' 
      END AS referrer_mapped
FROM bootcamp.web_events we 
INNER JOIN bootcamp.devices d  ON we.device_id = d.device_id  
) 
  SELECT COALESCE(referrer_mapped, '(overall)') AS referrer_mapped, 
         COALESCE(browser_type, '(overall)'), 
         COALESCE(os_type, '(overall)'),
         COUNT(1) as number_of_site_hits, 
         COUNT(CASE WHEN url = '/signup' THEN 1 END) AS number_of_signup_visits,
         COUNT(CASE WHEN url = '/contact' THEN 1 END) AS number_of_contact_visits,
         COUNT(CASE WHEN url = '/login' THEN 1 END) AS number_of_login_visits,
         CAST(COUNT(CASE WHEN url = '/signup' THEN 1 END) AS REAL) / COUNT(1) AS pct_visited_signup
FROM combined 
GROUP BY GROUPING SETS(
    (referrer_mapped, browser_type, os_type),
    (os_type),
    (browser_type),
    (referrer_mapped),
    () -- EMPTY FOR A GRANT TOTAL 
)
HAVING COUNT(1) > 100
ORDER BY pct_visited_signup DESC


CREATE TABLE sortiz.web_events_dashboard AS 
WITH combined AS (
SELECT 
    COALESCE(d.browser_type, 'N/A') AS browser_type,
    COALESCE(d.os_type, 'N/A') AS os_type,
    we.*,
    CASE 
      WHEN referrer LIKE '%zachwilson%' THEN 'On Site'
      WHEN referrer LIKE '%eczachly%' THEN 'On Site'
      WHEN referrer LIKE '%dataengineer.io%' THEN 'On Site'
      WHEN referrer LIKE '%t.co%' THEN 'Twitter'
      WHEN referrer LIKE '%linkdedin%' THEN 'Linkedin'
      WHEN referrer LIKE '%instagram%' THEN 'Instagram'
      WHEN referrer IS NULL THEN 'Direct'
      ELSE 'Other' 
      END AS referrer_mapped
FROM bootcamp.web_events we 
INNER JOIN bootcamp.devices d  ON we.device_id = d.device_id  
) 
  SELECT COALESCE(referrer_mapped, '(overall)') AS referrer_mapped, 
         COALESCE(browser_type, '(overall)') AS browser_type, 
         COALESCE(os_type, '(overall)') AS os_type,
         COUNT(1) as number_of_site_hits, 
         COUNT(CASE WHEN url = '/signup' THEN 1 END) AS number_of_signup_visits,
         COUNT(CASE WHEN url = '/contact' THEN 1 END) AS number_of_contact_visits,
         COUNT(CASE WHEN url = '/login' THEN 1 END) AS number_of_login_visits,
         CAST(COUNT(CASE WHEN url = '/signup' THEN 1 END) AS REAL) / COUNT(1) AS pct_visited_signup
FROM combined 
GROUP BY GROUPING SETS(
    (referrer_mapped, browser_type, os_type),
    (os_type),
    (browser_type),
    (referrer_mapped),
    () -- EMPTY FOR A GRANT TOTAL 
)
HAVING COUNT(1) > 100
ORDER BY pct_visited_signup DESC


-- SELF JOIN
-- FUNNEL ANALYSIS

WITH combined AS (
SELECT 
    COALESCE(d.browser_type, 'N/A') AS browser_type,
    COALESCE(d.os_type, 'N/A') AS os_type,
    we.*,
    CASE 
      WHEN referrer LIKE '%zachwilson%' THEN 'On Site'
      WHEN referrer LIKE '%eczachly%' THEN 'On Site'
      WHEN referrer LIKE '%dataengineer.io%' THEN 'On Site'
      WHEN referrer LIKE '%t.co%' THEN 'Twitter'
      WHEN referrer LIKE '%linkdedin%' THEN 'Linkedin'
      WHEN referrer LIKE '%instagram%' THEN 'Instagram'
      WHEN referrer IS NULL THEN 'Direct'
      ELSE 'Other' 
      END AS referrer_mapped
FROM bootcamp.web_events we 
INNER JOIN bootcamp.devices d  ON we.device_id = d.device_id  
) 
SELECT * 
FROM combined c1 
JOIN combined c2 
    ON c1.user_id = c2.user_id 
    AND DATE(c1.event_time) = DATE(c2.event_time)
    AND c1.event_time > c2.event_time 
WHERE c1.user_id = 1037893568
LIMIT 10

-- FOR FUNNEST ANALYSIS 
-- WE SEE HOW users duration in different levels of metrics
-- from one site to another to evaluate how much time 
-- or how many users too
-- for example how many time toke the users to suscribe or paid
-- and if we add some change, like a color into a button 
-- see if the time decrease or increase or even if the number of users
-- that suscribe or paid increase or decrease 

WITH combined AS (
SELECT 
    COALESCE(d.browser_type, 'N/A') AS browser_type,
    COALESCE(d.os_type, 'N/A') AS os_type,
    we.*,
    CASE 
      WHEN referrer LIKE '%zachwilson%' THEN 'On Site'
      WHEN referrer LIKE '%eczachly%' THEN 'On Site'
      WHEN referrer LIKE '%dataengineer.io%' THEN 'On Site'
      WHEN referrer LIKE '%t.co%' THEN 'Twitter'
      WHEN referrer LIKE '%linkdedin%' THEN 'Linkedin'
      WHEN referrer LIKE '%instagram%' THEN 'Instagram'
      WHEN referrer IS NULL THEN 'Direct'
      ELSE 'Other' 
      END AS referrer_mapped
FROM bootcamp.web_events we 
INNER JOIN bootcamp.devices d  ON we.device_id = d.device_id  
) , aggregated as (
SELECT c1.user_id, c2.url as to_url, c2.url as from_url, 
       min(c1.event_time - c2.event_time) as duration
FROM combined c1 
JOIN combined c2 
    ON c1.user_id = c2.user_id 
    AND DATE(c1.event_time) = DATE(c2.event_time)
GROUP BY c1.user_id, c1.url, c2.url
) 
SELECT to_url, from_url, 
    COUNT(1) AS number_of_users,
    MIN(duration) AS min_duration,
    MAX(duration) AS max_duration,
    AVG(duration) AS avg_duration

FROM aggregated 
GROUP BY to_url, from_url
HAVING COUNT(1) > 1000
LIMIT 100