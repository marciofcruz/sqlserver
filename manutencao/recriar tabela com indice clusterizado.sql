-- desabilitar constraints
exec sp_msforeachtable "ALTER TABLE ? NOCHECK CONSTRAINT ALL"
exec sp_msforeachtable "ALTER TABLE ? DISABLE TRIGGER ALL"

DECLARE @sql NVARCHAR(MAX) = N'';

;WITH x AS 
(
  SELECT DISTINCT obj = 
      QUOTENAME(OBJECT_SCHEMA_NAME(parent_object_id)) + '.' 
    + QUOTENAME(OBJECT_NAME(parent_object_id)) 
  FROM sys.foreign_keys
)
SELECT @sql += N'ALTER TABLE ' + obj + ' NOCHECK CONSTRAINT ALL;
' FROM x;

EXEC sp_executesql @sql;

-- renomear tabela
EXEC sp_rename 'PONTO', 'PONTO_ANT'


INSERT INTO PONTO
SELECT * FROM PONTO_ANT
ORDER BY ALOCACAOMAODEOBRA, DATA

-- habilitar
DECLARE @sql NVARCHAR(MAX) = N'';

;WITH x AS 
(
  SELECT DISTINCT obj = 
      QUOTENAME(OBJECT_SCHEMA_NAME(parent_object_id)) + '.' 
    + QUOTENAME(OBJECT_NAME(parent_object_id)) 
  FROM sys.foreign_keys
)
SELECT @sql += N'ALTER TABLE ' + obj + ' WITH CHECK CHECK CONSTRAINT ALL;
' FROM x;

EXEC sp_executesql @sql;

exec sp_msforeachtable "ALTER TABLE ? WITH CHECK CHECK CONSTRAINT ALL"
exec sp_msforeachtable "ALTER TABLE ? ENABLE TRIGGER ALL"