# Rapprochement bancaire automatique · Gr05

**Auteurs** : REYNAUD Arthur, VAZ-SAMPAIO-DESTOT Léo

**Prérequis** : un service `vscode-pyspark` lancé sur Onyxia, qui fournit déjà AWS CLI, DuckDB et `kubectl`. Les dépendances Python (dont `dbt-duckdb`) s'installent avec `uv sync`. Pour l'accès au stockage, on colle dans le terminal le script « AWS CLI » de la page S3 d'Onyxia, puis on crée le secret DuckDB `s3_onyxia_connection` comme dans le lab DuckDB. Les clés expirent au bout de quelques heures : il faut alors recoller le script.

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
