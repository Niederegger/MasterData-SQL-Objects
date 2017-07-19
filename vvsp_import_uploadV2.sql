-- 27.04.17 KB: Ersten Entwurf der Prozedur erstellt.
--              Die Prozedur überträgt Daten von VV_MASTERVALUES_UPLOAD nach VV_MASTERVALUES
--              und übernimmt dabei nur Werte, die sich tatsächlich geändert haben
-- 05.05.17 KB: if exist und drop/create genutzt statt ALTER PROCEDURE. Added logic to remove duplicate rows.
-- 07.05.17 KB: Neues Feld MV_UPLOAD_ID eingebaut
-- 08.06.17 KB: Neues Feld MV_LAST_SEEN behandelt, NEue Tabelle vv_updates eingebaut, neue Version uploadV2 (alte Vers=wrapper)
-- 18.06.17 KB: In der Datenübernahme in vv_mastervalues (Step5) statt @COMMENT jetzt Feld MVU_COMMENT aus der Quelltabelle genutzt
-- 12.07.17 AG: Anpassung: Upload erhällt als zusätzliche Condition auf Data_Origin zu achten, neben Source_Id, Änderungen: (Z:52, Z:62, Z:102, Z:115)
-- 12.07.17 AG: Z:126 ein Leerzeichen wurde hinzugefügt, für bessere Lesbarkeit (Nach der Source_ID ein Leerzeichen, damit die Zahl nicht direkt dran gehängt wird)

use MasterData
go

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[vvsp_import_uploadV2]') )
  drop procedure dbo.vvsp_import_uploadV2
go

create procedure dbo.vvsp_import_uploadV2
  @SOURCE_ID    char(8),       -- z.B. DBAG für "Deutsche Böse AG", definiert u.a. welche Felder kommen.
  @DATA_ORIGIN  varchar(256),  -- Die Quelle, woher wir diesen wert haben, zB "File 20170426_Frankfurt_Data.csv"
  @URLSOURCE    varchar(256),  -- Wenn relevant, der URL-Link der Quelle, zB "http://www.deutsche-boerse-cash-market.com/dbcm-de/instrumente-statistiken/alle-handelbaren-instrumente/boersefrankfurt"
  @COMMENT      varchar(256)   -- Optional für freie Kommentare, z.B. "manueller upload nach Formatänderung"
as

Set NOCOUNT ON

declare @upload_id int        -- Kennung für diesen Batch, wird ermittelt als max(vorhandene) + 1
declare @received_rows int    -- number of rows in table "vv_mastervalues_upload" when this procedure is called
declare @identical_rows int   -- number of duplicate rows in table "vv_mastervalues_upload" which are removed
declare @seen_rows int        -- number of rows in table "vv_mastervalues_upload" which already exist in target table "vv_mastervalues"
declare @existing_rows int    -- number of rows in table "vv_mastervalues_upload" which already exist in target table "vv_mastervalues"
declare @inserted_rows int    -- number of rows which finally made it into the target table.
declare @now datetime

set @now = getdate()


----- Eintrag in VV_LOG machen
insert vv_log 
  select @now,						-- LOG_TIMESTAMP
         user_name(),				-- LOG_USER_ID
         HOST_NAME(),				-- LOG_HOST_NAME,          
         'vvsp_import_uploadV2',	-- LOG_PROGRAM_NAME
         'start ',					-- LOG_VERARBEITUNGSSTATUS 
         'procedure started, @SOURCE_ID='+CONVERT(varchar(12),@SOURCE_ID)     -- LOG_TEXT

