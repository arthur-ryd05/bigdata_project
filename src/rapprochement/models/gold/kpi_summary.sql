{{ config(location=lake_path('gold', 'kpi_summary', 'csv'), format='csv') }}
-- Indicateurs repondant a la problematique (une ligne par indicateur).
with r as (select * from {{ ref('reconciliation') }}),
t as (select count(*) as n from {{ ref('stg_transfers') }}),
u as (select count(*) as n from {{ ref('unexpected_transfers') }}),
x as (select count(*) as n from {{ ref('exceptions_for_review') }})
select 'expected_payments' as kpi, count(*)::double as value from r
union all select 'transfers_in_statement', (select n from t)
union all select 'matched_exact', count(*) filter (where status = 'matched') from r
union all select 'matched_with_difference', count(*) filter (where status = 'matched_with_difference') from r
union all select 'ambiguous', count(*) filter (where status = 'ambiguous') from r
union all select 'missing', count(*) filter (where status = 'missing') from r
union all select 'missing_explained_loan_repaid', count(*) filter (where reason = 'loan_already_repaid') from r
union all select 'unexpected_transfers', (select n from u)
union all select 'transfers_matched_pct',
    round(100.0 * ((select n from t) - (select n from u)) / (select n from t), 2)
union all select 'expected_matched_pct',
    round(100.0 * count(*) filter (where status in ('matched', 'matched_with_difference')) / count(*), 2) from r
union all select 'items_for_review', (select n from x)
