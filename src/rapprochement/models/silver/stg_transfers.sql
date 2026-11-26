{{ config(location=lake_path('silver', 'stg_transfers')) }}
-- Releve bancaire : virements emis vers une autre banque.
with src as (
    select * from {{ source('bronze', 'trans') }}
)
select
    cast(trans_id as integer)                            as trans_id,
    cast(account_id as integer)                          as account_id,
    -- Dates au format YYMMDD sur deux chiffres : toutes en 1993-1998, donc siecle 19.
    cast(strptime('19' || date, '%Y%m%d') as date)       as trans_date,
    cast(date_trunc('month', strptime('19' || date, '%Y%m%d')) as date) as trans_month,
    cast(amount as decimal(12, 2))                       as amount,
    cast(balance as decimal(12, 2))                      as balance_after,
    nullif(trim(k_symbol), '')                           as k_symbol,
    upper(trim(bank))                                    as bank,
    lpad(trim(account), 8, '0')                          as account
from src
where type = 'VYDAJ' and operation = 'PREVOD NA UCET'
qualify row_number() over (partition by trans_id order by trans_id) = 1
