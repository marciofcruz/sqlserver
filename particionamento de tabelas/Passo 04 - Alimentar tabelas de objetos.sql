set nocount on

-- Comando para eliminar constraint FK
declare @TSQLDropFK varchar(max)
declare @ParentTableSchema varchar(4000)
declare @ParentTableName varchar(4000)
declare @ForeignKeyName varchar(4000)
DECLARE @TSQLDropIndex VARCHAR(MAX)
declare @SchemaName varchar(100)
declare @TableName varchar(256)
declare @IndexName varchar(256)

declare @auxiliar smallint
DECLARE @STRFUNCAO VARCHAR(400)

DELETE FROM COMANDODDL

declare CursorFK cursor for 
select fk.name ForeignKeyName, 
schema_name(t.schema_id) ParentTableSchema, 
t.name ParentTableName
from sys.foreign_keys fk  
inner join sys.tables t on fk.parent_object_id=t.object_id
open CursorFK

fetch next from CursorFK into  @ForeignKeyName, @ParentTableSchema, @ParentTableName
while (@@FETCH_STATUS=0)
begin
	select  
	@auxiliar =COUNT(*)
	from --sys.tables t inner join 
	sys.foreign_keys fk 
	inner join sys.foreign_key_columns fkc on fk.object_id=fkc.constraint_object_id
	inner join sys.columns c1 on c1.object_id=fkc.parent_object_id and c1.column_id=fkc.parent_column_id 
	inner join sys.columns c2 on c2.object_id=fkc.referenced_object_id and c2.column_id=fkc.referenced_column_id 
	inner join sys.tables t1 on t1.object_id=fkc.parent_object_id 
	inner join sys.tables t2 on t2.object_id=fkc.referenced_object_id 
	WHERE
	fk.name=@ForeignKeyName

	if @auxiliar<>0
	begin
		set @TSQLDropFK ='ALTER TABLE '+quotename(@ParentTableSchema)+'.'+quotename(@ParentTableName)+' DROP CONSTRAINT '+quotename(@ForeignKeyName)
		insert into COMANDODDL (TIPO, SQL) values (0, @TSQLDropFK)
	end

fetch next from CursorFK into  @ForeignKeyName, @ParentTableSchema, @ParentTableName
end
close CursorFK
deallocate CursorFK

DECLARE CursorIndexes CURSOR FOR
SELECT  schema_name(t.schema_id), t.name,  i.name 
FROM sys.indexes i
INNER JOIN sys.tables t ON t.object_id= i.object_id
WHERE i.type>0 and t.is_ms_shipped=0 and t.name<>'sysdiagrams'
and (is_primary_key=1 or is_unique_constraint=1)
OPEN CursorIndexes

SET @TSQLDropIndex = ''

FETCH NEXT FROM CursorIndexes INTO @SchemaName,@TableName,@IndexName
WHILE @@fetch_status = 0
BEGIN
	SET @TSQLDropIndex = ' ALTER TABLE '+QUOTENAME(@SchemaName)+ '.' + QUOTENAME(@TableName) + ' DROP CONSTRAINT ' +QUOTENAME(@IndexName)

	insert into COMANDODDL (TIPO, SQL) values (2, @TSQLDropIndex)

	FETCH NEXT FROM CursorIndexes INTO @SchemaName,@TableName,@IndexName
END

CLOSE CursorIndexes
DEALLOCATE CursorIndexes

declare	@FILLFACTORPADRAO INT = 90

declare @columnName varchar(256)
declare @is_unique_constraint varchar(100)
declare @IndexTypeDesc varchar(100)
declare @FileGroupName varchar(100)
declare @is_disabled varchar(100)
declare @IndexOptions varchar(max)
declare @IndexColumnId int
declare @IsDescendingKey int 
declare @IsIncludedColumn int
declare @TSQLScripCreationIndex varchar(max)
declare @is_primary_key varchar(100)
declare @strauxiliar varchar(256)


declare CursorIndex cursor for
select schema_name(t.schema_id) [schema_name], t.name, ix.name,
case when ix.is_unique_constraint = 1 then ' UNIQUE ' else '' END 
,case when ix.is_primary_key = 1 then ' PRIMARY KEY ' else '' END 
, ix.type_desc,
case when ix.is_padded=1 then 'PAD_INDEX = ON, ' else 'PAD_INDEX = OFF, ' end
+ case when ix.allow_page_locks=1 then 'ALLOW_PAGE_LOCKS = ON, ' else 'ALLOW_PAGE_LOCKS = OFF, ' end
+ case when ix.allow_row_locks=1 then  'ALLOW_ROW_LOCKS = ON, ' else 'ALLOW_ROW_LOCKS = OFF, ' end
+ case when INDEXPROPERTY(t.object_id, ix.name, 'IsStatistics') = 1 then 'STATISTICS_NORECOMPUTE = ON, ' else 'STATISTICS_NORECOMPUTE = OFF, ' end
+ case when ix.ignore_dup_key=1 then 'IGNORE_DUP_KEY = ON, ' else 'IGNORE_DUP_KEY = OFF, ' end
+ 'SORT_IN_TEMPDB = OFF, FILLFACTOR =' + CAST(CASE WHEN ix.fill_factor=0 THEN @FILLFACTORPADRAO ELSE ix.fill_factor END  AS VARCHAR(3)) AS IndexOptions
, FILEGROUP_NAME(ix.data_space_id) FileGroupName
from sys.tables t 
inner join sys.indexes ix on t.object_id=ix.object_id
where ix.type>0 and  (ix.is_primary_key=1 or ix.is_unique_constraint=1) --and schema_name(tb.schema_id)= @SchemaName and tb.name=@TableName
and t.is_ms_shipped=0 and t.name<>'sysdiagrams'
order by schema_name(t.schema_id), t.name, ix.name
open CursorIndex

