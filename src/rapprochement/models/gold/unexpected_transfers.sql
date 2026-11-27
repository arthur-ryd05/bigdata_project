{{ config(location=lake_path('gold', 'unexpected_transfers')) }}
-- Virements du releve sans paiement attendu correspondant.
select t.*
from {{ ref('stg_transfers') }} as t
where t.trans_id not in (
    select trans_id from {{ ref('matches') }} where not is_ambiguous
)
