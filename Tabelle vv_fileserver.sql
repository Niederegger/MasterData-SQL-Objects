-- 19.07.2017 AG; Init FileServer Table

USE [MasterData]
GO

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[vv_fileserver]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].[vv_fileserver]
GO

CREATE TABLE [dbo].[vv_fileserver](
	[fs_filename] [char](64) NOT NULL,		-- Name der Datei
	[fs_location] [char](512) NOT NULL,		-- FullPath der Datei
	[fs_fk_user] int NOT NULL,				-- Foreign Key, verweis auf User
	[fs_establishment] [char](16) NOT NULL,	-- Name des Unternehmens
	[fs_timestamp] [datetime] NOT NULL CONSTRAINT [fs_timestamp_GETDATE]  DEFAULT (getdate()),
	[fs_ip] [char] (256) not null,			-- Ip Adresse des Uploads
	[fs_comment] [varchar] (256) not null,	-- Kommentar
) ON [PRIMARY]

GO


