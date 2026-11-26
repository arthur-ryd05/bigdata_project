{{ config(location=lake_path('silver', 'stg_orders')) }}
-- Journal des virements attendus : un ordre permanent = un virement par mois.
with src as (
    select * from {{ source('bronze', 'order') }}
)
select
    cast(order_id as integer)                    as order_id,
    cast(account_id as integer)                  as account_id,
    upper(trim(bank_to))                         as bank_to,
    -- Les numeros de compte ont perdu leurs zeros de tete (4 a 8 chiffres) : format fixe a 8.
    lpad(trim(account_to), 8, '0')               as account_to,
    cast(amount as decimal(12, 2))               as amount,
    -- k_symbol vaut tantot ' ', tantot '' : les deux signifient "non renseigne".
    nullif(trim(k_symbol), '')                   as k_symbol,
    case nullif(trim(k_symbol), '')
        when 'SIPO'     then 'household'
        when 'UVER'     then 'loan'
        when 'POJISTNE' then 'insurance'
        when 'LEASING'  then 'leasing'
        else 'unspecified'
    end                                          as payment_type
from src
qualify row_number() over (partition by order_id order by order_id) = 1
