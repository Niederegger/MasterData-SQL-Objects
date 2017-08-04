use MasterData
go

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[vvsp_get_maininfoV2]') )
  drop procedure dbo.vvsp_get_maininfoV2
go

-- 30.06.17 KB: Ersten Entwurf der Prozedur erstellt.
-- 30.06.17 AG: Anpassung an MIC select, sodass leere MICS ignoriert werden
-- 30.07.17 KB: Dynamik über Tabelle vv_field_definitions eingebaut. 
--              Neue Felder in Return-Set: SEQUENCE_NUM, DATA_ORIGIN, URLSOURCE, SOURCE_NUM
-- 03.08.17 KB: Source ID und Timestamp im Result zurückliefern
-- 04.08.17 KB: Sortierung bei Rückgabe eingebaut
create procedure dbo.vvsp_get_maininfoV2
  @ISIN char(12)
as
  declare @SEQUENCE_NUM int       -- wie vv_field_definitions.FD_SEQUENCE_NUM:Legt die Reihenfolge der Felder in der Anzeige fest, kleinste zuerst (Kann 1,2,3 oder 10, 20, 30,sein)
  declare @FIELDNAME    char(48)  -- wie vv_field_definitions.FD_FIELDNAME: field as in VV_MASTERVALUES.MV_FIELDNAME
  declare @HANDLING     char(8)   -- wie vv_field_definitions.FD_HANDLING: derzeit AKT, UNIQ, FIRST, ALL

  Set NOCOUNT ON

  if @ISIN is null return         -- hier sollte noch eine vernünftige Rückmeldung zur Darstellung af der webseite kommen, aber in welchem Format? 
  if @ISIN = '' return

  -- Prüfung auf WKN und ggf Übersetzung in ISIN 
  if len(@ISIN) = 6                                      -- haben wir vielleicht eine WKN statt einer ISIN bekommen?
  begin
    select top 1 @ISIN=mv_isin 
      from vv_mastervalues
     where MV_SOURCE_ID='DBAG'                           -- mal bei Deutscher Börse nachsehen...
       and MV_FIELDNAME='WKN'                            -- ...ob diese WKN bekannt ist
       and MV_STRINGVALUE=@ISIN
     order by coalesce(MV_LAST_SEEN, MV_TIMESTAMP) desc  -- die jüngste nehmen (LAST_SEEN kann NULL sein, TIMESTAMP immer da aber ggf älter als wirklich "zuletzt gesehen")
  end     
  
  if @ISIN is null return         -- hier sollte noch eine vernünftige Rückmeldung zur Darstellung af der webseite kommen, aber in welchem Format? 
  if len(@ISIN) != 12 return      -- hier sollte noch eine vernünftige Rückmeldung zur Darstellung af der webseite kommen, aber in welchem Format? 



create table #felder
(
  SEQUENCE_NUM int,       -- wie vv_field_definitions.FD_SEQUENCE_NUM
  FIELDNAME    char(48),  -- wie vv_field_definitions.FD_FIELDNAME, hier kommt der Feldname rein     
  HANDLING     char(8)    -- wie vv_field_definitions.FD_HANDLING   
)  

create table #result
(
  SOURCE_ID    char(8),       -- aus VV_FIELD_DEFINITIONS, z.B. "DBAG" für Dt.Börse (identisch mit Feld in mastervalues)
  SEQUENCE_NUM int,           -- aus VV_FIELD_DEFINITIONS die Reihenfolge in der Ansicht
  FIELDNAME    char(48),      -- aus VV_FIELD_DEFINITIONS der von uns vergebene Feldname (ggf. Level1.Level2 mit Punkt)
  SOURCE_NUM   int,           -- aus VV_FIELD_DEFINITIONS der Zähler der Quellen innerhalb eines Feldes
  STRINGVALUE  varchar(256),  -- aus VV_MASTERVALUES der Inhalt des Feldes
  RECORD_DATE  datetime,      -- aus VV_MASTERVALUES entweder (wenn vorhanden) Wert aus MV_LAST_SEEN, sonst aus MV_TIMESTAMP
  DATA_ORIGIN  varchar(256),  -- aus VV_UPLOADS die Quelle, woher wir diesen Wert haben (zweite Zeile unserer Quellangabe). Wenn von Webseite dann der TITLE, 'Download' bei Download mittels Loader, 'User Upload' bei Upload von User, 'manual' wenn manuelle Eingabe,...
  URLSOURCE    varchar(256),  -- aus VV_UPLOADS der URL-Link oder die IP der Quelle (erste Zeile unserer Quellangabe), zB "http://www.deutsche-boerse-cash-market.com/dbcm-de/instrumente-statistiken/alle-handelbaren-instrumente/boersefrankfurt"
)  


