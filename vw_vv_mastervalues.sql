-- 08.06.2017 KB: Neue View zur Zusammenführung von vv_mastervalues und vv_uploads

Use MasterData
go

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[[vw_vv_mastervalues]]') )
drop view [dbo].vw_vv_mastervalues
GO

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE VIEW [dbo].vw_vv_mastervalues
as
select 
  MV_SOURCE_ID, 
  MV_UPLOAD_ID,
  MV_ISIN,
  MV_MIC,
  MV_AS_OF_DATE,
  MV_FIELDNAME,
  MV_TIMESTAMP,
  MV_LAST_SEEN,
  MV_STRINGVALUE,
  MV_COMMENT,
  UPL_USER_ID,
  UPL_HOST_NAME,
  UPL_TIMESTAMP,
  UPL_RECEIVED_ROWS,
  UPL_IDENTICAL_ROWS,
  UPL_EXISTING_ROWS,
  UPL_INSERTED_ROWS,
  UPL_DATA_ORIGIN,
  UPL_URLSOURCE,
  UPL_COMMENT
from vv_mastervalues
left outer join vv_uploads on UPL_UPLOAD_ID = MV_UPLOAD_ID 
  
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--
-- grant select on vw_vv_mastervalues to lesen, buchen
--
-- sp_helptext vw_vv_masterdata
-- 
/*

 select top 99 * from vw_vv_mastervalues
 
 select top 9 * from vv_mastervalues 
 select top 9 * from vv_uploads


*/
