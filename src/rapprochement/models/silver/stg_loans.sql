{{ config(location=lake_path('silver', 'stg_loans')) }}
-- Prets : la fin theorique (debut + duree) explique l'arret des ordres de type "loan".
select
    cast(loan_id as integer)                                   as loan_id,
    cast(account_id as integer)                                as account_id,
    cast(strptime('19' || date, '%Y%m%d') as date)             as granted_on,
    cast(duration as integer)                                  as duration_months,
    cast(strptime('19' || date, '%Y%m%d') + to_months(cast(duration as integer)) as date) as ends_on,
    cast(payments as decimal(12, 2))                           as monthly_payment,
    status
from {{ source('bronze', 'loan') }}
