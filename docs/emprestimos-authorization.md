# Autorização de Empréstimos por Papel de Usuário

Documentação do fluxo de autorização do menu "Empréstimos" (`/loans-per-operator`), que exibe linhas de crédito agrupadas por operador. Cada papel de usuário tem acesso a um subconjunto diferente dos dados.

---

## Papeis de Usuário

| Papel | Identificação | Escopo de Acesso |
|-------|---------------|-----------------|
| ADM | `sessionStorage.operatorId === 'admin'` | Todos os operadores do sistema |
| SUPERVISOR | `Equipe.supervisor.id === operador.id` | Apenas os operadores da sua equipe |
| OPERADOR | qualquer outro caso | Apenas seus próprios empréstimos |

> O campo `operatorId` é gravado no `sessionStorage` no momento do login. O valor literal `'admin'` indica o papel de ADM; qualquer valor numérico identifica um operador ou supervisor.

---

## Fluxo de Determinacao de Papel (Frontend)

O componente `LoansPerOperator` (`lpo.component.ts`) determina o papel do usuário logado no `ngOnInit`:

```
ngOnInit
├── operatorId === 'admin'
│   └── isAdmin = true → loadAllOperators()
│
└── operatorId != 'admin'
    └── getCurrentOperator() [GET /api/custom-operadors/me]
        ├── operator.equipe existe
        │   └── GET /api/equipes/{equipe.id}
        │       ├── equipe.supervisor.id === operator.id
        │       │   └── isSupervisor = true → loadTeamOperators()
        │       └── nao e supervisor
        │           └── loadSingleOperator(operator)
        └── operator.equipe nao existe
            └── loadSingleOperator(operator)
```

### Metodos de carregamento de operadores

| Metodo | Endpoint chamado | Resultado |
|--------|-----------------|-----------|
| `loadAllOperators()` | `GET /api/custom-operadors/all` | Lista todos os operadores |
| `loadTeamOperators()` | `GET /api/custom-operadors/equipe` | Lista operadores da equipe do supervisor |
| `loadSingleOperator(operator)` | (sem chamada adicional) | Lista com apenas o operador logado |

---

## Verificacao de Seguranca no Backend

O metodo `buscarEmprestimosComSeguranca(List<Long> operadorIds)` em `CustomEmprestimoService` replica a logica de autorizacao no servidor, evitando que um cliente malicioso acesse dados de outros operadores.

```
buscarEmprestimosComSeguranca(operadorIds)
├── Obtem login do usuario autenticado (SecurityUtils)
│
├── ROLE_ADMIN
│   └── Retorna emprestimos de todos os operadorIds solicitados
│
├── login nao e numero → AccessDeniedException
│   ("Login do usuario nao corresponde a um operador valido")
│
├── operadorIds contem o proprio ID do operador
│   └── Retorna seus proprios emprestimos
│
├── operador e supervisor da sua equipe
│   └── Retorna emprestimos dos operadorIds solicitados
│
└── nenhuma condicao satisfeita → AccessDeniedException
    ("Acesso negado aos emprestimos deste operador")
```

**Arquivo:** `services/MaisCashPro/src/main/java/br/com/maiscashtech/maiscashpro/service/CustomEmprestimoService.java:47-85`

### Por que o login e um numero?

No MaisCashPro, o campo `username` do usuario JWT e preenchido com o **ID numerico** do `Operador`. O unico caso em que o login nao e numerico e para o papel ADM (identificado pela role `ROLE_ADMIN` no token), que e tratado antes da conversao numerica.

---

## Relacionamento entre Entidades

```
Operador (N) ───── (1) Equipe
Equipe (1) ─────── (1) Operador [supervisor]
Cliente (1) ─────── (N) Emprestimo
Emprestimo (N) ──── (1) Operador [via Cliente]
```

O vinculo entre `Emprestimo` e `Operador` passa pela entidade `Cliente`: cada `Cliente` pertence a um `Operador`, e cada `Emprestimo` pertence a um `Cliente`. Para buscar emprestimos de um operador, a query usa `cliente.operador.id`.

