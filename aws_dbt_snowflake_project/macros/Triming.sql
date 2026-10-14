{%{% macro triming(column_name, node) %}

    {{col_name | trim | upper}}

{% endmacro %}%}