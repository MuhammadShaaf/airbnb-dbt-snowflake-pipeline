{{
    config(
        materialized = 'ephemeral'
    )
}}

-- The OBT has one row per BOOKING, so a listing appears many times.
-- A snapshot needs exactly one row per unique_key, so we keep one row per LISTING_ID.
WITH listings AS (

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
        PRICE_PER_GUEST,
        PRICE_CATEGORY,
        LISTING_CREATED_AT AS CREATED_AT
    FROM {{ ref('obt') }}

    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY LISTING_ID
        ORDER BY LISTING_CREATED_AT DESC NULLS LAST
    ) = 1

)

SELECT * FROM listings