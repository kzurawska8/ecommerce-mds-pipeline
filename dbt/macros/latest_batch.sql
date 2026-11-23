{#-
    RAW is append-only: every ingestion run lands a complete snapshot of the
    API. The current state is therefore the latest batch as a whole, not the
    latest row per id - filtering per id would keep records that have since
    been deleted at the source. Window functions in the same SELECT still see
    every batch, because QUALIFY is applied after them.
-#}
{% macro latest_batch(loaded_at='_loaded_at') -%}
    qualify dense_rank() over (order by {{ loaded_at }} desc) = 1
{%- endmacro %}
