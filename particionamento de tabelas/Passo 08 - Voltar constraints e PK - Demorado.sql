ALTER TABLE [dbo].[TABELA8] ADD CONSTRAINT [PK_TABELA8] PRIMARY KEY CLUSTERED(TABELA8 ASC, DATAQUALQUER) 
WITH (PAD_INDEX = OFF, ALLOW_PAGE_LOCKS = ON, ALLOW_ROW_LOCKS = ON, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, SORT_IN_TEMPDB = OFF, FILLFACTOR =90);
go

ALTER TABLE [dbo].[TABELA9] ADD CONSTRAINT [PK_TABELA9] PRIMARY KEY CLUSTERED(TABELA9 ASC, OUTROCAMPODATA ASC) 
WITH (PAD_INDEX = OFF, ALLOW_PAGE_LOCKS = ON, ALLOW_ROW_LOCKS = ON, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, SORT_IN_TEMPDB = OFF, FILLFACTOR =90);
GO


declare @nomebanco varchar(100)=DB_NAME();

DECLARE @SQL NVARCHAR(MAX)
DECLARE @total INT
DECLARE @DESCTIPO VARCHAR(30)
declare @CONT INT = 0
DECLARE @POSICAO VARCHAR(10)
declare @auxiliar int

select @total=count(*) from comandoddl where tipo>=3

print 'Desabilitando constraints de todas as tabelas';
exec [HabilitarConstraints] 0
print 'Habilitando constraints de todas as tabelas';
exec [HabilitarConstraints] 1

print 'Desabilitando constraints de todas as tabelas';
exec [HabilitarConstraints] 0


DECLARE C_COMANDOS CURSOR STATIC FOR
select 
CASE TIPO
	WHEN  3 THEN 'Criar Primary Key'
	WHEN  4 THEN 'Criar ForeignKey'
	WHEN  5 THEN 'Criar Constraint ForeignKey'
END DESCTIPO,
SQL 
from 
comandoddl 
where
tipo>=3
order by tipo, id
OPEN C_COMANDOS

FETCH NEXT FROM C_COMANDOS INTO @DESCTIPO, @SQL
WHILE @@FETCH_STATUS=0
BEGIN
	SET @CONT = @CONT + 1

	set @POSICAO = CAST(@CONT AS VARCHAR(10))+'/'+CAST(@TOTAL AS VARCHAR(10))

	BEGIN TRY   
		PRINT @POSICAO+': '+@DESCTIPO+': '+@SQL
		EXEC (@SQL)

		--WAITFOR DELAY '00:00:01';
	END TRY
	BEGIN CATCH
		PRINT ERROR_MESSAGE() 
		PRINT '--------------------------'
	END CATCH

	FETCH NEXT FROM C_COMANDOS INTO @DESCTIPO, @SQL
END

CLOSE C_COMANDOS
DEALLOCATE C_COMANDOS

print 'Habilitando constraints de todas as tabelas';
exec [HabilitarConstraints] 1


print 'Executando schrink de dados '+@nomebanco+'...';
exec [ReduzirArquivoDados] @NOMEBANCO


print 'Habilitando modo Multi Usuario no banco '+@nomebanco+'...';
exec [ModoSingleUser] @NOMEBANCO,0


