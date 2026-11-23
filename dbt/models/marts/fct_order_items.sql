-- Grain: one order line. user_id and first_seen_at are copied from the order
-- so line-level questions (revenue per user, per product) need no extra join.
select
    {{ dbt_utils.generate_surrogate_key(['items.cart_id', 'items.line_number']) }}
                                                        as order_item_id,
    items.cart_id                                       as order_id,
    items.line_number,
    items.product_id,
    carts.user_id,
    carts.first_seen_at,
    items.quantity,
    items.unit_price,
    items.discount_percentage,
    items.gross_amount,
    items.net_amount,
    (items.gross_amount - items.net_amount)::number(12, 2)  as discount_amount
from {{ ref('stg_dummyjson__cart_items') }} as items
inner join {{ ref('stg_dummyjson__carts') }} as carts
    on items.cart_id = carts.cart_id
