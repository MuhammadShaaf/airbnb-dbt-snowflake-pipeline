{% macro calculate_booking_total(
    nights,
    nightly_rate,
    cleaning_fee,
    service_fee
) %}
    ROUND(
        (
            COALESCE({{ nights }}, 0)
            * COALESCE({{ nightly_rate }}, 0)
        )
        + COALESCE({{ cleaning_fee }}, 0)
        + COALESCE({{ service_fee }}, 0),
        2
    )
{% endmacro %}
