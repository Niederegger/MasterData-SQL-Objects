-- 30.06.17 KB: Ersten Entwurf der Prozedur erstellt.
-- 30.06.17 AG: Anpassung an MIC select, sodass leere MICS ignoriert werden

use MasterData
go

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[vvsp_get_maininfo]') )
  drop procedure dbo.vvsp_get_maininfo
go

create procedure dbo.vvsp_get_maininfo
  @ISIN char(12)
as
  if @ISIN is null return               -- hier sollte noch eine vernünftige Rückmeldung zur Darstellung af der webseite kommen, aber in welchem Format? 
  if @ISIN ='' return

  if len(@ISIN) = 6                     -- haben wir vielleicht eine WKN statt einer ISIN bekommen?
  begin
    select top 1 @ISIN=mv_isin 
      from vv_mastervalues
     where MV_SOURCE_ID='DBAG'                             -- mal bei Deutscher Börse nachsehen...
       and MV_FIELDNAME='WKN'                              -- ...ob diese WKN bekannt ist
       and MV_STRINGVALUE=@ISIN
     order by coalesce(MV_LAST_SEEN, MV_TIMESTAMP) desc    -- die jüngste nehmen (LAST_SEEN kann NULL sein, TIMESTAMP immer da aber ggf älter als wirklich "zuletzt gesehen")
  end     
  
  if @ISIN is null return               -- hier sollte noch eine vernünftige Rückmeldung zur Darstellung af der webseite kommen, aber in welchem Format? 
  if len(@ISIN) != 12 return            -- hier sollte noch eine vernünftige Rückmeldung zur Darstellung af der webseite kommen, aber in welchem Format? 

create table #result
(
  LEVEL1     varchar(50) not null,       
  LEVEL2     varchar(50),
  STRINGVALUE varchar(256) not null
)  

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

select * from #result    

return
  
-----------------------------------------------------------------------------------------
-- sp_helptext vvsp_get_maininfo 
/*
Beispielaufruf:

exec vvsp_get_maininfo 'de000BASF111'
  
   select * from vv_mastervalues where mv_isin='de000BASF111'
select top 99 * from vv_mastervalues where mv_upload_id=14 


*/

