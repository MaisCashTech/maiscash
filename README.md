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
└── docs/              # Documentação consolidada
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

## 🔧 Tecnologias

- **Backend**: Java 17, Spring Boot, JHipster, Apache Artemis
- **Frontend**: Angular 18, TypeScript, Material Design
- **Database**: PostgreSQL
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