With Row_Numbered as 
		(select reconciliationidentity,instanceid,lastscandate, row_number() 
		over (partition by reconciliationidentity order by reconciliationidentity) as Row_Num
		from BMC_CORE_BMC_BaseElement  where datasetid = 'BMC.ASSET' ) 
select a.instanceid'A instanceid','DUPEbyREID' as DUPEbyREID,a.ReconciliationIdentity,DATEADD(s,a.LastScanDate,'19700101')'A scan date', DATEADD(s,r.LastScanDate,'19700101')'R scan date' from Row_Numbered r
join row_numbered a on a.reconciliationidentity = r.reconciliationidentity 
where r.Row_Num > 1
and a.lastscandate < r.lastscandate
