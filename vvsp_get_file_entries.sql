use MasterData
go

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[vvsp_get_file_entries]') )
  drop procedure dbo.vvsp_get_file_entries
go

-- 30.07.17 KB: Neue Prozedur erstellt, wird aufgerufen von Java-Function getFiles
create procedure dbo.vvsp_get_file_entries
  @p_isin char(12)
as

Set NOCOUNT ON

select fs_filename,
       fs_location,
       fs_fk_user,
       fs_isin,
       fs_timestamp,
       fs_ip,
       fs_data_origin,
       fs_data_type,
       fs_comment
  from vv_fileserver 
 where fs_isin = @p_isin

-----------------------------------------------------------------------------------------
/* sp_helptext vvsp_get_file_entries
 
exec vvsp_get_file_entries 'de000basf111'


aus der Tabellendefinition: 
CREATE TABLE [dbo].[vv_fileserver](
  [fs_filename] [char](256) NOT NULL,    -- Name der Datei
  [fs_location] [char](1024) NOT NULL,  -- FullPath der Datei
  [fs_fk_user] int NOT NULL,        -- Foreign Key, verweis auf User
  [fs_isin] [char](12) NOT NULL,      -- Name des Unternehmens
  [fs_timestamp] [datetime] NOT NULL CONSTRAINT [fs_timestamp_GETDATE]  DEFAULT (getdate()),
  [fs_ip] [char] (256) not null,      -- Ip Adresse des Uploads
  [fs_data_origin] varchar(256),      -- Die Quelle, woher die Datei Stammt
  [fs_data_type]   varchar(64),      -- Typ der datei zb KIID, FACTSHEET
  [fs_comment] [varchar] (256) not null,  -- Kommentar
) ON [PRIMARY]


select * from vv_fileserver


*/
