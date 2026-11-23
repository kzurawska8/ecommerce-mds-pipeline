with source as (

    select * from {{ source('dummyjson', 'products') }}

),

renamed as (

    select
        payload:id::number                          as product_id,
        payload:sku::varchar                        as sku,
        payload:title::varchar                      as title,
        payload:category::varchar                   as category,
        -- Not every product has a brand (about half don't).
        payload:brand::varchar                      as brand,
        payload:price::number(12, 2)                as price,
        payload:discountPercentage::number(5, 2)    as discount_percentage,
        payload:rating::number(3, 2)                as rating,
        payload:stock::number                       as stock,
        payload:availabilityStatus::varchar         as availability_status,
        payload:minimumOrderQuantity::number        as minimum_order_quantity,
        payload:meta:createdAt::timestamp_tz        as created_at,
        payload:meta:updatedAt::timestamp_tz        as updated_at,
        _batch_id,
        _loaded_at
    from source
    {{ latest_batch() }}

)

select * from renamed
