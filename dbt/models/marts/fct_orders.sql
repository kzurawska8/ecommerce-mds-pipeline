-- Grain: one order (a DummyJSON cart).
select
    cart_id                                         as order_id,
    user_id,
    first_seen_at,
    line_count,
    item_quantity,
    gross_amount,
    net_amount,
    (gross_amount - net_amount)::number(12, 2)      as discount_amount
from {{ ref('stg_dummyjson__carts') }}
