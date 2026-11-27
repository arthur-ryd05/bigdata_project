{#- Une passe d'appariement 1-1 entre paiements attendus et virements non encore apparies.
    Une paire n'est retenue que si elle est la seule candidate des deux cotes : jamais deux
    operations differentes rattachees au meme virement (ni l'inverse). Les cles a plusieurs
    candidats sont renvoyees avec is_ambiguous = true et restent non appariees. -#}
{% macro match_pass(expected, transfers, keys, pass_name) %}
    select
        e.expected_id,
        t.trans_id,
        '{{ pass_name }}' as match_pass,
        count(*) over (partition by e.expected_id) > 1
            or count(*) over (partition by t.trans_id) > 1 as is_ambiguous
    from {{ expected }} as e
    join {{ transfers }} as t
      on {% for k in keys %}e.{{ k[0] }} = t.{{ k[1] }}{% if not loop.last %} and {% endif %}{% endfor %}
{% endmacro %}