-- alle anzuzeigenden Felder aus der Definitionstabelle holen (mit Sortiernummer und Handhabungshinweis)

insert #felder
select min(FD_SEQUENCE_NUM), FD_FIELDNAME, min(FD_HANDLING)  -- SEQUENCE_NUM und HANDLINNG olle eindeutig pro Feld sein
  from vv_field_definitions
 where FD_USER is null    -- momentan gibt es nur System-Einstellungen, userabhängige kommen später (dafür ist neuer Parameter nötig)
 group by FD_FIELDNAME

-- jetzt alle Felder nacheinander abarbeiten
while (select count(*) from #felder) > 0
begin
  select top 1 @SEQUENCE_NUM = SEQUENCE_NUM, @FIELDNAME = FIELDNAME, @HANDLING = HANDLING   
    from #felder
   order by SEQUENCE_NUM
  
  delete #felder where @FIELDNAME = FIELDNAME   -- was jetzt bearbeitet wird, kann hier schonmal raus
  
  if @FIELDNAME= 'ISIN'    -- Sonderbehandlung ISIN-Feld. Inhalt ist ja klar, aber Quellen und Datum wollen wir zeigen
  begin
    if @HANDLING ='AKT'    -- aktuellste Quelle zuerst
      insert #result 
      select top 1 
             FD_SOURCE_ID, 
             FD_SEQUENCE_NUM, 
             FD_FIELDNAME,     -- hier konstant "ISIN"
             FD_SOURCE_NUM, 
             @ISIN,            -- an diese Stelle eben NICHT ein Inhalt aus der vv_masteralues-Tabelle
             coalesce(MV_LAST_SEEN, MV_TIMESTAMP),
             UPL_DATA_ORIGIN, 
             UPL_URLSOURCE
        from VV_MASTERVALUES
       inner join VV_FIELD_DEFINITIONS           -- Felddefinition nachschlagen, wo...
          on FD_SEQUENCE_NUM = @SEQUENCE_NUM     -- ...Sequenznummer die gerade bearbeitete ist 
         and FD_FIELDNAME    = @FIELDNAME        -- ...Feldname der gerade bearbeitete ist 
         and FD_SOURCE_ID    = MV_SOURCE_ID      -- ...die Source soll in mastervalues nachgesehen werden
       inner join VV_UPLOADS                     -- in den uploads stehen die SOURCE-Felder ...
          on UPL_UPLOAD_ID = MV_UPLOAD_ID        -- also für den komkreten Upload nacschlagen, woher er kam
       where MV_ISIN = @ISIN
       order by coalesce(MV_LAST_SEEN, MV_TIMESTAMP) desc        -- größter Wert (also der aktuellste) zuerst
  
     if @HANDLING ='FIRST'  -- die erste Quelle aus meinen gewünschten Quelldefintionen nehmen, dei einen Wert hat
        or @HANDLING ='UNIQ'  -- aus allen Quellen nur die unterschiedlichen Werte anzeigen (bei ISIN identisch)
      insert #result 
      select top 1 
             FD_SOURCE_ID, 
             FD_SEQUENCE_NUM, 
             FD_FIELDNAME,       -- hier konstant "ISIN"
             FD_SOURCE_NUM, 
             @ISIN,              -- an diese Stelle eben NICHT ein Inhalt aus der vv_masteralues-Tabelle
             coalesce(MV_LAST_SEEN, MV_TIMESTAMP),
             UPL_DATA_ORIGIN, 
             UPL_URLSOURCE
        from VV_MASTERVALUES
       inner join VV_FIELD_DEFINITIONS           -- Felddefinition nachschlagen, wo...
          on FD_SEQUENCE_NUM = @SEQUENCE_NUM     -- ...Sequenznummer die gerade bearbeitete ist 
         and FD_FIELDNAME    = @FIELDNAME        -- ...Feldname der gerade bearbeitete ist 
         and FD_SOURCE_ID    = MV_SOURCE_ID      -- ...die Source soll in mastervalues nachgesehen werden
       inner join VV_UPLOADS                     -- in den uploads stehen die SOURCE-Felder ...
          on UPL_UPLOAD_ID = MV_UPLOAD_ID        -- also für den komkreten Upload nacschlagen, woher er kam
       where MV_ISIN = @ISIN
       order by FD_SOURCE_NUM                    -- sortiert wie in Definition gegeben

     if @HANDLING ='ALL'  -- alle Quellen angeben (auch wenn alle gleich sind)
      insert #result 
      select -- wegen ALL ohne TOP1-Einschränkung, dafür unten grouping 
             FD_SOURCE_ID, 
             FD_SEQUENCE_NUM, 
             FD_FIELDNAME,     -- hier konstant "ISIN"
             FD_SOURCE_NUM, 
             @ISIN,            -- an diese Stelle eben NICHT ein Inhalt aus der vv_masteralues-Tabelle
             max(coalesce(MV_LAST_SEEN, MV_TIMESTAMP)),
             UPL_DATA_ORIGIN, 
             UPL_URLSOURCE
        from VV_MASTERVALUES
       inner join VV_FIELD_DEFINITIONS           -- Felddefinition nachschlagen, wo...
          on FD_SEQUENCE_NUM = @SEQUENCE_NUM     -- ...Sequenznummer die gerade bearbeitete ist 
         and FD_FIELDNAME = @FIELDNAME           -- ...Feldname der gerade bearbeitete ist 
         and FD_SOURCE_ID = MV_SOURCE_ID         -- ...die Source soll in mastervalues nachgesehen werden
       inner join VV_UPLOADS                     -- in den uploads stehen die SOURCE-Felder ...
          on UPL_UPLOAD_ID = MV_UPLOAD_ID        -- also für den komkreten Upload nacschlagen, woher er kam
       where MV_ISIN = @ISIN
       group by FD_SOURCE_ID, FD_SEQUENCE_NUM, FD_FIELDNAME, FD_SOURCE_NUM, UPL_DATA_ORIGIN, UPL_URLSOURCE
       order by FD_SOURCE_NUM                    -- sortiert wie in Definition gegeben
 
    continue -- zum WHILE-Kopf   
  end -- of ISIN
  
  if @FIELDNAME= 'Handelsplätze'  -- Sonderbehandlung Feld 'Handelsplätze'
  begin
   
   -- das hier ist noch SCHROTT und muss überdacht werden, insbesondere wenn künftig mehr Quellen hinzu kommen 
   insert #result 
   select distinct 
      'DBAG', 
      101, 
      'Handelsplätze',
       1, 
       MV_MIC+' ('+dbo.fn_vv_current_value('DBAG', @ISIN, MV_MIC, null, 'Market Segment')+')',    -- Marktsegment ist nur eine NOTLÖSUNG, nachsehen in Tabelle MIC wäre besser
       convert(datetime,'20170101'),
       'fehlt noch',
       'fehlt noch'
    from vv_mastervalues
   where MV_ISIN=@ISIN and not MV_MIC=''

   --  xxxxxxxxxxxxxxxxxxxx TODO xxxxxxxxxxxxxxxxxxxxxxxx

  end -- of Handelsplätze
  
  -- hier folgt jetzt der ALLGEMEINE FALL

    if @HANDLING ='AKT'  -- aktuellste Quelle zuerst
      insert #result 
      select top 1 
             FD_SOURCE_ID, 
             FD_SEQUENCE_NUM, 
             FD_FIELDNAME, 
             FD_SOURCE_NUM, 
             MV_STRINGVALUE, 
             coalesce(MV_LAST_SEEN, MV_TIMESTAMP),
             UPL_DATA_ORIGIN, 
             UPL_URLSOURCE
        from VV_MASTERVALUES
       inner join VV_FIELD_DEFINITIONS              -- Felddefinition nachschlagen, wo...
          on FD_SEQUENCE_NUM = @SEQUENCE_NUM        -- ...Sequenznummer die gerade bearbeitete ist 
         and FD_FIELDNAME    = @FIELDNAME           -- ...Feldname der gerade bearbeitete ist 
         and FD_SOURCE_ID    = MV_SOURCE_ID         -- ...die Source soll in mastervalues nachgesehen werden
         and FD_SOURCE_FIELD = MV_FIELDNAME         -- .. und das dort definierte Feld muss zu Mastervalues-Feld passen
       inner join VV_UPLOADS                        -- in den uploads stehen die SOURCE-Felder ...
          on UPL_UPLOAD_ID = MV_UPLOAD_ID           -- also für den komkreten Upload nacschlagen, woher er kam
       where MV_ISIN = @ISIN
       order by coalesce(MV_LAST_SEEN, MV_TIMESTAMP) desc    -- größter Wert (also der aktuellste) zuerst
  
    if @HANDLING ='FIRST'  -- die erste Quelle aus meinen gewünschten Quelldefintionen nehmen, dei einen Wert hat
      insert #result 
      select top 1
             FD_SOURCE_ID, 
             FD_SEQUENCE_NUM, 
             FD_FIELDNAME, 
             FD_SOURCE_NUM, 
             MV_STRINGVALUE, 
             coalesce(MV_LAST_SEEN, MV_TIMESTAMP),
             UPL_DATA_ORIGIN, 
             UPL_URLSOURCE
        from VV_MASTERVALUES
       inner join VV_FIELD_DEFINITIONS              -- Felddefinition nachschlagen, wo...
          on FD_SEQUENCE_NUM = @SEQUENCE_NUM        -- ...Sequenznummer die gerade bearbeitete ist 
         and FD_FIELDNAME    = @FIELDNAME           -- ...Feldname der gerade bearbeitete ist 
         and FD_SOURCE_ID    = MV_SOURCE_ID         -- ...die Source soll in mastervalues nachgesehen werden
         and FD_SOURCE_FIELD = MV_FIELDNAME         -- .. und das dort definierte Feld muss zu Mastervalues-Feld passen
       inner join VV_UPLOADS                        -- in den uploads stehen die SOURCE-Felder ...
          on UPL_UPLOAD_ID = MV_UPLOAD_ID           -- also für den komkreten Upload nacschlagen, woher er kam
       where MV_ISIN = @ISIN
       order by FD_SOURCE_NUM                       -- sortiert wie in Definition gegeben
 
    if @HANDLING ='ALL'  -- alle Quellen angeben (auch wenn alle gleich sind)
         or @HANDLING ='UNIQ'  -- bei UNIQ gehen wir zunächst vor wie bei ALL, aber löschen gleich was...
      insert #result
      select 
             FD_SOURCE_ID, 
             FD_SEQUENCE_NUM, 
             FD_FIELDNAME, 
             FD_SOURCE_NUM, 
             MV_STRINGVALUE, 
             max(coalesce(MV_LAST_SEEN, MV_TIMESTAMP)),
             UPL_DATA_ORIGIN, 
             UPL_URLSOURCE
        from VV_MASTERVALUES
       inner join VV_FIELD_DEFINITIONS              -- Felddefinition nachschlagen, wo...
          on FD_SEQUENCE_NUM = @SEQUENCE_NUM        -- ...Sequenznummer die gerade bearbeitete ist 
         and FD_FIELDNAME    = @FIELDNAME           -- ...Feldname der gerade bearbeitete ist 
         and FD_SOURCE_ID    = MV_SOURCE_ID         -- ...die Source soll in mastervalues nachgesehen werden
         and FD_SOURCE_FIELD = MV_FIELDNAME         -- .. und das dort definierte Feld muss zu Mastervalues-Feld passen
       inner join VV_UPLOADS                        -- in den uploads stehen die SOURCE-Felder ...
          on UPL_UPLOAD_ID = MV_UPLOAD_ID           -- also für den komkreten Upload nacschlagen, woher er kam
       where MV_ISIN = @ISIN
	   group by FD_SOURCE_ID, FD_SEQUENCE_NUM, FD_FIELDNAME, FD_SOURCE_NUM, MV_STRINGVALUE, UPL_DATA_ORIGIN, UPL_URLSOURCE
       order by VV_FIELD_DEFINITIONS.FD_SOURCE_NUM       -- sortiert wie in Definition gegeben

    if @HANDLING ='UNIQ'  -- jeden Wert nur einmal angeben, öfters vorkommende jetzt wieder entfernen...
      delete R1           -- (Achtung, es kann immer noch doppelte geben, wenn EINE source den Wert zweimal enthält)
        from #result R1
       where SEQUENCE_NUM = @SEQUENCE_NUM
         and FIELDNAME = @FIELDNAME
         and SOURCE_NUM > (select MIN(SOURCE_NUM)                    -- alle source_num außer der kleinsten löschen
                             from #result R2                         --
                            where R2.SEQUENCE_NUM = @SEQUENCE_NUM    -- ...die für dieses Feld
                              and R2.FIELDNAME = @FIELDNAME          --
                              and R2.STRINGVALUE = R1.STRINGVALUE    -- ...den gleichen Wert haben
                                 )

  
  end -- of while

  -- jetzt Rückgabe der Werte
  select SOURCE_ID,
         SEQUENCE_NUM,
         FIELDNAME,
         SOURCE_NUM,
         STRINGVALUE,
         RECORD_DATE,
         DATA_ORIGIN,
         URLSOURCE
    from #result    
order by SEQUENCE_NUM asc , SOURCE_NUM asc, RECORD_DATE desc
   
return
  
-----------------------------------------------------------------------------------------
-- sp_helptext vvsp_get_maininfoV2 
/*
select * from vv_field_definitions order by FD_SEQUENCE_NUM
Beispielaufruf:

exec vvsp_get_maininfoV2 'de000BASF111'
  
   select * from vv_mastervalues where mv_isin='de000BASF111'
select top 99 * from vv_mastervalues where mv_upload_id=14 



insert #result  select 'ISIN', null, @ISIN
insert #result  select 'WKN', null, dbo.fn_vv_current_value('DBAG', @ISIN, null, null, 'WKN')
insert #result  select 'Name', null, dbo.fn_vv_current_value('DBAG', @ISIN, null, null, 'Instrument') 
insert #result  select 'Kurzname', null, dbo.fn_vv_current_value('DBAG', @ISIN, null, null, 'Mnemonic')             -- das ist FALSCH aber vorläufig zur Demo so OK
insert #result  select 'Instrumententyp(CFI)', null, '123456'                                                      -- das ist FALSCH aber vorläufig zur Demo so OK
insert #result  select 'Währung',  null, dbo.fn_vv_current_value('DBAG', @ISIN, null, null, 'Settlement Currency')  -- eigentlich Börsenplatzabhängig !
insert #result  select 'Emittent LEI', null, '123456'                                                              -- das ist FALSCH aber vorläufig zur Demo so OK
insert #result  select 'Emittent Web', null, 'http://www.basf.de'                                                  -- das ist FALSCH aber vorläufig zur Demo so OK
insert #result  select 'Instrument BIB', null, 'http://www.basf.com/de/company/investor-relations.html'            -- das ist FALSCH aber vorläufig zur Demo so OK

insert #result 
  select distinct 'Handelsplätze', MV_MIC, dbo.fn_vv_current_value('DBAG', @ISIN, MV_MIC, null, 'Market Segment')   -- Marktsegment ist nur eine NOTLÖSUNG, nachsehen in Tabelle MIC wäre besser
    from vv_mastervalues
   where MV_ISIN=@ISIN and not MV_MIC=''

insert #result select 'Zielmarkt', 'a) Kundenkategorie', 'Privatkunden, prof.Kunden, geeig.Gegenparteien'
insert #result select 'Zielmarkt', 'b) Kenntnisse & Erfahrungen', 'Basiskenntnisse'
insert #result select 'Zielmarkt', 'c) Verlusttragfähigkeit', 'Bis zum Totalverlust'
insert #result select 'Zielmarkt', 'd) Risiko-/Renditeprofil', '5 (auf Skala 1-7) "substantielles Risiko"'
insert #result select 'Zielmarkt', 'e) Anlageziele', 'Allg.Vermögensbildung'
insert #result select 'Zielmarkt', 'f) Anglagehorizont', 'ohne Einschränkung'
insert #result select 'Zielmarkt', 'g) Spezielle Anforderungen', 'unbestimmt'

*/

