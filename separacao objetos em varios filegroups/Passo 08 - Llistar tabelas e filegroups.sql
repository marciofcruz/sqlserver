-- listagem de filegroup
SELECT * FROM sys.filegroups


-- Listar tabelas criadas e qual filegroup está associado
SELECT f.[name], COUNT(*) FROM sys.indexes i
INNER JOIN sys.filegroups f
ON i.data_space_id = f.data_space_id
INNER JOIN sys.all_objects o
ON i.[object_id] = o.[object_id] WHERE i.data_space_id = f.data_space_id
AND o.type = 'U' -- User Created Tables
GROUP BY
f.[name]
order by COUNT(*) desc


-- Listar tabelas criadas e qual filegroup está associado
SELECT o.[name], o.[type], i.[name], i.[index_id], f.[name] filegroup FROM sys.indexes i
INNER JOIN sys.filegroups f ON i.data_space_id = f.data_space_id
INNER JOIN sys.all_objects o ON i.[object_id] = o.[object_id] WHERE i.data_space_id = f.data_space_id
AND o.type in ( 'U','V')

-- nome e espaço ocupado
SELECT sdf.name AS [FileName],
size/128 AS [Size_in_MB],
fg.name AS [File_Group_Name]
FROM sys.database_files sdf
INNER JOIN sys.filegroups fg ON sdf.data_space_id=fg.data_space_id


-- get filegroup files
--DECLARE @FileGroupName sysname = N'PRIMARY';
 
;WITH src AS
(
  SELECT FG          = fg.name, 
         FileID      = f.file_id,
         LogicalName = f.name,
         [Path]      = f.physical_name, 
         FileSizeMB  = f.size/128.0, 
         UsedSpaceMB = CONVERT(bigint, FILEPROPERTY(f.[name], 'SpaceUsed'))/128.0, 
         GrowthMB    = CASE f.is_percent_growth WHEN 1 THEN NULL ELSE f.growth/128.0 END,
         MaxSizeMB   = NULLIF(f.max_size, -1)/128.0,
         DriveSizeMB = vs.total_bytes/1048576.0,
         DriveFreeMB = vs.available_bytes/1048576.0
  FROM sys.database_files AS f
  INNER JOIN sys.filegroups AS fg
        ON f.data_space_id = fg.data_space_id
  CROSS APPLY sys.dm_os_volume_stats(DB_ID(), f.file_id) AS vs
  --WHERE fg.name = COALESCE(@FileGroupName, fg.name)
)

SELECT [Filegroup] = FG, FileID, LogicalName, [Path],
  FileSizeMB  = CONVERT(decimal(18,2), FileSizeMB),
  FreeSpaceMB = CONVERT(decimal(18,2), FileSizeMB-UsedSpaceMB),
  [%]         = CONVERT(decimal(5,2), 100.0*(FileSizeMB-UsedSpaceMB)/FileSizeMB),
  GrowthMB    = COALESCE(RTRIM(CONVERT(decimal(18,2), GrowthMB)), '% warning!'),
  MaxSizeMB   = CONVERT(decimal(18,2), MaxSizeMB),
  DriveSizeMB = CONVERT(bigint, DriveSizeMB),
  DriveFreeMB = CONVERT(bigint, DriveFreeMB),
  [%]         = CONVERT(decimal(5,2), 100.0*(DriveFreeMB)/DriveSizeMB)
FROM src
ORDER BY FG, LogicalName;


-- CONSTRAINTS
SELECT
  OBJECT_NAME(parent_object_id) AS 'Table',
  name AS 'Constraint',
  is_disabled, 
  is_not_trusted
FROM sys.foreign_keys
UNION
SELECT 
  OBJECT_NAME(parent_object_id),
  name,
  is_disabled, 
  is_not_trusted
FROM sys.check_constraints

-- Lista de tabelas particionadas
select 
    object_schema_name(i.object_id) as [schema],
    object_name(i.object_id) as [object_name],
    t.name as [table_name],
    i.name as [index_name],
    s.name as [partition_scheme]
from sys.indexes i
    join sys.partition_schemes s on i.data_space_id = s.data_space_id
    join sys.tables t on i.object_id = t.object_id 