begin tran

  -- STEP 1: neue @upload_id für diesen Upload ermitteln und @received_rows zählen
  select @upload_id = MAX(UPL_UPLOAD_ID)+1 from vv_uploads WITH (TABLOCK, HOLDLOCK)

  select @received_rows = COUNT(*) from vv_mastervalues_upload WITH (TABLOCK, HOLDLOCK)
                                   where MVU_SOURCE_ID = @SOURCE_ID and MVU_DATA_ORIGIN = @DATA_ORIGIN 

  -- STEP 2: Remove duplicate rows from the source table
  delete T1
  from 
    (SELECT *, Row_number() OVER ( partition BY MVU_ISIN, MVU_MIC, MVU_AS_OF_DATE, MVU_SOURCE_ID, MVU_FIELDNAME,  MVU_STRINGVALUE, MVU_DATA_ORIGIN, MVU_URLSOURCE, MVU_COMMENT
                                   ORDER  BY MVU_timestamp desc  -- most recent is rownum=1, others will be deleted
                                 ) ROWNUM
       FROM vv_mastervalues_upload) T1
  where ROWNUM>1
    and MVU_SOURCE_ID = @SOURCE_ID  and MVU_DATA_ORIGIN = @DATA_ORIGIN 
    
  set @identical_rows = @@ROWCOUNT

  -- STEP 3: Alle Daten, deren Werte schon bekannt (d.h. in vv_mastervalue vorhanden) sind, im Feld MV_LAST_SEEN updaten 
  update T2
  set T2.MV_LAST_SEEN = @now 
    from vv_mastervalues_upload T1
   inner join vv_mastervalues T2
      on MVU_SOURCE_ID = MV_SOURCE_ID
     and MVU_ISIN = MV_ISIN    
     and MV_FIELDNAME = MVU_FIELDNAME    
     and ((MVU_MIC is null and MV_MIC is null) or MVU_MIC = MV_MIC )
     and ((MVU_AS_OF_DATE is null and  MV_AS_OF_DATE  is null) or MVU_AS_OF_DATE = MV_AS_OF_DATE)
     and ((MVU_STRINGVALUE is null and MV_STRINGVALUE is null) or MVU_STRINGVALUE = MV_STRINGVALUE)
   where T1.MVU_SOURCE_ID = @SOURCE_ID and T1.MVU_DATA_ORIGIN = @DATA_ORIGIN 

  set @seen_rows = @@ROWCOUNT  -- muss gleich @existing_rows sein !


  -- STEP 4: Alle upload-Daten verwerfen, deren Werte schon bekannt (d.h. in vv_mastervalue vorhanden) sind
  delete T1
    from vv_mastervalues_upload T1
   inner join vv_mastervalues 
      on MVU_SOURCE_ID = MV_SOURCE_ID
     and MVU_ISIN = MV_ISIN    
     and MV_FIELDNAME = MVU_FIELDNAME    
     and ((MVU_MIC is null and MV_MIC is null) or MVU_MIC = MV_MIC )
     and ((MVU_AS_OF_DATE is null and  MV_AS_OF_DATE  is null) or MVU_AS_OF_DATE = MV_AS_OF_DATE)
     and ((MVU_STRINGVALUE is null and MV_STRINGVALUE is null) or MVU_STRINGVALUE = MV_STRINGVALUE)
   where T1.MVU_SOURCE_ID = @SOURCE_ID  and T1.MVU_DATA_ORIGIN = @DATA_ORIGIN 
   
  set @existing_rows = @@ROWCOUNT

  
  -- STEP 5: verbliebene Daten nun in Zieltabelle aufnehmen (Feld MV_LAST_SEEN nicht, bleibt NULL)
  insert vv_mastervalues 
        (MV_SOURCE_ID,  MV_UPLOAD_ID, MV_ISIN, MV_MIC,  MV_AS_OF_DATE,  MV_FIELDNAME,  MV_TIMESTAMP,  MV_STRINGVALUE, MV_COMMENT)
  select MVU_SOURCE_ID, @upload_id,  MVU_ISIN, MVU_MIC, MVU_AS_OF_DATE, MVU_FIELDNAME, MVU_TIMESTAMP, MVU_STRINGVALUE, MVU_COMMENT 
   from vv_mastervalues_upload
  where MVU_SOURCE_ID = @SOURCE_ID and MVU_DATA_ORIGIN = @DATA_ORIGIN 

  set @inserted_rows = @@ROWCOUNT


  -- STEP 6: Eine Zeile eintragen in Tabelle vv_uploads für die Upload-Historie (und vergebene Upload_IDs)
  insert vv_uploads 
        (UPL_UPLOAD_ID, UPL_SOURCE_ID, UPL_USER_ID, UPL_HOST_NAME, UPL_TIMESTAMP, UPL_RECEIVED_ROWS, UPL_IDENTICAL_ROWS, UPL_EXISTING_ROWS, UPL_INSERTED_ROWS, UPL_DATA_ORIGIN, UPL_URLSOURCE, UPL_COMMENT)
  select @upload_id,  @SOURCE_ID, user_name(), HOST_NAME(), @now, @received_rows, @identical_rows, @existing_rows, @inserted_rows, @DATA_ORIGIN, @URLSOURCE, @COMMENT  
  
  
  -- STEP 7: Upload-Tabelle für die erledigte Source-ID löschen
  delete vv_mastervalues_upload
   where MVU_SOURCE_ID = @SOURCE_ID and MVU_DATA_ORIGIN = @DATA_ORIGIN 


  insert vv_log 
  select getdate(),                         -- LOG_TIMESTAMP
         user_name(),                       -- LOG_USER_ID
         HOST_NAME(),                       -- LOG_HOST_NAME, 
         'vvsp_import_uploadV2',            -- LOG_PROGRAM_NAME, ist varchar(32) in vv_LOG
         'done',                            -- LOG_VERARBEITUNGSSTATUS 
         'procedure finished, @upload_id='+CONVERT(varchar(10), @upload_id)
                               +', @SOURCE_ID='+CONVERT(varchar(12),@SOURCE_ID)+' '
                               +CONVERT(varchar(12),@received_rows)+' rows received, '
                               +CONVERT(varchar(12),@identical_rows)+' duplicate rows deleted, '  
                               +CONVERT(varchar(12),@seen_rows)+' existing rows updated, '  
                               +CONVERT(varchar(12),@existing_rows)+' existing rows discarded, '  
                               +CONVERT(varchar(12),@inserted_rows)+' rows inserted'

