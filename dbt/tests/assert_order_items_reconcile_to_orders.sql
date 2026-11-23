-- Every order header must equal the sum of its lines. Catches flattening
-- mistakes (lost or duplicated lines) and inconsistencies in the source.
-- Returns the orders that don't reconcile; the test passes on zero rows.
with lines as (

    select
        order_id,
        count(*)          as line_count,
        sum(quantity)     as item_quantity,
        sum(gross_amount) as gross_amount,
        sum(net_amount)   as net_amount
    from {{ ref('fct_order_items') }}
    group by order_id

)

select
    orders.order_id,
    orders.line_count,
    lines.line_count    as lines_line_count,
    orders.item_quantity,
    lines.item_quantity as lines_item_quantity,
    orders.gross_amount,
    lines.gross_amount  as lines_gross_amount,
    orders.net_amount,
    lines.net_amount    as lines_net_amount
from {{ ref('fct_orders') }} as orders
left join lines
    on orders.order_id = lines.order_id
where
    lines.order_id is null
    or orders.line_count != lines.line_count
    or orders.item_quantity != lines.item_quantity
    or orders.gross_amount != lines.gross_amount
    or orders.net_amount != lines.net_amount
