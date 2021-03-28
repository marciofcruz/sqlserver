SELECT 
spid,
open_tran
FROM master.dbo.sysprocesses
WHERE dbid = DB_ID('NOME DO BANCO')
