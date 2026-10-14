{# SELECT * FROM {{ ref('bronze_bookings') }}; #}
SELECT * FROM {{ ref('silver_bookings') }};