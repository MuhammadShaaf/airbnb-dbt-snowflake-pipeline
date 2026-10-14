{{
    config(
        materialized = 'table'
    )
}}

-- FACT TABLE: one row per booking.
-- Holds the measures + foreign keys (surrogate keys) pointing to the SCD2 dimensions.

{% set configs = [
    {
        "table": "obt",
        "alias": "o",
        "columns": [
            "BOOKING_ID",
            "LISTING_ID",
            "HOST_ID",
            "BOOKING_DATE",
            "NIGHTS_BOOKED",
            "BOOKING_AMOUNT",
            "CLEANING_FEE",
            "SERVICE_FEE",
            "ACCOMMODATION_AMOUNT",
            "TOTAL_FEES",
            "TOTAL_AMOUNT",
            "CONFIRMED_BOOKING_REVENUE"
        ]
    },
    {
        "table": "dim_bookings",
        "alias": "d_bookings",
        "columns": ["dbt_scd_id AS DIM_BOOKINGS_SK"],
        "join_condition": "o.BOOKING_ID = d_bookings.BOOKING_ID AND d_bookings.dbt_valid_to::DATE = TO_DATE('9999-12-31')"
    },
    {
        "table": "dim_listings",
        "alias": "d_listings",
        "columns": ["dbt_scd_id AS DIM_LISTINGS_SK"],
        "join_condition": "o.LISTING_ID = d_listings.LISTING_ID AND d_listings.dbt_valid_to::DATE = TO_DATE('9999-12-31')"
    },
    {
        "table": "dim_host",
        "alias": "d_host",
        "columns": ["dbt_scd_id AS DIM_HOST_SK"],
        "join_condition": "o.HOST_ID = d_host.HOST_ID AND d_host.dbt_valid_to::DATE = TO_DATE('9999-12-31')"
    }
] %}

{% set select_cols = [] %}

{% for cfg in configs %}
    {% for col in cfg.columns %}
        {% do select_cols.append(cfg.alias ~ '.' ~ col) %}
    {% endfor %}
{% endfor %}

SELECT
    {{ select_cols | join(',\n    ') }}

FROM {{ ref(configs[0].table) }} AS {{ configs[0].alias }}

{% for cfg in configs[1:] %}
LEFT JOIN {{ ref(cfg.table) }} AS {{ cfg.alias }}
    ON {{ cfg.join_condition }}
{% endfor %}