fetch next from CursorIndex into  @SchemaName, @TableName, @IndexName, @is_unique_constraint, @is_primary_key, @IndexTypeDesc, @IndexOptions, @FileGroupName
while (@@fetch_status=0)
begin
	declare @IndexColumns varchar(max)
	declare @IncludedColumns varchar(max)
	set @IndexColumns=''
	set @IncludedColumns=''
	declare CursorIndexColumn cursor for 
	select col.name, ixc.is_descending_key, ixc.is_included_column
	from sys.tables tb 
	inner join sys.indexes ix on tb.object_id=ix.object_id
	inner join sys.index_columns ixc on ix.object_id=ixc.object_id and ix.index_id= ixc.index_id
	inner join sys.columns col on ixc.object_id =col.object_id  and ixc.column_id=col.column_id
	where ix.type>0 and (ix.is_primary_key=1 or ix.is_unique_constraint=1)
	and schema_name(tb.schema_id)=@SchemaName and tb.name=@TableName and ix.name=@IndexName
	order by ixc.key_ordinal
	open CursorIndexColumn 

	fetch next from CursorIndexColumn into  @ColumnName, @IsDescendingKey, @IsIncludedColumn
	while (@@fetch_status=0)
	begin
	if @IsIncludedColumn=0 
	set @IndexColumns=@IndexColumns + @ColumnName  + case when @IsDescendingKey=1  then ' DESC, ' else  ' ASC, ' end
	else 
	set @IncludedColumns=@IncludedColumns  + @ColumnName  +', ' 
     
	fetch next from CursorIndexColumn into @ColumnName, @IsDescendingKey, @IsIncludedColumn
	end
	close CursorIndexColumn
	deallocate CursorIndexColumn
	set @IndexColumns = substring(@IndexColumns, 1, len(@IndexColumns)-1)
	set @IncludedColumns = case when len(@IncludedColumns) >0 then substring(@IncludedColumns, 1, len(@IncludedColumns)-1) else '' end

	SET @STRAUXILIAR=NULL
	SET @STRFUNCAO = NULL

	SELECT @STRAUXILIAR=A.NOMEFILEGROUP, @STRFUNCAO=A.FUNCAOPARTICAO FROM CONFIGTAB A WHERE A.NOMETABELA=@TableName

	IF @STRAUXILIAR IS NULL OR @STRAUXILIAR='' 
	BEGIN
		SET @STRAUXILIAR  = @FILEGROUPNAME
	END

	IF @STRFUNCAO IS NOT NULL
	BEGIN
		SET @STRAUXILIAR=@STRFUNCAO
	END

	set @TSQLScripCreationIndex =''
	set  @TSQLScripCreationIndex='ALTER TABLE '+  QUOTENAME(@SchemaName) +'.'+ QUOTENAME(@TableName)+ ' ADD CONSTRAINT ' +  QUOTENAME(@IndexName) + @is_unique_constraint + @is_primary_key + +@IndexTypeDesc +  '('+@IndexColumns+') '+ 
		case when len(@IncludedColumns)>0 then CHAR(13) +'INCLUDE (' + @IncludedColumns+ ')' else '' end + CHAR(13)+'WITH (' +  @IndexOptions+ ') ON ' + QUOTENAME(@STRAUXILIAR) + ';'  

	insert into COMANDODDL (TIPO, SQL) values (3, @TSQLScripCreationIndex)

fetch next from CursorIndex into  @SchemaName, @TableName, @IndexName, @is_unique_constraint, @is_primary_key, @IndexTypeDesc, @IndexOptions, @FileGroupName

end
close CursorIndex
deallocate CursorIndex


declare @ForeignKeyID int
declare @ParentColumn varchar(4000)
declare @ReferencedTable varchar(4000)
declare @ReferencedColumn varchar(4000)
declare @StrParentColumn varchar(max)
declare @StrReferencedColumn varchar(max)
declare @ReferencedTableSchema varchar(4000)
declare @TSQLCreationFK varchar(max)

