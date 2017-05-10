-- 26.04.2017 KB: Funktion dbo.fn_vv_current_value erstellt und Testdaten ausgedacht
-- 27.04.2017 KB: Parameter @SOURCE_ID ergänzt

Use MasterData
go

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[fn_vv_current_value]') and OBJECTPROPERTY(id, N'IsScalarFunction') = 1)
drop function [dbo].fn_vv_current_value
GO


create function dbo.fn_vv_current_value(@SOURCE_ID  as char(8),  -- Kennung der Quelle, zB 'DBAG'
                                        @ISIN as char(12),       -- die ISIN des Wertpapiers als Schlüssel, zB 'DE0007100000' für Daimler
                                        @MIC as char(4),         -- die Börsen-ID, sofern der abgefragte Wert börsenabhängig ist (kann sonst NULL sein)
                                        @AS_OF_DATE date,        -- das as-of-date, sofern der abgefragte Wert sich auf ein Datum bezieht (wie bei Kursen), ansonsten NULL
                                        @FIELDNAME as char(48))  -- der Name des Wertes, den man mit deiser Funktion abfragen will (z.B. 'a1-FullName')
returns varchar(2048)
as
begin
  declare @STRING varchar(2048)
  
  select top 1 @STRING = MV_STRINGVALUE
    from vv_mastervalues
   where MV_SOURCE_ID = coalesce(@SOURCE_ID,MV_SOURCE_ID)                            -- wenn @SOURCE_ID gegeben, dann muss sie gleich sein, wenn nicht, dann egal
     and MV_ISIN      = @ISIN                                                        -- das richtige Instrument
     and (MV_MIC is NULL or @MIC is NULL or @MIC=MV_MIC)                             -- wenn Parameter @MIC NULL ist (=MIC ist egal) oder wenn Feld MV_MIC NUL ist (=Feld gilt für alle MICs) oder wenn Wert gleich
     and (MV_AS_OF_DATE is NULL or @AS_OF_DATE is NULL or @AS_OF_DATE=MV_AS_OF_DATE) -- wie oben, also einer muss NULL sein oder es muss passen
     and MV_FIELDNAME = @FIELDNAME                                                   -- das gewünschte Feld raussuchen
   order by MV_AS_OF_DATE desc, MV_TIMESTAMP desc
   
  return @STRING
end
  
---------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------
/*

Testaufrufe:

select dbo.fn_vv_current_value('DBAG','DE0007100000', null, null, 'WKN')
select dbo.fn_vv_current_value('DBAG','DE0007100000', null, null, 'Instrument')
select dbo.fn_vv_current_value('DBAG','DE0007100000', 'XETR', null, 'Market Segment')
select dbo.fn_vv_current_value('DBAG','DE0007100000', 'XFRA', null, 'Market Segment')

select dbo.fn_vv_current_value('DBAG','DE0007100000', 'XFRA', null, 'Closing Price Previous Business Day')

select dbo.fn_vv_current_value('DBAG','DE0007100000', 'XFRA', '20170314', 'Closing Price Previous Business Day')


select * from vv_mastervalues where MV_ISIN='DE0007100000'      
     
*/
-- Thomas Kommentar