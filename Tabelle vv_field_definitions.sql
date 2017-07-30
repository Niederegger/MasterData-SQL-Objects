-- 30.07.2017 KB: Neue Tabelle vv_field_definitions angelegt, um Quellen für die Anzeige auf Feldebene definieren zu können

Use MasterData
go


CREATE TABLE dbo.vv_field_definitions
(
  FD_USER          nvarchar(32),       -- Der user, der diese Defintion benutzt (NULL = system default)
  FD_SEQUENCE_NUM  int,                -- Legt die Reihenfolge der Felder in der Anzeige fest, kleinste zuerst (Kann 1,2,3 oder 10, 20, 30,sein) 
  FD_FIELDNAME     char(48) NOT NULL,  -- field as in VV_MASTERVALUES.MV_FIELDNAME
  FD_ALLOW_DELETE  tinyint,            -- Dürfen User dieses Feld in der Ansicht entfernen? (Boolean gibts nicht und tinyint ist einfacher zu mappen)
  FD_ALLOW_DEFINE  tinyint,            -- Dürfen User dieses Definition dieses Feldes bearbeiten?
  FD_HANDLING      char(8),            -- derzeit AKT, UNIQ, FIRST, ALL
  FD_SOURCE_NUM    int,                -- die reihenfolge der Quellen für dieses Feld
  FD_SOURCE_ID     char(8),            -- analog zu MV_SOURCE_ID, z.B. DBAG für "Deutsche Böse AG"
  FD_SOURCE_FIELD  char(48),           -- ursprünglicher Feldname in der Quelle 
)
  

CREATE  CLUSTERED  INDEX vv_field_definitions_index1 ON dbo.vv_field_definitions(FD_FIELDNAME, FD_USER) WITH  FILLFACTOR = 95
GO

