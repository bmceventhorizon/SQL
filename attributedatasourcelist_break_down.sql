declare @fieldname nvarchar(128), @classname nvarchar(256), @fieldid nvarchar(32)
set @fieldname = 'Name'
set @classname = 'BMC.CORE:BMC_Computersystem'

set @fieldid = '%'+(select cast(fieldid as nvarchar(32)) from field where schemaid = (select schemaid from arschema where name = @classname) and fieldname = @fieldname)+'%'

select 
substring(
SUBSTRING(
       substring('/'+cast(cs.attributedatasourcelist as nvarchar(1024)),1,patindex(@fieldid,'/'+cast(cs.attributedatasourcelist as nvarchar(1024)))+len(@fieldid)-3), 
       LEN(substring('/'+cast(cs.attributedatasourcelist as nvarchar(1024)),1,patindex(@fieldid,'/'+cast(cs.attributedatasourcelist as nvarchar(1024)))+len(@fieldid)-3)) -  
       CHARINDEX('/',REVERSE(substring('/'+cast(cs.attributedatasourcelist as nvarchar(1024)),1,patindex(@fieldid,'/'+cast(cs.attributedatasourcelist as nvarchar(1024)))+len(@fieldid)-3))) + 2, 
       LEN(substring('/'+cast(cs.attributedatasourcelist as nvarchar(1024)),1,patindex(@fieldid,'/'+cast(cs.attributedatasourcelist as nvarchar(1024)))+len(@fieldid)-3))
       ),1,CHARINDEX(':',
       SUBSTRING(
       substring('/'+cast(cs.attributedatasourcelist as nvarchar(1024)),1,patindex(@fieldid,'/'+cast(cs.attributedatasourcelist as nvarchar(1024)))+len(@fieldid)-3), 
       LEN(substring('/'+cast(cs.attributedatasourcelist as nvarchar(1024)),1,patindex(@fieldid,'/'+cast(cs.attributedatasourcelist as nvarchar(1024)))+len(@fieldid)-3)) -  
       CHARINDEX('/',REVERSE(substring('/'+cast(cs.attributedatasourcelist as nvarchar(1024)),1,patindex(@fieldid,'/'+cast(cs.attributedatasourcelist as nvarchar(1024)))+len(@fieldid)-3))) + 2, 
       LEN(substring('/'+cast(cs.attributedatasourcelist as nvarchar(1024)),1,patindex(@fieldid,'/'+cast(cs.attributedatasourcelist as nvarchar(1024)))+len(@fieldid)-3))
       ))),
cs.Name
from BMC_CORE_BMC_ComputerSystem cs
join AST_ComputerSystem ac on cs.instanceid = ac.instance_id
join [dbo].[utf_EnumValues]('ast:attributes', 'assetlifecyclestatus') als on als.value = ac.assetlifecyclestatus 
where cs.DatasetId = 'BMC.Asset'
and cs.name not like 'k%'
and cs.Type = 'Server'
and cs.item not in ('Appliance','Blade Enclosure','Chassis','Console','Onboard Administrator','Other')
and cs.name != 'Deactivated Computer'
and cs.name != 'VM no longer being discovered'
and cs.name != 'VM no longer in Vcenter'
and als.display = 'Deployed'
