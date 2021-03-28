Apesar de eu trabalhar com linguagem de programação e saber que o banco de dados é uma outra camada e, em teoria,
outra pessoa cuidar, nos deparamos com situações que nós mesmos precisando fazer manutenção no banco.

Para fins didáticos, além do filegroup PRIMARY, incluí 3: MODULOA, MODULOB e MODULOC. Eu acredito que os filegroups
devem espelhar os módulos que um sistema tem, assim, fica mais fácil o entendimento depois.

Agora, sobre os diretórios.

1) Diretorio "manutencao":
Há scripts diversos que nos auxiliam em:
# Saber conexões em aberto
# Desfragmentar objetos de banco de daods
# Reindexação
# Saber Querys mais pesadas
# Saber de cada tabela no banco, qual a quantidade de registros
# Script para saber log de restauração de banco de dados
# Simulador do "for update no wait" do Oracle, no SQL Server
# Indicador de indices faltantes ou sem utilização
# Limpeza de log e Cache

2) Diretorio "separacao objetos em varios filegroups":
Sabemos que  a operação de utilizar arquivo de disco é uma operação bloqueante. Ou seja, não importa a capacidade
computacional, etc, o acesso ao disco é sempre bloqueante e se tiver mais de um usuário esperando ao mesmo tempo.

Dito isso, estes scripts fazem o processo de separar vários filegroups em disco e, para cada filegroup, 2 arquivos (pode ser
configurado mais). 

Assim, pode-se aplicar o algoritimo "proportional fill", além do mais, possibilitar que o SGBD do SQL Server
utilize o poder do multicore.

3) Diretório "particionamento de tabelas":
Sempre há no sistema aquelas tabelas gigantes. Assim,  este script é uma sequência de comandos que pega determinadas tabelas do sistema e aplicamos particionamento de acordo
com parâmetros, por exemplo a data.

No meu exemplo, eu separei filegroups divididos em trimestres e, nele, criei uma aplicação de partionamento para tal.
Assim, podemos pegar qualquer tabela do sistema e, aplicar o determinado particionamento.

Todos estes exemplos apresentados funcionam em produção e, possibilitou:
# Aumento da performance do sistema em produção
# Facilitou o backup e o restore
# Diminuição da necessidade de fazer desfragmentação 

Espero ter ajudado.

Marcio