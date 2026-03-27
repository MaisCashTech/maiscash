# Fluxo do Extrato - Empréstimos Consignados GovBahia

> Documentação do fluxo completo de consulta, coleta, persistência e sincronização de extratos de empréstimos consignados dos servidores do Estado da Bahia.

## Visão Geral

O **Extrato** é o processo de consulta dos dados de empréstimos consignados de servidores públicos do Estado da Bahia. O sistema realiza scraping no portal GovBahia ConsigLog e distribui os dados para múltiplos serviços via message queues.

## Diagrama do Fluxo

```
┌───────────────────┐
│  Operador (UI)    │
│  Informa CPF no   │
│  Consig1 frontend │
│  Aba: Extrato de  │
│  Consignações     │
└────────┬──────────┘
         │ WebSocket
         ▼
┌───────────────────┐
│   Consig1MS       │
│  Publica CPF na   │
│  fila "extrato"   │
└────────┬──────────┘
         │ Artemis Queue
         ▼
┌─────────────────────┐
│ Consig1CollectorsMS │
│  Consome da fila    │
│  REST: GET /api/{cpf}│
└────────┬────────────┘
         │ HTTP
         ▼
┌───────────────────┐
│ Serviço Extrato   │  ← Python/Java, containers "extrato" (mct-main) e "extrato1-7" (mct-extrato)
│  1. Obtém token   │
│     do ConsigLog  │
│  2. Scrape HTML   │
│  3. Parse dados   │
│  4. Retorna JSON  │
│     GovBahia      │
└────────┬──────────┘
         │ JSON Response (GovBahia DTO)
         ▼
┌─────────────────────┐
│ Consig1CollectorsMS │
│  Envia para filas   │
└────┬───────────┬────┘
     │           │
     ▼           ▼
┌──────────┐  ┌──────────────┐
│ Consig1MS│  │ Fila         │
│ DATABASE │  │ op_extrato   │
│ _OPS_QUEUE│  │ (para        │
│          │  │ MaisCashPro) │
└────┬─────┘  └──────┬───────┘
     │               │
     ▼               ▼
┌──────────┐  ┌──────────────────┐
│ Consig1  │  │ MaisCashPro      │
│ DB       │  │ ExtratoServiceTask│
│(consig1) │  │ → GovBahiaProcessor│
│          │  │ → EmprestimoMgmt │
│          │  │   Service        │
└──────────┘  └──────────────────┘
```

## Componentes Envolvidos

| Componente | Responsabilidade | Container | Porta |
|------------|------------------|-----------|-------|
| **Consig1 Frontend** | UI para input do CPF | N/A (static) | consig1.com.br |
| **Consig1MS** | Orquestra requisição, persiste em consig1 DB, publica na fila op_extrato | Consig1MS | mct-main |
| **Consig1CollectorsMS** | Consome fila, chama serviço extrato via REST | Consig1CollectorsMS | mct-main |
| **Extrato** | Scraping do portal GovBahia ConsigLog | extrato (mct-main) + extrato1-7 (mct-extrato) | mct-main/mct-extrato |
| **Artemis** | Message broker | artemis | mct-main:61616 |
| **MaisCashPro** | Persistência final para operadores | maiscashpro-app-1 | mct-main:8080 |

## Filas do Artemis

| Fila | Producer | Consumer | Formato | Descrição |
|------|----------|----------|---------|-----------|
| `extrato` | Consig1MS | Consig1CollectorsMS | CPF string | Requisição de consulta |
| `DATABASE_OPERATIONS_QUEUE` | Consig1CollectorsMS | Consig1MS | GovBahia JSON | Persistência no Consig1 DB |
| `op_extrato` | Consig1MS | MaisCashPro | GovBahia JSON | Persistência no MaisCashPro DB |
| `op_extrato-ERROR` | MaisCashPro | Admin | GovBahia JSON | Mensagens com falha |

## Formato da Mensagem (GovBahia JSON)

```json
{
  "serverData": [
    {
      "name": "NOME DO SERVIDOR",
      "register": "871124417000000",
      "cpf": "18680496553",
      "service": "EMPRÉSTIMO - 1",
      "availableMargin": 0.00,
      "totalMargin": 3643.24
    }
  ],
  "statementOfConsignments": [
    {
      "consignee": "BANCO - DIGIO [1684]",
      "situation": "Deferida",
      "ade": 8789915,
      "service": "EMPRÉSTIMO - 1 - 5017",
      "numberOfInstallments": 120,
      "installmentsPaid": 3,
      "installmentValue": 507.12,
      "deferring": 1764558000000,
      "discharge": null,
      "lastDiscountDate": null,
      "lastInstallmentDate": null,
      "register": "871124417000000",
      "htmlRegister": "871124417000000",
      "availableMargin": 0.00,
      "totalMargin": 3643.24
    }
  ]
}
```

