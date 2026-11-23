"""Stand-ins for dbt_utils macros, so sqlfluff's jinja templater can render
models offline. Only the shape of the SQL matters for linting."""


def generate_surrogate_key(field_list):
    return "md5(" + " || '-' || ".join(field_list) + ")"
