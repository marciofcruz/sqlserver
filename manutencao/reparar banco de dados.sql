-- para mostrar os erros
DBCC CHECKDB('NOMEBANCO') WITH NO_INFOMSGS

-- para reparar os erros
ALTER DATABASE NOMEBANCO SET SINGLE_USER
GO
DBCC CHECKDB('NOMEBANCO', REPAIR_REBUILD)

ALTER NOMEBANCO SET MULTI_USER

