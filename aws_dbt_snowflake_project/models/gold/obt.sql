{{
    config(
        materialized='table'
    )
}}

{% set configs = [
    {
        "table": "silver_bookings",
        "alias": "b",
        "columns": [
            "BOOKING_ID",
            "LISTING_ID",
            "BOOKING_DATE",
            "BOOKING_YEAR",
            "BOOKING_MONTH",
            "NIGHTS_BOOKED",
            "STAY_CATEGORY",
            "BOOKING_STATUS_CATEGORY",
            "BOOKING_AMOUNT",
            "CLEANING_FEE",
            "SERVICE_FEE",
            "ACCOMMODATION_AMOUNT",
            "TOTAL_FEES",
            "TOTAL_AMOUNT",
            "CONFIRMED_BOOKING_REVENUE",
            "CREATED_AT AS BOOKING_CREATED_AT"
        ],
        "where": "b.DATA_QUALITY_STATUS = 'VALID'"
    },
    {
        "table": "silver_listings",
        "alias": "l",
        "columns": [
            "HOST_ID",
            "PROPERTY_TYPE",
            "ROOM_TYPE",
            "CITY",
            "COUNTRY",
            "ACCOMMODATES",
            "BEDROOMS",
            "BATHROOMS",
            "PRICE_PER_NIGHT",
            "PRICE_PER_GUEST",
            "PRICE_CATEGORY",
            "CREATED_AT AS LISTING_CREATED_AT"
        ],
        "join_condition": "b.LISTING_ID = l.LISTING_ID",
        "where": "l.DATA_QUALITY_STATUS IN ('VALID', 'BEDROOMS_EXCEED_CAPACITY')"
    },
    {
        "table": "silver_host",
        "alias": "h",
        "columns": [
            "HOST_NAME",
            "HOST_SINCE",
            "IS_SUPERHOST",
            "RESPONSE_RATE",
            "RESPONSE_RATE_QUALITY",
            "CREATED_AT AS HOST_CREATED_AT"
        ],
        "join_condition": "l.HOST_ID = h.HOST_ID",
        "where": "h.DATA_QUALITY_STATUS = 'VALID'"
    }
] %}

{% set select_cols = [] %}
{% set filters = [] %}

{% for cfg in configs %}
    {% for col in cfg.columns %}
        {% do select_cols.append(cfg.alias ~ '.' ~ col) %}
    {% endfor %}
    {% if cfg.where %}
        {% do filters.append(cfg.where) %}
    {% endif %}
{% endfor %}

SELECT
    {{ select_cols | join(',\n    ') }}

FROM {{ ref(configs[0].table) }} AS {{ configs[0].alias }}

{% for cfg in configs[1:] %}
INNER JOIN {{ ref(cfg.table) }} AS {{ cfg.alias }}
    ON {{ cfg.join_condition }}
{% endfor %}

{% if filters %}
WHERE {{ filters | join('\n  AND ') }}
{% endif %}