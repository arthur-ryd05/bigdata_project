{{ config(location=lake_path('gold', 'expected_payments')) }}
-- Paiements attendus : chaque ordre permanent doit produire un virement par mois de la periode.
with months as (
    select cast(m as date) as expected_month
    from generate_series(
        cast('{{ var("period_start") }}' as date),
        cast('{{ var("period_end") }}' as date),
        interval 1 month
    ) as g(m)
)
select
    o.order_id || '-' || strftime(m.expected_month, '%Y%m') as expected_id,
    o.order_id,
    o.account_id,
    o.bank_to,
    o.account_to,
    o.amount,
    o.payment_type,
    m.expected_month
from {{ ref('stg_orders') }} as o
cross join months as m
