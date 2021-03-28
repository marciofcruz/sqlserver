--Abrir tela da Seção 1 do BANCO
select * from TABELA
BEGIN TRANSACTION
select * from TABELA with (REPEATABLEREAD) where TABELA = 1

--Abrir tela da Seção 2 do BANCO
BEGIN TRANSACTION
UPDATE TABELA WITH (NOWAIT) SET TABELA.TABELA = 1 where TABELA.TABELA = 1
ROLLBACK
-- vai causar exceção