### Campos Importantes

**serverData** — Margens por tipo de serviço (do cabeçalho do extrato):
- `register`: matrícula do servidor
- `service`: tipo de serviço SEM código numérico (ex: "EMPRÉSTIMO - 1", "BENEFÍCIO - 1 - ASSISTENCIAL")
- **IMPORTANTE**: serverData SÓ contém entradas tipo "1" — não existem entradas para tipos 2, 3

**statementOfConsignments** — Empréstimos individuais:
- `register`: matrícula (deve fazer match com serverData.register)
- `service`: tipo de serviço COM código numérico (ex: "EMPRÉSTIMO - 2 - 5020", "EMPRÉSTIMO - 3 - 5015")
- `situation`: Deferida, Quitada, Cancelada, Liquidação (Transferido)
- Datas como timestamps em milissegundos

## Fluxo de Persistência Detalhado

### 1. Consig1MS (DatabaseOperationsService.java)

```
createUpdateDeleteGovBahia(originalMessage):
  1. Deserializa JSON → GovBahia
  2. Persiste/atualiza em gov_bahia_scraping_data (CPF como chave)
  3. Publica mensagem INTEIRA (sem filtro) na fila op_extrato
```

**Chave**: Consig1MS armazena o JSON completo e publica SEM nenhum filtro.

### 2. MaisCashPro (EmprestimoManagementService.java)

```
processGovBahiaData(govBahia):
  1. captureMargensAtuais() — salva margens anteriores para histórico
  2. deleteEmprestimos() — deleta TODOS os empréstimos do CPF
  3. persistEmprestimos() — para cada consignment:
     a. Normaliza o tipo de serviço (remove código 4+ dígitos)
     b. Busca serverData correspondente por register + categoria de serviço
     c. Se match → cria Emprestimo e persiste
     d. Se não match → skip (log DEBUG)
```

### Matching de Tipo de Serviço (saoServicosMesmoTipo)

O matching compara por **categoria base**, alinhado com `ExtratoService.isServiceMatch()`:

| Categoria | serverData | Consignment (match) |
|-----------|-----------|---------------------|
| EMPRÉSTIMO | "EMPRÉSTIMO - 1" | "EMPRÉSTIMO - 1 - 5017", "EMPRÉSTIMO - 2 - 5020", "EMPRÉSTIMO - 3 - 5015" |
| BENEFÍCIO ASSISTENCIAL | "BENEFÍCIO - 1 - ASSISTENCIAL" | "BENEFÍCIO - 1 - ASSISTENCIAL - 5041", "BENEFÍCIO - 2 - ASSISTENCIAL - 5055" |
| MENSALIDADE | "MENSALIDADE - 1 - ROTINA VALOR" | Qualquer MENSALIDADE |
| CREDCESTA SAQUE | "BENEFÍCIO - 1 - CREDCESTA SAQUE" | Qualquer CREDCESTA + SAQUE |
| CREDCESTA COMPRA | "BENEFÍCIO - CREDCESTA - COMPRA" | Qualquer CREDCESTA + COMPRA |

## Persistência em Dois Bancos

| Campo | Consig1 DB (consig1) | MaisCashPro DB (maiscashpro) |
|-------|---------------------|------------------------------|
| Tabela | `gov_bahia_scraping_data` | `emprestimo` |
| Formato | JSON completo (GovBahia) | Entidade relacional (1 row por consignment) |
| Chave | CPF | ID auto-increment |
| Filtro | Nenhum (armazena tudo) | Match register + categoria de serviço |
| Atualização | Sobrescreve JSON inteiro | Delete all + re-insert |

## Pontos de Atenção

- **Timeout**: Scraping pode demorar 1-4 minutos para CPFs com muitos registros
- **Retry**: Mensagens com falha no MaisCashPro vão para `op_extrato-ERROR`
- **Idempotência**: Re-consulta sobrescreve dados existentes (delete + insert)
- **Delay da fila**: ~30-60 segundos entre consulta no Consig1 e persistência no MaisCashPro
- **Dados históricos**: CPFs consultados antes de fixes precisam ser re-consultados para atualizar

## Bugs Conhecidos (Resolvidos)

### Service Type Matching (PR #40 — 2026-03-27)
- Tipos 2/3 eram descartados por matching estrito
- Fix: matching por categoria base em `saoServicosMesmoTipo()`

### Pendente: Datas -1 dia (timezone)
- Datas de deferimento no MaisCashPro são 1 dia antes do Consig1
- Causa provável: `java.util.Date` parseada sem timezone → `.toInstant()` converte em UTC → Hibernate persiste em UTC → frontend exibe sem ajuste

---

*Última atualização: 2026-03-27*
