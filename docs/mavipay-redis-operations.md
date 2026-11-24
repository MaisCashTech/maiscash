# Operação do MaviPay e Redis

Estado verificado em 24/11/2026. Este guia reúne a integração no workspace; os
procedimentos detalhados e a configuração executável permanecem nos repositórios
de cada componente.

## Recursos e situação

| Recurso | Situação |
|---|---|
| PostgreSQL | Base `mavipay`, usuário `mavipay_app` e 20 migrations Flyway aplicadas com sucesso |
| Redis | Instalado e saudável, com instalação e reinstalação pelo Jenkins validadas |
| Credenciais Jenkins | `redis-password` e `maiscash-api-mobile-env` cadastradas |
| Backend MaviPay | Implantado pelo build #3; health HTTPS 200/UP e endpoint protegido 401 sem token |
| WhatsApp/ChatGuru e SMTP | ChatGuru configurado; SMTP opcional para WhatsApp, pendente para alternativa por e-mail |
| HTTPS da API | `https://mavipay.consig1.com.br`, TLS válido e health check HTTP 200/UP |

## Jobs Jenkins

Usar exclusivamente o Jenkins MaisCashTech: **https://jenkins.consig1.com.br**.

| Job | Fonte | Função |
|---|---|---|
| [redis - install and deploy](https://jenkins.consig1.com.br/job/redis%20-%20install%20and%20deploy/) | `MaisCashTech/redis`, `*/main`, `Jenkinsfile` da raiz | Instalar/reinstalar Redis no `mct-main` |
| [mavipay - build and deploy](https://jenkins.consig1.com.br/job/mavipay%20-%20build%20and%20deploy/) | `MaisCashTech/mavipay`, `*/main`, `Jenkinsfile` da raiz | Build Docker de `api-mobile/` e deploy do backend |

Ambos utilizam agente `built-in` e credencial SSH `GitHub` para checkout. Redis
permanece manual, sem webhook ou agendamento. MaviPay tem GitHubPushTrigger ativo
e webhook de push para `https://jenkins.consig1.com.br/github-webhook/`, com TLS
verificado e ping entregue com HTTP 200. O job foi restaurado para `*/main` após
o primeiro deploy. Não há cron; novos commits na main são detectados pelo SCM.

A [PR MaviPay #26](https://github.com/MaisCashTech/mavipay/pull/26) versiona o
trigger e corrige a variável opcional `EXTRA_NETWORK` omitida pelo Jenkins quando
vazia. O deploy inicial bem-sucedido usou a branch dessa correção (commit
`9be8b9c`); mesclar a PR antes dos próximos deploys da main. O build #1 compilou,
mas abortou antes de criar container pela variável ausente; o #2 falhou ao buscar
um SHA com checkout lightweight. O #3 aplicou as migrations e passou no health.

O webhook não aguarda GitHub Actions: gates devem estar na proteção de branch.
Instalar Redis não dispara o job do backend. O app Expo tem publicação separada via EAS.

Redis: [build #1](https://jenkins.consig1.com.br/job/redis%20-%20install%20and%20deploy/1/)
e [build #2](https://jenkins.consig1.com.br/job/redis%20-%20install%20and%20deploy/2/)
concluídos com SUCCESS. Foram verificados PING autenticado, rejeição sem senha,
TTL/GETDEL, persistência após restart e ausência de portas publicadas no host.

## Credenciais

| ID | Tipo | Conteúdo e responsabilidade |
|---|---|---|
| `GitHub` | SSH Username with private key | Credencial existente de checkout |
| `redis-password` | Secret text | Senha Redis, 64 caracteres hexadecimais |
| `maiscash-api-mobile-env` | Secret file | Variáveis de produção do backend |

O Secret file contém PostgreSQL, Redis, chaves JWT/AES/HMAC e os dados ChatGuru
fornecidos em arquivo pelo usuário. `CHATGURU_CODE_DIALOG_ID` foi mantido vazio;
a implementação utiliza texto livre nesse caso. Não foi enviado WhatsApp real.

SMTP permanece sem credenciais. O código implementa a alternativa por e-mail,
inclusive a opção “Usar e-mail” no app, mas o fluxo WhatsApp não depende de SMTP
e o health check de mail é desabilitado em prod. Não anunciar o canal de e-mail
como operacional antes de configurá-lo ou desabilitá-lo no produto.

| Variável | Valor de integração, sem segredos |
|---|---|
| `DATABASE_URL` | `jdbc:postgresql://172.19.0.1:5432/mavipay` |
| `DATABASE_USERNAME` | `mavipay_app` |
| `REDIS_HOST` / `REDIS_PORT` | `redis` / `6379` |
| `SPRING_PROFILES_ACTIVE` | `prod` |
| `CONSIG_API_URL` | `http://maiscashpro-app-1:8080` |

O gateway `172.19.0.1` foi obtido da rede Docker `consig1`; valide-o em outras
instalações. `localhost` dentro do container da API não alcança o banco ou Redis.
A senha Redis no Secret file foi conferida com o Secret text `redis-password`.

Cópias protegidas no `mct-main`: `/etc/mavipay/production.env` (configuração do
backend) e `/etc/mavipay/database.env` (somente banco), arquivos root:root 0600,
diretório 0700. Não versionar, imprimir em logs ou incluir em PRs. Preserve as
chaves AES/HMAC após entrada de dados; substituí-las afeta os CPFs já armazenados.

## Primeiro deploy e próximos testes

[Build #3](https://jenkins.consig1.com.br/job/mavipay%20-%20build%20and%20deploy/3/)
concluído com SUCCESS. Verificações realizadas sem criar usuários ou enviar mensagens:

- `GET /actuator/health`: HTTPS 200, status UP.
- `GET /api/v1/users/me` sem token: 401.
- Preflight CORS: 200 com os métodos esperados.
- Flyway: 20 migrations com success=true, última versão V20.
- Container `MaisCashApiMobile`: imagem `maiscashapimobile:3`, bind apenas em
  `127.0.0.1:7920` para a porta interna 8080.

Próximos testes exigem usuário/destinatário autorizado: cadastro WhatsApp, emissão
e validação do código, login e consulta de margem. SMTP não bloqueia esse roteiro;
o canal alternativo por e-mail permanece indisponível. Não foram validadas ofertas
bancárias reais nem efetuados envios ChatGuru durante o provisionamento.

Definir `EXPO_PUBLIC_API_URL=https://mavipay.consig1.com.br` no ambiente de publicação
do app Expo; a configuração do NGINX não atualiza builds móveis já publicados.
Atualizações de Secret file requerem build manual/recriação do container.

## HTTPS da API

O DNS A `mavipay.consig1.com.br` aponta para `193.123.104.25` (`mct-main`).
HTTP redireciona para HTTPS. O certificado Let's Encrypt foi emitido com validade
inicial até 22/02/2027. A renovação utiliza webroot `/var/lib/letsencrypt`, o timer
existente `snap.certbot.renew.timer` e hook de reload do NGINX. A simulação
`certbot renew --cert-name mavipay.consig1.com.br --dry-run` passou.

A configuração `infra/nginx/conf.d/mavipay.conf` pertence ao repositório DevOps.
O proxy encaminha para `127.0.0.1:7920` e converte falhas de conexão 502/504 em
HTTP 503 com JSON `{"status":"unavailable"}`. Isso não indica saúde do backend:
essa resposta é esperada somente quando o upstream estiver indisponível. Após
o primeiro deploy, `/actuator/health` passou a retornar HTTP 200/UP.

A configuração aplicada e o manual `infra/nginx/MAVIPAY.md` estão no submódulo
DevOps, incorporados pela [PR #6](https://github.com/MaisCashTech/devops/pull/6)
já mesclada. O ponteiro do monorepo inclui essa configuração.
Não é necessário NGINX ou certificado para o Redis, que continua interno.

## Operação do Redis

Container `redis`, volume de dados `maiscash_redis_data`, rede `consig1`. Dados com
AOF (`everysec`) e snapshots RDB; sem porta publicada no host. O health check usa
senha lida da configuração protegida, sem registrá-la no comando do container.

```sh
ssh mct-main 'docker inspect redis --format "{{.State.Health.Status}}"'
ssh mct-main 'docker inspect redis --format "{{json .HostConfig.PortBindings}}"'
ssh mct-main 'docker stats --no-stream redis'
ssh mct-main 'docker logs --tail 50 redis'
```

O resultado esperado de portas é `{}`. Não adicionar Redis ao NGINX nem abrir a
porta 6379 publicamente. Há autenticação, mas não TLS entre containers do mesmo
host. A política `noeviction` protege os registros temporários contra expulsão por
pressão de memória; no limite, novas escritas falham. Monitorar memória e disco.

Para reinstalar a mesma versão, usar o job Redis; ele mantém o volume de dados e
recupera o container anterior se a troca falhar. `redis_previous` remanescente
bloqueia novas execuções e exige investigação. Não iniciar dois servidores no
mesmo volume. Para mudança de versão, revisar compatibilidade RDB/AOF e fazer
backup antes do build; rollback do container não desfaz alterações no disco.

A persistência é local, sem backup externo agendado ou alta disponibilidade.
Antes de copiar o volume, realizar parada coordenada para obter uma cópia
consistente e preservar todo o diretório AOF. Nunca executar limpeza indiscriminada
de volumes. Procedimento completo no [manual Redis](https://github.com/MaisCashTech/redis/blob/main/README.md).

Rotação exige coordenação: atualizar `redis-password`, reinstalar Redis, atualizar
`REDIS_PASSWORD` no Secret file e recriar o backend. Há uma janela de
incompatibilidade; planejar manutenção e preservar as chaves de criptografia.

## Referências e integração no Git

- [Repositório Redis e manual](https://github.com/MaisCashTech/redis).
- [Deploy MaviPay](https://github.com/MaisCashTech/mavipay/blob/main/docs/DEPLOY.md).
- [Provisionamento PostgreSQL](https://github.com/MaisCashTech/mavipay/blob/main/docs/DATABASE-PROVISIONING.md).
- [PR monorepo #5](https://github.com/MaisCashTech/maiscash/pull/5): ponteiro MaviPay com provisionamento PostgreSQL.
- [PR monorepo #6](https://github.com/MaisCashTech/maiscash/pull/6): submódulo Redis e índice da raiz.
- [PR MaviPay #24](https://github.com/MaisCashTech/mavipay/pull/24): atualização dos manuais após instalação Redis.

Os PRs de integração não executam deploy por si mesmos. Quando novas mudanças
forem mescladas nos repositórios de serviços, atualizar os gitlinks do monorepo
para disponibilizar os mesmos arquivos em clones recursivos.
