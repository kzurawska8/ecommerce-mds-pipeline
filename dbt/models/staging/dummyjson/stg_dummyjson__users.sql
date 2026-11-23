with source as (

    select * from {{ source('dummyjson', 'users') }}

),

-- Data minimisation: only attributes useful for analysis leave RAW. Names,
-- contact details, street address, coordinates, birth date, government IDs
-- (ssn, ein), bank and crypto details, IP/MAC address and user agent are
-- deliberately not selected, so no downstream model can expose them.
renamed as (

    select
        payload:id::number                      as user_id,
        payload:age::number                     as age,
        payload:gender::varchar                 as gender,
        payload:role::varchar                   as user_role,
        payload:address:city::varchar           as city,
        payload:address:state::varchar          as state,
        payload:address:country::varchar        as country,
        payload:university::varchar             as university,
        payload:company:department::varchar     as company_department,
        payload:company:title::varchar          as job_title,
        _batch_id,
        _loaded_at
    from source
    {{ latest_batch() }}

)

select * from renamed