commit
print 'procedure finished, @upload_id='+CONVERT(varchar(10), @upload_id)
                               +', @SOURCE_ID='+CONVERT(varchar(12),@SOURCE_ID)
                               +CONVERT(varchar(12),@received_rows)+' rows received, '
                               +CONVERT(varchar(12),@identical_rows)+' duplicate rows deleted, '  
                               +CONVERT(varchar(12),@seen_rows)+' existing rows updated, '  
                               +CONVERT(varchar(12),@existing_rows)+' existing rows discarded, '  
                               +CONVERT(varchar(12),@inserted_rows)+' rows inserted'

-----------------------------------------------------------------------------------------
-- sp_helptext vvsp_import_uploadV2 
/*

insert vv_mastervalues_upload select top 99 * from vv_mastervalues
exec vvsp_import_uploadV2 'DBAG', 'x', 'x', 'x'

insert vv_mastervalues_upload select * from vv_upload_beispiel

select top 999 * from vv_mastervalues where mv_upload_id=14 
select MV_UPLOAD_ID, MV_SOURCE_ID, count(*) from vv_mastervalues group by MV_UPLOAD_ID, MV_SOURCE_ID 
delete vv_mastervalues where mv_upload_id=14 and MV_MIC='XFRA'

select * into vv_beispiel5 from vv_mastervalues_upload with (nolock) --  550269
select top 99 * from vv_beispiel5 

insert vv_mastervalues_upload select * from vv_beispiel5
update vv_mastervalues_upload set MVU_source_id='DBAGKURS' where MVU_Fieldname like 'Closing%'

select count(*) from vv_mastervalues_upload with (nolock)


select * from vv_log order by log_timestamp desc

select top 999 * from vv_mastervalues order by mv_timestamp desc
select * from vv_uploads
select top 9 * from vv_mastervalues_upload order by mvu_timestamp desc
select count(*) from vv_mastervalues_upload 



Insert vv_mastervalues_upload ( MVU_SOURCE_ID, MVU_ISIN, MVU_MIC, MVU_FIELDNAME, MVU_STRINGVALUE, MVU_DATA_ORIGIN, MVU_URLSOURCE, MVU_COMMENT ) values ('DBA2', 'AEDFXA0M6V00', 'XFRA', 'Instrument', 'DP yyy LTD    DL 2', '20170314 allTradableInstruments.txt', 'http://www.deutsche-boerse-cash-market.com/dbcm-de/instrumente-statistiken/alle-handelbaren-instrumente/boersefrankfurt', 'Manuell von Kay');	Insert vv_mastervalues_upload ( MVU_SOURCE_ID, MVU_ISIN, MVU_MIC, MVU_FIELDNAME, MVU_STRINGVALUE, MVU_DATA_ORIGIN, MVU_URLSOURCE, MVU_COMMENT ) values ('DBAG', 'AEDFXA0M6V00', 'XFRA', 'WKN', 'A0M6V0', '20170427 allTradableInstruments.txt', 'http://www.deutsche-boerse-cash-market.com/dbcm-de/instrumente-statistiken/alle-handelbaren-instrumente/boersefrankfurt', 'Manuell von Kay');	Insert vv_mastervalues_upload ( MVU_SOURCE_ID, MVU_ISIN, MVU_MIC, MVU_FIELDNAME, MVU_STRINGVALUE, MVU_DATA_ORIGIN, MVU_URLSOURCE, MVU_COMMENT ) values ('DBAG', 'AEDFXA0M6V00', 'XFRA', 'Mnemonic', '3DW', '20170427 allTradableInstruments.txt', 'http://www.deutsche-boerse-cash-market.com/dbcm-de/instrumente-statistiken/alle-handelbaren-instrumente/boersefrankfurt', 'Manuell von Kay');	Insert vv_mastervalues_upload ( MVU_SOURCE_ID, MVU_ISIN, MVU_MIC, MVU_FIELDNAME, MVU_STRINGVALUE, MVU_DATA_ORIGIN, MVU_URLSOURCE, MVU_COMMENT ) values ('DBAG', 'AEDFXA0M6V00', 'XFRA', 'CCP eligible', 'no', '20170427 allTradableInstruments.txt', 'http://www.deutsche-boerse-cash-market.com/dbcm-de/instrumente-statistiken/alle-handelbaren-instrumente/boersefrankfurt', 'Manuell von Kay');
Insert vv_mastervalues_upload ( MVU_SOURCE_ID, MVU_ISIN, MVU_MIC, MVU_FIELDNAME, MVU_STRINGVALUE, MVU_DATA_ORIGIN, MVU_URLSOURCE, MVU_COMMENT ) values ('DBA2', 'AGP8696W1045', 'XFRA', 'Instrument', 'SINOVAC BIOTECH   DL-,001', '20170314 allTradableInstruments.txt', 'http://www.deutsche-boerse-cash-market.com/dbcm-de/instrumente-statistiken/alle-handelbaren-instrumente/boersefrankfurt', 'Manuell von Kay');	Insert vv_mastervalues_upload ( MVU_SOURCE_ID, MVU_ISIN, MVU_MIC, MVU_FIELDNAME, MVU_STRINGVALUE, MVU_DATA_ORIGIN, MVU_URLSOURCE, MVU_COMMENT ) values ('DBAG', 'AGP8696W1045', 'XFRA', 'WKN', '789125', '20170427 allTradableInstruments.txt', 'http://www.deutsche-boerse-cash-market.com/dbcm-de/instrumente-statistiken/alle-handelbaren-instrumente/boersefrankfurt', 'Manuell von Kay');	Insert vv_mastervalues_upload ( MVU_SOURCE_ID, MVU_ISIN, MVU_MIC, MVU_FIELDNAME, MVU_STRINGVALUE, MVU_DATA_ORIGIN, MVU_URLSOURCE, MVU_COMMENT ) values ('DBAG', 'AGP8696W1045', 'XFRA', 'Mnemonic', 'SVQ', '20170427 allTradableInstruments.txt', 'http://www.deutsche-boerse-cash-market.com/dbcm-de/instrumente-statistiken/alle-handelbaren-instrumente/boersefrankfurt', 'Manuell von Kay');	Insert vv_mastervalues_upload ( MVU_SOURCE_ID, MVU_ISIN, MVU_MIC, MVU_FIELDNAME, MVU_STRINGVALUE, MVU_DATA_ORIGIN, MVU_URLSOURCE, MVU_COMMENT ) values ('DBAG', 'AGP8696W1045', 'XFRA', 'CCP eligible', 'no', '20170427 allTradableInstruments.txt', 'http://www.deutsche-boerse-cash-market.com/dbcm-de/instrumente-statistiken/alle-handelbaren-instrumente/boersefrankfurt', 'Manuell von Kay');
Insert vv_mastervalues_upload ( MVU_SOURCE_ID, MVU_ISIN, MVU_MIC, MVU_FIELDNAME, MVU_STRINGVALUE, MVU_DATA_ORIGIN, MVU_URLSOURCE, MVU_COMMENT ) values ('DBA2', 'AN8068571086', 'XETR', 'Instrument', 'SCHLUMBERGER   DL-,01', '20170314 allTradableInstruments.txt', 'http://www.deutsche-boerse-cash-market.com/dbcm-de/instrumente-statistiken/alle-handelbaren-instrumente/boersefrankfurt', 'Manuell von Kay');	Insert vv_mastervalues_upload ( MVU_SOURCE_ID, MVU_ISIN, MVU_MIC, MVU_FIELDNAME, MVU_STRINGVALUE, MVU_DATA_ORIGIN, MVU_URLSOURCE, MVU_COMMENT ) values ('DBAG', 'AN8068571086', 'XETR', 'WKN', '853390', '20170427 allTradableInstruments.txt', 'http://www.deutsche-boerse-cash-market.com/dbcm-de/instrumente-statistiken/alle-handelbaren-instrumente/boersefrankfurt', 'Manuell von Kay');	Insert vv_mastervalues_upload ( MVU_SOURCE_ID, MVU_ISIN, MVU_MIC, MVU_FIELDNAME, MVU_STRINGVALUE, MVU_DATA_ORIGIN, MVU_URLSOURCE, MVU_COMMENT ) values ('DBAG', 'AN8068571086', 'XETR', 'Mnemonic', 'SCL', '20170427 allTradableInstruments.txt', 'http://www.deutsche-boerse-cash-market.com/dbcm-de/instrumente-statistiken/alle-handelbaren-instrumente/boersefrankfurt', 'Manuell von Kay');	Insert vv_mastervalues_upload ( MVU_SOURCE_ID, MVU_ISIN, MVU_MIC, MVU_FIELDNAME, MVU_STRINGVALUE, MVU_DATA_ORIGIN, MVU_URLSOURCE, MVU_COMMENT ) values ('DBAG', 'AN8068571086', 'XETR', 'CCP eligible', 'no', '20170427 allTradableInstruments.txt', 'http://www.deutsche-boerse-cash-market.com/dbcm-de/instrumente-statistiken/alle-handelbaren-instrumente/boersefrankfurt', 'Manuell von Kay');
Insert vv_mastervalues_upload ( MVU_SOURCE_ID, MVU_ISIN, MVU_MIC, MVU_FIELDNAME, MVU_STRINGVALUE, MVU_DATA_ORIGIN, MVU_URLSOURCE, MVU_COMMENT ) values ('DBA2', 'AN8068571086', 'XFRA', 'Instrument', 'SCHLUMBERGER   DL-,01', '20170314 allTradableInstruments.txt', 'http://www.deutsche-boerse-cash-market.com/dbcm-de/instrumente-statistiken/alle-handelbaren-instrumente/boersefrankfurt', 'Manuell von Kay');	Insert vv_mastervalues_upload ( MVU_SOURCE_ID, MVU_ISIN, MVU_MIC, MVU_FIELDNAME, MVU_STRINGVALUE, MVU_DATA_ORIGIN, MVU_URLSOURCE, MVU_COMMENT ) values ('DBAG', 'AN8068571086', 'XFRA', 'WKN', '853390', '20170427 allTradableInstruments.txt', 'http://www.deutsche-boerse-cash-market.com/dbcm-de/instrumente-statistiken/alle-handelbaren-instrumente/boersefrankfurt', 'Manuell von Kay');	Insert vv_mastervalues_upload ( MVU_SOURCE_ID, MVU_ISIN, MVU_MIC, MVU_FIELDNAME, MVU_STRINGVALUE, MVU_DATA_ORIGIN, MVU_URLSOURCE, MVU_COMMENT ) values ('DBAG', 'AN8068571086', 'XFRA', 'Mnemonic', 'SCL', '20170427 allTradableInstruments.txt', 'http://www.deutsche-boerse-cash-market.com/dbcm-de/instrumente-statistiken/alle-handelbaren-instrumente/boersefrankfurt', 'Manuell von Kay');	Insert vv_mastervalues_upload ( MVU_SOURCE_ID, MVU_ISIN, MVU_MIC, MVU_FIELDNAME, MVU_STRINGVALUE, MVU_DATA_ORIGIN, MVU_URLSOURCE, MVU_COMMENT ) values ('DBAG', 'AN8068571086', 'XFRA', 'CCP eligible', 'no', '20170427 allTradableInstruments.txt', 'http://www.deutsche-boerse-cash-market.com/dbcm-de/instrumente-statistiken/alle-handelbaren-instrumente/boersefrankfurt', 'Manuell von Kay');
Insert vv_mastervalues_upload ( MVU_SOURCE_ID, MVU_ISIN, MVU_MIC, MVU_FIELDNAME, MVU_STRINGVALUE, MVU_DATA_ORIGIN, MVU_URLSOURCE, MVU_COMMENT ) values ('DBA2', 'ANN4327C1220', 'XFRA', 'Instrument', 'HUNTER DOUGLAS      EO-24', '20170314 allTradableInstruments.txt', 'http://www.deutsche-boerse-cash-market.com/dbcm-de/instrumente-statistiken/alle-handelbaren-instrumente/boersefrankfurt', 'Manuell von Kay');	Insert vv_mastervalues_upload ( MVU_SOURCE_ID, MVU_ISIN, MVU_MIC, MVU_FIELDNAME, MVU_STRINGVALUE, MVU_DATA_ORIGIN, MVU_URLSOURCE, MVU_COMMENT ) values ('DBAG', 'ANN4327C1220', 'XFRA', 'WKN', '855243', '20170427 allTradableInstruments.txt', 'http://www.deutsche-boerse-cash-market.com/dbcm-de/instrumente-statistiken/alle-handelbaren-instrumente/boersefrankfurt', 'Manuell von Kay');	Insert vv_mastervalues_upload ( MVU_SOURCE_ID, MVU_ISIN, MVU_MIC, MVU_FIELDNAME, MVU_STRINGVALUE, MVU_DATA_ORIGIN, MVU_URLSOURCE, MVU_COMMENT ) values ('DBAG', 'ANN4327C1220', 'XFRA', 'Mnemonic', 'HUD', '20170427 allTradableInstruments.txt', 'http://www.deutsche-boerse-cash-market.com/dbcm-de/instrumente-statistiken/alle-handelbaren-instrumente/boersefrankfurt', 'Manuell von Kay');	Insert vv_mastervalues_upload ( MVU_SOURCE_ID, MVU_ISIN, MVU_MIC, MVU_FIELDNAME, MVU_STRINGVALUE, MVU_DATA_ORIGIN, MVU_URLSOURCE, MVU_COMMENT ) values ('DBAG', 'ANN4327C1220', 'XFRA', 'CCP eligible', 'no', '20170427 allTradableInstruments.txt', 'http://www.deutsche-boerse-cash-market.com/dbcm-de/instrumente-statistiken/alle-handelbaren-instrumente/boersefrankfurt', 'Manuell von Kay');
Insert vv_mastervalues_upload ( MVU_SOURCE_ID, MVU_ISIN, MVU_MIC, MVU_FIELDNAME, MVU_STRINGVALUE, MVU_DATA_ORIGIN, MVU_URLSOURCE, MVU_COMMENT ) values ('DBA2', 'ANN6748L1027', 'XFRA', 'Instrument', 'ORTHOFIX INT.      DL-,10', '20170314 allTradableInstruments.txt', 'http://www.deutsche-boerse-cash-market.com/dbcm-de/instrumente-statistiken/alle-handelbaren-instrumente/boersefrankfurt', 'Manuell von Kay');	Insert vv_mastervalues_upload ( MVU_SOURCE_ID, MVU_ISIN, MVU_MIC, MVU_FIELDNAME, MVU_STRINGVALUE, MVU_DATA_ORIGIN, MVU_URLSOURCE, MVU_COMMENT ) values ('DBAG', 'ANN6748L1027', 'XFRA', 'WKN', '889410', '20170427 allTradableInstruments.txt', 'http://www.deutsche-boerse-cash-market.com/dbcm-de/instrumente-statistiken/alle-handelbaren-instrumente/boersefrankfurt', 'Manuell von Kay');	Insert vv_mastervalues_upload ( MVU_SOURCE_ID, MVU_ISIN, MVU_MIC, MVU_FIELDNAME, MVU_STRINGVALUE, MVU_DATA_ORIGIN, MVU_URLSOURCE, MVU_COMMENT ) values ('DBAG', 'ANN6748L1027', 'XFRA', 'Mnemonic', 'OFX', '20170427 allTradableInstruments.txt', 'http://www.deutsche-boerse-cash-market.com/dbcm-de/instrumente-statistiken/alle-handelbaren-instrumente/boersefrankfurt', 'Manuell von Kay');	Insert vv_mastervalues_upload ( MVU_SOURCE_ID, MVU_ISIN, MVU_MIC, MVU_FIELDNAME, MVU_STRINGVALUE, MVU_DATA_ORIGIN, MVU_URLSOURCE, MVU_COMMENT ) values ('DBAG', 'ANN6748L1027', 'XFRA', 'CCP eligible', 'no', '20170427 allTradableInstruments.txt', 'http://www.deutsche-boerse-cash-market.com/dbcm-de/instrumente-statistiken/alle-handelbaren-instrumente/boersefrankfurt', 'Manuell von Kay');


*/

