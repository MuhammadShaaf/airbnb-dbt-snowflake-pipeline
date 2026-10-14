{{
    config(
        materialized = 'ephemeral'
    )
}}
 
WITH bookings AS (
 
    SELECT
        BOOKING_ID,
        BOOKING_DATE,
        BOOKING_YEAR,
        BOOKING_MONTH,
        STAY_CATEGORY,
        BOOKING_STATUS_CATEGORY,
        BOOKING_CREATED_AT AS CREATED_AT
    FROM {{ ref('obt') }}
 
)
 
SELECT * FROM bookings