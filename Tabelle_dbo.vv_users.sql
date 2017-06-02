-- 02.06.2017 AG: Tabelle dbo.vv_users erstellt

Use UserDb
go

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[vv_users]') and OBJECTPROPERTY(id, N'IsUserTable') = 1)
drop table [dbo].vv_users
GO


CREATE TABLE [dbo].[vv_users]
(
	[u_name] [char](32) NOT NULL,		-- Der name des Benutzers
	[u_password] [char](32) NOT NULL,	-- Das Password des Benutzers
	[u_role] [char](16) NOT NULL,		-- Die Rolle des Benutzers, Admin, Basic, Kunde, etc, noch unrelevant
	[u_mail] [char](32) NOT NULL,		-- Die Email-Adresse des Benutzers, falls PW vergessen, kann dadurch resette werden
	[u_verified] [bit] ,					-- hat der Benutzer seine email bestätigt

) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO
