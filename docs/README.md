# Documentação técnica — MaisCash

Guias de integração e operação do workspace MaisCashTech. As configurações
executáveis ficam nos repositórios dos serviços; este diretório explica como os
componentes se conectam e onde encontrar seus procedimentos.

## Arquitetura, desenvolvimento e operação

| Documento | Conteúdo |
|---|---|
| [Arquitetura](architecture.md) | Organização dos submódulos, dependências MaviPay/PostgreSQL/Redis, rede Docker e separação dos pipelines |
| [Setup de desenvolvimento](development-setup.md) | JDK 21 do MaviPay, PostgreSQL/Redis locais, variáveis de ambiente e testes |
| [Operação MaviPay e Redis](mavipay-redis-operations.md) | Recursos provisionados, jobs Jenkins, IDs de credenciais, primeiro deploy, persistência, backup e rotação |

O MaviPay possui base PostgreSQL e Redis provisionados, mas o backend ainda não
foi implantado. O domínio `https://mavipay.consig1.com.br` já tem certificado e
proxy configurados; responde 503 até o backend estar disponível. Credenciais
reais de WhatsApp/SMTP permanecem pendentes. O guia de operação registra o estado verificado e as evidências dos
builds Redis, sem expor senhas ou chaves.

## Autorização e segurança

| Documento | Conteúdo |
|---|---|
| [Autorização de empréstimos](emprestimos-authorization.md) | Papéis ADM/SUPERVISOR/OPERADOR, verificações frontend/backend e correções do Issue #38 |

## Fluxos de dados

| Documento | Conteúdo |
|---|---|
| [Fluxo do Extrato](../ai_docs/flows/extrato-flow.md) | Consulta de empréstimos GovBahia, coleta, persistência e sincronização |

## Manuais dos componentes

| Componente | Fonte |
|---|---|
| MaviPay | [Deploy](https://github.com/MaisCashTech/mavipay/blob/main/docs/DEPLOY.md) e [banco PostgreSQL](https://github.com/MaisCashTech/mavipay/blob/main/docs/DATABASE-PROVISIONING.md) |
| Redis | [Instalação via Jenkins e operação](https://github.com/MaisCashTech/redis/blob/main/README.md) |
| Infraestrutura existente | [DevOps](../infra/devops/README.md) |

Ao alterar banco, rede, credenciais ou pipelines, atualizar também este índice e o
guia de operação correspondente. Nunca incluir valores secretos em documentação.
