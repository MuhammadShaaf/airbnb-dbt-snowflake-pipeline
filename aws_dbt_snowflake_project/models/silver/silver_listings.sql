{{
    config(
        materialized='incremental',
        unique_key='LISTING_ID',
        incremental_strategy='merge'
    )
}}

WITH source AS (

    SELECT
        TRY_TO_NUMBER(LISTING_ID::STRING)                   AS LISTING_ID,
        TRY_TO_NUMBER(HOST_ID::STRING)                      AS HOST_ID,
        {{ clean_string('PROPERTY_TYPE') }}                 AS PROPERTY_TYPE,
        {{ clean_string('ROOM_TYPE') }}                     AS ROOM_TYPE,
        {{ clean_string('CITY', 'title') }}                 AS CITY,
        {{ clean_string('COUNTRY', 'title') }}              AS COUNTRY,
        TRY_TO_NUMBER(ACCOMMODATES::STRING)                 AS ACCOMMODATES,
        TRY_TO_NUMBER(BEDROOMS::STRING)                     AS BEDROOMS,
        TRY_TO_NUMBER(BATHROOMS::STRING)                    AS BATHROOMS,
        TRY_TO_DECIMAL(PRICE_PER_NIGHT::STRING, 10, 2)      AS PRICE_PER_NIGHT,
        TRY_TO_TIMESTAMP_NTZ(CREATED_AT::STRING)            AS CREATED_AT

    FROM {{ ref('bronze_listings') }}

    {% if is_incremental() %}
    WHERE TRY_TO_TIMESTAMP_NTZ(CREATED_AT::STRING) >= (
        SELECT COALESCE(MAX(CREATED_AT), '1900-01-01'::TIMESTAMP_NTZ)
        FROM {{ this }}
    )
    {% endif %}

),

deduplicated AS (

    SELECT *
    FROM source

    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY LISTING_ID
        ORDER BY CREATED_AT DESC NULLS LAST
    ) = 1

),

transformed AS (

    SELECT
        LISTING_ID,
        HOST_ID,
        PROPERTY_TYPE,
        ROOM_TYPE,
        CITY,
        COUNTRY,
        ACCOMMODATES,
        BEDROOMS,
        BATHROOMS,
        PRICE_PER_NIGHT,
        CREATED_AT,

        ROUND(PRICE_PER_NIGHT / NULLIF(ACCOMMODATES, 0), 2) AS PRICE_PER_GUEST,

        CASE
            WHEN PRICE_PER_NIGHT IS NULL THEN 'UNKNOWN'
            WHEN PRICE_PER_NIGHT < 100   THEN 'BUDGET'
            WHEN PRICE_PER_NIGHT < 200   THEN 'STANDARD'
            ELSE 'PREMIUM'
        END AS PRICE_CATEGORY,

        CASE
            WHEN LISTING_ID IS NULL                          THEN 'MISSING_LISTING_ID'
            WHEN HOST_ID IS NULL                             THEN 'MISSING_HOST_ID'
            WHEN PROPERTY_TYPE IS NULL                       THEN 'MISSING_PROPERTY_TYPE'
            WHEN ROOM_TYPE IS NULL                           THEN 'MISSING_ROOM_TYPE'
            WHEN PRICE_PER_NIGHT IS NULL OR PRICE_PER_NIGHT <= 0
                                                             THEN 'INVALID_PRICE'
            WHEN ACCOMMODATES IS NULL OR ACCOMMODATES <= 0   THEN 'INVALID_CAPACITY'
            WHEN BEDROOMS IS NULL OR BEDROOMS < 0
                 OR BATHROOMS IS NULL OR BATHROOMS < 0       THEN 'INVALID_ROOM_COUNT'
            WHEN BEDROOMS > ACCOMMODATES                     THEN 'BEDROOMS_EXCEED_CAPACITY'
            ELSE 'VALID'
        END AS DATA_QUALITY_STATUS

    FROM deduplicated

)

SELECT *
FROM transformed