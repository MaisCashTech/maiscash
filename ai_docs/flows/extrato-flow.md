# Fluxo do Extrato - Empréstimos Consignados GovBahia

> Documentação do fluxo de consulta de extratos de empréstimos consignados dos servidores do Estado da Bahia.

## Visão Geral

O **Extrato** é o processo de consulta dos dados de empréstimos consignados de servidores públicos do Estado da Bahia. O sistema realiza scraping no portal GovBahia e distribui os dados para múltiplos serviços via message queues.

## Diagrama do Fluxo

```
┌─────────────────┐
│  Usuário Web    │
│  (consig1 UI)   │
│  Informa CPF    │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   Consig1MS     │
│  Recebe request │
│  via WebSocket  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Artemis Queue  │
│   (extrato)     │
└────────┬────────┘
         │
         ▼
┌─────────────────────┐
│ Consig1CollectorsMS │
│  Consome da fila    │
│  Chama REST API     │
└────────┬────────────┘
         │
         ▼
┌─────────────────┐
│ Serviço Extrato │
│   (scraping)    │
│   GovBahia      │
└────────┬────────┘
         │
         ▼ JSON Response
┌─────────────────────────┐
│   Publicação em Filas   │
├─────────────────────────┤
│                         │
│  ┌─────────────────┐    │
│  │ Fila Consig1MS  │────┼──► Salva em tabelas Consig1MS
│  └─────────────────┘    │
│                         │
│  ┌─────────────────┐    │
│  │ Fila op_extrato │────┼──► Salva em tabelas MaisCashPro
│  │   (MaisCashPro) │    │
│  └─────────────────┘    │
│                         │
└─────────────────────────┘
```

## Componentes Envolvidos

| Componente | Responsabilidade | Tecnologia |
|------------|------------------|------------|
| **consig1** | Interface web para input do CPF | Angular |
| **Consig1MS** | Orquestra requisição, publica na fila | Java/Spring Boot |
| **Artemis** | Message broker | Apache ActiveMQ Artemis |
| **Consig1CollectorsMS** | Consome fila, chama serviço extrato | Java/Spring Boot |
| **Serviço Extrato** | Scraping do portal GovBahia | Python/FastAPI (presumido) |
| **MaisCashPro** | Persistência final dos dados | Java/Spring Boot |

## Filas do Artemis

| Fila | Producer | Consumer | Descrição |
|------|----------|----------|-----------|
| `extrato` | Consig1MS | Consig1CollectorsMS | Requisição de consulta |
| `op_extrato` | Consig1CollectorsMS | MaisCashPro | Dados para persistência |
| `op_extrato-ERROR` | Sistema | Admin | Mensagens com falha |

## Dados do Extrato

O JSON retornado pelo scraping contém informações sobre:

- Dados do servidor (CPF, nome, matrícula)
- Empréstimos ativos (valor, parcelas, taxa)
- Margem disponível para novos empréstimos
- Histórico de consignações

## Persistência

Os dados são salvos em **duas bases diferentes**:

1. **Consig1MS**: Dados operacionais para processamento
2. **MaisCashPro**: Dados consolidados para gestão comercial

Isso permite que cada sistema trabalhe com os dados de forma independente, respeitando seus domínios específicos.

## Pontos de Atenção

- **Timeout**: O scraping pode demorar devido à lentidão do portal GovBahia
- **Retry**: Mensagens com falha vão para fila de erro
- **Idempotência**: Consultas repetidas devem atualizar dados existentes
- **Compliance**: Dados sensíveis (CPF) devem seguir LGPD

## Serviços Relacionados

- `services/Consig1MS/` - Orquestrador principal
- `services/Consig1CollectorsMS/` - Collectors e integração
- `services/MaisCashPro/` - Backend principal
- `common/extrato/` - Serviço de scraping (submodule)

---

*Última atualização: 2025-11-22*
