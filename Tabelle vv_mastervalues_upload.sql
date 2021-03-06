-- 26.04.2017 KB: Tabelle dbo.vv_mastervalues erstellt und Testdaten ausgedacht
-- 27.04.2017 KB: MV_SOURCE_ID eingef�gt und statt MV_SOURCE jetzt MV_DATA_ORIGIN. MV_FIELDNAME verl�ngert.
-- 05.05.2017 KB: Bugfix bei Index und constraint
-- 31.07.2017 AG: Hinzunahme der Spalte MVU_SOURCEFILE

Use MasterData
go

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[vv_mastervalues_upload]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].vv_mastervalues_upload
GO

CREATE TABLE dbo.vv_mastervalues_upload
(
  MVU_SOURCE_ID   char(8),            -- z.B. DBAG f�r "Deutsche B�se AG", definiert u.a. welche Felder kommen. K�nnte zuk�nftig auch "USER" f�r Benutzer�nderungen nach WIKI-Methodik enthalten.
  MVU_ISIN        char(12) NOT NULL,  -- ISIN des Wertpapiers, zB DE0007100000
  MVU_MIC         char(4),            -- Market Identifier Code, Kennung der B�rse, 4stellig nach ISO10383. Kann Schl�ssel sein (zB bei Kursen), wenn unn�tig, dann NULL (zB bei WP-Name)
  MVU_AS_OF_DATE  date,               -- wird auf ein Datum gesetzt, wenn der Wert sich auf ein bestimtes Datum bezieht (z.b bei Kursen oder Handelsvolumen). sonst NULL.
  MVU_FIELDNAME   char(48) NOT NULL,  -- Name des Stammdatenfelds, z.B. "123XYZ_LONGNAME" (oder zB 'Closing Price Previous Business Day' bei DBAG)
  MVU_TIMESTAMP   datetime NOT NULL CONSTRAINT mvu_timestamp_GETDATE DEFAULT GETDATE() ,   -- Datum, wann dieses Feld geschrieben wurde (es gibt hier nie updates, max timestamp= aktuell)
  MVU_STRINGVALUE varchar(256),       -- Der Wert des Felds, zB "DAIMLER AG NAMENS-AKTIEN O.N."
  MVU_DATA_ORIGIN varchar(256),       -- Die Quelle, woher wir diesen wert haben, zB "File 20170426_Frankfurt_Data.csv"
  MVU_URLSOURCE   varchar(256),       -- Wenn relevant, der URL-Link der Quelle, zB "http://www.deutsche-boerse-cash-market.com/dbcm-de/instrumente-statistiken/alle-handelbaren-instrumente/boersefrankfurt"
  MVU_SOURCEFILE  varchar(256),       -- Name der Datei, aus der die Daten Stammen (falls �ber Datei-Upload geschehen)
  MVU_COMMENT     varchar(256)        -- Optional f�r freie Kommentare, z.B. "manueller upload nach Format�nderung"
)
  

CREATE  CLUSTERED  INDEX vv_mastervalues_upload_index1 ON dbo.vv_mastervalues_upload(MVU_TIMESTAMP, MVU_ISIN, MVU_FIELDNAME) WITH  FILLFACTOR = 95
GO

CREATE  INDEX vv_mastervalues_upload_index2 ON dbo.vv_mastervalues_upload(MVU_ISIN, MVU_MIC, MVU_AS_OF_DATE, MVU_FIELDNAME, MVU_TIMESTAMP) WITH  FILLFACTOR = 90
GO

