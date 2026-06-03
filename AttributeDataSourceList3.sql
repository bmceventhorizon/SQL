WITH schema_fields AS (
    SELECT
        f.fieldid::TEXT AS fieldid,
        f.fieldname
    FROM field f
    JOIN arschema s
        ON s.schemaid = f.schemaid
    WHERE s.name = 'BMC.CORE:BMC_Computersystem'
),
name_field AS (
    SELECT fieldid
    FROM schema_fields
    WHERE fieldname = 'Name'
)
SELECT
    segment.src_name AS "List",
    cs.name          AS "CI Name",
    cs.datasetid     AS "Dataset",
    cs.attributedatasourcelist AS "AttributeDataSourceList",
    translated.translated_list AS "AttributeDataSourceList Fields"
FROM BMC_CORE_BMC_ComputerSystem cs
JOIN AST_ComputerSystem ac
    ON cs.reconciliationidentity = ac.reconciliation_identity
JOIN ast_attributes als
    ON als.reconciliationidentity = cs.reconciliationidentity
CROSS JOIN name_field nf
LEFT JOIN LATERAL (
    SELECT
        LEFT(part.val, STRPOS(part.val, ':') - 1) AS src_name
    FROM regexp_split_to_table(cs.attributedatasourcelist::TEXT, '/') AS part(val)
    WHERE part.val ~ ('(^|[^0-9])' || nf.fieldid || '([^0-9]|$)')
      AND STRPOS(part.val, ':') > 0
    LIMIT 1
) segment ON TRUE
LEFT JOIN LATERAL (
    SELECT
        string_agg(
            CASE
                WHEN field_names.names IS NULL THEN part.val
                WHEN STRPOS(part.val, ':') > 0 THEN
                    LEFT(part.val, STRPOS(part.val, ':') - 1) || ': ' || field_names.names
                ELSE field_names.names
            END,
            ' / '
            ORDER BY part.ord
        ) AS translated_list
    FROM regexp_split_to_table(cs.attributedatasourcelist::TEXT, '/') WITH ORDINALITY AS part(val, ord)
    LEFT JOIN LATERAL (
        SELECT string_agg(DISTINCT sf.fieldname, ', ' ORDER BY sf.fieldname) AS names
        FROM schema_fields sf
        WHERE part.val ~ ('(^|[^0-9])' || sf.fieldid || '([^0-9]|$)')
    ) field_names ON TRUE
    WHERE part.val <> ''
) translated ON TRUE
WHERE cs.datasetid = 'BMC.ASSET'
  -- AND als.assetlifecyclestatus = '3'
  AND cs.attributedatasourcelist IS NOT NULL
ORDER BY cs.name;