-- Using the 2019 Census county estimates data, calculate a ratio of births to
-- deaths for each county in New York state. Which region of the state generally
-- saw a higher ratio of births to deaths in 2019?

SELECT state_name,
       percentile_cont(.5)
       WITHIN GROUP (ORDER BY pop_est_2019)
FROM us_counties_pop_est_2019
WHERE state_name IN ('New York', 'California')
GROUP BY state_name;;


-- Which county had the greatest percentage loss of population between 2010 and 2019?

SELECT c2019.county_name,
       c2019.state_name,
       c2019.pop_est_2019                              AS pop_2019,
       c2010.estimates_base_2010                       AS pop_2010,
       c2019.pop_est_2019 - c2010.estimates_base_2010  AS raw_change,
       round((c2019.pop_est_2019::numeric - c2010.estimates_base_2010)
                 / c2010.estimates_base_2010 * 100, 1) AS pct_change
FROM us_counties_pop_est_2019 AS c2019
         JOIN us_counties_pop_est_2010 AS c2010
              ON c2019.state_fips = c2010.state_fips
                  AND c2019.county_fips = c2010.county_fips
ORDER BY pct_change ASC;

-- Was the 2019 median county population estimate higher in California or New York?

SELECT county_name,
       state_name,
       births_2019                                  AS births,
       deaths_2019                                  AS DEATHS,
       round(births_2019::numeric / deaths_2019, 2) AS birth_death_ratio
FROM us_counties_pop_est_2019
WHERE state_name = 'New York'
ORDER BY birth_death_ratio DESC;

-- Merge queries of the census county population estimates for 2010 and 2019.
-- Your results should include a column called year that specifies the
-- year of the estimate for each row in the results.

SELECT '2010'              AS year,
       state_fips,
       county_fips,
       county_name,
       state_name,
       estimates_base_2010 AS estimate
FROM us_counties_pop_est_2010
UNION
SELECT '2019'       AS year,
       state_fips,
       county_fips,
       county_name,
       state_name,
       pop_est_2019 AS estimate
FROM us_counties_pop_est_2019
ORDER BY state_fips, county_fips, year;


-- Determine the median of the percent change in estimated county
-- population between 2010 and 2019.

SELECT percentile_cont(.5)
       WITHIN GROUP (ORDER BY round((c2019.pop_est_2019::numeric - c2010.estimates_base_2010)
                                        / c2010.estimates_base_2010 * 100, 1)) AS percentile_50th
FROM us_counties_pop_est_2019 AS c2019
         JOIN us_counties_pop_est_2010 AS c2010
              ON c2019.state_fips = c2010.state_fips
                  AND c2019.county_fips = c2010.county_fips;


ALTER TABLE meat_poultry_egg_establishments ADD COLUMN meat_processing boolean;
ALTER TABLE meat_poultry_egg_establishments ADD COLUMN poultry_processing boolean;

SELECT * FROM meat_poultry_egg_establishments;

SELECT company,
       widget_output,
        rank() OVER (ORDER BY widget_output DESC),
        dense_rank() OVER (ORDER BY widget_output DESC)
FROM widget_companies
ORDER BY widget_output DESC;

SELECT


