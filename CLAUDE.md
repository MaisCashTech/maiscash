# CLAUDE.md - MaisCash Workspace

Este arquivo fornece orientações ao Claude Code (claude.ai/code) ao trabalhar com o workspace unificado da MaisCashTech.

## 📁 Estrutura do Workspace (Git Submodules)

Este repositório utiliza **Git Submodules** para organizar todos os projetos da MaisCashTech:

### 🚀 Services (Microserviços Backend)
- **MaisCashPro** - Aplicação principal JHipster (Spring Boot + Angular)
- **Consig1MS** - Microserviço core de consulta de empréstimos consignados
- **Consig1CollectorsMS** - Serviço de coleta de dados
- **Consig1ExportMS** - Serviço de exportação
- **Consig1ImportMS** - Serviço de importação
- **AuthorizationMS** - Serviço de autorização
- **UserMS** - Gerenciamento de usuários
- **extrato** - Serviço de consulta a dados de funcionários públicos da Bahia

### 🎨 Frontend (Aplicações Web)
- **MaiscashPro-Frontend** - Interface Angular standalone com componentes avançados
- **consig1-dashboard** - Dashboard de monitoramento

### 📚 Common (Bibliotecas Compartilhadas)
- **consig1** - Módulos compartilhados (CommonBusinessMS, CommonDbMS, CommonRestMS, ModelConsig1, CommonOAuthMS)
- **asteba** - Integrações específicas com ASTEBA

### 🗄️ Legacy (Projetos Legados)
- **consig1-angular** - Interface Angular legada
- **consig1-secrets** - Configurações e secrets

## 🛠️ Comandos de Gestão do Workspace

### Inicialização do Workspace
```bash
# Clonar o workspace completo com todos os submodules
git clone --recursive git@github.com:MaisCashTech/maiscash.git

# Ou se já clonou sem --recursive
git submodule update --init --recursive
```

### Atualização de Todos os Projetos
```bash
# Script automatizado (recomendado)
./scripts/pull-all.sh

# Comando manual
git submodule update --remote --merge
```

### Trabalhando com Submodules
```bash
# Entrar em um submodule e trabalhar normalmente
cd services/Consig1MS
git checkout main
git pull
# ... fazer alterações ...
git commit -m "suas alterações"
git push

# Voltar ao workspace principal e confirmar as mudanças
cd ../..
git add services/Consig1MS
git commit -m "update: Consig1MS to latest version"
git push
```

## 📋 Fluxo de Desenvolvimento

### Para Mudanças em um Único Projeto:
1. `cd services/NomeDoProjeto`
2. Trabalhe normalmente (branch, commits, push)
3. `cd ../..` (volta ao workspace)
4. `git add services/NomeDoProjeto`
5. `git commit -m "update: NomeDoProjeto"`

### Para Mudanças Cross-Project:
1. Use os scripts em `./scripts/` para operações em lote
2. Sempre teste em ambiente de desenvolvimento primeiro
3. Coordene mudanças interdependentes

## 🔧 Stack Tecnológica Unificada

- **Backend**: Java 17, Spring Boot 3.3.1, JHipster 8.6.0
- **Frontend**: Angular 18, TypeScript 5.4.5, Angular Material, DevExtreme
- **Gateway**: Spring Cloud Gateway
- **Message Queue**: Apache Artemis
- **Database**: PostgreSQL
- **Build**: Maven (Backend), npm (Frontend)
- **Containers**: Docker + Docker Compose

## ⚠️ Regras Importantes

### 🔥 POLÍTICA DE SCRIPTS SQL OBRIGATÓRIA
Sempre que criar um script SQL de atualização em qualquer microserviço:
1. **Crie o script de update**: `database/updates/YYYY-MM-DD-descricao.sql`
2. **OBRIGATORIAMENTE atualize o script original**: `database/2-Tables.postgres.sql`
3. **Mantenha consistência** entre scripts de update e criação

### 🧪 FLUXO DE DESENVOLVIMENTO OBRIGATÓRIO
1. **SEMPRE execute testes antes de commit**:
   ```bash
   ./mvnw clean verify
   ./mvnw checkstyle:check
   ./npmw test (se frontend modificado)
   ```

2. **NUNCA faça commit** com testes falhando
3. **SEMPRE corrija** todos os erros antes de commitar

## 🚀 Comandos Rápidos por Projeto

### MaisCashPro (Principal)
```bash
cd services/MaisCashPro
./mvnw                    # Backend (8080)
./npmw start              # Frontend (9000)
npm run watch             # Ambos concorrentemente
```

### Microserviços
```bash
cd services/[NomeDoMS]
./mvnw spring-boot:run    # Executar individualmente
```

### Frontend Standalone
```bash
cd frontend/MaiscashPro-Frontend
ng serve                  # Servidor de desenvolvimento
ng build                 # Build de produção
```

## 📞 Domínio de Negócio

**Função Principal**: Sistema de consulta de empréstimos consignados para funcionários do estado da Bahia
- **Consultas por CPF**: Interface "Pesquisa por CPF" para consulta de empréstimos
- **Processamento via Mensagens**: Sistema assíncrono usando Apache Artemis
- **Integração Externa**: Conexão direta com sistemas de folha de pagamento da Bahia
- **Processamento em Tempo Real**: Coleta e processamento assíncrono de dados

## 🏗️ Padrões Arquiteturais

- **API Gateway Pattern**: Spring Cloud Gateway roteia requisições
- **Message-Driven Architecture**: Apache Artemis para comunicação assíncrona
- **Microservices Architecture**: Serviços independentes e especializados
- **Domain-Driven Design**: Separação clara entre consulta de empréstimos e funções de apoio

---

**Este workspace centraliza todos os projetos MaisCashTech em uma estrutura organizada e versionada.**