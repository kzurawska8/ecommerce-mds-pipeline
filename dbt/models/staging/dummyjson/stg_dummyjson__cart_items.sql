with source as (

    select * from {{ source('dummyjson', 'carts') }}

),

-- One row per element of the cart's products array.
flattened as (

    select
        source.payload:id::number                       as cart_id,
        -- A cart can list the same product on two lines, so the line's
        -- position in the array (not product_id) identifies it.
        (item.index + 1)::number                        as line_number,
        item.value:id::number                           as product_id,
        item.value:quantity::number                     as quantity,
        item.value:price::number(12, 2)                 as unit_price,
        item.value:discountPercentage::number(5, 2)     as discount_percentage,
        item.value:total::number(12, 2)                 as gross_amount,
        item.value:discountedTotal::number(12, 2)       as net_amount,
        source._batch_id,
        source._loaded_at
    from source,
        lateral flatten(input => source.payload:products) as item
    {{ latest_batch('source._loaded_at') }}

)

select * from flattened
