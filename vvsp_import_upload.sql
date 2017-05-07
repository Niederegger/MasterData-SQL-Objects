-- 27.04.17 KB: Ersten Entwurf der Prozedur erstellt.
--              Die Prozedur überträgt Daten von VV_MASTERVALUES_UPLOAD nach VV_MASTERVALUES
--              und übernimmt dabei nur Werte, die sich tatsächlich geändert haben
-- 05.05.17 KB: if exist und drop/create genutzt statt ALTER PROCEDURE. Added logic to remove duplicate rows.
-- 07.05.17 KB: Neues Feld MV_UPLOAD_ID eingebaut

use MasterData
go

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[vvsp_import_upload]') )
  drop procedure dbo.vvsp_import_upload
go

create procedure dbo.vvsp_import_upload
as

Set NOCOUNT ON

declare @upload_id int        -- Kennung für diesen Batch, wird ermittelt als max(vorhandene) + 1
declare @received_rows int    -- number of rows in table "vv_mastervalues_upload" when this procedure is called
declare @identical_rows int   -- number of duplicate rows in table "vv_mastervalues_upload" which are removed
declare @existing_rows int    -- number of rows in table "vv_mastervalues_upload" which already exist in target table "vv_mastervalues"
declare @inserted_rows int    -- number of rows which finally made it into the target table.

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

  -- STEP 1: Remove duplicate rows from the source table
  delete T1
  from 
    (SELECT *, Row_number() OVER ( partition BY MVU_ISIN, MVU_MIC, MVU_AS_OF_DATE, MVU_SOURCE_ID, MVU_FIELDNAME,  MVU_STRINGVALUE, MVU_DATA_ORIGIN, MVU_URLSOURCE, MVU_COMMENT
                                   ORDER  BY MVU_timestamp desc  -- most recent is rownum=1, others will be deleted
                                 ) ROWNUM
       FROM vv_mastervalues_upload) T1
  where ROWNUM>1
  set @identical_rows = @@ROWCOUNT


  -- STEP 2: Alle upload-Daten verwerfen, deren Werte schon bekannt (d.h. in vv_mastervalue vorhanden) sind
  delete T1
    from vv_mastervalues_upload T1
   inner join vv_mastervalues 
      on MVU_SOURCE_ID = MV_SOURCE_ID
     and MVU_ISIN = MV_ISIN    
     and MV_FIELDNAME = MVU_FIELDNAME    
     and ((MVU_MIC is null and MV_MIC is null) or MVU_MIC = MV_MIC )
     and ((MVU_AS_OF_DATE is null and  MV_AS_OF_DATE  is null) or MVU_AS_OF_DATE = MV_AS_OF_DATE)
     and ((MVU_STRINGVALUE is null and MV_STRINGVALUE is null) or MVU_STRINGVALUE = MV_STRINGVALUE)

  set @existing_rows = @@ROWCOUNT


  -- STEP 3: upload_id ermitteln 
  select @upload_id = MAX(MV_UPLOAD_ID)+1 from vv_mastervalues
  
  -- STEP 4: verbliebene Daten nun in Zieltablle aufnehmen
  insert vv_mastervalues 
        (MV_SOURCE_ID,  MV_UPLOAD_ID, MV_ISIN, MV_MIC,  MV_AS_OF_DATE,  MV_FIELDNAME,  MV_TIMESTAMP,  MV_STRINGVALUE,  MV_DATA_ORIGIN,  MV_URLSOURCE,  MV_COMMENT)
  select MVU_SOURCE_ID, @upload_id,  MVU_ISIN, MVU_MIC, MVU_AS_OF_DATE, MVU_FIELDNAME, MVU_TIMESTAMP, MVU_STRINGVALUE, MVU_DATA_ORIGIN, MVU_URLSOURCE, MVU_COMMENT
   from vv_mastervalues_upload
  set @inserted_rows = @@ROWCOUNT

  -- STEP 5: Tabelle komplett löschen, frei für nächsten upload
  delete vv_mastervalues_upload

  insert vv_log 
  select getdate(),                           -- LOG_TIMESTAMP
         user_name(),                         -- LOG_USER_ID
         HOST_NAME(),                         -- LOG_HOST_NAME, 
         'vvsp_import_upload',                -- LOG_PROGRAM_NAME, ist varchar(32) in vv_LOG
         'done',                              -- LOG_VERARBEITUNGSSTATUS 
         'procedure finished, '+CONVERT(varchar(12),@received_rows)+' rows received, '
                               +CONVERT(varchar(12),@identical_rows)+' duplicate rows deleted, '  
                               +CONVERT(varchar(12),@existing_rows)+' existing rows deleted, '  
                               +CONVERT(varchar(12),@inserted_rows)+' rows inserted, '

