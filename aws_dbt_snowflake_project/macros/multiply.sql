{% macro multiply(x, y, precision=2) %}
    ROUND(
        ({{ x }}) * ({{ y }}),
        {{ precision }}
    )
{% endmacro %}