{#-
    The grants config on marts covers the tables only; a role also needs USAGE
    on the schema to reach them. Runs in prod only, and only when the marts
    schema was built in this run, so `dbt build -s staging` doesn't fail on a
    schema that doesn't exist yet. Renders to nothing otherwise (a no-op hook).
-#}
{% macro grant_marts_schema_usage(role) -%}
    {%- if target.name == 'prod' -%}
        {%- set marts_schema = generate_schema_name('marts', none) | trim | upper -%}
        {%- for schema in schemas if schema | upper == marts_schema -%}
            grant usage on schema {{ target.database }}.{{ schema }} to role {{ role }}
        {%- endfor -%}
    {%- endif -%}
{%- endmacro %}
