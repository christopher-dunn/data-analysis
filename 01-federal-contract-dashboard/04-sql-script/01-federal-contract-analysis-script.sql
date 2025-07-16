/* Create clean 2023 table */

CREATE TABLE clean_contracts_2023 AS
SELECT
  -- Location fields
  recipient_county_name,
  recipient_state_code,
  recipient_country_code,

  -- Core dollar fields
  federal_action_obligation::NUMERIC AS federal_action_obligation,

  -- Recipient and agency metadata
  recipient_name,
  recipient_parent_name,
  awarding_agency_name,
  awarding_sub_agency_name,
  funding_agency_name,

  -- Time
  TO_DATE(action_date, 'YYYY-MM-DD') AS action_date,
  action_date_fiscal_year,
  award_id_piid,

  -- Categoricals
  naics_description,
  product_or_service_code_description,
  contracting_officers_determination_of_business_size,

  -- Flags (stored as 't'/'f' → converted to BOOLEAN)
  CASE WHEN veteran_owned_business = 't' THEN TRUE ELSE FALSE END AS veteran_owned_business,
  CASE WHEN minority_owned_business = 't' THEN TRUE ELSE FALSE END AS minority_owned_business,
  CASE WHEN woman_owned_business = 't' THEN TRUE ELSE FALSE END AS woman_owned_business

FROM federal_contracts_2023

-- Only keep rows with clean, parseable values
WHERE
  federal_action_obligation ~ '^[0-9.]+$'
  AND action_date ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$';


/* Create clean 2024 table */

CREATE TABLE clean_contracts_2024 AS
SELECT
  -- Location fields
  recipient_county_name,
  recipient_state_code,
  recipient_country_code,

  -- Core dollar fields
  federal_action_obligation::NUMERIC AS federal_action_obligation,

  -- Recipient and agency metadata
  recipient_name,
  recipient_parent_name,
  awarding_agency_name,
  awarding_sub_agency_name,
  funding_agency_name,

  -- Time
  TO_DATE(action_date, 'YYYY-MM-DD') AS action_date,
  action_date_fiscal_year,
  award_id_piid,

  -- Categoricals
  naics_description,
  product_or_service_code_description,
  contracting_officers_determination_of_business_size,

  -- Flags (stored as 't'/'f' → converted to BOOLEAN)
  CASE WHEN veteran_owned_business = 't' THEN TRUE ELSE FALSE END AS veteran_owned_business,
  CASE WHEN minority_owned_business = 't' THEN TRUE ELSE FALSE END AS minority_owned_business,
  CASE WHEN woman_owned_business = 't' THEN TRUE ELSE FALSE END AS woman_owned_business

FROM federal_contracts_2024

-- Only keep rows with clean, parseable values
WHERE
  federal_action_obligation ~ '^[0-9.]+$'
  AND action_date ~ '^[0-9]{4}-[0-9]{2}-[0-9]{2}$';


/* Create single cleaned table */

CREATE TABLE clean_contracts_all AS
SELECT *, 2023 AS contract_year FROM clean_contracts_2023
UNION ALL
SELECT *, 2024 AS contract_year FROM clean_contracts_2024;


/* Recipient Location view */

CREATE VIEW recipient_location AS
SELECT
  recipient_country_code,
  recipient_state_code,
  recipient_county_name,
  naics_description,
  recipient_name,
  contract_year,
  SUM(federal_action_obligation) AS total_awarded
FROM clean_contracts_all
GROUP BY
  recipient_country_code,
  recipient_state_code,
  recipient_county_name,
  naics_description,
  recipient_name,
  contract_year;


/* Top Agencies view */

CREATE VIEW top_agencies AS
SELECT
  awarding_agency_name,
  contract_year,
  SUM(federal_action_obligation) AS total_awarded,
  COUNT(*) AS contract_count
FROM clean_contracts_all
GROUP BY 1, 2;


/* Top Recipients view */

CREATE VIEW top_recipients AS
SELECT
  CASE 
    WHEN recipient_name = 'LOCKHEED MARTIN CORP' THEN 'LOCKHEED MARTIN CORPORATION'
    ELSE recipient_name
  END AS recipient_name,
  contract_year,
  SUM(federal_action_obligation) AS total_awarded,
  RANK() OVER (PARTITION BY contract_year ORDER BY SUM(federal_action_obligation) DESC) AS vendor_rank,
  SUM(SUM(federal_action_obligation)) OVER (PARTITION BY contract_year) AS total_market,
  SUM(federal_action_obligation) * 1.0 / SUM(SUM(federal_action_obligation)) OVER (PARTITION BY contract_year) AS pct_of_total,
  SUM(SUM(federal_action_obligation)) OVER (
    PARTITION BY contract_year
    ORDER BY SUM(federal_action_obligation) DESC
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
  ) * 1.0
  / SUM(SUM(federal_action_obligation)) OVER (PARTITION BY contract_year) AS running_pct_of_total
FROM clean_contracts_all
GROUP BY 
  CASE 
    WHEN recipient_name = 'LOCKHEED MARTIN CORP' THEN 'LOCKHEED MARTIN CORPORATION'
    ELSE recipient_name
  END,
  contract_year;


/* Awards by Agency view */

CREATE VIEW awards_by_agency AS
SELECT
  contract_year,
  awarding_agency_name,
  federal_action_obligation
FROM clean_contracts_all
WHERE federal_action_obligation IS NOT NULL
  AND federal_action_obligation > 0;


/* Dollar amount sense check */

SELECT
    SUM(federal_action_obligation) AS total_award_amount
FROM
    clean_contracts_all;


