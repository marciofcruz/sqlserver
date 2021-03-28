DECLARE @NOMEBANCO VARCHAR(100);
DECLARE @NOMETABELA VARCHAR(100);
DECLARE @TABELAEXISTE smallint;
DECLARE @NOMEINDICE VARCHAR(100);
DECLARE @FRAGMENTACAO NUMERIC(15,5);
DECLARE @CHAVE INT;
DECLARE @SOMENTECONSULTA INT;
DECLARE @NOMES TABLE  (CHAVE INT, NOMETABELA VARCHAR(100), TABELAEXISTE SMALLINT, NOMEINDICE VARCHAR(100), FRAGMENTACAO NUMERIC(15,5));
DECLARE @NOME VARCHAR(50);

DECLARE @TOTAL SMALLINT = 0;
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

SELECT @TOTAL=COUNT(A.NAME) FROM (SELECT
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
t.Name, s.Name, p.Rows) A;

FETCH NEXT FROM C_NOMETABELA INTO @NOMETABELA;
WHILE @@FETCH_STATUS=0
BEGIN
	SET @CONT= @CONT+1;

	PRINT  'Reindexando objetos de '+@NOMETABELA+' ('+CAST(@CONT AS VARCHAR)+'/'+CAST(@TOTAL AS VARCHAR)+')';
	DBCC DBREINDEX (@NOMETABELA); 

	--WAITFOR DELAY '00:00:10'; para destravar o uso do sistema para a produção
	
	FETCH NEXT FROM C_NOMETABELA INTO @NOMETABELA;
END

CLOSE C_NOMETABELA;
DEALLOCATE C_NOMETABELA;

print 'concluido';