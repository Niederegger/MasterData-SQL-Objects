use MasterData
go

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[vvsp_get_file_location]') )
  drop procedure dbo.vvsp_get_file_location
go

-- 30.07.17 KB: Neue Prozedur erstellt, wird aufgerufen von Java-Function getFileLocation
create procedure dbo.vvsp_get_file_location
  @p_filename  char(256),    -- Name der Datei
  @p_timestamp datetime      -- wird als default mittels getdate() gesetzt
as

Set NOCOUNT ON

select fs_location
  from vv_fileserver 
 where fs_filename  = @p_filename
   and fs_timestamp = @p_timestamp

-----------------------------------------------------------------------------------------
/* sp_helptext vvsp_get_file_location
 
exec vvsp_get_file_location 'de000basf111'


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
