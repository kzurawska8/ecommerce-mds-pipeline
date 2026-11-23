{#-
    prod builds into clean schema names (STAGING, MARTS, SNAPSHOTS), which is
    what consumers and grants refer to. Every other target prefixes them with
    its own schema (DEV_STAGING, DEV_MARTS, ...), so a development build can
    never overwrite prod objects.
-#}
{% macro generate_schema_name(custom_schema_name, node) -%}
    {%- if custom_schema_name is none -%}
        {{ target.schema }}
    {%- elif target.name == 'prod' -%}
        {{ custom_schema_name | trim }}
    {%- else -%}
        {{ target.schema }}_{{ custom_schema_name | trim }}
    {%- endif -%}
{%- endmacro %}
