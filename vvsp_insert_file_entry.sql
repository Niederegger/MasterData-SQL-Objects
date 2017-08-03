use MasterData
go

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[vvsp_insert_file_entry]') )
  drop procedure dbo.vvsp_insert_file_entry
go

-- 30.07.17 KB: Neue Prozedur erstellt, wird aufgerufen von Java-Function fileUploadEntry
create procedure dbo.vvsp_insert_file_entry
  @p_filename    char(256),    -- Name der Datei
  @p_location    char(1024),   -- FullPath der Datei
  @p_fk_user     int,          -- Foreign Key, verweis auf User
  @p_isin        char(12),     -- Name des Unternehmens
  @p_ip          char(256),    -- Ip Adresse des Uploads
  @p_data_origin varchar(256), -- Die Quelle, woher die Datei Stammt
  @p_data_type   varchar(64),  -- Typ der datei zb KIID, FACTSHEET
  @p_comment     varchar(256)  -- Kommentar
as

Set NOCOUNT ON

INSERT INTO dbo.vv_fileserver 
       (fs_filename, fs_location, fs_fk_user, fs_isin, fs_ip, fs_comment, fs_data_origin, fs_data_type) 
VALUES (@p_filename, @p_location, @p_fk_user, @p_isin, @p_ip, @p_comment, @p_data_origin, @p_data_type)
   

-----------------------------------------------------------------------------------------
/* sp_helptext vvsp_insert_file_entry
 

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
