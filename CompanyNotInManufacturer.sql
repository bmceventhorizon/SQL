-- SQL Server 2012 compatible
SELECT
  COUNT(*) AS record_count,
  CASE
    WHEN b.normalizationstatus = '10' THEN 'Other'
    WHEN b.normalizationstatus = '20' THEN 'Not Normalized'
    WHEN b.normalizationstatus = '30' THEN 'Not Applicable for Normalization'
    WHEN b.normalizationstatus = '40' THEN 'Normalization Failed'
    WHEN b.normalizationstatus = '50' THEN 'Normalized but Not Approved'
    WHEN b.normalizationstatus = '60' THEN 'Normalized and Approved'
    WHEN b.normalizationstatus = '70' THEN 'Modified after last Normalization'
  END AS NormalizationStatus,
  b.Classid,
  b.Category,
  b.[Type],           -- reserved word
  b.Item,
  b.Model,
  COALESCE(b.ManufacturerName, 'BMC_UNKNOWN') AS ManufacturerName,
  CASE WHEN b.Company = 'ACME Co' THEN '- Global -' ELSE b.Company END AS Company,
  cMatch.description AS COM_Company,
  cMatch.company_type AS CompanyType
FROM BMC_CORE_BMC_BaseElement AS b

-- Clean ManufacturerName: lowercase -> strip punctuation -> drop common suffixes
CROSS APPLY (
  SELECT LOWER(ISNULL(b.ManufacturerName, '')) AS mf_lower
) AS bl
CROSS APPLY (
  SELECT
    /* 10 balanced REPLACE() calls: ' ', '.', ',', '-', '/', '&', ''' , '"', '(', ')' */
    REPLACE(
      REPLACE(
        REPLACE(
          REPLACE(
            REPLACE(
              REPLACE(
                REPLACE(
                  REPLACE(
                    REPLACE(
                      REPLACE(bl.mf_lower,
                        ' ', ''), '.', ''), ',', ''), '-', ''), '/', ''), '&', ''), '''', ''), '"', ''), '(', ''), ')', ''
    ) AS mf_raw
) AS br
CROSS APPLY (
  SELECT
    REPLACE(
      REPLACE(
        REPLACE(
          REPLACE(
            REPLACE(br.mf_raw,
              'inc',''), 'corp',''), 'corporation',''), 'co',''), 'ltd',''
    ) AS mf_clean
) AS bc

-- Lateral lookup for best matching COM_Company row
OUTER APPLY (
  SELECT TOP (1)
         c.description,
         c.company_type
  FROM COM_Company AS c
  CROSS APPLY (
    SELECT LOWER(ISNULL(c.description,'')) AS desc_lower
  ) AS dl
  CROSS APPLY (
    SELECT
      REPLACE(
        REPLACE(
          REPLACE(
            REPLACE(
              REPLACE(
                REPLACE(
                  REPLACE(
                    REPLACE(
                      REPLACE(
                        REPLACE(dl.desc_lower,
                          ' ', ''), '.', ''), ',', ''), '-', ''), '/', ''), '&', ''), '''', ''), '"', ''), '(', ''), ')', ''
      ) AS desc_raw
  ) AS dr
  CROSS APPLY (
    SELECT
      REPLACE(
        REPLACE(
          REPLACE(
            REPLACE(
              REPLACE(dr.desc_raw,
                'inc',''), 'corp',''), 'corporation',''), 'co',''), 'ltd',''
      ) AS desc_clean
  ) AS dc
  WHERE c.company_type LIKE '%Manufacturer%'
    AND (
         dc.desc_clean LIKE '%' + bc.mf_clean + '%'
      OR  bc.mf_clean  LIKE '%' + dc.desc_clean + '%'
    )
  ORDER BY LEN(c.description) DESC
) AS cMatch

WHERE b.datasetid = 'BMC.ADDM'
  AND b.NormalizationStatus = '40'
  AND b.Model IS NOT NULL
  AND (cMatch.description IS NULL OR b.ManufacturerName <> cMatch.description)

GROUP BY
  CASE
    WHEN b.normalizationstatus = '10' THEN 'Other'
    WHEN b.normalizationstatus = '20' THEN 'Not Normalized'
    WHEN b.normalizationstatus = '30' THEN 'Not Applicable for Normalization'
    WHEN b.normalizationstatus = '40' THEN 'Normalization Failed'
    WHEN b.normalizationstatus = '50' THEN 'Normalized but Not Approved'
    WHEN b.normalizationstatus = '60' THEN 'Normalized and Approved'
    WHEN b.normalizationstatus = '70' THEN 'Modified after last Normalization'
  END,
  b.Classid, b.Category, b.[Type], b.Item, b.Model, b.ManufacturerName, b.Company,
  cMatch.description, cMatch.company_type;
