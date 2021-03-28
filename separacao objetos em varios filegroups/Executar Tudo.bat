for %%G in (*.sql) do sqlcmd /S #SERVIDOR# /d #NOMEDOBANCO# -Usa -P#SENHA# -i"%%G" >> Execucao.log
