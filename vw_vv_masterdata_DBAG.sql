-- 26.04.2017 KB: View  dbo.vv_mastervalues erstellt und Testdaten ausgedacht

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[vw_vv_masterdata_DBAG]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [dbo].vw_vv_masterdata_DBAG
GO

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
CREATE VIEW dbo.vw_vv_masterdata_DBAG
as
select T1.MV_ISIN                                                                                     as MD_ISIN,
       T1.MV_MIC                                                                                      as MD_MIC,
       convert(char(32), dbo.fn_vv_current_value('DBAG', T1.MV_ISIN, T1.MV_MIC, null, 'Instrument'))  as Instrument,
       convert(char(6),  dbo.fn_vv_current_value('DBAG', T1.MV_ISIN, T1.MV_MIC, null, 'WKN'))         as WKN,
       convert(char(12), dbo.fn_vv_current_value('DBAG', T1.MV_ISIN, T1.MV_MIC, null, 'Mnemonic'))    as Mnemonic,
       convert(char(8),  dbo.fn_vv_current_value('DBAG', T1.MV_ISIN, T1.MV_MIC, null, 'CCP eligible')) as CCP_eligible,
       convert(char(16),  dbo.fn_vv_current_value('DBAG', T1.MV_ISIN, T1.MV_MIC, null, 'Unit of Quotation')) as Unit_of_Quotation,
       convert(decimal(8,4), dbo.fn_vv_current_value('DBAG', T1.MV_ISIN, T1.MV_MIC, null, 'Interest Rate'))     as Interest_Rate,
       convert(money, replace(dbo.fn_vv_current_value('DBAG', T1.MV_ISIN, T1.MV_MIC, null,'Closing Price Previous Business Day'),',','.')) as MD_LASTPRICE,
       convert(char(64), dbo.fn_vv_current_value('DBAG', T1.MV_ISIN, T1.MV_MIC, null, 'Market Segment'))     as Market_Segment, 
       convert(char(32), dbo.fn_vv_current_value('DBAG', T1.MV_ISIN, T1.MV_MIC, null, 'Settlement Currency'))     as Settlement_Currency
  from (select MV_ISIN, MV_MIC from vv_mastervalues group by MV_ISIN, MV_MIC) T1

go
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[vw_vv_fulldata]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [dbo].vw_vv_fulldata
GO
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------  
CREATE VIEW dbo.vw_vv_fulldata
as
select T1.MV_ISIN                                                                                  as MD_ISIN,
       T1.MV_MIC                                                                                   as MD_MIC,
       T1.MV_AS_OF_DATE                                                                            as MD_AS_OF_DATE,
       convert(char(3), dbo.fn_vv_current_value(T1.MV_ISIN, MV_MIC, MV_AS_OF_DATE, 'A1-CURRENCY'))            as MD_CURRENCY,
       convert(money, replace(dbo.fn_vv_current_value(T1.MV_ISIN, MV_MIC, MV_AS_OF_DATE,'A3-PRICE'),',','.')) as MD_PRICE,
       dbo.fn_vv_current_value(T1.MV_ISIN, null, null,'A1-FULLNAME')                               as MD_LONGNAME
  from (select MV_ISIN, MV_MIC, MV_AS_OF_DATE from vv_mastervalues group by MV_ISIN, MV_MIC, MV_AS_OF_DATE) T1
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--
-- grant select on vw_vv_masterdata to fvs_orders_lesen, fvs_orders_buchen
--
-- sp_helptext vw_vv_masterdata_DBAG
-- sp_helptext vw_vv_fulldata
/*
 
 select * from vw_vv_masterdata_DBAG where MD_ISIN='de0007100000'   -- View ausprobieren
 select * from vv_mastervalues where MV_ISIN='de0007100000'         -- Zum Vergleich die Quelldaten für Daimler
 select len(MV_STRINGVALUE),* from vv_mastervalues where MV_FIELDNAME ='Market Segment' order by len(MV_STRINGVALUE) desc
 select * , replace(MV_STRINGVALUE,',','') from vv_mastervalues  where MV_FIELDNAME='Closing Price Previous Business Day' and MV_STRINGVALUE like '%,%'
 update vv_mastervalues  set MV_STRINGVALUE=replace(MV_STRINGVALUE,',','') where MV_FIELDNAME='Closing Price Previous Business Day' and MV_STRINGVALUE like '%,%'
  
*/
