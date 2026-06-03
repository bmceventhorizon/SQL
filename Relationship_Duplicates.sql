WITH RankedMatches AS (
SELECT reconciliationidentity,to_timestamp(createdate)as "Created Date", submitter,
markasdeleted,
Source_ReconciliationIdentity,Destination_ReconciliationIden,
datasetid,
classid, instanceid,
COUNT(*) OVER (PARTITION BY reconciliationidentity,Source_ReconciliationIdentity,Destination_ReconciliationIden, datasetid, classid) as total_count,
ROW_NUMBER() OVER (PARTITION BY Source_ReconciliationIdentity,Destination_ReconciliationIden, datasetid, classid, markasdeleted ORDER BY classid DESC) as rn
FROM BMC_CORE_BMC_BaseRelationship
WHERE datasetid = 'BMC.ASSET'
)
SELECT *
FROM RankedMatches
WHERE total_count >= 2 AND rn >= 2 --and source_reconciliationidentity != '0' and destination_reconciliationiden != '0'
and markasdeleted = '1'
--and reconciliationidentity = '0'
order by total_count DESC
