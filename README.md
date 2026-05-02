# Migrador de Mensagens Rápidas

Este script em Shell (`Insert_quick_answers.sh`) tem como objetivo facilitar a migração e importação de "mensagens rápidas" (quick answers) de um arquivo CSV diretamente para um banco de dados PostgreSQL. Ele automatiza o processo de leitura do CSV, criação de uma tabela temporária e inserção segura dos dados na tabela principal, evitando duplicatas.

## Funcionalidades

- **Carregamento Automático de Credenciais:** O script lê as credenciais do banco de dados automaticamente a partir de um arquivo `.env` predefinido.
- **Interação com o Usuário:** Solicita de forma interativa o nome do arquivo CSV e o ID do Cliente (`COMPANY_ID`).
- **Importação Segura:** Utiliza uma tabela temporária para carregar os dados do CSV antes de inseri-los na tabela final.
- **Prevenção de Duplicatas:** Realiza a inserção na tabela `public.quick_answers` utilizando `NOT EXISTS` e `DISTINCT` para garantir que mensagens já existentes para o mesmo cliente não sejam duplicadas.
- **Tratamento de JSONB:** Formata o conteúdo da mensagem em um objeto JSONB (`content`) conforme a estrutura exigida pelo banco de dados.

## Pré-requisitos

Antes de executar o script, certifique-se de que os seguintes requisitos sejam atendidos:

1. **PostgreSQL Client (`psql`):** O comando `psql` deve estar instalado e acessível no sistema.
2. **Arquivo `.env`:** Um arquivo `.env` contendo as variáveis de conexão do banco de dados deve existir no caminho especificado no script (`/$DIR/.env`).
   - Variáveis esperadas no `.env`: `PG_HOST`, `PG_PORT`, `PG_USER`, `PG_DB_NAME`, `PG_PASSWORD`.
3. **Diretório de CSVs:** Os arquivos CSV a serem importados devem estar localizados no diretório `/opt/import_quick_anwser`.

## Estrutura Esperada do CSV

O arquivo CSV deve possuir um cabeçalho e utilizar ponto e vírgula (`;`) como delimitador. As colunas esperadas (com base na tabela temporária criada pelo script) são:

- `id`
- `company_id`
- `user_id`
- `name` (Título da mensagem rápida)
- `answer` (Conteúdo da mensagem rápida)
- `created_at`
- `updated_at`

*Nota: O script utiliza as colunas `name` e `answer` para popular a tabela final.*

## Como Usar

1. Coloque o arquivo CSV contendo as mensagens rápidas no diretório `/opt/import_quick_anwser`.
2. Dê permissão de execução ao script (se ainda não tiver):
   ```bash
   chmod +x Insert_quick_answers.sh
   ```
3. Execute o script:
   ```bash
   ./Insert_quick_answers.sh
   ```
4. Siga as instruções na tela:
   - Digite o nome do arquivo CSV (ex: `dados_cliente.csv`).
   - Digite o `COMPANY_ID` (UUID do cliente que receberá as mensagens).

## Tratamento de Erros

O script inclui verificações básicas de erro, como:
- Validação da existência do arquivo `.env`.
- Verificação se o nome do arquivo CSV e o `COMPANY_ID` foram fornecidos.
- Verificação da existência do arquivo CSV no diretório especificado.
- Validação do status de saída do comando `psql` para confirmar se a migração foi bem-sucedida ou se ocorreu um erro no banco de dados.

## Considerações de Segurança

O script exporta a variável de ambiente `PGPASSWORD` temporariamente para permitir a autenticação sem senha interativa no `psql`. Esta variável é removida (`unset`) ao final da execução do script para manter a segurança.