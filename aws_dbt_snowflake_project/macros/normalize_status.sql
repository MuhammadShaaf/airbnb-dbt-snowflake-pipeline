{% macro normalize_status(column_name) %}
    UPPER(TRIM({{ column_name }}))
{% endmacro %}
