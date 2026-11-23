with source as (

    select * from {{ source('dummyjson', 'carts') }}

),

renamed as (

    select
        payload:id::number                      as cart_id,
        payload:userId::number                  as user_id,
        payload:totalProducts::number           as line_count,
        payload:totalQuantity::number           as item_quantity,
        payload:total::number(12, 2)            as gross_amount,
        payload:discountedTotal::number(12, 2)  as net_amount,
        -- Carts carry no date. The closest honest substitute is when the
        -- pipeline first saw the cart, computed over all batches (the window
        -- runs before latest_batch's QUALIFY filters them).
        min(_loaded_at) over (partition by payload:id)  as first_seen_at,
        _batch_id,
        _loaded_at
    from source
    {{ latest_batch() }}

)

select * from renamed
