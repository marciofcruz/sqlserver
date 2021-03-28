* Abrir o arquivo Executar Tudo.bat e, trocar os parâmetros:
** #NOMEDOBANCO#
** #SENHA#
** #SERVIDOR#
** O usuário deixei como sa mas, pode ser que mude


* Deve ser criado uma tabela, chamado CONFIGTAB, onde mencionaremos as tabelas que existem e quais os FileGroups especifico
** O Arquivo Passo01 - Preparar Tabelas x FileGroup.sql mencionamos isso
 

No Passo 02, criei algumas procedures uteis que serão usadas no processo

Ao executar o Executar Tudo.bat, todas as tabelas mencionadas no Passo 01 serão enviadas para seus respectivos filegroups.

É importante testar isso em homologação e, fazer vários testes e ensaios para verificar a melhor distribuição de filegroups e tabelas.

Criei uma função chamada schPartAnoQuarto(Data) onde associamos a mesma a algumas tabelas

Usei como exemplo somente uma tal de TABELA8 e TABELA9

Eu acredito que o partionamento de tabela é algo que deve ser feito depois que particionamos o banco em diversos filegroups