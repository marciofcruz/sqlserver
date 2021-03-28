USE master;
GO
DECLARE bancos CURSOR FOR
	select sys.databases.name as banco, sys.sysaltfiles.name as arqlog
	from sys.databases
		inner join sys.sysaltfiles on (sys.databases.database_id=sys.sysaltfiles.dbid)
	where 
		sys.databases.database_id>4
		and sys.sysaltfiles.fileid=2
OPEN bancos;

DECLARE @DBNome NVARCHAR(128);
DECLARE @DBLog NVARCHAR(50);
DECLARE @SQLInstrucao NVARCHAR(300);

FETCH NEXT FROM bancos INTO @DBNome, @DBLog;
WHILE (@@FETCH_STATUS = 0)
BEGIN
   PRINT N'DATABASE ' + @DBNome;
   SET @SQLInstrucao = N'USE ' + @DBNome + CHAR(13)
      + N'ALTER DATABASE ' + @DBNome + CHAR(13)
      + N'SET RECOVERY SIMPLE' + CHAR(13)
      + N'DBCC SHRINKFILE (' + @DBLog + N',1)' + CHAR(13)
      + N'ALTER DATABASE ' + @DBNome + CHAR(13)
      + N'SET RECOVERY FULL';
   EXEC sp_executesql @SQLInstrucao;
   PRINT CHAR(13) + CHAR(13);
   FETCH NEXT FROM bancos INTO @DBNome, @DBLog;
END;

CLOSE bancos;
DEALLOCATE bancos;
GO

-- limpando o cache

DBCC DROPCLEANBUFFERS
DBCC FREEPROCCACHE