-- GRANT SELECT, UPDATE ON [dbo].[fvs_analyse_ergebnis]  TO [Verwalten]
---------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------
/*   sp_spaceused vv_mastervalues_upload

select top 99 * from vv_mastervalues_upload 


-- Insert ohne Datumsangabe (nutzt getdate als default), ohne MIC (B�rsenunabh�ngig) und ohne AS_OF_DATE (nicht Stichtagsbezogen):
Insert vv_mastervalues ( MV_ISIN, MV_FIELDNAME, MV_STRINGVALUE, MV_SOURCE, MV_URLSOURCE, MV_COMMENT )
  values ('DE0007100000', 'A1-FULLNAME', 'DAIMLER AG NAMENS-AKTIEN O.N.', 'manuell', '','von Kay')

--mit TIMESTAMP explizit gesetzt, ohne MIC (B�rsenunabh�ngig) und ohne AS_OF_DATE (nicht Stichtagsbezogen):
Insert vv_mastervalues ( MV_ISIN, MV_FIELDNAME, MV_TIMESTAMP, MV_STRINGVALUE, MV_SOURCE, MV_URLSOURCE, MV_COMMENT )
  values ('DE0007100000', 'A1-FULLNAME', '1.1.1971', 'DAIMLER MOTORENWERKE AG', 'manuell', '','von Kay')

--die W�hrung ist B�rsenabh�ngig (MIC), aber kein Datumsbezug (AS_OF_DATE) und TIMESTAP sparen wir uns auch:
Insert vv_mastervalues ( MV_ISIN, MV_MIC, MV_FIELDNAME, MV_STRINGVALUE, MV_SOURCE, MV_URLSOURCE, MV_COMMENT )
  values ('DE0007100000', 'XETR', 'A2-CURRENCY', 'EUR', 'manuell', '','von Kay')
  
--Kursdaten mit Datumsbezug (AS_OF_DATE) und B�rsenbezug (MIC):
Insert vv_mastervalues 
  (MV_ISIN, MV_MIC, MV_AS_OF_DATE, MV_FIELDNAME, MV_STRINGVALUE, MV_SOURCE, MV_URLSOURCE, MV_COMMENT )
values 
  ('DE0007100000', 'XETR', '20170425', 'A3-PRICE', '68,7', 'manuell','','von Kay'),
  ('DE0007100000', 'XETR', '20170424', 'A3-PRICE', '67,78', 'manuell','','von Kay'),
  ('DE0007100000', 'XETR', '20170421', 'A3-PRICE', '66,17', 'manuell','','von Kay'),
  ('DE0007100000', 'XETR', '20170420', 'A3-PRICE', '66,29', 'manuell','','von Kay'),
  ('DE0007100000', 'XETR', '20170419', 'A3-PRICE', '65,88', 'manuell','','von Kay'),
  ('DE0007100000', 'XETR', '20170418', 'A3-PRICE', '65,55', 'manuell','','von Kay'),
  ('DE0007100000', 'XETR', '20170413', 'A3-PRICE', '66,42', 'manuell','','von Kay'),
  ('DE0007100000', 'XETR', '20170412', 'A3-PRICE', '66,82', 'manuell','','von Kay'),
  ('DE0007100000', 'XETR', '20170411', 'A3-PRICE', '66,64', 'manuell','','von Kay'),
  ('DE0007100000', 'XETR', '20170410', 'A3-PRICE', '66,93', 'manuell','','von Kay'),
  ('DE0007100000', 'XETR', '20170407', 'A3-PRICE', '67', 'manuell','','von Kay'),
  ('DE0007100000', 'XETR', '20170406', 'A3-PRICE', '67,12', 'manuell','','von Kay'),
  ('DE0007100000', 'XETR', '20170405', 'A3-PRICE', '67,06', 'manuell','','von Kay'),
  ('DE0007100000', 'XETR', '20170404', 'A3-PRICE', '67,74', 'manuell','','von Kay'),
  ('DE0007100000', 'XETR', '20170403', 'A3-PRICE', '68,45', 'manuell','','von Kay'),
  ('DE0007100000', 'XETR', '20170331', 'A3-PRICE', '69,2', 'manuell','','von Kay'),
  ('DE0007100000', 'XETR', '20170330', 'A3-PRICE', '69,33', 'manuell','','von Kay'),
  ('DE0007100000', 'XETR', '20170329', 'A3-PRICE', '72,36', 'manuell','','von Kay'),
  ('DE0007100000', 'XETR', '20170328', 'A3-PRICE', '71,63', 'manuell','','von Kay'),
  ('DE0007100000', 'XETR', '20170327', 'A3-PRICE', '70,48', 'manuell','','von Kay')

*/
