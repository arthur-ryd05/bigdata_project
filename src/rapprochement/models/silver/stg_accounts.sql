{{ config(location=lake_path('silver', 'stg_accounts')) }}
select
    cast(account_id as integer)                       as account_id,
    cast(district_id as integer)                      as district_id,
    frequency,
    cast(strptime('19' || date, '%Y%m%d') as date)    as opened_on
from {{ source('bronze', 'account') }}
