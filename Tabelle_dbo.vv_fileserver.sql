-- 02.06.2017 AG: Tabelle dbo.vv_fileserver erstellt

Use UserDb
go

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[vv_fileserver]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].vv_fileserver
GO


CREATE TABLE [dbo].[vv_fileserver]
(
	[fs_filename] [char](32) NOT NULL,	-- Name der File
	[fs_location] [char](32) NOT NULL,	-- Ort des Mediums
	[fs_fk_user] [char](16) NOT NULL,	-- Bezug zum Nutzer
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO
