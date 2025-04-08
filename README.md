# Ambiente Docker para Integração de Serviços

Este projeto configura um ambiente Docker completo com N8N, PostgreSQL, Redis e Evolution API, além de ferramentas de gestão como PGAdmin e Redis Commander.

## Componentes

- **PostgreSQL**: Banco de dados relacional (versão 16-alpine)
- **PGAdmin**: Interface gráfica para gerenciamento do PostgreSQL
- **Redis**: Banco de dados em memória (versão 7-alpine)
- **Redis Commander**: Interface de administração para Redis
- **N8N**: Plataforma de automação de fluxos de trabalho
- **Evolution API**: API para interação com WhatsApp
- **Watchtower**: Atualização automática de containers

## Pré-requisitos

- Docker (v20.10+)
- Docker Compose (v2.0+)
- 4GB+ de RAM disponível
- 10GB+ de espaço em disco

## Estrutura de Diretórios

```
.
├── docker-compose.yml
├── init/
│   └── init.sql
└── README.md
```

## Instalação

1. Crie a estrutura de diretórios:

```bash
mkdir -p ambiente-docker/init
cd ambiente-docker
```

2. Copie os arquivos `docker-compose.yml` e `init.sql` fornecidos para os respectivos diretórios.

3. Inicie os serviços:

```bash
docker compose up -d
```

## Acessos aos Serviços

| Serviço | URL | Credenciais |
|---------|-----|-------------|
| N8N | http://localhost:5678 | admin / adminpass |
| Evolution API | http://localhost:8080 | API KEY: change-me-to-a-secure-key |
| PostgreSQL | localhost:5432 | postgres / rootpass |
| PGAdmin | http://localhost:5050 | admin@admin.com / admin |
| Redis Commander | http://localhost:8081 | - |

## Bancos de Dados

### PostgreSQL
- **Databases**: 
  - `postgres`: banco de dados padrão
  - `n8n`: para uso do N8N
  - `evolutiondb`: para uso da Evolution API
  - `appdb`: para armazenamento de dados da aplicação

#### Tabelas no banco appdb
- `clientes`: Armazena informações de clientes
  - Campos: id, nome, telefone, email, status, criado_em, atualizado_em
- `historico_conversas`: Armazena histórico de mensagens
  - Campos: id, cliente_id, telefone, mensagem, tipo, status, criado_em

### Redis
- Diferentes DBs são usadas para cada serviço:
  - DB 3: utilizada pelo N8N
  - DB 6: utilizada pela Evolution API

## Redes

O ambiente utiliza a rede `app-network` para comunicação entre os containers.

## Segurança

⚠️ **Para uso em produção, altere todas as senhas e chaves de API nos arquivos:**
- `docker-compose.yml` 
- `init.sql`

Especialmente importante:
- `AUTHENTICATION_API_KEY` para Evolution API
- `N8N_ENCRYPTION_KEY` para N8N (altere `your-secret-encryption-key-change-me`)
- Todas as senhas de banco de dados, incluindo a do usuário `appuser`

## Volumes

Os dados persistentes são armazenados em volumes Docker:
- `postgres_data`: dados do PostgreSQL
- `pgadmin_data`: configurações do PGAdmin
- `redis_data`: dados do Redis
- `n8n_data`: workflows e dados do N8N
- `evolution_data` e `evolution_instances`: dados da Evolution API

## Manutenção

### Backup dos dados

```bash
# Backup dos volumes
docker run --rm -v ambiente-docker_postgres_data:/source -v $(pwd)/backups:/backup alpine tar -czf /backup/postgres-backup.tar.gz -C /source .
docker run --rm -v ambiente-docker_n8n_data:/source -v $(pwd)/backups:/backup alpine tar -czf /backup/n8n-backup.tar.gz -C /source .
docker run --rm -v ambiente-docker_evolution_data:/source -v $(pwd)/backups:/backup alpine tar -czf /backup/evolution-backup.tar.gz -C /source .
docker run --rm -v ambiente-docker_evolution_instances:/source -v $(pwd)/backups:/backup alpine tar -czf /backup/evolution-instances-backup.tar.gz -C /source .
```

### Backup do banco de dados da aplicação

```bash
# Backup específico do banco de dados appdb
docker exec -t postgres pg_dump -U postgres -d appdb > ./backups/appdb_backup_$(date +%Y%m%d%H%M%S).sql
```

### Atualizações

As atualizações de containers são gerenciadas automaticamente pelo Watchtower uma vez ao dia.

Para atualizar manualmente:

```bash
docker compose pull
docker compose up -d
```

## Detalhes do script init.sql

O script `init.sql` cria automaticamente:

1. Usuário e banco de dados para N8N
2. Usuário e banco de dados para Evolution API
3. Usuário `appuser` e banco de dados `appdb` para a aplicação
4. Tabelas `clientes` e `historico_conversas` no banco `appdb`
5. Índices para otimização de consultas
6. Permissões necessárias para o usuário `n8n` acessar o banco `appdb`

## Acesso ao banco da aplicação (appdb)

Para acessar o banco de dados da aplicação com N8N, utilize as seguintes configurações de conexão:

```
Host: postgres
Port: 5432
Database: appdb
User: n8n
Password: n8npass
```

## Solução de Problemas

### Verificar status dos containers
```bash
docker compose ps
```

### Ver logs
```bash
docker compose logs -f [nome_serviço]
```

### Reiniciar um serviço
```bash
docker compose restart [nome_serviço]
```

### Problemas de permissão no PostgreSQL
Se houver problemas com permissões no banco de dados, você pode executar:

```bash
docker compose exec postgres psql -U postgres -c "ALTER USER evolution CREATEDB;"
docker compose exec postgres psql -U postgres -c "ALTER USER n8n CREATEDB;"
docker compose exec postgres psql -U postgres -c "ALTER USER appuser CREATEDB;"
```

### Problemas com o Evolution API
Se o Evolution API não estiver se conectando ao PostgreSQL, verifique se o banco de dados está rodando e se o usuário tem as permissões corretas:

```bash
docker compose logs evolutionapi
docker compose exec postgres psql -U postgres -c "\du"
```

### Verificando acesso do N8N ao banco appdb
Para verificar se o N8N pode acessar o banco de dados da aplicação:

```bash
docker compose exec postgres psql -U postgres -c "SELECT grantee, privilege_type FROM information_schema.role_table_grants WHERE table_name='clientes' AND table_schema='public';"
```

## Configuração do Fuso Horário

O ambiente está configurado para usar o fuso horário `America/Sao_Paulo`. Para alterar, modifique os parâmetros:
- `GENERIC_TIMEZONE` no serviço n8n
- `TZ` no serviço watchtower