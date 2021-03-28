--Abrir tela da Seção 1 do BANCO
select * from entidade
BEGIN TRANSACTION
select * from ENTIDADE with (REPEATABLEREAD) where ENTIDADE = 1

--Abrir tela da Seção 2 do BANCO
BEGIN TRANSACTION
UPDATE ENTIDADE WITH (NOWAIT) SET ENTIDADE.ENTIDADE = 1 where ENTIDADE.ENTIDADE = 1
ROLLBACK
-- vai causar exceção
