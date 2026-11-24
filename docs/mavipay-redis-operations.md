# Operação do MaviPay e Redis

Estado verificado em 24/11/2026. Este guia reúne a integração no workspace; os
procedimentos detalhados e a configuração executável permanecem nos repositórios
de cada componente.

## Recursos e situação

| Recurso | Situação |
|---|---|
| PostgreSQL | Base `mavipay` e usuário `mavipay_app` criados no `mct-main`; sem tabelas de aplicação, aguardando primeiro Flyway |
| Redis | Instalado e saudável, com instalação e reinstalação pelo Jenkins validadas |
| Credenciais Jenkins | `redis-password` e `maiscash-api-mobile-env` cadastradas |
| Backend MaviPay | Job criado; nenhum deploy disparado durante este provisionamento |
| WhatsApp/ChatGuru e SMTP | Valores reais de produção pendentes |
| HTTPS da API | `https://mavipay.consig1.com.br`, certificado e proxy NGINX configurados; HTTP 503 até o backend estar disponível |

## Jobs Jenkins

Usar exclusivamente o Jenkins MaisCashTech: **https://jenkins.consig1.com.br**.

| Job | Fonte | Função |
|---|---|---|
| [redis - install and deploy](https://jenkins.consig1.com.br/job/redis%20-%20install%20and%20deploy/) | `MaisCashTech/redis`, `*/main`, `Jenkinsfile` da raiz | Instalar/reinstalar Redis no `mct-main` |
| [mavipay - build and deploy](https://jenkins.consig1.com.br/job/mavipay%20-%20build%20and%20deploy/) | `MaisCashTech/mavipay`, `*/main`, `Jenkinsfile` da raiz | Build Docker de `api-mobile/` e deploy do backend |

Ambos utilizam agente `built-in`, credencial SSH `GitHub` para checkout e execução
manual, sem webhook ou agendamento configurado. Instalar Redis não dispara o job
do backend. O app Expo tem publicação separada via EAS.

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

O Secret file contém a conexão PostgreSQL, Redis e chaves JWT/AES/HMAC geradas para
o primeiro ambiente. As credenciais de ChatGuru e SMTP continuam vazias; cadastrar
o arquivo não torna esses fluxos operacionais.

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

## Antes do primeiro deploy MaviPay

1. Confirmar PostgreSQL e Redis acessíveis pela rede `consig1` e os valores do
   Secret file. As 20 migrations foram testadas em transação com ROLLBACK; o
   primeiro Flyway deve criar o histórico e as tabelas, sem aplicação manual dos SQLs.
2. Completar as credenciais reais de ChatGuru/WhatsApp e SMTP e validar o envio
   utilizado por cadastro e autenticação.
3. Confirmar o acesso a `https://mavipay.consig1.com.br`. O proxy para
   `127.0.0.1:7920` e o certificado já estão configurados; a resposta 503 antes do
   deploy é esperada. O endpoint é público, sem allowlist de IPs de escritório.
   Definir `EXPO_PUBLIC_API_URL=https://mavipay.consig1.com.br` no ambiente de
   publicação do app Expo; builds já publicados não são atualizados pelo NGINX.
4. Conferir a porta 7920 e executar o job MaviPay em janela acompanhada. Verificar
   health check, migrations e os fluxos de cadastro/login antes da liberação.

## HTTPS da API

O DNS A `mavipay.consig1.com.br` aponta para `193.123.104.25` (`mct-main`).
HTTP redireciona para HTTPS. O certificado Let's Encrypt foi emitido com validade
inicial até 22/02/2027. A renovação utiliza webroot `/var/lib/letsencrypt`, o timer
existente `snap.certbot.renew.timer` e hook de reload do NGINX. A simulação
`certbot renew --cert-name mavipay.consig1.com.br --dry-run` passou.

A configuração `infra/nginx/conf.d/mavipay.conf` pertence ao repositório DevOps.
O proxy encaminha para `127.0.0.1:7920` e converte falhas de conexão 502/504 em
HTTP 503 com JSON `{"status":"unavailable"}`. Isso não indica saúde do backend:
a API ainda precisa ser implantada, e `/actuator/health` deve passar a refletir
seu estado real após o primeiro deploy.

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
