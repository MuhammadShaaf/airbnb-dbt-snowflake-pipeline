{{
    config(
        materialized = 'ephemeral'
    )
}}

-- One row per HOST_ID (a host appears once per booking in the OBT).
WITH hosts AS (

    SELECT
        HOST_ID,
        HOST_NAME,
        HOST_SINCE,
        IS_SUPERHOST,
        RESPONSE_RATE,
        RESPONSE_RATE_QUALITY,
        HOST_CREATED_AT AS CREATED_AT
    FROM {{ ref('obt') }}

    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY HOST_ID
        ORDER BY HOST_CREATED_AT DESC NULLS LAST
    ) = 1

)

SELECT * FROM hosts