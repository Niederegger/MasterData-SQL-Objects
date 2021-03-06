-- 27.04.17 KB: Ersten Entwurf der Prozedur erstellt.
--              Die Prozedur �bertr�gt Daten von VV_MASTERVALUES_UPLOAD nach VV_MASTERVALUES
--              und �bernimmt dabei nur Werte, die sich tats�chlich ge�ndert haben
-- 05.05.17 KB: if exist und drop/create genutzt statt ALTER PROCEDURE. Added logic to remove duplicate rows.
-- 07.05.17 KB: Neues Feld MV_UPLOAD_ID eingebaut
-- 08.06.17 KB: NEues Feld MV_LAST_SEEN behandelt, Update eingebaut

use MasterData
go

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[vvsp_import_upload]') )
  drop procedure dbo.vvsp_import_upload
go

create procedure dbo.vvsp_import_upload
as

Set NOCOUNT ON

declare @CURRENT_SOURCE_ID    char(8)        -- z.B. DBAG f�r "Deutsche B�se AG", definiert u.a. welche Felder kommen.
declare @CURRENT_DATA_ORIGIN  varchar(256)   -- Die Quelle, woher wir diesen wert haben, zB "File 20170426_Frankfurt_Data.csv"
declare @CURRENT_URLSOURCE    varchar(256)   -- Wenn relevant, der URL-Link der Quelle, zB "http://www.deutsche-boerse-cash-market.com/dbcm-de/instrumente-statistiken/alle-handelbaren-instrumente/boersefrankfurt"
declare @CURRENT_COMMENT      varchar(256)   -- Optional f�r freie Kommentare, z.B. "manueller upload nach Format�nderung"


----- Eintrag in VV_LOG machen
insert vv_log 
  select getdate(),                  -- LOG_TIMESTAMP
         user_name(),                -- LOG_USER_ID
         HOST_NAME(),                -- LOG_HOST_NAME,          
         'vvsp_import_upload',       -- LOG_PROGRAM_NAME
         'start',                    -- LOG_VERARBEITUNGSSTATUS 
         'procedure started'         -- LOG_TEXT

begin tran

  while(1=1)
  begin
  
    select top 1
       @CURRENT_SOURCE_ID   = MVU_SOURCE_ID,
       @CURRENT_DATA_ORIGIN = MVU_DATA_ORIGIN,
       @CURRENT_URLSOURCE   = MVU_URLSOURCE,
       @CURRENT_COMMENT     = MVU_COMMENT
      from vv_mastervalues_upload  WITH (TABLOCK, HOLDLOCK)
     order by MVU_TIMESTAMP, MVU_SOURCE_ID, MVU_DATA_ORIGIN, MVU_URLSOURCE, MVU_COMMENT

    if @@ROWCOUNT=0 break

    exec dbo.vvsp_import_uploadV2  @CURRENT_SOURCE_ID, @CURRENT_DATA_ORIGIN, @CURRENT_URLSOURCE, @CURRENT_COMMENT

    delete vv_mastervalues_upload -- geschieht eigentlich innerhalb von vvsp_import_uploadV2, hier zur Sicherheit
     where MVU_SOURCE_ID   = @CURRENT_SOURCE_ID
       and MVU_DATA_ORIGIN = @CURRENT_DATA_ORIGIN
       and MVU_URLSOURCE   = @CURRENT_URLSOURCE   
       and MVU_COMMENT     = @CURRENT_COMMENT     

  end --of while

  insert vv_log 
  select getdate(),                -- LOG_TIMESTAMP
         user_name(),              -- LOG_USER_ID
         HOST_NAME(),              -- LOG_HOST_NAME, 
         'vvsp_import_upload',     -- LOG_PROGRAM_NAME, ist varchar(32) in vv_LOG
         'done',                   -- LOG_VERARBEITUNGSSTATUS 
         'procedure finished'      -- LOG_TEXT

commit

print 'procedure vvsp_import_upload finished'

-----------------------------------------------------------------------------------------
-- sp_helptext vvsp_import_upload 
/*

insert vv_mastervalues_upload select top 99 * from vv_mastervalues
exec vvsp_import_upload
select HOST_NAME()
select * from vv_log order by LOG_TIMESTAMP desc
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

