{{ config(location=lake_path('gold', 'exceptions_for_review', 'csv'), format='csv') }}
-- Liste a transmettre a la comptabilite : tout ce qui n'est ni apparie exactement,
-- ni explique par une regle metier verifiable (pret deja rembourse).
select
    'expected_payment'      as item_type,
    expected_id             as item_id,
    order_id,
    account_id,
    expected_month          as month,
    amount,
    payment_type,
    status,
    reason
from {{ ref('reconciliation') }}
where status <> 'matched' and reason <> 'loan_already_repaid'
union all
select
    'unexpected_transfer',
    cast(trans_id as varchar),
    null,
    account_id,
    trans_month,
    amount,
    null,
    'unexpected',
    'no_standing_order'
from {{ ref('unexpected_transfers') }}
order by item_type, account_id, month
