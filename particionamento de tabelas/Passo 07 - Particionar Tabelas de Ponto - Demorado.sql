if exists(select 1 from sys.tables where name = 'TABELA8')
begin
	print 'particionando a tabela8...';

	exec SP_RENAME 'dbo.TABELA8', 'TABELA8ANTIGO';

	CREATE TABLE [dbo].[TABELA8](
	[CHAVE] [int] NOT NULL,
	[DATAQUALQUER] [DATETIME] NOT NULL,
	COLUNAA	numeric,
	COLUNAB	numeric,
	COLUNAC	numeric,
	COLUNAD	numeric	)  on schPartAnoQuarto (DATAQUALQUER)

	insert into TABELA8
	SELECT * FROM TABELA8ANTIGO;

	DROP TABLE TABELA8ANTIGO;
end

if exists(select 1 from sys.tables where name = 'TABELA9')
begin
	print 'particionando a TABELA9...';

	exec SP_RENAME 'dbo.TABELA9', 'TABELA9ANTIGO';

	CREATE TABLE [dbo].[TABELA9](
	[CHAVE] [int] NOT NULL,
	[OUTROCAMPODATA] [DATETIME] NOT NULL,
	COLUNAC	numeric,
	COLUNAD	numeric	)  on schPartAnoQuarto (OUTROCAMPODATA)

	insert into TABELA9
	SELECT * FROM TABELA9ANTIGO;

	DROP TABLE TABELA9ANTIGO;
end



