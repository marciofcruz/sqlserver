
-- criação de procedimentos para teste
create procedure [dbo].[ExisteFK] (@NomeFK varchar(100), @Existe int OUTPUT) AS
begin
	DECLARE @QTDE INT

	select  
	@QTDE=COUNT(*)
	from --sys.tables t inner join 
	sys.foreign_keys fk 
	inner join sys.foreign_key_columns fkc on fk.object_id=fkc.constraint_object_id
	inner join sys.columns c1 on c1.object_id=fkc.parent_object_id and c1.column_id=fkc.parent_column_id 
	inner join sys.columns c2 on c2.object_id=fkc.referenced_object_id and c2.column_id=fkc.referenced_column_id 
	inner join sys.tables t1 on t1.object_id=fkc.parent_object_id 
	inner join sys.tables t2 on t2.object_id=fkc.referenced_object_id 
	WHERE
	fk.name=@NomeFK

	IF @QTDE=0
	BEGIN
		SET @EXISTE = 0
	END
	ELSE
	BEGIN
		SET @EXISTE = 1
	END
end
GO


create procedure [dbo].[HabilitarConstraints] (@Habilitar int) AS
begin
	declare @sql nvarchar(max)

	if @Habilitar=1
	begin
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
	end
	else
	begin
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

	end
end
GO


create procedure [dbo].Rebuildar (@NOMEBANCO varchar(100), @Resultado int OUTPUT) AS
begin
	SET NOCOUNT ON
	
	DECLARE @SQL nvarchar(max)
	declare @NOMETABELA varchar(100)

	-- Rebuildar tabelas
	DECLARE @TABELAEXISTE smallint;
	DECLARE @FRAGMENTACAO NUMERIC(15,5);
	DECLARE @CHAVE INT;
	DECLARE @SOMENTECONSULTA INT;
	DECLARE @NOMES TABLE  (CHAVE INT, NOMETABELA VARCHAR(100), TABELAEXISTE SMALLINT, NOMEINDICE VARCHAR(100), FRAGMENTACAO NUMERIC(15,5));
	DECLARE @NOME VARCHAR(50);

	DECLARE @CONT SMALLINT = 0;

	-- SETAR PARAMETROS
	SELECT @NOMEBANCO=DB_NAME();

	DECLARE C_NOMETABELA CURSOR FOR 
	SELECT
	t.NAME 
	FROM
	sys.tables t
	INNER JOIN sys.indexes i ON (t.OBJECT_ID = i.object_id)
	INNER JOIN sys.partitions p ON (i.object_id = p.OBJECT_ID AND i.index_id = p.index_id)
	INNER JOIN sys.allocation_units a ON (p.partition_id = a.container_id)
	LEFT OUTER JOIN sys.schemas s ON (t.schema_id = s.schema_id)
	WHERE
	t.is_ms_shipped = 0
	and t.NAME NOT LIKE 'dt%' 
	AND i.OBJECT_ID > 255
	GROUP BY
	t.Name, s.Name, p.Rows
	ORDER BY
	SUM(a.total_pages) * 8
	OPEN C_NOMETABELA;

	FETCH NEXT FROM C_NOMETABELA INTO @NOMETABELA;
	WHILE @@FETCH_STATUS=0
	BEGIN
		  BEGIN TRY   
			 SET @sql = 'ALTER INDEX ALL ON ' + @NOMETABELA + ' REBUILD' 
			 EXEC (@sql) 
		  END TRY
		  BEGIN CATCH
			 PRINT '---'
			 PRINT @sql
			 PRINT ERROR_MESSAGE() 
			 PRINT '---'
		  END CATCH
		
		FETCH NEXT FROM C_NOMETABELA INTO @NOMETABELA;
	END

	CLOSE C_NOMETABELA;
	DEALLOCATE C_NOMETABELA;
END
go