commit
print 'procedure finished, '+CONVERT(varchar(12),@received_rows)+' rows received, '
                               +CONVERT(varchar(12),@identical_rows)+' duplicate rows deleted, '  
                               +CONVERT(varchar(12),@existing_rows)+' existing rows deleted, '  
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


Insert vv_mastervalues_upload ( MVU_SOURCE_ID, MVU_ISIN, MVU_MIC, MVU_FIELDNAME, MVU_STRINGVALUE, MVU_DATA_ORIGIN, MVU_URLSOURCE, MVU_COMMENT ) values ('DBA2', 'AEDFXA0M6V00', 'XFRA', 'Instrument', 'DP yyy LTD    DL 2', '20170314 allTradableInstruments.txt', 'http://www.deutsche-boerse-cash-market.com/dbcm-de/instrumente-statistiken/alle-handelbaren-instrumente/boersefrankfurt', 'Manuell von Kay');	Insert vv_mastervalues_upload ( MVU_SOURCE_ID, MVU_ISIN, MVU_MIC, MVU_FIELDNAME, MVU_STRINGVALUE, MVU_DATA_ORIGIN, MVU_URLSOURCE, MVU_COMMENT ) values ('DBAG', 'AEDFXA0M6V00', 'XFRA', 'WKN', 'A0M6V0', '20170427 allTradableInstruments.txt', 'http://www.deutsche-boerse-cash-market.com/dbcm-de/instrumente-statistiken/alle-handelbaren-instrumente/boersefrankfurt', 'Manuell von Kay');	Insert vv_mastervalues_upload ( MVU_SOURCE_ID, MVU_ISIN, MVU_MIC, MVU_FIELDNAME, MVU_STRINGVALUE, MVU_DATA_ORIGIN, MVU_URLSOURCE, MVU_COMMENT ) values ('DBAG', 'AEDFXA0M6V00', 'XFRA', 'Mnemonic', '3DW', '20170427 allTradableInstruments.txt', 'http://www.deutsche-boerse-cash-market.com/dbcm-de/instrumente-statistiken/alle-handelbaren-instrumente/boersefrankfurt', 'Manuell von Kay');	Insert vv_mastervalues_upload ( MVU_SOURCE_ID, MVU_ISIN, MVU_MIC, MVU_FIELDNAME, MVU_STRINGVALUE, MVU_DATA_ORIGIN, MVU_URLSOURCE, MVU_COMMENT ) values ('DBAG', 'AEDFXA0M6V00', 'XFRA', 'CCP eligible', 'no', '20170427 allTradableInstruments.txt', 'http://www.deutsche-boerse-cash-market.com/dbcm-de/instrumente-statistiken/alle-handelbaren-instrumente/boersefrankfurt', 'Manuell von Kay');
Insert vv_mastervalues_upload ( MVU_SOURCE_ID, MVU_ISIN, MVU_MIC, MVU_FIELDNAME, MVU_STRINGVALUE, MVU_DATA_ORIGIN, MVU_URLSOURCE, MVU_COMMENT ) values ('DBA2', 'AGP8696W1045', 'XFRA', 'Instrument', 'SINOVAC BIOTECH   DL-,001', '20170314 allTradableInstruments.txt', 'http://www.deutsche-boerse-cash-market.com/dbcm-de/instrumente-statistiken/alle-handelbaren-instrumente/boersefrankfurt', 'Manuell von Kay');	Insert vv_mastervalues_upload ( MVU_SOURCE_ID, MVU_ISIN, MVU_MIC, MVU_FIELDNAME, MVU_STRINGVALUE, MVU_DATA_ORIGIN, MVU_URLSOURCE, MVU_COMMENT ) values ('DBAG', 'AGP8696W1045', 'XFRA', 'WKN', '789125', '20170427 allTradableInstruments.txt', 'http://www.deutsche-boerse-cash-market.com/dbcm-de/instrumente-statistiken/alle-handelbaren-instrumente/boersefrankfurt', 'Manuell von Kay');	Insert vv_mastervalues_upload ( MVU_SOURCE_ID, MVU_ISIN, MVU_MIC, MVU_FIELDNAME, MVU_STRINGVALUE, MVU_DATA_ORIGIN, MVU_URLSOURCE, MVU_COMMENT ) values ('DBAG', 'AGP8696W1045', 'XFRA', 'Mnemonic', 'SVQ', '20170427 allTradableInstruments.txt', 'http://www.deutsche-boerse-cash-market.com/dbcm-de/instrumente-statistiken/alle-handelbaren-instrumente/boersefrankfurt', 'Manuell von Kay');	Insert vv_mastervalues_upload ( MVU_SOURCE_ID, MVU_ISIN, MVU_MIC, MVU_FIELDNAME, MVU_STRINGVALUE, MVU_DATA_ORIGIN, MVU_URLSOURCE, MVU_COMMENT ) values ('DBAG', 'AGP8696W1045', 'XFRA', 'CCP eligible', 'no', '20170427 allTradableInstruments.txt', 'http://www.deutsche-boerse-cash-market.com/dbcm-de/instrumente-statistiken/alle-handelbaren-instrumente/boersefrankfurt', 'Manuell von Kay');
Insert vv_mastervalues_upload ( MVU_SOURCE_ID, MVU_ISIN, MVU_MIC, MVU_FIELDNAME, MVU_STRINGVALUE, MVU_DATA_ORIGIN, MVU_URLSOURCE, MVU_COMMENT ) values ('DBA2', 'AN8068571086', 'XETR', 'Instrument', 'SCHLUMBERGER   DL-,01', '20170314 allTradableInstruments.txt', 'http://www.deutsche-boerse-cash-market.com/dbcm-de/instrumente-statistiken/alle-handelbaren-instrumente/boersefrankfurt', 'Manuell von Kay');	Insert vv_mastervalues_upload ( MVU_SOURCE_ID, MVU_ISIN, MVU_MIC, MVU_FIELDNAME, MVU_STRINGVALUE, MVU_DATA_ORIGIN, MVU_URLSOURCE, MVU_COMMENT ) values ('DBAG', 'AN8068571086', 'XETR', 'WKN', '853390', '20170427 allTradableInstruments.txt', 'http://www.deutsche-boerse-cash-market.com/dbcm-de/instrumente-statistiken/alle-handelbaren-instrumente/boersefrankfurt', 'Manuell von Kay');	Insert vv_mastervalues_upload ( MVU_SOURCE_ID, MVU_ISIN, MVU_MIC, MVU_FIELDNAME, MVU_STRINGVALUE, MVU_DATA_ORIGIN, MVU_URLSOURCE, MVU_COMMENT ) values ('DBAG', 'AN8068571086', 'XETR', 'Mnemonic', 'SCL', '20170427 allTradableInstruments.txt', 'http://www.deutsche-boerse-cash-market.com/dbcm-de/instrumente-statistiken/alle-handelbaren-instrumente/boersefrankfurt', 'Manuell von Kay');	Insert vv_mastervalues_upload ( MVU_SOURCE_ID, MVU_ISIN, MVU_MIC, MVU_FIELDNAME, MVU_STRINGVALUE, MVU_DATA_ORIGIN, MVU_URLSOURCE, MVU_COMMENT ) values ('DBAG', 'AN8068571086', 'XETR', 'CCP eligible', 'no', '20170427 allTradableInstruments.txt', 'http://www.deutsche-boerse-cash-market.com/dbcm-de/instrumente-statistiken/alle-handelbaren-instrumente/boersefrankfurt', 'Manuell von Kay');
Insert vv_mastervalues_upload ( MVU_SOURCE_ID, MVU_ISIN, MVU_MIC, MVU_FIELDNAME, MVU_STRINGVALUE, MVU_DATA_ORIGIN, MVU_URLSOURCE, MVU_COMMENT ) values ('DBA2', 'AN8068571086', 'XFRA', 'Instrument', 'SCHLUMBERGER   DL-,01', '20170314 allTradableInstruments.txt', 'http://www.deutsche-boerse-cash-market.com/dbcm-de/instrumente-statistiken/alle-handelbaren-instrumente/boersefrankfurt', 'Manuell von Kay');	Insert vv_mastervalues_upload ( MVU_SOURCE_ID, MVU_ISIN, MVU_MIC, MVU_FIELDNAME, MVU_STRINGVALUE, MVU_DATA_ORIGIN, MVU_URLSOURCE, MVU_COMMENT ) values ('DBAG', 'AN8068571086', 'XFRA', 'WKN', '853390', '20170427 allTradableInstruments.txt', 'http://www.deutsche-boerse-cash-market.com/dbcm-de/instrumente-statistiken/alle-handelbaren-instrumente/boersefrankfurt', 'Manuell von Kay');	Insert vv_mastervalues_upload ( MVU_SOURCE_ID, MVU_ISIN, MVU_MIC, MVU_FIELDNAME, MVU_STRINGVALUE, MVU_DATA_ORIGIN, MVU_URLSOURCE, MVU_COMMENT ) values ('DBAG', 'AN8068571086', 'XFRA', 'Mnemonic', 'SCL', '20170427 allTradableInstruments.txt', 'http://www.deutsche-boerse-cash-market.com/dbcm-de/instrumente-statistiken/alle-handelbaren-instrumente/boersefrankfurt', 'Manuell von Kay');	Insert vv_mastervalues_upload ( MVU_SOURCE_ID, MVU_ISIN, MVU_MIC, MVU_FIELDNAME, MVU_STRINGVALUE, MVU_DATA_ORIGIN, MVU_URLSOURCE, MVU_COMMENT ) values ('DBAG', 'AN8068571086', 'XFRA', 'CCP eligible', 'no', '20170427 allTradableInstruments.txt', 'http://www.deutsche-boerse-cash-market.com/dbcm-de/instrumente-statistiken/alle-handelbaren-instrumente/boersefrankfurt', 'Manuell von Kay');
Insert vv_mastervalues_upload ( MVU_SOURCE_ID, MVU_ISIN, MVU_MIC, MVU_FIELDNAME, MVU_STRINGVALUE, MVU_DATA_ORIGIN, MVU_URLSOURCE, MVU_COMMENT ) values ('DBA2', 'ANN4327C1220', 'XFRA', 'Instrument', 'HUNTER DOUGLAS      EO-24', '20170314 allTradableInstruments.txt', 'http://www.deutsche-boerse-cash-market.com/dbcm-de/instrumente-statistiken/alle-handelbaren-instrumente/boersefrankfurt', 'Manuell von Kay');	Insert vv_mastervalues_upload ( MVU_SOURCE_ID, MVU_ISIN, MVU_MIC, MVU_FIELDNAME, MVU_STRINGVALUE, MVU_DATA_ORIGIN, MVU_URLSOURCE, MVU_COMMENT ) values ('DBAG', 'ANN4327C1220', 'XFRA', 'WKN', '855243', '20170427 allTradableInstruments.txt', 'http://www.deutsche-boerse-cash-market.com/dbcm-de/instrumente-statistiken/alle-handelbaren-instrumente/boersefrankfurt', 'Manuell von Kay');	Insert vv_mastervalues_upload ( MVU_SOURCE_ID, MVU_ISIN, MVU_MIC, MVU_FIELDNAME, MVU_STRINGVALUE, MVU_DATA_ORIGIN, MVU_URLSOURCE, MVU_COMMENT ) values ('DBAG', 'ANN4327C1220', 'XFRA', 'Mnemonic', 'HUD', '20170427 allTradableInstruments.txt', 'http://www.deutsche-boerse-cash-market.com/dbcm-de/instrumente-statistiken/alle-handelbaren-instrumente/boersefrankfurt', 'Manuell von Kay');	Insert vv_mastervalues_upload ( MVU_SOURCE_ID, MVU_ISIN, MVU_MIC, MVU_FIELDNAME, MVU_STRINGVALUE, MVU_DATA_ORIGIN, MVU_URLSOURCE, MVU_COMMENT ) values ('DBAG', 'ANN4327C1220', 'XFRA', 'CCP eligible', 'no', '20170427 allTradableInstruments.txt', 'http://www.deutsche-boerse-cash-market.com/dbcm-de/instrumente-statistiken/alle-handelbaren-instrumente/boersefrankfurt', 'Manuell von Kay');
Insert vv_mastervalues_upload ( MVU_SOURCE_ID, MVU_ISIN, MVU_MIC, MVU_FIELDNAME, MVU_STRINGVALUE, MVU_DATA_ORIGIN, MVU_URLSOURCE, MVU_COMMENT ) values ('DBA2', 'ANN6748L1027', 'XFRA', 'Instrument', 'ORTHOFIX INT.      DL-,10', '20170314 allTradableInstruments.txt', 'http://www.deutsche-boerse-cash-market.com/dbcm-de/instrumente-statistiken/alle-handelbaren-instrumente/boersefrankfurt', 'Manuell von Kay');	Insert vv_mastervalues_upload ( MVU_SOURCE_ID, MVU_ISIN, MVU_MIC, MVU_FIELDNAME, MVU_STRINGVALUE, MVU_DATA_ORIGIN, MVU_URLSOURCE, MVU_COMMENT ) values ('DBAG', 'ANN6748L1027', 'XFRA', 'WKN', '889410', '20170427 allTradableInstruments.txt', 'http://www.deutsche-boerse-cash-market.com/dbcm-de/instrumente-statistiken/alle-handelbaren-instrumente/boersefrankfurt', 'Manuell von Kay');	Insert vv_mastervalues_upload ( MVU_SOURCE_ID, MVU_ISIN, MVU_MIC, MVU_FIELDNAME, MVU_STRINGVALUE, MVU_DATA_ORIGIN, MVU_URLSOURCE, MVU_COMMENT ) values ('DBAG', 'ANN6748L1027', 'XFRA', 'Mnemonic', 'OFX', '20170427 allTradableInstruments.txt', 'http://www.deutsche-boerse-cash-market.com/dbcm-de/instrumente-statistiken/alle-handelbaren-instrumente/boersefrankfurt', 'Manuell von Kay');	Insert vv_mastervalues_upload ( MVU_SOURCE_ID, MVU_ISIN, MVU_MIC, MVU_FIELDNAME, MVU_STRINGVALUE, MVU_DATA_ORIGIN, MVU_URLSOURCE, MVU_COMMENT ) values ('DBAG', 'ANN6748L1027', 'XFRA', 'CCP eligible', 'no', '20170427 allTradableInstruments.txt', 'http://www.deutsche-boerse-cash-market.com/dbcm-de/instrumente-statistiken/alle-handelbaren-instrumente/boersefrankfurt', 'Manuell von Kay');


*/

