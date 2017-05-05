-- 27.04.17 KB: Ersten Entwurf der Prozedur erstellt.
--              Die Prozedur überträgt Daten von VV_MASTERVALUES_UPLOAD nach VV_MASTERVALUES
--              und übernimmt dabei nur Werte, die sich tatsächlich geändert haben
-- 05.05.17 KB: if exist und drop/create genutzt statt ALTER PROCEDURE
use MasterData
go

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[vvsp_import_upload]') )
  drop procedure dbo.vvsp_import_upload
go

create procedure dbo.vvsp_import_upload
as

Set NOCOUNT ON

declare @received_rows int
declare @identical_rows int
declare @deleted_rows int
declare @inserted_rows int

----- Eintrag in VV_LOG machen
insert vv_log 
  select getdate(),                           -- LOG_TIMESTAMP
         user_name(),                         -- LOG_USER_ID
         HOST_NAME(),                         -- LOG_HOST_NAME,          
         'vvsp_import_upload',                -- LOG_PROGRAM_NAME
         'start',                             -- LOG_VERARBEITUNGSSTATUS 
         'procedure started'                  -- LOG_TEXT

begin tran

  select @received_rows = COUNT(*) from vv_mastervalues_upload WITH (TABLOCK, HOLDLOCK)

  -- Schritt 1: Alle upload-Daten verwerfen, deren Werte schon bekannt (d.h. in vv_mastervalue vorhanden) sind
  delete T1
    from vv_mastervalues_upload T1
   inner join vv_mastervalues 
      on MVU_SOURCE_ID = MV_SOURCE_ID
     and MVU_ISIN = MV_ISIN        
     and ((MVU_MIC is null and MV_MIC is null) or MVU_MIC = MV_MIC )
     and ((MVU_AS_OF_DATE is null and  MV_AS_OF_DATE  is null) or MVU_AS_OF_DATE = MV_AS_OF_DATE)
     and ((MVU_STRINGVALUE is null and MV_STRINGVALUE is null) or MVU_STRINGVALUE = MV_STRINGVALUE)

  set @deleted_rows = @@ROWCOUNT

  -- Schritt 2: verbliebene Daten nun in Zieltablle aufnehmen
  insert vv_mastervalues select * from vv_mastervalues_upload
  set @inserted_rows = @@ROWCOUNT

  -- Schritt 3: Tabelle komplett löschen, frei für nächsten upload
  delete vv_mastervalues_upload

  insert vv_log 
  select getdate(),                           -- LOG_TIMESTAMP
         user_name(),                         -- LOG_USER_ID
         HOST_NAME(),                         -- LOG_HOST_NAME, 
         'vvsp_import_upload',                -- LOG_PROGRAM_NAME, ist varchar(32) in vv_LOG
         'done',                              -- LOG_VERARBEITUNGSSTATUS 
         'procedure finished, '+CONVERT(varchar(12),@received_rows)+' rows received, '
                               +CONVERT(varchar(12),@deleted_rows)+' rows deleted, '  
                               +CONVERT(varchar(12),@inserted_rows)+' rows inserted, '

commit
print 'procedure finished, '+CONVERT(varchar(12),@received_rows)+' rows received, '
                               +CONVERT(varchar(12),@deleted_rows)+' rows deleted, '  
                               +CONVERT(varchar(12),@inserted_rows)+' rows inserted, '

-----------------------------------------------------------------------------------------
-- sp_helptext vvsp_import_upload 
/*

insert vv_mastervalues_upload select top 99 * from vv_mastervalues
exec vvsp_import_upload
select HOST_NAME()
select * from vv_log
select * from vv_mastervalues_upload 
select top 9 * from vv_mastervalues order by mv_timestamp desc
select top 9 * from vv_mastervalues_upload order by mvu_timestamp desc
select count(*) from vv_mastervalues_upload 
select @@rowcount


*/

