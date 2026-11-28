{{ config(location=lake_path('gold', 'order_status')) }}
-- Synthese par ordre permanent sur la periode.
select
    order_id,
    account_id,
    payment_type,
    amount,
    count(*)                                                  as months_expected,
    count(*) filter (where status in ('matched', 'matched_with_difference')) as months_executed,
    case
        when count(*) filter (where status in ('matched', 'matched_with_difference')) = count(*) then 'complete'
        when count(*) filter (where status in ('matched', 'matched_with_difference')) = 0 then 'never_executed'
        else 'partial'
    end                                                       as order_status,
    -- cause dominante des mois non executes
    mode(reason) filter (where status not in ('matched'))     as main_reason
from {{ ref('reconciliation') }}
group by all
