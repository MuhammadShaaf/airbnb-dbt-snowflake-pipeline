
{{
    config(
        materialized='incremental',
        unique_key='HOST_ID',
        incremental_strategy='merge'
    )
}}

WITH source AS (

    SELECT
        HOST_ID,
        REPLACE(TRIM(HOST_NAME), ' ', '_') AS HOST_NAME,
        TRY_TO_DATE(HOST_SINCE) AS HOST_SINCE,
        IS_SUPERHOST,
        TRY_TO_NUMBER(
            REPLACE(TO_VARCHAR(RESPONSE_RATE), '%', '')
        ) AS RESPONSE_RATE,
        CREATED_AT::TIMESTAMP_NTZ AS CREATED_AT

    FROM {{ ref('bronze_hosts') }}

),

transformed AS (

    SELECT
        HOST_ID,
        HOST_NAME,
        HOST_SINCE,
        IS_SUPERHOST,
        RESPONSE_RATE,

        CASE
            WHEN RESPONSE_RATE IS NULL THEN 'UNKNOWN'
            WHEN RESPONSE_RATE > 95 THEN 'VERY GOOD'
            WHEN RESPONSE_RATE > 80 THEN 'GOOD'
            WHEN RESPONSE_RATE > 60 THEN 'FAIR'
            ELSE 'POOR'
        END AS RESPONSE_RATE_QUALITY,

        CASE
            WHEN HOST_ID IS NULL THEN 'MISSING_HOST_ID'
            WHEN HOST_NAME IS NULL OR HOST_NAME = ''
                THEN 'MISSING_HOST_NAME'
            WHEN RESPONSE_RATE < 0 OR RESPONSE_RATE > 100
                THEN 'INVALID_RESPONSE_RATE'
            ELSE 'VALID'
        END AS DATA_QUALITY_STATUS,

        CREATED_AT

    FROM source

)

SELECT *
FROM transformed
