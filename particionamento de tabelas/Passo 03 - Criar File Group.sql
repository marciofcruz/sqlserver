SET NOCOUNT ON

declare @nomebanco varchar(100)=DB_NAME();
declare @sql nvarchar(max)

declare @temFileGroupEmMemoria smallint = 0
declare @pastadadossqlnoC varchar(100) = 'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER2019\MSSQL\DATA\';
declare @temAutoGrowFiles smallint = 1;

IF OBJECT_ID(N'tempdb..#listamodulos') IS NOT NULL
BEGIN
	drop table #LISTAMODULOS
END

print 'Habilitando modo Single Usuario no banco '+@nomebanco+'...';
exec [ModoSingleUser] @NOMEBANCO,1


create table #LISTAMODULOS (NOME VARCHAR(20))
INSERT INTO #LISTAMODULOS (NOME) VALUES ('MODULOA')
INSERT INTO #LISTAMODULOS (NOME) VALUES ('MODULOB')
INSERT INTO #LISTAMODULOS (NOME) VALUES ('MODULOC')
DECLARE @STRAUXILIAR VARCHAR(50)

DECLARE @QTDE INT
DECLARE @QTDECOLUNASINDICE INT

DECLARE @path nvarchar(511) = CONVERT(nvarchar(511), SERVERPROPERTY('InstanceDefaultDataPath'));
DECLARE @NOMEEMPRESA VARCHAR(100)

set @NOMEEMPRESA=@nomebanco+'_EMPRESAX'

declare @NOMETABELA varchar(100);
declare @NOMECOLUNA VARCHAR(100);
DECLARE @FILEGROUPDESTINO VARCHAR(100);
declare @NOMEINDICE VARCHAR(100);
DECLARE @MODULO VARCHAR(100);
declare @NOMEARQUIVODADOS VARCHAR(100)
DECLARE @NOMEARQUIVOLOG VARCHAR(100)

declare @size varchar(20) = '32MB';
declare @maxsize varchar(20) = 'unlimited';
declare @grouth varchar(20) = '32MB';

--if @temFileGroupEmMemoria = 0
--begin
	--INSERT INTO #LISTAMODULOS (NOME) VALUES ('VIEWOPT')
--end


if @temFileGroupEmMemoria=1
begin
	SET @MODULO = 'VIEWOPT';
	SELECT @QTDE=COUNT(*) FROM sys.filegroups TABELA WHERE TABELA.NAME=@MODULO
	if @qtde=0
	begin
		print 'Criando File Group de memória chamado VIEWOPT...';

		SET @SQL = N'ALTER DATABASE $db$ ADD FILEGROUP $nomefilegroup$ CONTAINS MEMORY_OPTIMIZED_DATA ;
		ALTER DATABASE $db$ ADD FILE (
			NAME=''$nomefilegroup$'',
			FILENAME=''$path$'',
			MAXSIZE=UNLIMITED)
		TO FILEGROUP $nomefilegroup$;
		';
		set @sql = REPLACE(@SQL, '$db$', @nomebanco)
		set @sql = REPLACE(@SQL, '$path$', @pastadadossqlnoC+@nomeempresa)
		set @sql = REPLACE(@SQL, '$nomefilegroup$', @MODULO)
		EXEC sys.sp_executesql @sql;
	end
end

DECLARE C_MODULOS CURSOR STATIC FOR 
SELECT NOME FROM #LISTAMODULOS
OPEN C_MODULOS

FETCH NEXT FROM C_MODULOS INTO @MODULO
WHILE @@FETCH_STATUS=0
BEGIN
	SELECT @QTDE=COUNT(*) FROM sys.filegroups TABELA WHERE TABELA.NAME=@MODULO

	IF @QTDE=0
	BEGIN
		print 'Criando File Group físico '+@MODULO+'...';

		SET @SQL = N'	ALTER DATABASE $db$ ADD FILEGROUP $nomefilegroup$;
	ALTER DATABASE $db$ ADD FILE (
			NAME=''$name1$'',
			FILENAME=''$arquivodados1$'',
			SIZE=$size$,
			MAXSIZE=$maxsize$,
			FILEGROWTH=$grouth$),
		(
			NAME=''$name2$'',
			FILENAME=''$arquivodados2$'',
			SIZE=$size$,
			MAXSIZE=$maxsize$,
			FILEGROWTH=$grouth$)
		TO FILEGROUP $nomefilegroup$;
		';

		if @temAutoGrowFiles=1 
		begin
			print '		Habilitando AutoGroth';

			SET @SQL = @SQL +
			'ALTER DATABASE $db$ MODIFY FILEGROUP $nomefilegroup$ 
			AUTOGROW_ALL_FILES'; 
		end
	
		SET @SQL = @SQL +';'; 


		set @sql = REPLACE(@SQL, '$db$', @nomebanco)
		set @sql = REPLACE(@SQL, '$size$', @size)
		set @sql = REPLACE(@SQL, '$maxsize$', @maxsize)
		set @sql = REPLACE(@SQL, '$grouth$', @grouth)
		set @sql = REPLACE(@SQL, '$path$', @path)
		set @sql = REPLACE(@SQL, '$nomefilegroup$', @MODULO)
		set @sql = REPLACE(@SQL, '$name1$', @MODULO+'1')
		set @sql = REPLACE(@SQL, '$arquivodados1$', @path+@NOMEEMPRESA+'_'+@MODULO+'1.ndf')
		set @sql = REPLACE(@SQL, '$name2$', @MODULO+'2')
		set @sql = REPLACE(@SQL, '$arquivodados2$', @path+@NOMEEMPRESA+'_'+@MODULO+'2.ndf')
		EXEC sys.sp_executesql @sql;

	END

	FETCH NEXT FROM C_MODULOS INTO @MODULO
END

close C_MODULOS
deallocate C_MODULOS



print 'Habilitando modo Multi Usuario no banco '+@nomebanco+'...';
exec [ModoSingleUser] @NOMEBANCO,0