--- SCRIPT TO GENERATE THE CREATION SCRIPT OF ALL FOREIGN KEY CONSTRAINTS
--Written by Percy Reyes www.percyreyes.com
declare CursorFK cursor for select object_id--, name, object_name( parent_object_id) 
from sys.foreign_keys
open CursorFK
fetch next from CursorFK into @ForeignKeyID
while (@@FETCH_STATUS=0)
begin
	set @StrParentColumn=''
	set @StrReferencedColumn=''
	declare CursorFKDetails cursor for
	select  fk.name ForeignKeyName, schema_name(t1.schema_id) ParentTableSchema,
	object_name(fkc.parent_object_id) ParentTable, c1.name ParentColumn,schema_name(t2.schema_id) ReferencedTableSchema,
	object_name(fkc.referenced_object_id) ReferencedTable,c2.name ReferencedColumn
	from --sys.tables t inner join 
	sys.foreign_keys fk 
	inner join sys.foreign_key_columns fkc on fk.object_id=fkc.constraint_object_id
	inner join sys.columns c1 on c1.object_id=fkc.parent_object_id and c1.column_id=fkc.parent_column_id 
	inner join sys.columns c2 on c2.object_id=fkc.referenced_object_id and c2.column_id=fkc.referenced_column_id 
	inner join sys.tables t1 on t1.object_id=fkc.parent_object_id 
	inner join sys.tables t2 on t2.object_id=fkc.referenced_object_id 
	where fk.object_id=@ForeignKeyID
	open CursorFKDetails
	fetch next from CursorFKDetails into  @ForeignKeyName, @ParentTableSchema, @ParentTableName, @ParentColumn, @ReferencedTableSchema, @ReferencedTable, @ReferencedColumn
	while (@@FETCH_STATUS=0)
	begin    
	set @StrParentColumn=@StrParentColumn + ', ' + quotename(@ParentColumn)
	set @StrReferencedColumn=@StrReferencedColumn + ', ' + quotename(@ReferencedColumn)
  
		fetch next from CursorFKDetails into  @ForeignKeyName, @ParentTableSchema, @ParentTableName, @ParentColumn, @ReferencedTableSchema, @ReferencedTable, @ReferencedColumn
	end
	close CursorFKDetails
	deallocate CursorFKDetails

	SET @STRFUNCAO = NULL
	SELECT @STRFUNCAO=A.FUNCAOPARTICAO FROM CONFIGTAB A WHERE A.NOMETABELA=@ParentTableName

	set @StrParentColumn=substring(@StrParentColumn,2,len(@StrParentColumn)-1)
	set @StrReferencedColumn=substring(@StrReferencedColumn,2,len(@StrReferencedColumn)-1)
	set @TSQLCreationFK='ALTER TABLE '+quotename(@ParentTableSchema)+'.'+quotename(@ParentTableName)+' WITH CHECK ADD CONSTRAINT '+quotename(@ForeignKeyName)
	+ ' FOREIGN KEY('+ltrim(@StrParentColumn)+') '+ char(13) +'REFERENCES '+quotename(@ReferencedTableSchema)+'.'+quotename(@ReferencedTable)+' ('+ltrim(@StrReferencedColumn)+') ';

	IF @STRFUNCAO IS NOT NULL
	BEGIN
		set @TSQLCreationFK = @TSQLCreationFK +' on '+@STRFUNCAO
	END

	--PRINT @TSQLCreationFK

	insert into COMANDODDL (TIPO, SQL) values (5, @TSQLCreationFK)

fetch next from CursorFK into @ForeignKeyID 
end
close CursorFK
deallocate CursorFK


DECLARE @SQL nvarchar(max)
declare @NOMETABELA varchar(100)

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
		
	SET @STRAUXILIAR=NULL
	SET @STRFUNCAO = NULL
	SELECT @STRAUXILIAR=A.NOMEFILEGROUP, @strfuncao=A.FUNCAOPARTICAO FROM CONFIGTAB A WHERE A.NOMETABELA=@NOMETABELA

	FETCH NEXT FROM C_INDICES INTO @NOMEINDICE, @COLUNAS, @ISUNIQUE, @TABLE_VIEW
	WHILE @@FETCH_STATUS=0
	BEGIN
		insert into COMANDODDL (TIPO, SQL) values (1, 'DROP INDEX '+@NOMEINDICE+' ON '+ @NOMETABELA)

		IF @STRFUNCAO IS NOT NULL 
		BEGIN
			SET @STRAUXILIAR = @STRFUNCAO
		END

		SET @SQL = 'CREATE NONCLUSTERED INDEX '+@NOMEINDICE+' ON '+@TABLE_VIEW+'('+@COLUNAS+')';
		IF @STRAUXILIAR IS NOT NULL OR @STRAUXILIAR<>'' 
		BEGIN
			SET @SQL = @SQL +' ON '+@STRAUXILIAR;
		END

		insert into COMANDODDL (TIPO, SQL) values (4, @SQL)

		FETCH NEXT FROM C_INDICES INTO @NOMEINDICE, @COLUNAS, @ISUNIQUE, @TABLE_VIEW
	END

	CLOSE C_INDICES
	DEALLOCATE C_INDICES

	FETCH NEXT FROM C_NOMETABELA INTO @NOMETABELA;
END

CLOSE C_NOMETABELA;
DEALLOCATE C_NOMETABELA;

select * from comandoddl order by tipo, id
