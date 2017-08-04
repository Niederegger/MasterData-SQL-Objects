use MasterData
go

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[vvsp_get_crawler_job]') )
  drop procedure dbo.vvsp_get_crawler_job
go

-- 30.07.17 KB: Neue Prozedur erstellt, wird vom Crwaler aufgerufen, der einen Job ausführen möchte
create procedure dbo.vvsp_get_crawler_job
  @p_crawler_id  char(8)   -- die Kennung des Crawlers, der einen Job abholen will
as

Set NOCOUNT ON

declare @cj_job_num    int        -- eindeutiger Schlüssel
declare @cj_crawler_id char(8)    -- ID des Crawlers, der diesen Job übernehmen soll
declare @cj_isin       char(12)   -- ISIN, die der Crawler recherchieren soll
declare @cj_timestamp  datetime   -- wann dieser Job in diese Tabelle kam
  
select top 1 
       @cj_job_num    = cj_job_num,
       @cj_crawler_id = cj_crawler_id, 
       @cj_isin       = cj_isin,
       @cj_timestamp  = cj_timestamp 
  from vv_crawler_jobs
 where @p_crawler_id = cj_crawler_id
 order by cj_timestamp   -- kleinster Wert zuerst, also der älteste Eintrag (wartet am längsten) wird bearbeitet

delete vv_crawler_jobs where cj_job_num = @cj_job_num

select @cj_job_num    as cj_job_num,
       @cj_crawler_id as cj_crawler_id, 
       @cj_isin       as cj_isin,
       @cj_timestamp  as cj_timestamp



-----------------------------------------------------------------------------------------
/* sp_helptext vvsp_get_crawler_job
 
exec vvsp_get_crawler_job 'crawl1'
 
select * from vv_crawler_jobs

truncate table vv_crawler_jobs

insert vv_crawler_jobs(cj_crawler_id, cj_isin, cj_timestamp) values ('CRAWL1','de000basf111',getdate())

CREATE TABLE [dbo].vv_crawler_jobs(
  cj_job_num     int identity constraint vv_crawler_jobs_index1 primary key,
  cj_crawler_id  char(8),    -- ID des Crawlers, der diesen Job übernehmen soll
  cj_isin        char(12),  -- ISIN, die der Crawler recherchieren soll
  cj_timestamp   datetime CONSTRAINT vv_crawler_jobs_GETDATE DEFAULT GETDATE(), -- wann dieser Job in diese Tabelle kam
) ON [PRIMARY]

GO


/*
vv_mastervalues
select * from vv_uploads
sp_helptext vvsp_import_uploadv3

*/
*/
