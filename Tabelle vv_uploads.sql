-- 08.06.2017 KB: Neue Tabelle zur Protokollierung der Uploads. Wird befüllt durch upload-storedProc
-- 30.07.2017 KB: Feld UPL_SOURCEFILE neu eingefügt (an vorletzter Stelle)

Use MasterData
go

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[vv_uploads]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].vv_uploads
GO

CREATE TABLE dbo.vv_uploads
(
  UPL_UPLOAD_ID      int not null,  -- a counter which increases by one for each upload-batch
  UPL_SOURCE_ID      char(8),       -- z.B. DBAG für "Deutsche Böse AG", definiert u.a. welche Felder kommen. Könnte zukünftig auch "USER" für Benutzeränderungen nach WIKI-Methodik enthalten.
  UPL_USER_ID        nvarchar(32),  -- the user (in future: web-user) uploading this batch (type is as in vv_log)
  UPL_HOST_NAME      nvarchar(32),  -- host_name() (type is as in vv_log)
  UPL_TIMESTAMP      datetime,      -- Datum, wann dieses Feld geschrieben wurde (es gibt hier nie updates, max timestamp= aktuell)
  UPL_RECEIVED_ROWS  int,           -- number of rows in table "vv_mastervalues_upload" when this procedure is called
  UPL_IDENTICAL_ROWS int,           -- number of duplicate rows in table "vv_mastervalues_upload" which are removed
  UPL_EXISTING_ROWS  int,           -- number of rows in table "vv_mastervalues_upload" which already exist in target table "vv_mastervalues"
  UPL_INSERTED_ROWS  int,           -- number of rows which finally made it into the target table.
  UPL_DATA_ORIGIN    varchar(256),  -- Die Quelle, woher wir diesen wert haben (zweite Zeile unserer Quellangabe). Wenn von Webseite dann der TITLE, 'Download' bei Download mittels Loader, 'User Upload' bei Upload von User, 'manual' wenn manuelle Eingabe,...
  UPL_URLSOURCE      varchar(256),  -- URL-Link oder IP der Quelle (erste Zeile unserer Quellangabe), zB "http://www.deutsche-boerse-cash-market.com/dbcm-de/instrumente-statistiken/alle-handelbaren-instrumente/boersefrankfurt"
  UPL_SOURCEFILE     varchar(256),  -- Wenn der Wert aus einer Datei stammt, der tatsächliche Dateiname, zB "File 20170426_Frankfurt_Data.csv"
  UPL_COMMENT        varchar(256)   -- Optional für freie Kommentare, z.B. "manueller upload nach Formatänderung"
)
  

CREATE  CLUSTERED  INDEX vv_uploads_index1 ON dbo.vv_uploads(UPL_UPLOAD_ID) WITH  FILLFACTOR = 95
GO

CREATE  INDEX vv_uploads_index2 ON dbo.vv_uploads(UPL_SOURCE_ID, UPL_UPLOAD_ID) WITH  FILLFACTOR = 90
GO

CREATE  INDEX vv_uploads_index3 ON dbo.vv_uploads(UPL_TIMESTAMP) WITH  FILLFACTOR = 90
GO

-- GRANT SELECT, UPDATE ON [dbo].[fvs_analyse_ergebnis]  TO [Verwalten]
---------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------
/*   sp_spaceused vv_uploads

select top 99 * from vv_uploads order by UPL_UPLOAD_ID desc

-------------------------------------------------------------------------------
-- Daten zwischenspeichern und Tabelle nach Änderung vom 30.7.2017 neu anlegen:
select * into vv_uploads_bak20170730 from vv_uploads
insert vv_uploads
  select UPL_UPLOAD_ID, UPL_SOURCE_ID, UPL_USER_ID, UPL_HOST_NAME, UPL_TIMESTAMP, UPL_RECEIVED_ROWS, UPL_IDENTICAL_ROWS, UPL_EXISTING_ROWS, UPL_INSERTED_ROWS, UPL_DATA_ORIGIN, UPL_URLSOURCE, null, UPL_COMMENT  
  from vv_uploads_bak20170730 

update vv_uploads set upl_sourcefile=upl_data_origin where upl_data_origin like '%.csv' or upl_data_origin like '%.txt' 
update vv_uploads set upl_data_origin=null where upl_sourcefile is not null --where upl_data_origin like '%.csv' or upl_data_origin like '%.txt' 
  
-------------------------------------------------------------------------------
-- initiale Befüllung am 8.6.2017:
insert vv_uploads
  select   MV_UPLOAD_ID,  MV_SOURCE_ID,  null,  host_name(),  max(MV_TIMESTAMP),  null,  null,  null,  count(mv_isin) as inserted_rows,  MV_DATA_ORIGIN,  MV_URLSOURCE,  MV_COMMENT  
    from vv_mastervalues   
   group by  MV_SOURCE_ID, MV_UPLOAD_ID,   DATEADD(DAY, DATEDIFF(DAY, 0, MV_TIMESTAMP) , 0) ,  MV_DATA_ORIGIN,  MV_URLSOURCE,  MV_COMMENT

*/
