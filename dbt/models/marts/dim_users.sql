select
    user_id,
    age,
    gender,
    user_role,
    city,
    state,
    country,
    university,
    company_department,
    job_title
from {{ ref('stg_dummyjson__users') }}