-- GRANT SELECT, UPDATE ON [dbo].[fvs_analyse_ergebnis]  TO [Verwalten]
---------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------
/*   sp_spaceused vv_field_definitions     drop table vv_field_definitions

select top 99 * from vv_field_definitions order by FD_USER, FD_Sequence_num

-- initiale Befüllung am 30.07.2017:
insert vv_field_definitions values (null, 10, 'ISIN', 0, 0, 'UNIQ', 1, 'DBAG', 'ISIN')
insert vv_field_definitions values (null, 10, 'ISIN', 0, 0, 'UNIQ', 2, 'ESMFDSHA', 'ISIN')
insert vv_field_definitions values (null, 10, 'ISIN', 0, 0, 'UNIQ', 3, 'User', 'ISIN')
insert vv_field_definitions values (null, 10, 'ISIN', 0, 0, 'UNIQ', 4, 'AnonUser', 'ISIN')
insert vv_field_definitions values (null, 10, 'ISIN', 0, 0, 'UNIQ', 5, 'ESMFDSHA', 'ISIN')

insert vv_field_definitions values (null, 20, 'WKN', 1, 1, 'UNIQ', 1, 'DBAG', 'WKN')
insert vv_field_definitions values (null, 20, 'WKN', 1, 1, 'UNIQ', 2, 'Web', 'WKN')
insert vv_field_definitions values (null, 20, 'WKN', 1, 1, 'UNIQ', 3, 'User', 'WKN')
insert vv_field_definitions values (null, 20, 'WKN', 1, 1, 'UNIQ', 4, 'AnonUser', 'WKN')

insert vv_field_definitions values (null, 30, 'Name', 0, 1, 'UNIQ', 1, 'DBAG', 'Instrument')
insert vv_field_definitions values (null, 30, 'Name', 0, 1, 'UNIQ', 2, 'ESMFDSHA', 'sha_name')
insert vv_field_definitions values (null, 30, 'Name', 0, 1, 'UNIQ', 3, 'Web', 'Name')
insert vv_field_definitions values (null, 30, 'Name', 0, 1, 'UNIQ', 4, 'User', 'Name')
insert vv_field_definitions values (null, 30, 'Name', 0, 1, 'UNIQ', 5, 'AnonUser', 'Name')

insert vv_field_definitions values (null, 40, 'Kurzname', 1, 1, 'UNIQ', 1, 'DBAG', 'Mnemonic')
insert vv_field_definitions values (null, 40, 'Kurzname', 0, 1, 'UNIQ', 2, 'ESMFDSHA', 'sha_name')
insert vv_field_definitions values (null, 40, 'Kurzname', 1, 1, 'UNIQ', 2, 'Web', 'Kurzname')
insert vv_field_definitions values (null, 40, 'Kurzname', 1, 1, 'UNIQ', 3, 'User', 'Kurzname')
insert vv_field_definitions values (null, 40, 'Kurzname', 1, 1, 'UNIQ', 4, 'AnonUser', 'Kurzname')

insert vv_field_definitions values (null, 50, 'Instrumententyp(CFI)', 1, 1, 'UNIQ', 1, 'Web', 'Instrumententyp(CFI)')
insert vv_field_definitions values (null, 50, 'Instrumententyp(CFI)', 1, 1, 'UNIQ', 2, 'User', 'Instrumententyp(CFI)')
insert vv_field_definitions values (null, 50, 'Instrumententyp(CFI)', 1, 1, 'UNIQ', 3, 'AnonUser', 'Instrumententyp(CFI)')

insert vv_field_definitions values (null, 60, 'Währung', 1, 1, 'UNIQ', 1, 'DBAG', 'Settlement Currency')
insert vv_field_definitions values (null, 60, 'Währung', 1, 1, 'UNIQ', 2, 'Web', 'Währung')
insert vv_field_definitions values (null, 60, 'Währung', 1, 1, 'UNIQ', 3, 'User', 'Währung')
insert vv_field_definitions values (null, 60, 'Währung', 1, 1, 'UNIQ', 4, 'AnonUser', 'Währung')

insert vv_field_definitions values (null, 70, 'Emittent LEI', 1, 1, 'UNIQ', 2, 'Web', 'Emittent LEI')
insert vv_field_definitions values (null, 70, 'Emittent LEI', 1, 1, 'UNIQ', 3, 'User', 'Emittent LEI')
insert vv_field_definitions values (null, 70, 'Emittent LEI', 1, 1, 'UNIQ', 4, 'AnonUser', 'Emittent LEI')

insert vv_field_definitions values (null, 80, 'Emittent Web', 1, 1, 'UNIQ', 1, 'Web', 'Emittent Web')
insert vv_field_definitions values (null, 80, 'Emittent Web', 1, 1, 'UNIQ', 2, 'User', 'Emittent Web')
insert vv_field_definitions values (null, 80, 'Emittent Web', 1, 1, 'UNIQ', 3, 'AnonUser', 'Emittent Web')

insert vv_field_definitions values (null, 90, 'Instrument BIB', 1, 1, 'UNIQ', 1, 'Web', 'Instrument BIB')
insert vv_field_definitions values (null, 90, 'Instrument BIB', 1, 1, 'UNIQ', 2, 'User', 'Instrument BIB')
insert vv_field_definitions values (null, 90, 'Instrument BIB', 1, 1, 'UNIQ', 3, 'AnonUser', 'Instrument BIB')

insert vv_field_definitions values (null, 100, 'Handelsplätze', 1, 1, 'UNIQ', 1, 'DBAG', '(automatic)')
insert vv_field_definitions values (null, 100, 'Handelsplätze', 1, 1, 'UNIQ', 2, 'Web', 'Handelsplätze')
insert vv_field_definitions values (null, 100, 'Handelsplätze', 1, 1, 'UNIQ', 3, 'User', 'Handelsplätze')
insert vv_field_definitions values (null, 100, 'Handelsplätze', 1, 1, 'UNIQ', 4, 'AnonUser', 'Handelsplätze')

insert vv_field_definitions values (null, 110, 'Zielmarkt.Kundenkategorie', 1, 1, 'UNIQ', 1, 'Web', 'Zielmarkt.Kundenkategorie')
insert vv_field_definitions values (null, 110, 'Zielmarkt.Kundenkategorie', 1, 1, 'UNIQ', 2, 'User', 'Zielmarkt.Kundenkategorie')
insert vv_field_definitions values (null, 110, 'Zielmarkt.Kundenkategorie', 1, 1, 'UNIQ', 3, 'AnonUser', 'Zielmarkt.Kundenkategorie')

insert vv_field_definitions values (null, 120, 'Zielmarkt.Kenntnisse & Erfahrungen', 1, 1, 'UNIQ', 1, 'Web', 'Zielmarkt.Kenntnisse & Erfahrungen')
insert vv_field_definitions values (null, 120, 'Zielmarkt.Kenntnisse & Erfahrungen', 1, 1, 'UNIQ', 2, 'User', 'Zielmarkt.Kenntnisse & Erfahrungen')
insert vv_field_definitions values (null, 120, 'Zielmarkt.Kenntnisse & Erfahrungen', 1, 1, 'UNIQ', 3, 'AnonUser', 'Zielmarkt.Kenntnisse & Erfahrungen')

insert vv_field_definitions values (null, 130, 'Zielmarkt.Verlusttragfähigkeit', 1, 1, 'UNIQ', 1, 'Web', 'Zielmarkt.Verlusttragfähigkeit')
insert vv_field_definitions values (null, 130, 'Zielmarkt.Verlusttragfähigkeit', 1, 1, 'UNIQ', 2, 'User', 'Zielmarkt.Verlusttragfähigkeit')
insert vv_field_definitions values (null, 130, 'Zielmarkt.Verlusttragfähigkeit', 1, 1, 'UNIQ', 3, 'AnonUser', 'Zielmarkt.Verlusttragfähigkeit')

insert vv_field_definitions values (null, 140, 'Zielmarkt.Risiko-/Renditeprofil', 1, 1, 'UNIQ', 1, 'Web', 'Zielmarkt.Risiko-/Renditeprofil')
insert vv_field_definitions values (null, 140, 'Zielmarkt.Risiko-/Renditeprofil', 1, 1, 'UNIQ', 2, 'User', 'Zielmarkt.Risiko-/Renditeprofil')
insert vv_field_definitions values (null, 140, 'Zielmarkt.Risiko-/Renditeprofil', 1, 1, 'UNIQ', 3, 'AnonUser', 'Zielmarkt.Risiko-/Renditeprofil')

insert vv_field_definitions values (null, 150, 'Zielmarkt.Anlageziele', 1, 1, 'UNIQ', 1, 'Web', 'Zielmarkt.Anlageziele')
insert vv_field_definitions values (null, 150, 'Zielmarkt.Anlageziele', 1, 1, 'UNIQ', 2, 'User', 'Zielmarkt.Anlageziele')
insert vv_field_definitions values (null, 150, 'Zielmarkt.Anlageziele', 1, 1, 'UNIQ', 3, 'AnonUser', 'Zielmarkt.Anlageziele')

insert vv_field_definitions values (null, 160, 'Zielmarkt.Anlagehorizont', 1, 1, 'UNIQ', 1, 'Web', 'Zielmarkt.Anlagehorizont')
insert vv_field_definitions values (null, 160, 'Zielmarkt.Anlagehorizont', 1, 1, 'UNIQ', 2, 'User', 'Zielmarkt.Anlagehorizont')
insert vv_field_definitions values (null, 160, 'Zielmarkt.Anlagehorizont', 1, 1, 'UNIQ', 3, 'AnonUser', 'Zielmarkt.Anlagehorizont')

insert vv_field_definitions values (null, 170, 'Zielmarkt.Spezielle Anforderungen', 1, 1, 'UNIQ', 1, 'Web', 'Zielmarkt.Spezielle Anforderungen')
insert vv_field_definitions values (null, 170, 'Zielmarkt.Spezielle Anforderungen', 1, 1, 'UNIQ', 2, 'User', 'Zielmarkt.Spezielle Anforderungen')
insert vv_field_definitions values (null, 170, 'Zielmarkt.Spezielle Anforderungen', 1, 1, 'UNIQ', 3, 'AnonUser', 'Zielmarkt.Spezielle Anforderungen')




*/
