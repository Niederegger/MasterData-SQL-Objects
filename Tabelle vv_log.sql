-- 26.04.2017 KB: Tabelle dbo.vv_mastervalues erstellt und Testdaten ausgedacht
-- 27.04.2017 KB: MV_SOURCE_ID eingefügt und statt MV_SOURCE jetzt MV_DATA_ORIGIN. MV_FIELDNAME verlängert.

Use MasterData
go

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[vv_log]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].vv_log
GO

CREATE TABLE dbo.vv_log
(
  LOG_TIMESTAMP    datetime,         --
  LOG_USER_ID      nvarchar(32),     -- user_name() liefert eigentlich nvarchar(256)
  LOG_HOST_NAME    nvarchar(32),     -- host_name() liefert eigentlich nvarchar(256)
  LOG_PROGRAM_NAME varchar(32),      --
  LOG_STATUS       varchar(16),      --
  LOG_TEXT         varchar(256)     --
)
 

CREATE  CLUSTERED  INDEX vv_log_index1 ON dbo.vv_log(LOG_TIMESTAMP) WITH  FILLFACTOR = 95
GO

CREATE INDEX vv_log_index2 ON dbo.vv_log(LOG_USER_ID, LOG_TIMESTAMP) WITH  FILLFACTOR = 90
GO


-- GRANT SELECT, UPDATE ON [dbo].[vv_log]  TO [Verwalten]
---------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------
/*   sp_spaceused vv_log

--- kurze Abfrage mit aktuell=oben:
select top 99 * from vv_log order by LOG_TIMESTAMP desc


--- Daten erhalten, wenn Tabelle neu CREATED wird:
select * into #xxx from vv_log
insert vv_log select * from #xxx 
drop table #xxx


--- 
select top 50 row_number() over (partition by MV_ISIN order by MV_ISIN),* from vv_mastervalues
select top 5 * from vv_mastervalues_upload

*/
