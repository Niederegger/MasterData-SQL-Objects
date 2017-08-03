use MasterData
go

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[vvsp_get_isin_for_wkn]') )
  drop procedure dbo.vvsp_get_isin_for_wkn
go

-- 30.07.17 KB: Neue Prozedur erstellt, wird aufgerufen von Java-Function getIsinOfWkn
create procedure dbo.vvsp_get_isin_for_wkn
  @p_isin char(12)
as

Set NOCOUNT ON

select distinct mv_isin 
  from vv_mastervalues 
 where MV_Stringvalue = @p_isin
   and mv_fieldname   = 'WKN'        -- ursprünglich war die Abfrage ohne diese Einschränkung

-- Problem 1: full table scan macht diese Prozedur langsam

-- Problem 2: was ist, wenn 2 unterschiedliche ISINs zurück kommen? Anonyme Users sind auch drin!

-- Problem 3: Quellen, bei denen das Feld nicht "WKN" heisst, bleiben unberücksichtigt


-----------------------------------------------------------------------------------------
/* sp_helptext vvsp_get_isin_for_wkn
 
exec vvsp_get_isin_for_wkn 'basf11'



*/
