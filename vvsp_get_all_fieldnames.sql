use MasterData
go

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[vvsp_get_all_fieldnames]') )
  drop procedure dbo.vvsp_get_all_fieldnames
go

-- 04.08.17 KB: Neue Proc erstellt
create procedure dbo.vvsp_get_all_fieldnames
  @USER nvarchar(64)   -- wie FD_USER in VV_FIELD_DEFINITIONS
as
 
select min(FD_SEQUENCE_NUM) as SEQUENCE_NUM, 
       FD_FIELDNAME         as FIELDNAME
  from VV_FIELD_DEFINITIONS
 where FD_USER is null       -- User=NULL sind die Default-Systemfelder, die kommen hier immer
       or FD_USER =@USER     -- hier kommen die Felder, die der User ggf selber definiert hat
 group by FD_FIELDNAME
 order by min(FD_SEQUENCE_NUM)

 -----------------------------------------------------------------------------------------
-- sp_helptext vvsp_get_all_fieldnames 
/*
select * from vv_field_definitions order by FD_SEQUENCE_NUM

vvsp_get_all_fieldnames null
vvsp_get_all_fieldnames 'Peter'

*/