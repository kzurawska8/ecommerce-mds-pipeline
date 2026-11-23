select
    product_id,
    sku,
    title,
    category,
    brand,
    price,
    discount_percentage,
    rating,
    stock,
    availability_status,
    created_at,
    updated_at
from {{ ref('stg_dummyjson__products') }}
