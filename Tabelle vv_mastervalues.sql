-- 26.04.2017 KB: Tabelle dbo.vv_mastervalues erstellt und Testdaten ausgedacht
-- 27.04.2017 KB: MV_SOURCE_ID eingefügt und statt MV_SOURCE jetzt MV_DATA_ORIGIN. MV_FIELDNAME verlängert.
-- 07.05.2017 KB: Added field MV_UPLOAD_ID to identify each upload-batch 
-- 08.06.2017 KB; Added field MV_LAST_SEEN, removed MV_DATA_ORIGIN and MV_URLSOURCE (now in vv_uploads table)
-- 03.08.2017 KB: MV_ID_NUM hinzugefügt und Index-struktur angepasst. Im Kommentar sind Hilfen zur Datenerhaltung

Use MasterData
go

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[vv_mastervalues]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
-- hier auskommentiert, ist sonst gefährlich
-- drop table [dbo].vv_mastervalues
GO

CREATE TABLE dbo.vv_mastervalues 
(
  MV_ID_NUM       int identity constraint vv_mastervalues_index1 primary key,  -- identity fängt bei 1 an und erhöht um 1, primary key = unique und not null
  MV_SOURCE_ID    char(8),            -- z.B. DBAG für "Deutsche Böse AG", definiert u.a. welche Felder kommen. Könnte zukünftig auch "USER" für Benutzeränderungen nach WIKI-Methodik enthalten.
  MV_UPLOAD_ID    int,                -- a counter which increases by one for each upload-batch
  MV_ISIN         char(12) NOT NULL,  -- ISIN des Wertpapiers, zB DE0007100000
  MV_MIC          char(4),            -- Market Identifier Code, Kennung der Börse, 4stellig nach ISO10383. Kann Schlüssel sein (zB bei Kursen), wenn unnötig, dann NULL (zB bei WP-Name)
  MV_AS_OF_DATE   date,               -- wird auf ein Datum gesetzt, wenn der Wert sich auf ein bestimtes Datum bezieht (z.b bei Kursen oder Handelsvolumen). sonst NULL.
  MV_FIELDNAME    char(48) NOT NULL,  -- Name des Stammdatenfelds, z.B. "123XYZ_LONGNAME" (oder zB 'Closing Price Previous Business Day' bei DBAG)
  MV_TIMESTAMP    datetime NOT NULL CONSTRAINT mv_timestamp_GETDATE DEFAULT GETDATE() ,   -- Datum, wann dieses Feld geschrieben wurde (es gibt hier nie updates, max timestamp= aktuell)
  MV_LAST_SEEN    datetime,           -- Der Zeitpunkt, wann dieser Wert das letzte mal so von der Quelle geliefert wurde  
  MV_STRINGVALUE  varchar(256),       -- Der Wert des Felds, zB "DAIMLER AG NAMENS-AKTIEN O.N."
  MV_COMMENT      varchar(256)        -- Optional für freie Kommentare, z.B. "manuelle Korrektur" 
)
  

CREATE  INDEX vv_mastervalues_index2 ON dbo.vv_mastervalues(mv_timestamp, MV_ISIN, MV_FIELDNAME) WITH  FILLFACTOR = 95 -- clustered nach Timestamp, d.h. wächst i.d.R. nur am Ende weiter
GO

CREATE  INDEX vv_mastervalues_index3 ON dbo.vv_mastervalues(MV_ISIN, MV_MIC, MV_FIELDNAME, MV_AS_OF_DATE) WITH  FILLFACTOR = 90 -- für Kurssuche
GO

--CREATE  INDEX vv_mastervalues_index3 ON dbo.vv_mastervalues(MV_ISIN, MV_FIELDNAME) WITH  FILLFACTOR = 90  -- für Suche nach anderen Feldern
--GO

-- GRANT SELECT, UPDATE ON [dbo].[fvs_analyse_ergebnis]  TO [Verwalten]
---------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------
/*   sp_spaceused vv_mastervalues

select top 99 * from vv_mastervalues order by MV_ID_NUM desc

------- Daten erhalten, wenn Tabelle neu CREATED wird: ---------
select * into vv_mastervalues_bak20170803 from vv_mastervalues

-- und zurückholen:
insert vv_mastervalues 
  select MV_SOURCE_ID, MV_UPLOAD_ID, MV_ISIN, MV_MIC,   MV_AS_OF_DATE ,  MV_FIELDNAME  ,  MV_TIMESTAMP  ,MV_LAST_SEEN,  MV_STRINGVALUE, MV_COMMENT  
from vv_mastervalues_bak20170803 
order by MV_TIMESTAMP

----------------------------------------------------------------
select count(*) from vv_mastervalues
select count(*) from vv_mastervalues_bak20170608 
select top 9 * from vv_mastervalues_bak20170608 

-- Insert ohne Datumsangabe (nutzt getdate als default), ohne MIC (Börsenunabhängig) und ohne AS_OF_DATE (nicht Stichtagsbezogen):
Insert vv_mastervalues ( MV_ISIN, MV_FIELDNAME, MV_STRINGVALUE, MV_SOURCE, MV_URLSOURCE, MV_COMMENT )
  values ('DE0007100000', 'A1-FULLNAME', 'DAIMLER AG NAMENS-AKTIEN O.N.', 'manuell', '','von Kay')

--mit TIMESTAMP explizit gesetzt, ohne MIC (Börsenunabhängig) und ohne AS_OF_DATE (nicht Stichtagsbezogen):
Insert vv_mastervalues ( MV_ISIN, MV_FIELDNAME, MV_TIMESTAMP, MV_STRINGVALUE, MV_SOURCE, MV_URLSOURCE, MV_COMMENT )
  values ('DE0007100000', 'A1-FULLNAME', '1.1.1971', 'DAIMLER MOTORENWERKE AG', 'manuell', '','von Kay')

--die Währung ist Börsenabhängig (MIC), aber kein Datumsbezug (AS_OF_DATE) und TIMESTAP sparen wir uns auch:
Insert vv_mastervalues ( MV_ISIN, MV_MIC, MV_FIELDNAME, MV_STRINGVALUE, MV_SOURCE, MV_URLSOURCE, MV_COMMENT )
  values ('DE0007100000', 'XETR', 'A2-CURRENCY', 'EUR', 'manuell', '','von Kay')
  
--Kursdaten mit Datumsbezug (AS_OF_DATE) und Börsenbezug (MIC):
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
vorher auf ACER:
name              rows                 reserved           data               index_size         unused
----------------- -------------------- ------------------ ------------------ ------------------ ------------------
vv_mastervalues   2198851              1191448 KB         634480 KB          556752 KB          216 KB

name              rows                 reserved           data               index_size         unused
----------------- -------------------- ------------------ ------------------ ------------------ ------------------
vv_mastervalues   2198851              650776 KB          298296 KB          352328 KB          152 KB


*/