create procedure [dbo].Reindexar (@NOMEBANCO varchar(100), @Resultado int OUTPUT) AS
begin
	SET NOCOUNT ON
	
	DECLARE @SQL nvarchar(max)
	declare @NOMETABELA varchar(100)

	declare @STRAUXILIAR varchar(100)

	-- reindexar tabelas
	DECLARE @TABELAEXISTE smallint;
	DECLARE @FRAGMENTACAO NUMERIC(15,5);
	DECLARE @CHAVE INT;
	DECLARE @SOMENTECONSULTA INT;
	DECLARE @NOMES TABLE  (CHAVE INT, NOMETABELA VARCHAR(100), TABELAEXISTE SMALLINT, NOMEINDICE VARCHAR(100), FRAGMENTACAO NUMERIC(15,5));
	DECLARE @NOME VARCHAR(50);

	DECLARE @NOMEINDICE VARCHAR(200)
	DECLARE @COLUNAS NVARCHAR(MAX)
	DECLARE @ISUNIQUE INT
	DECLARE @TABLE_VIEW VARCHAR(200)

	DECLARE @CONT SMALLINT = 0;

	-- SETAR PARAMETROS
	DECLARE C_NOMETABELA CURSOR FOR 
	SELECT
	t.NAME 
	FROM
	sys.tables t
	INNER JOIN sys.indexes i ON (t.OBJECT_ID = i.object_id)
	INNER JOIN sys.partitions p ON (i.object_id = p.OBJECT_ID AND i.index_id = p.index_id)
	INNER JOIN sys.allocation_units a ON (p.partition_id = a.container_id)
	LEFT OUTER JOIN sys.schemas s ON (t.schema_id = s.schema_id)
	WHERE
	t.is_ms_shipped = 0
	and t.NAME NOT LIKE 'dt%' 
	AND i.OBJECT_ID > 255
	GROUP BY
	t.Name, s.Name, p.Rows
	ORDER BY
	SUM(a.total_pages) * 8
	OPEN C_NOMETABELA;

	FETCH NEXT FROM C_NOMETABELA INTO @NOMETABELA;
	WHILE @@FETCH_STATUS=0
	BEGIN
		DECLARE C_INDICES CURSOR STATIC FOR
		select 
		i.[name] as index_name,
		substring(column_names, 1, len(column_names)-1) as [columns],
		i.is_unique,
		schema_name(t.schema_id) + '.' + t.[name] as table_view
		from sys.objects t
			inner join sys.indexes i
				on t.object_id = i.object_id
			cross apply (select col.[name] + ', '
							from sys.index_columns ic
								inner join sys.columns col
									on ic.object_id = col.object_id
									and ic.column_id = col.column_id
							where ic.object_id = t.object_id
								and ic.index_id = i.index_id
									order by key_ordinal
									for xml path ('') ) D (column_names)
		where t.is_ms_shipped <> 1
		and index_id > 0
		and t.name = @NOMETABELA and i.[type]=2 and t.[type]='U'
		order by i.[name]
		OPEN C_INDICES
		
		FETCH NEXT FROM C_INDICES INTO @NOMEINDICE, @COLUNAS, @ISUNIQUE, @TABLE_VIEW
		WHILE @@FETCH_STATUS=0
		BEGIN
			 SET @STRAUXILIAR=NULL
			 SELECT @STRAUXILIAR=A.NOMEFILEGROUP FROM CONFIGTAB A WHERE A.NOMETABELA=@NOMETABELA


			SET @SQL = 'DROP INDEX '+@NOMEINDICE+' ON '+ @NOMETABELA+' '+CHAR(13)+
			           'CREATE NONCLUSTERED INDEX '+@NOMEINDICE+' ON '+@TABLE_VIEW+'('+@COLUNAS+')';

			 IF @STRAUXILIAR IS NOT NULL OR @STRAUXILIAR<>'' 
			 BEGIN
				SET @SQL = @SQL +' ON ['+@STRAUXILIAR+']';
			 END

			  BEGIN TRY   
				 EXEC (@sql) 
			  END TRY
			  BEGIN CATCH
				 PRINT '---'
				 PRINT @sql
				 PRINT ERROR_MESSAGE() 
				 PRINT '---'
			  END CATCH

			FETCH NEXT FROM C_INDICES INTO @NOMEINDICE, @COLUNAS, @ISUNIQUE, @TABLE_VIEW
		END

		CLOSE C_INDICES
		DEALLOCATE C_INDICES

		FETCH NEXT FROM C_NOMETABELA INTO @NOMETABELA;
	END

	CLOSE C_NOMETABELA;
	DEALLOCATE C_NOMETABELA;
END
go


create procedure [dbo].[ModoSingleUser] (@nomebanco varchar(100), @SingleUser int) AS
begin
	declare @comando nvarchar(max)

	if @SingleUser=1
	begin
		SET @COMANDO = 'ALTER DATABASE $db$ SET SINGLE_USER WITH ROLLBACK IMMEDIATE;';
	end
	else
	begin
		SET @COMANDO = 'ALTER DATABASE $db$ SET MULTI_USER;';
	end
	
	set @COMANDO = REPLACE(@COMANDO, '$db$', @nomebanco)

	EXEC sp_executesql @COMANDO;
end
GO
create procedure [dbo].[ApagarDivergenciasBase] (@Resultado int OUTPUT) AS
begin
	SET NOCOUNT ON
	-- comandos para eliminar eventuais divergências de FK
end
GO
create procedure [dbo].[ReduzirArquivoDados] (@nomebanco varchar(100)) AS
begin
	declare @strauxiliar varchar(100)

	-- schrink files
	DECLARE C_LISTA CURSOR STATIC FOR
	select NAME from sys.database_files a where a.type=0
	OPEN C_LISTA

	FETCH NEXT FROM C_LISTA INTO @STRAUXILIAR
	WHILE @@FETCH_STATUS=0
	BEGIN
		DBCC SHRINKFILE (@STRAUXILIAR);

		FETCH NEXT FROM C_LISTA INTO @STRAUXILIAR
	END
	CLOSE C_LISTA
	DEALLOCATE C_LISTA

end
go