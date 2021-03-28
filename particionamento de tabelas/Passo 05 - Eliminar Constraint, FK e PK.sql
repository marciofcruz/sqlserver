declare @nomebanco varchar(100)=DB_NAME();

set nocount on

DECLARE @SQL NVARCHAR(MAX)
DECLARE @total INT
DECLARE @DESCTIPO VARCHAR(30)
declare @CONT INT = 0
DECLARE @POSICAO VARCHAR(10)
declare @auxiliar int

select @total=count(*) from comandoddl where tipo in (0,1,2) 

print 'Desabilitando constraints de todas as tabelas';
exec [HabilitarConstraints] 0
print 'Habilitando constraints de todas as tabelas';
exec [HabilitarConstraints] 1

print 'Desabilitando constraints de todas as tabelas';
exec [HabilitarConstraints] 0

print 'Apagar divergencias de FK da base de dados';
exec [ApagarDivergenciasBase] @auxiliar output

DECLARE C_COMANDOS CURSOR STATIC FOR
select 
CASE TIPO
	WHEN  0 THEN 'Eliminar Constraint ForeignKey'
	WHEN  1 THEN 'Eliminar Foreign Key'
	WHEN  2 THEN 'Eliminar Primary Key'
	WHEN  3 THEN 'Criar Primary Key'
	WHEN  4 THEN 'Criar ForeignKey'
	WHEN  5 THEN 'Criar Constraint ForeignKey'
END DESCTIPO,
SQL 
from 
comandoddl 
WHERE TIPO IN (0,1,2)
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


print 'Habilitando modo Multi Usuario no banco '+@nomebanco+'...';
exec [ModoSingleUser] @NOMEBANCO,0


