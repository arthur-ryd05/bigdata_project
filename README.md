# Rapprochement bancaire automatique · Gr05

**Auteurs** : REYNAUD Arthur, VAZ-SAMPAIO-DESTOT Léo

**Prérequis** : service Onyxia `vscode-pyspark` (DuckDB CLI, AWS CLI, `kubectl`), [uv](https://docs.astral.sh/uv/), profil S3 Onyxia configuré (onglet *Mon compte › Connexion au stockage*), secret DuckDB `s3_onyxia_connection` valide. Python ≥ 3.11 et `dbt-duckdb` sont installés par `uv sync`.

**Dataset** : *Berka Financial Dataset* (PKDD'99 Discovery Challenge). Ce sont les vraies données anonymisées d'une banque tchèque, 1993-1998.
- Source : <https://github.com/jlacko/berka-dataset>, commit `77e9972`. Sommes sha256 vérifiées par le script. Dataset décrit sur <https://relational.fel.cvut.cz/dataset/Financial>.
- Licence : aucune licence explicite. Le jeu a été diffusé publiquement par les organisateurs du PKDD'99 pour la recherche et l'enseignement.
- Téléchargé le 25/11/2026.
- Données brutes retenues : **3,40 Mo** au total (`manifest.json`). `order.asc` (6 471 ordres permanents), `account.asc` (4 500 comptes) et `loan.asc` (682 prêts) sont copiés tels quels. `trans.asc` (69,4 Mo dans la source, 1 056 320 opérations) est réduit aux 34 962 virements émis de juillet à décembre 1998, sans modifier aucune ligne.

**Problématique** : quelle part des virements attendus (ordres permanents × mois) peut-on rapprocher automatiquement du relevé bancaire, sans jamais rattacher un même virement à deux opérations différentes ? Quels écarts restent inexpliqués et doivent être transmis à la comptabilité ?

**Chemins S3** (bucket `$KUBERNETES_NAMESPACE`, soit `user-<identifiant Onyxia>`, préfixe `gr05/rapprochement/`) :
- `bronze/` : `*.asc` bruts et `manifest.json`
- `silver/` : `stg_*.parquet`
- `gold/` : `expected_payments`, `matches`, `reconciliation`, `unexpected_transfers`, `order_status` et `strategy_comparison` en `.parquet`, `kpi_summary.csv`, `exceptions_for_review.csv` et `data_quality_issues.csv` ; `silver/hop/` et `quarantine/` (pipeline Hop)

**Reproduction** : les commandes d'exécution, de reprise et de vérification sont ajoutées avec les composants correspondants.
