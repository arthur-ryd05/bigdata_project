{{ config(location=lake_path('gold', 'reconciliation')) }}
-- Une ligne par paiement attendu, avec son statut de rapprochement et sa cause probable.
with matched as (
    select expected_id, trans_id, match_pass from {{ ref('matches') }} where not is_ambiguous
),
ambiguous as (
    select expected_id, count(distinct trans_id) as n_candidates
    from {{ ref('matches') }} where is_ambiguous group by expected_id
)
select
    e.*,
    m.trans_id,
    t.trans_date,
    t.amount                                   as trans_amount,
    case
        when m.match_pass = 'exact'               then 'matched'
        when m.match_pass is not null             then 'matched_with_difference'
        when a.expected_id is not null            then 'ambiguous'
        else 'missing'
    end                                        as status,
    m.match_pass,
    a.n_candidates,
    case
        when m.trans_id is not null and m.match_pass = 'exact' then null
        when m.trans_id is not null               then m.match_pass
        when a.expected_id is not null            then 'several_candidates'
        when e.payment_type = 'leasing'           then 'leasing_never_in_statement'
        when e.payment_type = 'loan' and l.loan_id is null then 'loan_order_without_loan_record'
        when e.payment_type = 'loan' and l.ends_on < e.expected_month then 'loan_already_repaid'
        else 'unexplained'
    end                                        as reason
from {{ ref('expected_payments') }} as e
left join matched as m using (expected_id)
left join ambiguous as a using (expected_id)
left join {{ ref('stg_transfers') }} as t on t.trans_id = m.trans_id
left join {{ ref('stg_loans') }} as l on l.account_id = e.account_id
