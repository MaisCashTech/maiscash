# Setup de desenvolvimento

O workspace utiliza Git submodules. Faça clone recursivo ou inicialize os
submódulos necessários após atualizar o checkout:

```sh
git submodule update --init --recursive services/mavipay
```

`infra/redis` é adicionado pela [PR #6](https://github.com/MaisCashTech/maiscash/pull/6).
Depois de integrá-la, inicialize-o com `git submodule update --init infra/redis`.
Não é necessário executar seu Jenkinsfile para desenvolver localmente.

## MaviPay: backend

Pré-requisitos: JDK 21, Docker com Compose e acesso ao repositório privado.
Os outros serviços podem utilizar JDK 17; selecione o JDK conforme o projeto.

```sh
cd services/mavipay/api-mobile
test -f .env || cp .env.example .env
docker compose up -d postgres redis
```

O Compose de desenvolvimento cria PostgreSQL 16 com base `maiscash_dev` e Redis 7.
Esses recursos são locais; não use a base de produção ou seu Secret file no
ambiente de desenvolvimento. Confira se as portas locais 5432 e 6379 estão livres.

Ajuste o `.env` com as configurações locais. Defina `JWT_SECRET` com uma chave
aleatória válida de pelo menos 256 bits; o valor ilustrativo não é uma chave de
produção. Para gerar uma chave local, utilize `openssl rand -base64 48`. Configure
as integrações necessárias ao fluxo que deseja testar.

Para executar pelo Maven, exporte as variáveis no shell: o Maven não importa
automaticamente o `.env`. O arquivo deve conter atribuições compatíveis com shell;
não carregue arquivos recebidos de fontes não confiáveis.

```sh
set -a
. ./.env
set +a
./mvnw spring-boot:run
```

No processo Java executado no host, `DATABASE_URL` aponta para
`jdbc:postgresql://localhost:5432/maiscash_dev` e `REDIS_HOST=localhost`, conforme o
exemplo local. No container de produção, os endereços são diferentes; consulte
[operação](mavipay-redis-operations.md).

As migrations Flyway criam e atualizam as tabelas ao iniciar o backend. Não
execute os scripts administrativos de criação do banco contra uma base existente.

## Testes e aplicativo móvel

```sh
cd services/mavipay/api-mobile
./mvnw test
```

Execute a partir da raiz do workspace ou ajuste o `cd` se já estiver na subpasta.
As suítes que utilizam Testcontainers precisam de Docker disponível. Os scripts
genéricos do monorepo procuram `mvnw` na raiz de cada serviço e não descobrem
automaticamente `services/mavipay/api-mobile`; use os comandos nessa subpasta.

Para o app Expo, consulte o próprio projeto `services/mavipay/maiscash-app` e sua
configuração de EAS. O job Jenkins do backend não publica o aplicativo nas lojas.

## Documentação dos projetos

- [Deploy MaviPay](https://github.com/MaisCashTech/mavipay/blob/main/docs/DEPLOY.md).
- [Provisionamento PostgreSQL](https://github.com/MaisCashTech/mavipay/blob/main/docs/DATABASE-PROVISIONING.md).
- [Instalação e operação Redis](https://github.com/MaisCashTech/redis/blob/main/README.md).