**Repositorio relevante:** `CustomEmprestimoRepository.findEmprestimosByOperadorIds(List<Long> operadorIds)`

---

## Problema Corrigido - Issue #38

O menu "Empréstimos" nao carregava para usuarios com papel OPERADOR. Quatro causas foram identificadas e corrigidas:

### 1. `fetch()` nativo fora do NgZone

**Problema:** O componente usava `fetch()` nativo para chamar `/api/equipes/{id}`. Como o `ChangeDetectionStrategy.OnPush` so dispara quando o Angular detecta mudancas, e o callback do `fetch()` roda fora da NgZone, a tela nunca era atualizada para usuarios OPERADOR.

**Correcao:** Substituicao de todas as chamadas `fetch()` por `HttpClient` do Angular, que automaticamente opera dentro da NgZone e dispara a deteccao de mudancas.

```typescript
// Antes (problematico)
fetch(`https://maiscashpro-backend.consig1.com.br/api/equipes/${operator.equipe.id}`, ...)
  .then(res => res.json())
  .then(equipe => { /* nunca atualizava a view */ });

// Depois (correto)
this.http.get<any>(`/api/equipes/${operator.equipe.id}`).subscribe({
  next: equipeCompleta => {
    // Angular detecta mudancas corretamente
  }
});
```

**Arquivo:** `frontend/MaiscashPro-Frontend/src/app/pages/loans-per-operator/lpo.component.ts:198`

### 2. URLs hardcoded de producao

**Problema:** URLs absolutas como `https://maiscashpro-backend.consig1.com.br/api/...` falhavam em ambientes de desenvolvimento e causavam erros CORS.

**Correcao:** Substituicao por URLs relativas (`/api/...`), que funcionam em qualquer ambiente pois o servidor Angular faz proxy para o backend configurado.

### 3. Tratamento silencioso de erros

**Problema:** Quando o backend retornava 403 ou 500, o handler de erro apenas ocultava o spinner sem notificar o usuario.

**Correcao:** Adicao de notificacoes via `MatSnackBar` para informar o usuario quando uma operacao falha.

```typescript
// Depois (correto)
error => {
  this.proccessing = false;
  this.changeDetectorRef.detectChanges();
  this.snackBar.open('Erro ao buscar emprestimos. Tente novamente.', 'Fechar', {
    duration: 5000
  });
}
```

**Arquivo:** `frontend/MaiscashPro-Frontend/src/app/pages/loans-per-operator/lpo.component.ts:396-404`

### 4. `NumberFormatException` no backend

**Problema:** `Long.parseLong(login)` lancava excecao nao tratada quando o login nao era um numero valido, resultando em erro 500 generico.

**Correcao:** Envolvimento em `try-catch` com lancamento de `AccessDeniedException` para retornar 403 com mensagem clara.

```java
// Depois (correto)
try {
    operadorId = Long.parseLong(login);
} catch (NumberFormatException e) {
    log.error("Login do usuario nao e um ID numerico valido: {}", login);
    throw new AccessDeniedException("Login do usuario nao corresponde a um operador valido: " + login);
}
```

**Arquivo:** `services/MaisCashPro/src/main/java/br/com/maiscashtech/maiscashpro/service/CustomEmprestimoService.java:58-63`

---

## Arquivos Relacionados

| Arquivo | Responsabilidade |
|---------|-----------------|
| `frontend/.../loans-per-operator/lpo.component.ts` | Determinacao de papel e carregamento de operadores |
| `frontend/.../services/operator.service.ts` | Chamadas REST para endpoints de operadores |
| `services/MaisCashPro/.../service/CustomEmprestimoService.java` | Verificacao de seguranca e busca de emprestimos |
| `services/MaisCashPro/.../web/rest/CustomEmprestimoResource.java` | Endpoint REST que delega para `CustomEmprestimoService` |

---

*Ultima atualizacao: 2026-03-13*
