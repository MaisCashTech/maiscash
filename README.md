# 🏦 MaisCash Workspace

Workspace unificado da **MaisCashTech** contendo todos os projetos e microserviços organizados via Git Submodules.

## 🚀 Quick Start

```bash
# 1. Clone com todos os submodules
git clone --recursive git@github.com:MaisCashTech/maiscash.git
cd maiscash

# 2. Execute script de setup inicial
./scripts/setup-workspace.sh

# 3. Inicie todos os serviços
./scripts/start-all.sh
```

## 📁 Estrutura

```
maiscash/
├── services/           # Microserviços Backend
│   ├── MaisCashPro/           # App principal (JHipster)
│   ├── Consig1MS/             # Core - consultas consignado
│   ├── Consig1CollectorsMS/   # Coleta de dados
│   ├── mavipay/               # Backend api-mobile (Java 21) e app Expo
│   ├── extrato/               # Consulta funcionários BA
│   └── ...
├── frontend/           # Aplicações Frontend
│   ├── MaiscashPro-Frontend/  # Angular standalone
│   └── consig1-dashboard/     # Dashboard
├── common/             # Bibliotecas compartilhadas
│   ├── consig1/               # Módulos comuns
│   └── asteba/                # Integrações ASTEBA
├── legacy/             # Projetos legados
├── scripts/            # Scripts de automação
└── docs/               # Documentação consolidada
```

## 🛠️ Scripts Disponíveis

| Script | Descrição |
|--------|-----------|
| `./scripts/pull-all.sh` | Atualiza todos os submodules |
| `./scripts/build-all.sh` | Compila todos os projetos |
| `./scripts/start-all.sh` | Inicia todos os serviços |
| `./scripts/test-all.sh` | Executa todos os testes |

## 📚 Documentação

- [CLAUDE.md](./CLAUDE.md) - Guia completo para Claude Code
- [Arquitetura](./docs/architecture.md) - Visão geral da arquitetura
- [Setup Desenvolvimento](./docs/development-setup.md) - Configuração do ambiente
- [Infra & DevOps](./infra/devops/README.md) - Jenkins, Nginx, Artemis, Postgres, Metabase

## 🔄 CI/CD

Jenkins MaisCash: **https://jenkins.consig1.com.br** — credenciais e padrões em [`infra/devops/infra/jenkins/`](./infra/devops/infra/jenkins/).

### MaviPay

O submódulo [`services/mavipay`](https://github.com/MaisCashTech/mavipay) contém
`api-mobile/` (backend Java 21) e `maiscash-app/` (Expo). O Jenkins compila apenas
`api-mobile/`, usando o `Jenkinsfile` da raiz e JDK 21 dentro do Docker.

- Job: [mavipay - build and deploy](https://jenkins.consig1.com.br/job/mavipay%20-%20build%20and%20deploy/).
- Setup, credenciais e operação: `services/mavipay/docs/DEPLOY.md`.
- Desenvolvimento: `cd services/mavipay/api-mobile && ./mvnw test` (JDK 21).
- Os scripts genéricos do workspace procuram Maven na raiz de cada serviço;
  execute o backend nesta subpasta ou use o job dedicado.
- A base PostgreSQL `mavipay` está provisionada no `mct-main`. As credenciais
  `maiscash-api-mobile-env` e `redis-password` estão cadastradas no Jenkins.
- Redis tem instalação dedicada em `infra/redis`, descrita abaixo. WhatsApp/SMTP
  ainda precisam de credenciais reais no Secret file antes de validar o login.
- A API usa `127.0.0.1:7920` no host; a publicação HTTPS requer a definição do
  domínio e certificado no NGINX. Instalar Redis não dispara o deploy do backend.

### Redis

O submódulo [`infra/redis`](https://github.com/MaisCashTech/redis) contém apenas
`README.md` e `Jenkinsfile`. A instalação é executada pelo job
[redis - install and deploy](https://jenkins.consig1.com.br/job/redis%20-%20install%20and%20deploy/)
no agente `built-in` do Jenkins MaisCashTech.

- Container `redis`, rede interna `consig1`, porta 6379 sem publicação no host.
- Senha na credencial Secret text `redis-password`, compartilhada com a variável
  `REDIS_PASSWORD` do Secret file `maiscash-api-mobile-env`.
- Dados no volume Docker `maiscash_redis_data`, com AOF e autenticação obrigatória.
- Versão da imagem fixada por digest; validação de saúde e recuperação do container
  anterior em falhas de instalação. Builds manuais e serializados.
- Manual de instalação, limites, backup e rotação: `infra/redis/README.md`.
- Redis atende inicialmente ao MaviPay; não altera os serviços existentes.

## 🔧 Tecnologias

- **Backend**: Java 17, Spring Boot, JHipster, Apache Artemis
- **Frontend**: Angular 18, TypeScript, Material Design
- **Database**: PostgreSQL
- **Redis**: autenticação temporária, limites de tentativas e cache do MaviPay
- **Build**: Maven, npm
- **Containers**: Docker, Docker Compose

## 🏗️ Arquitetura

Sistema de **empréstimos consignados** para funcionários do estado da Bahia:

- **Gateway**: Spring Cloud Gateway
- **Microserviços**: Processamento distribuído
- **Message Queue**: Apache Artemis para comunicação assíncrona
- **Frontend**: Angular para interfaces web

## 🤝 Contribuição

1. Clone o workspace: `git clone --recursive ...`
2. Crie uma branch: `git checkout -b feature/nova-funcionalidade`
3. Faça suas alterações nos submodules apropriados
4. Execute testes: `./scripts/test-all.sh`
5. Commit e push: siga as convenções de commit de cada projeto
6. Atualize o workspace principal: `git add . && git commit -m "update: submodules"`

## 📞 Suporte

Para dúvidas sobre a arquitetura ou configuração, consulte:
- [CLAUDE.md](./CLAUDE.md) para orientações técnicas
- Issues nos repositórios específicos de cada projeto
- Documentação em `./docs/`

---

**MaisCashTech** - Soluções financeiras para o setor público 🏛️
