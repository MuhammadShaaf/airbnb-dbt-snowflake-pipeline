{#
    clean_string(column_name, case_style)
    Trims whitespace, converts empty strings to NULL, and standardizes casing.

    case_style:
      'upper' (default) -> HOUSE, ENTIRE HOME
      'title'           -> House, Entire Home
#}
{% macro clean_string(column_name, case_style='upper') %}
    {%- if case_style == 'title' -%}
        NULLIF(INITCAP(TRIM({{ column_name }}::STRING)), '')
    {%- else -%}
        NULLIF(UPPER(TRIM({{ column_name }}::STRING)), '')
    {%- endif -%}
{% endmacro %}