
USE [MasterData]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[vv_crawler_jobs]')  )
 drop table [dbo].vv_crawler_jobs
GO

-- 03.08.2017 KB Neue Tabelle vv_crawler_jobs zur Steuerung der Web-Crawler (googlebots)

CREATE TABLE [dbo].vv_crawler_jobs(
	cj_job_num     int identity constraint vv_crawler_jobs_index1 primary key,
	cj_crawler_id  char(8),		-- ID des Crawlers, der diesen Job übernehmen soll
	cj_isin        char(12),  -- ISIN, die der Crawler recherchieren soll
  cj_timestamp   datetime CONSTRAINT vv_crawler_jobs_GETDATE DEFAULT GETDATE(), -- wann dieser Job in diese Tabelle kam
) ON [PRIMARY]

GO


/*
vv_mastervalues
select * from vv_uploads
sp_helptext vvsp_import_uploadv3

*/