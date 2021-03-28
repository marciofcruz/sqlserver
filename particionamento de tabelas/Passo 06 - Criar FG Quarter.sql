set nocount on

declare @dtiniciosistema datetime = '20190101'
declare @temAutoGrowFiles smallint = 1

declare @nomebanco varchar(100)=DB_NAME();
declare @NOMEEMPRESA varchar(150)
declare @dtauxiliar datetime 
declare @nomefg varchar(100)
declare @qtde int
declare @sql nvarchar(max)
DECLARE @path nvarchar(511) = CONVERT(nvarchar(511), SERVERPROPERTY('InstanceDefaultDataPath'));
declare @size varchar(20) = '8MB';
declare @maxsize varchar(20) = 'unlimited';
declare @grouth varchar(20) = '16MB';
declare @strfaixas nvarchar(max) 
declare @strfilegroup nvarchar(max)
DECLARE @ehPrimeiro smallint = 1

set @NOMEEMPRESA=@nomebanco+'_EMPRESAX'


set @dtauxiliar='20200101'

select @dtauxiliar=DATEFROMPARTS(year(@dtauxiliar), month(@dtauxiliar), 1)

if @dtauxiliar < datefromparts(2020,06,30)
begin
	SET @DTAUXILIAR = datefromparts(2019,06,30)
end

while @dtauxiliar <= datefromparts(2024,12,31)
begin
	set @nomefg = @NOMEEMPRESA +'_'+CAST(DATEPART(year, DATEADD(DAY, 1, EOMONTH(@dtauxiliar))) AS VARCHAR(4))+'_t'+cast(DATEPART(quarter, EOMONTH(@dtauxiliar)) as varchar(1))

	if @strfilegroup is null
	begin
		set @strfilegroup = @nomefg
	end
	else
	begin
		set @strfilegroup = @strfilegroup+','+@nomefg
	end

	if @ehPrimeiro=0
	begin
		if @strfaixas is null
		begin
			set @strfaixas = ''''+convert(varchar, EOMONTH(@dtauxiliar), 112)+''''
		end
		else
		begin
			set @strfaixas = @strfaixas +','+ ''''+convert(varchar, EOMONTH(@dtauxiliar), 112)+''''
		end
	end

	SELECT @QTDE=COUNT(*) FROM sys.filegroups a where a.name=@nomefg
	if @QTDE=0
	begin
		print 'Criando File Group '+@nomefg+'...';

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
			SET @SQL = @SQL +
			'ALTER DATABASE $db$ MODIFY FILEGROUP $nomefilegroup$ AUTOGROW_ALL_FILES'; 
		end
	
		SET @SQL = @SQL +';'; 


		set @sql = REPLACE(@SQL, '$db$', @nomebanco)
		set @sql = REPLACE(@SQL, '$size$', @size)
		set @sql = REPLACE(@SQL, '$maxsize$', @maxsize)
		set @sql = REPLACE(@SQL, '$grouth$', @grouth)
		set @sql = REPLACE(@SQL, '$path$', @path)
		set @sql = REPLACE(@SQL, '$nomefilegroup$', @nomefg)
		set @sql = REPLACE(@SQL, '$name1$', @nomefg+'1')
		set @sql = REPLACE(@SQL, '$arquivodados1$', @path+@nomefg+'_1.ndf')
		set @sql = REPLACE(@SQL, '$name2$', @nomefg+'2')
		set @sql = REPLACE(@SQL, '$arquivodados2$', @path+@nomefg+'_2.ndf')

		--print @sql
		EXEC sys.sp_executesql @sql;
	end

	set @dtauxiliar=DATEADD(quarter, 1, @dtauxiliar)
	set @ehPrimeiro = 0
end


if exists(select 1 from sys.partition_schemes where name = 'schPartAnoQuarto')
begin
	DROP PARTITION SCHEME  schPartAnoQuarto
end

if exists(select 1 from sys.partition_functions where name = 'fncAnoQuarto')
begin	
	DROP PARTITION FUNCTION [fncAnoQuarto]
end


set @sql ='CREATE PARTITION FUNCTION [fncAnoQuarto](DATETIME) AS RANGE RIGHT FOR VALUES ('+@strfaixas+')';
EXEC sys.sp_executesql @sql;
--print @sql

set @sql = 'CREATE PARTITION SCHEME [schPartAnoQuarto] AS PARTITION [fncAnoQuarto] TO ('+@strfilegroup+')';
--print @sql
EXEC sys.sp_executesql @sql;
