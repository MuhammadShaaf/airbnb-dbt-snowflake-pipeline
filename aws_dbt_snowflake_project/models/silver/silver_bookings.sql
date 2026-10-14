
{{
    config(
        materialized='incremental',
        unique_key='BOOKING_ID',
        incremental_strategy='merge'
    )
}}

WITH source AS (

    SELECT
        BOOKING_ID,
        LISTING_ID,
        TO_DATE(BOOKING_DATE) AS BOOKING_DATE,
        NIGHTS_BOOKED,
        BOOKING_AMOUNT,
        CLEANING_FEE,
        SERVICE_FEE,
        {{ normalize_status('BOOKING_STATUS') }} AS BOOKING_STATUS,
        CREATED_AT,

    FROM {{ ref('bronze_bookings') }}

),

deduplicated AS (

    SELECT *
    FROM source

    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY BOOKING_ID
        ORDER BY CREATED_AT DESC NULLS LAST
    ) = 1

),

transformed AS (

    SELECT
        BOOKING_ID,
        LISTING_ID,
        BOOKING_DATE,
        NIGHTS_BOOKED,
        BOOKING_AMOUNT,
        COALESCE(CLEANING_FEE, 0) AS CLEANING_FEE,
        COALESCE(SERVICE_FEE, 0) AS SERVICE_FEE,
        BOOKING_STATUS,
        CREATED_AT,

        -- Accommodation subtotal
        {{ multiply(
            'NIGHTS_BOOKED',
            'BOOKING_AMOUNT',
            2
        ) }} AS ACCOMMODATION_AMOUNT,

        -- Total fees
        COALESCE(CLEANING_FEE, 0)
            + COALESCE(SERVICE_FEE, 0) AS TOTAL_FEES,

        -- Complete booking value
        {{ calculate_booking_total(
            'NIGHTS_BOOKED',
            'BOOKING_AMOUNT',
            'CLEANING_FEE',
            'SERVICE_FEE'
        ) }} AS TOTAL_AMOUNT,

        -- Length of stay
        CASE
            WHEN NIGHTS_BOOKED IS NULL OR NIGHTS_BOOKED <= 0
                THEN 'INVALID_STAY'
            WHEN NIGHTS_BOOKED <= 3 THEN 'SHORT_STAY'
            WHEN NIGHTS_BOOKED <= 7 THEN 'MEDIUM_STAY'
            ELSE 'LONG_STAY'
        END AS STAY_CATEGORY,

        -- Standardized status classification
        CASE
            WHEN BOOKING_STATUS = 'CONFIRMED' THEN 'CONFIRMED'
            WHEN BOOKING_STATUS = 'CANCELLED' THEN 'CANCELLED'
            ELSE 'UNKNOWN'
        END AS BOOKING_STATUS_CATEGORY,

        -- Simplified confirmed-booking revenue measure
        CASE
            WHEN BOOKING_STATUS = 'CONFIRMED'
                THEN {{ calculate_booking_total(
                    'NIGHTS_BOOKED',
                    'BOOKING_AMOUNT',
                    'CLEANING_FEE',
                    'SERVICE_FEE'
                ) }}
            ELSE 0
        END AS CONFIRMED_BOOKING_REVENUE,

        -- Data quality flag
        CASE
            WHEN BOOKING_ID IS NULL
                THEN 'MISSING_BOOKING_ID'
            WHEN LISTING_ID IS NULL
                THEN 'MISSING_LISTING_ID'
            WHEN BOOKING_DATE IS NULL
                THEN 'INVALID_BOOKING_DATE'
            WHEN NIGHTS_BOOKED IS NULL OR NIGHTS_BOOKED <= 0
                THEN 'INVALID_NIGHTS'
            WHEN BOOKING_AMOUNT IS NULL OR BOOKING_AMOUNT < 0
                THEN 'INVALID_BOOKING_AMOUNT'
            WHEN CLEANING_FEE < 0 OR SERVICE_FEE < 0
                THEN 'INVALID_FEE'
            WHEN BOOKING_STATUS NOT IN ('CONFIRMED', 'CANCELLED')
                 OR BOOKING_STATUS IS NULL
                THEN 'INVALID_BOOKING_STATUS'
            ELSE 'VALID'
        END AS DATA_QUALITY_STATUS,

        -- Date dimensions
        YEAR(BOOKING_DATE) AS BOOKING_YEAR,
        MONTH(BOOKING_DATE) AS BOOKING_MONTH

    FROM deduplicated

)

SELECT *
FROM transformed
