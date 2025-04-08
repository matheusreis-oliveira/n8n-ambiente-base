-- Criação do usuário e banco para o n8n
CREATE USER n8n WITH PASSWORD 'n8npass';
CREATE DATABASE n8n OWNER n8n;
GRANT ALL PRIVILEGES ON DATABASE n8n TO n8n;

-- Criação do usuário e banco para o evolution-api
CREATE USER evolution WITH PASSWORD 'evolutionpass';
CREATE DATABASE evolutiondb OWNER evolution;
GRANT ALL PRIVILEGES ON DATABASE evolutiondb TO evolution;

-- Concede permissões no schema public do banco evolutiondb
\connect evolutiondb;
GRANT USAGE ON SCHEMA public TO evolution;
GRANT CREATE ON SCHEMA public TO evolution;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO evolution;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO evolution;
ALTER ROLE evolution SET search_path = public;

-- Concede permissões específicas ao Postgres para permitir que o Evolution API crie tabelas
ALTER USER evolution CREATEDB;

-- Criação do usuário e banco para a aplicação
CREATE USER appuser WITH PASSWORD 'apppass';
CREATE DATABASE appdb OWNER appuser;
GRANT ALL PRIVILEGES ON DATABASE appdb TO appuser;

-- Configura o banco de dados da aplicação
\connect appdb;
GRANT USAGE ON SCHEMA public TO appuser;
GRANT CREATE ON SCHEMA public TO appuser;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO appuser;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO appuser;
ALTER ROLE appuser SET search_path = public;

-- Cria a tabela de clientes no banco appdb
CREATE TABLE IF NOT EXISTS clientes (
    id SERIAL PRIMARY KEY,
    nome TEXT NOT NULL,
    telefone TEXT UNIQUE NOT NULL,
    email TEXT,
    status TEXT DEFAULT 'ativo',
    criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    atualizado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Cria a tabela de historico_conversas no banco appdb
CREATE TABLE IF NOT EXISTS historico_conversas (
    id SERIAL PRIMARY KEY,
    cliente_id INTEGER REFERENCES clientes(id),
    telefone TEXT NOT NULL,
    mensagem TEXT NOT NULL,
    tipo TEXT NOT NULL CHECK (tipo IN ('recebida', 'enviada')),
    status TEXT DEFAULT 'entregue',
    criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Cria índices para melhorar a performance
CREATE INDEX idx_clientes_telefone ON clientes(telefone);
CREATE INDEX idx_historico_telefone ON historico_conversas(telefone);
CREATE INDEX idx_historico_cliente_id ON historico_conversas(cliente_id);

-- Concede permissões para o usuário n8n acessar o banco de dados da aplicação
GRANT CONNECT ON DATABASE appdb TO n8n;
GRANT USAGE ON SCHEMA public TO n8n;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO n8n;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO n8n;
GRANT USAGE, SELECT, UPDATE ON ALL SEQUENCES IN SCHEMA public TO n8n;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT USAGE, SELECT, UPDATE ON SEQUENCES TO n8n;

-- Confirma que o banco de dados e tabelas estão prontos
SELECT 'Databases and tables created and permissions granted successfully.';