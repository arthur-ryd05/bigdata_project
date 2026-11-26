{#- Chemin d'un objet du lac : $LAKE_ROOT/<couche>/<nom>.<format>.
    LAKE_ROOT vaut s3://<bucket>/gr05/rapprochement sur Onyxia, ou un dossier local pour les tests. -#}
{% macro lake_path(layer, name, fmt='parquet') -%}
  {{ env_var('LAKE_ROOT') ~ '/' ~ layer ~ '/' ~ name ~ '.' ~ fmt }}
{%- endmacro %}
