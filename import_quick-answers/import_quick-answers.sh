#!/bin/bash

# ==========================================
# 1. Configurações e Carregamento do .env
# ==========================================
ENV_FILE="/"$DIR"/.env"
DIR_CSV="/opt/import_quick_anwser"

if [ -f "$ENV_FILE" ]; then
  set -a
  source "$ENV_FILE"
  set +a
else
  echo "⚠️ Erro: Arquivo .env não encontrado em $ENV_FILE"
  exit 1
fi

export PGPASSWORD="$PG_PASSWORD"

# ==========================================
# 2. Interação com o Usuário
# ==========================================
echo "=========================================="
echo "🚀 MIGRADOR DE MENSAGENS RÁPIDAS"
echo "=========================================="

# Solicita o nome do arquivo CSV
read -p "📂 Digite o nome do arquivo CSV (ex: dados_cliente.csv): " NOME_ARQUIVO

if [ -z "$NOME_ARQUIVO" ]; then
  echo "⚠️ Erro: O nome do arquivo não pode ser vazio."
  exit 1
fi

CSV_PATH="$DIR_CSV/$NOME_ARQUIVO"

if [ ! -f "$CSV_PATH" ]; then
  echo "⚠️ Erro: Arquivo $CSV_PATH não encontrado."
  exit 1
fi

# Solicita o ID do Cliente
read -p "🏢 Digite o COMPANY_ID (UUID do cliente): " COMPANY_ID

if [ -z "$COMPANY_ID" ]; then
  echo "⚠️ Erro: O COMPANY_ID não pode ser vazio."
  exit 1
fi

echo "🔄 Processando arquivo $NOME_ARQUIVO para o tenant: $COMPANY_ID..."

# ==========================================
# 3. Execução Direta via SQL
# ==========================================
psql -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" -d "$PG_DB_NAME" <<EOF
BEGIN;

-- 1. Tabela temporária tipada como TEXT
CREATE TEMP TABLE temp_csv (
    id TEXT,
    company_id TEXT,
    user_id TEXT,
    name TEXT,
    answer TEXT,
    created_at TEXT,
    updated_at TEXT
);

-- 2. Carrega os dados do CSV
\copy temp_csv FROM '$CSV_PATH' WITH (FORMAT csv, HEADER true, DELIMITER ';', NULL '');

-- 3. Inserção final com bloqueio de duplicatas (NOT EXISTS) e filtro de linhas repetidas (DISTINCT)
INSERT INTO public.quick_answers (
    company_id, 
    category_id, 
    "type", 
    title, 
    is_being_typed_active, 
    is_being_typed_time, 
    "content"
)
SELECT DISTINCT
    '$COMPANY_ID'::uuid,
    NULL::uuid,
    'text',
    t.name,
    true,
    3,
    jsonb_build_object('message', t.answer)
FROM temp_csv t
WHERE t.name != 'name' AND t.name IS NOT NULL
  AND NOT EXISTS (
      SELECT 1 
      FROM public.quick_answers qa 
      WHERE qa.company_id = '$COMPANY_ID'::uuid 
        AND qa.title = t.name 
        -- Extrai o texto de dentro do JSONB para comparar com o texto bruto do CSV
        AND qa.content->>'message' = t.answer
  );

COMMIT;
EOF

# ==========================================
# 4. Verificação
# ==========================================
if [ $? -eq 0 ]; then
  echo "=========================================="
  echo "✅ SUCESSO! Migração concluída (ignorando possíveis duplicatas)."
  echo "=========================================="
else
  echo "❌ Ocorreu um erro no banco de dados."
fi

unset PGPASSWORD