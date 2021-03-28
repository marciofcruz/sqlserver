DECLARE @NOMEBANCO VARCHAR(100);
DECLARE @NOMETABELA VARCHAR(100);
DECLARE @NOMEINDICE VARCHAR(100);
declare @comando varchar(100);

-- SETAR PARAMETROS
SELECT @NOMEBANCO=DB_NAME();

DECLARE C_NOMETABELA CURSOR FOR 
SELECT
t.NAME,
I.name
FROM
sys.tables t
INNER JOIN sys.indexes i ON (t.OBJECT_ID = i.object_id)
INNER JOIN sys.partitions p ON (i.object_id = p.OBJECT_ID AND i.index_id = p.index_id)
INNER JOIN sys.allocation_units a ON (p.partition_id = a.container_id)
LEFT OUTER JOIN sys.schemas s ON (t.schema_id = s.schema_id)
WHERE
t.is_ms_shipped = 0
and t.NAME NOT LIKE 'dt%' 
AND I.IS_PRIMARY_KEY=0
ORDER BY
T.NAME, I.NAME
OPEN C_NOMETABELA;

FETCH NEXT FROM C_NOMETABELA INTO @NOMETABELA, @NOMEINDICE
WHILE @@FETCH_STATUS=0
BEGIN
	
	PRINT   'DROP INDEX '+@NOMEINDICE+' ON '+@NOMETABELA
	print 'go'



	FETCH NEXT FROM C_NOMETABELA INTO @NOMETABELA, @NOMEINDICE;
END

CLOSE C_NOMETABELA;
DEALLOCATE C_NOMETABELA;
