{{ config(materialized='incremental') }}
{{ config(materialized='table') }}

SELECT * FROM  {{ source('staging', 'bookings') }}

{% if is_incremental() %}
    WHERE CREATED_AT > (SELECT COALESCE(MAX(CREATED_AT), '1900-01-01') FROM {{ this }})
{% endif %}