{{ config(location=lake_path('gold', 'matches')) }}
-- Appariement en cascade, chaque passe ne voit que ce qui reste des passes precedentes.
--   1. exact          : compte emetteur + banque + compte beneficiaire + montant + mois
--   2. amount_changed : meme beneficiaire, montant different (ordre modifie ?)
--   3. beneficiary_changed : meme montant, beneficiaire different (RIB modifie ?)
with expected as (
    select * from {{ ref('expected_payments') }}
),
transfers as (
    select * from {{ ref('stg_transfers') }}
),

p1 as (
    {{ match_pass('expected', 'transfers',
        [['account_id','account_id'], ['bank_to','bank'], ['account_to','account'],
         ['amount','amount'], ['expected_month','trans_month']], 'exact') }}
),
p1_ok as (select * from p1 where not is_ambiguous),

e2 as (select * from expected where expected_id not in (select expected_id from p1_ok)),
t2 as (select * from transfers where trans_id not in (select trans_id from p1_ok)),
p2 as (
    {{ match_pass('e2', 't2',
        [['account_id','account_id'], ['bank_to','bank'], ['account_to','account'],
         ['expected_month','trans_month']], 'amount_changed') }}
),
p2_ok as (select * from p2 where not is_ambiguous),

e3 as (select * from e2 where expected_id not in (select expected_id from p2_ok)),
t3 as (select * from t2 where trans_id not in (select trans_id from p2_ok)),
p3 as (
    {{ match_pass('e3', 't3',
        [['account_id','account_id'], ['amount','amount'], ['expected_month','trans_month']],
        'beneficiary_changed') }}
),

all_candidates as (
    select * from p1
    union all select * from p2
    union all select * from p3
)
select expected_id, trans_id, match_pass, is_ambiguous
from all_candidates
-- Une paire ambigue d'une passe peut etre resolue par une passe suivante : on ne garde
-- l'ambiguite que pour les paiements jamais apparies.
where not is_ambiguous
   or expected_id not in (select expected_id from all_candidates where not is_ambiguous)
-- Les cles se relachent d'une passe a l'autre : une meme paire ambigue reapparait.
-- On ne garde que sa premiere occurrence (passe la plus stricte).
qualify row_number() over (
    partition by expected_id, trans_id
    order by case match_pass when 'exact' then 1 when 'amount_changed' then 2 else 3 end
) = 1
