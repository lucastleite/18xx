# Skill: Manipulação de Ações em Jogos 18xx

Comandos para manipular ações de jogos hotseat e online no projeto 18xx.

---

## Contexto

- **Jogos Hotseat**: Armazenados no `localStorage` do navegador
  - URL: `http://localhost:9292/hotseat/{game_id}`
  - Storage key: `{game_id}` (ex: `hs_pmucqxbf_1`)
  - Estrutura: `{ actions: [...], ... }`

- **Jogos Online**: Armazenados no banco de dados PostgreSQL
  - URL: `http://localhost:9292/game/{game_id}`
  - Tabela: `games` e `actions`

---

## Gatilhos

Quando o usuário pedir para:
- "remover ação X do jogo Y"
- "deletar action do jogo"
- "ver ações do jogo"
- "listar actions"
- "adicionar ação no jogo"
- "modificar ação"
- "undo ação"

---

## Fluxo de Perguntas

### 1. Identificar tipo de jogo

Se não for claro pelo contexto, perguntar:
> "É um jogo **hotseat** (local) ou **online** (banco de dados)?"

**Dicas para identificar:**
- URL com `/hotseat/` → hotseat
- URL com `/game/` seguido de número → online
- Game ID começando com `hs_` → hotseat
- Game ID numérico puro → online

### 2. Identificar o Game ID

Se não informado:
> "Qual o ID do jogo? (pode ser a URL completa ou só o ID)"

**Extrair ID da URL:**
- `http://localhost:9292/hotseat/hs_wietmrbg_1` → `hs_wietmrbg_1`
- `http://localhost:9292/game/12345` → `12345`

### 3. Identificar a ação

Quando remover/modificar ação, perguntar se necessário:
> "Quer remover pela **posição no array** (ex: ação 5 = `actions[5]`) ou pelo **ID da ação** (ex: ação com `id: 5`)?"

---

## Comandos - Jogos Hotseat (Console do Navegador)

### Listar todas as ações

```javascript
let game = JSON.parse(localStorage.getItem('GAME_ID'));
console.table(game.actions.map((a, i) => ({ index: i, id: a.id, type: a.type, entity: a.entity, ...a })));
```

### Ver uma ação específica

```javascript
let game = JSON.parse(localStorage.getItem('GAME_ID'));
// Por posição no array:
console.log(game.actions[POSICAO]);
// Por ID:
console.log(game.actions.find(a => a.id === ID));
```

### Remover ação por posição no array

```javascript
let game = JSON.parse(localStorage.getItem('GAME_ID'));
console.log('Removendo:', game.actions[POSICAO]);
game.actions.splice(POSICAO, 1);
localStorage.setItem('GAME_ID', JSON.stringify(game));
console.log('Removido! Recarregue a página (F5).');
```

### Remover ação por ID

```javascript
let game = JSON.parse(localStorage.getItem('GAME_ID'));
let idx = game.actions.findIndex(a => a.id === ID);
if (idx === -1) { console.log('Ação não encontrada!'); }
else {
  console.log('Removendo:', game.actions[idx]);
  game.actions.splice(idx, 1);
  localStorage.setItem('GAME_ID', JSON.stringify(game));
  console.log('Removido! Recarregue a página (F5).');
}
```

### Remover da posição X até o final

```javascript
let game = JSON.parse(localStorage.getItem('GAME_ID'));
let removed = game.actions.splice(POSICAO);
localStorage.setItem('GAME_ID', JSON.stringify(game));
console.log(`Removidas ${removed.length} ações (da ${POSICAO} até o final). Recarregue a página.`);
```

### Remover últimas N ações

```javascript
let game = JSON.parse(localStorage.getItem('GAME_ID'));
let removed = game.actions.splice(-N);
localStorage.setItem('GAME_ID', JSON.stringify(game));
console.log(`Removidas ${removed.length} ações. Recarregue a página.`);
```

### Ver últimas N ações

```javascript
let game = JSON.parse(localStorage.getItem('GAME_ID'));
console.table(game.actions.slice(-N).map((a, i) => ({ index: game.actions.length - N + i, id: a.id, type: a.type, entity: a.entity })));
```

### Adicionar ação manualmente

```javascript
let game = JSON.parse(localStorage.getItem('GAME_ID'));
game.actions.push({
  type: 'TIPO_DA_ACAO',
  entity: 'ENTIDADE',
  // outros campos conforme necessário
});
localStorage.setItem('GAME_ID', JSON.stringify(game));
console.log('Ação adicionada! Recarregue a página.');
```

### Modificar ação existente

```javascript
let game = JSON.parse(localStorage.getItem('GAME_ID'));
// Encontrar e modificar
game.actions[POSICAO].CAMPO = NOVO_VALOR;
localStorage.setItem('GAME_ID', JSON.stringify(game));
console.log('Modificado! Recarregue a página.');
```

### Exportar jogo para arquivo

```javascript
let game = JSON.parse(localStorage.getItem('GAME_ID'));
let blob = new Blob([JSON.stringify(game, null, 2)], {type: 'application/json'});
let a = document.createElement('a');
a.href = URL.createObjectURL(blob);
a.download = 'GAME_ID.json';
a.click();
```

### Importar jogo de arquivo (substituir)

```javascript
// Após carregar o JSON do arquivo:
localStorage.setItem('GAME_ID', JSON.stringify(gameData));
console.log('Importado! Recarregue a página.');
```

---

## Comandos - Jogos Online (Banco de Dados)

### Estrutura do banco

```sql
-- Tabela games: metadados do jogo
-- Tabela actions: cada ação é uma linha separada
-- Colunas relevantes: id mod(PK auto), game_id, action_id, action (JSONB), created_at, updated_at

-- Ver estrutura
\d games
\d actions
```

### Listar ações do jogo

```sql
SELECT id, action_id, action->>'type' as type, action->>'entity' as entity
FROM actions
WHERE game_id = GAME_ID
ORDER BY action_id;
```

### Ver ação específica

```sql
SELECT * FROM actions WHERE game_id = GAME_ID AND action_id = ACTION_ID;
```

### Comparar ações entre jogos (range de 5 antes a 5 depois)

Quando pedir para ver uma ação X de múltiplos jogos, sempre mostrar o range X-5 até X+5:

```sql
SELECT *
FROM actions 
WHERE game_id IN (GAME_ID_1, GAME_ID_2) AND action_id BETWEEN ACTION_ID-5 AND ACTION_ID+5
ORDER BY action_id, game_id;
```

### Remover ação por action_id

```sql
DELETE FROM actions WHERE game_id = GAME_ID AND action_id = ACTION_ID;
```

### Remover ações do action_id X em diante

```sql
DELETE FROM actions WHERE game_id = GAME_ID AND action_id >= ACTION_ID;
```

### Remover últimas N ações

```sql
DELETE FROM actions
WHERE game_id = GAME_ID
AND action_id IN (
  SELECT action_id FROM actions
  WHERE game_id = GAME_ID
  ORDER BY action_id DESC
  LIMIT N
);
```

### Ver última ação

```sql
SELECT * FROM actions
WHERE game_id = GAME_ID
ORDER BY action_id DESC
LIMIT 1;
```

### Contar ações do jogo

```sql
SELECT COUNT(*) FROM actions WHERE game_id = GAME_ID;
```

---

## Auto Routing

### Habilitar auto routing

```sql
UPDATE games SET settings = jsonb_set(settings, '{auto_routing}', 'true') WHERE id = GAME_ID;
```

### Desabilitar auto routing

```sql
UPDATE games SET settings = jsonb_set(settings, '{auto_routing}', 'false') WHERE id = GAME_ID;
```

### Verificar se auto routing está habilitado

```sql
SELECT id, settings->>'auto_routing' as auto_routing FROM games WHERE id = GAME_ID;
```

---

## Copiar Ações Entre Jogos

### Copiar range de ações de um jogo para outro (substituindo jogador)

Útil para sincronizar jogos clonados quando um avança mais que o outro.

**IMPORTANTE:** Antes de copiar, deletar ações existentes no destino a partir do action_id inicial:

```sql
-- 1. Deletar ações existentes no destino
DELETE FROM actions WHERE game_id = GAME_DESTINO AND action_id >= ACTION_INICIAL;

-- 2. Copiar ações substituindo jogador (ex: jogador 1 vira jogador 2)
INSERT INTO actions (game_id, action_id, action, user_id, created_at, updated_at)
SELECT 
  GAME_DESTINO as game_id,
  action_id,
  CASE 
    WHEN action->>'entity' = 'JOGADOR_ORIGEM' AND action->>'entity_type' = 'player'
    THEN jsonb_set(action, '{entity}', '"JOGADOR_DESTINO"')
    ELSE action
  END as action,
  CASE WHEN user_id = JOGADOR_ORIGEM THEN JOGADOR_DESTINO ELSE user_id END as user_id,
  created_at,
  updated_at
FROM actions
WHERE game_id = GAME_ORIGEM AND action_id BETWEEN ACTION_INICIAL AND ACTION_FINAL;
```

**Exemplo:** Copiar ações 139-226 do jogo 19 para jogo 12, trocando jogador 1 por 2:

```sql
DELETE FROM actions WHERE game_id = 12 AND action_id >= 139;

INSERT INTO actions (game_id, action_id, action, user_id, created_at, updated_at)
SELECT 
  12 as game_id,
  action_id,
  CASE 
    WHEN action->>'entity' = '1' AND action->>'entity_type' = 'player'
    THEN jsonb_set(action, '{entity}', '"2"')
    ELSE action
  END as action,
  CASE WHEN user_id = 1 THEN 2 ELSE user_id END as user_id,
  created_at,
  updated_at
FROM actions
WHERE game_id = 19 AND action_id BETWEEN 139 AND 226;
```

### Copiar ações sem substituir jogador

```sql
INSERT INTO actions (game_id, action_id, action, user_id, created_at, updated_at)
SELECT 
  GAME_DESTINO as game_id,
  action_id,
  action,
  user_id,
  created_at,
  updated_at
FROM actions
WHERE game_id = GAME_ORIGEM AND action_id BETWEEN ACTION_INICIAL AND ACTION_FINAL;
```

---

## Inserir Ações no Meio do Jogo

### Hotseat (Console do Navegador)

Inserir é simples: divide o array, coloca a nova ação, junta de novo.

```javascript
let game = JSON.parse(localStorage.getItem('GAME_ID'));
let posicao = POSICAO; // posição onde inserir (0-indexed)
let novaAcao = {
  type: 'TIPO_DA_ACAO',
  entity: 'ENTIDADE',
  // outros campos...
};

// Divide e insere
let antes = game.actions.slice(0, posicao);
let depois = game.actions.slice(posicao);
game.actions = [...antes, novaAcao, ...depois];

localStorage.setItem('GAME_ID', JSON.stringify(game));
console.log(`Ação inserida na posição ${posicao}. Recarregue a página.`);
```

**Nota:** No hotseat, a ordem do array determina a sequência de processamento. O `id` da ação não importa.

### Online (Banco de Dados - Railway/PostgreSQL)

**IMPORTANTE:** No PostgreSQL do Railway, só permite alterar 1 registro por vez devido a constraints de unique key. Por isso, para inserir uma ação no meio:

1. **Empurrar** todas as ações do ponto de inserção até o final, **de trás para frente** (para evitar conflito de action_id duplicado)
2. **Inserir** a nova ação na posição desejada, usando `created_at` e `updated_at` da ação anterior

#### Passo 1: Empurrar ações (de trás para frente, em batches de 100)

Se queremos inserir na posição 101 e o jogo tem 1000 ações:

```sql
-- Batch 1: ações 1000 a 901 → viram 1001 a 902
UPDATE actions SET action_id = action_id + 1 WHERE game_id = GAME_ID AND action_id = 1000;
UPDATE actions SET action_id = action_id + 1 WHERE game_id = GAME_ID AND action_id = 999;
-- ... continuar até 901

-- Batch 2: ações 900 a 801
UPDATE actions SET action_id = action_id + 1 WHERE game_id = GAME_ID AND action_id = 900;
-- ... continuar até 801

-- ... repetir até chegar em 101
UPDATE actions SET action_id = action_id + 1 WHERE game_id = GAME_ID AND action_id = 101;
```

**Script SQL para gerar os comandos (executar no psql ou DBeaver):**

```sql
-- Gera comandos UPDATE para empurrar ações de POSICAO até MAX_ACTION
-- Substitua GAME_ID, POSICAO_INSERIR e MAX_ACTION_ID

SELECT 'UPDATE actions SET action_id = action_id + 1 WHERE game_id = ' || GAME_ID || ' AND action_id = ' || action_id || ';'
FROM actions
WHERE game_id = GAME_ID AND action_id >= POSICAO_INSERIR
ORDER BY action_id DESC;
```

#### Passo 2: Inserir a nova ação

```sql
-- Pegar created_at e updated_at da ação anterior (POSICAO - 1)
SELECT created_at, updated_at FROM actions 
WHERE game_id = GAME_ID AND action_id = POSICAO_ANTERIOR;

-- Inserir a nova ação
INSERT INTO actions (game_id, action_id, action, created_at, updated_at)
VALUES (
  GAME_ID,
  POSICAO_INSERIR,
  '{"type": "TIPO", "entity": "ENTIDADE"}'::jsonb,
  'CREATED_AT_DA_ACAO_ANTERIOR',
  'UPDATED_AT_DA_ACAO_ANTERIOR'
);
```

#### Exemplo Completo: Inserir ação pass na posição 101 do jogo 5432

```sql
-- 1. Ver quantas ações tem
SELECT MAX(action_id) FROM actions WHERE game_id = 5432;
-- Digamos que retorne 500

-- 2. Gerar comandos de empurrar (copiar e executar o resultado)
SELECT 'UPDATE actions SET action_id = action_id + 1 WHERE game_id = 5432 AND action_id = ' || action_id || ';'
FROM actions
WHERE game_id = 5432 AND action_id >= 101
ORDER BY action_id DESC;

-- 3. Executar os UPDATEs gerados (de trás para frente!)

-- 4. Pegar timestamps da ação 100
SELECT created_at, updated_at FROM actions WHERE game_id = 5432 AND action_id = 100;

-- 5. Inserir a nova ação 101
INSERT INTO actions (game_id, action_id, action, created_at, updated_at)
VALUES (
  5432,
  101,
  '{"type": "pass", "entity": "PLAYER_NAME"}'::jsonb,
  '2024-01-15 10:30:00.000000',  -- valor do passo 4
  '2024-01-15 10:30:00.000000'   -- valor do passo 4
);
```

---

## Conexão com Banco de Dados Local

```bash
# Via Docker (se usando docker-compose)
docker exec -it 18xx_db_1 psql -U root -d db_18xx

# Ou direto se PostgreSQL local
psql -U root -d db_18xx
```

---

## Exemplos de Uso

### Exemplo 1: Remover ação de hotseat

```
Usuário: remove a ação 939 do jogo hs_wietmrbg_1
Kiro: É pela posição no array (ação 939 = actions[939]) ou pelo ID da ação (id: 939)?
Usuário: posição
Kiro: Cole isso no console do navegador:

let game = JSON.parse(localStorage.getItem('hs_wietmrbg_1'));
console.log('Removendo:', game.actions[939]);
game.actions.splice(939, 1);
localStorage.setItem('hs_wietmrbg_1', JSON.stringify(game));
console.log('Removido! Recarregue a página (F5).');
```

### Exemplo 2: Ver últimas ações

```
Usuário: mostra as últimas 5 ações do meu jogo hotseat hs_pmucqxbf_1
Kiro: Cole isso no console:

let game = JSON.parse(localStorage.getItem('hs_pmucqxbf_1'));
console.table(game.actions.slice(-5).map((a, i) => ({ index: game.actions.length - 5 + i, id: a.id, type: a.type, entity: a.entity })));
```

### Exemplo 3: Undo múltiplas ações

```
Usuário: remove da ação 100 até o final no jogo online 5432
Kiro: Execute no banco:

DELETE FROM actions WHERE game_id = 5432 AND action_id >= 100;
```

---

## Notas Importantes

1. **Sempre mostrar o que será removido antes de remover** (console.log da ação)
2. **Lembrar de recarregar a página** após modificações no localStorage
3. **Backup recomendado** antes de alterações grandes (exportar jogo)
4. **IDs vs Posições**: No hotseat, `actions[5]` é a 6ª ação (0-indexed). A ação com `id: 5` pode estar em qualquer posição.
5. **Online vs Hotseat**: Online processa pela `action_id` (ordem importa). Hotseat processa pela ordem do array (id não importa).

---

## Tipos de Ações Comuns (Frost 1831)

Quando o usuário pedir para inserir uma ação, verificar se o tipo está documentado abaixo. Se estiver, gerar o JSON diretamente. Se não, perguntar os campos necessários.

### pass - Passar a vez

```json
{"type": "pass", "entity": "PLAYER_NAME ou CORP_ID"}
```

**Contexto:** Stock Round (jogador passa), Operating Round (corp passa uma etapa).

### buy_shares - Comprar ações

```json
{"type": "buy_shares", "entity": "PLAYER_NAME", "shares": ["CORP_ID_N"], "percent": 10}
```

**Exemplo:** `{"type": "buy_shares", "entity": "Lucas", "shares": ["EC_1"], "percent": 10}`

**Nota:** O share ID é `CORP_ID_N` onde N é o número do share (0 = presidente, 1-9 = normais).

### sell_shares - Vender ações

```json
{"type": "sell_shares", "entity": "PLAYER_NAME", "shares": ["CORP_ID_N"], "percent": 10}
```

### par - Definir preço inicial (PAR)

```json
{"type": "par", "entity": "PLAYER_NAME", "corporation": "CORP_ID", "share_price": "PRICE"}
```

**Exemplo:** `{"type": "par", "entity": "Lucas", "corporation": "EC", "share_price": "80"}`

### lay_tile - Colocar tile

```json
{"type": "lay_tile", "entity": "CORP_ID", "hex": "HEX_ID", "tile": "TILE_NUMBER-ROTATION", "rotation": N}
```

**Exemplo:** `{"type": "lay_tile", "entity": "EC", "hex": "H5", "tile": "8-0", "rotation": 0}`

### place_token - Colocar token

```json
{"type": "place_token", "entity": "CORP_ID", "city": "HEX_ID-CITY_SLOT", "slot": N}
```

**Exemplo:** `{"type": "place_token", "entity": "EC", "city": "D7-0-0", "slot": 0}`

### run_routes - Rodar trens

```json
{"type": "run_routes", "entity": "CORP_ID", "routes": [
  {"train": "TRAIN_ID", "connections": [["HEX1", "HEX2"], ["HEX2", "HEX3"]], "hexes": ["HEX1", "HEX2", "HEX3"]}
]}
```

**Nota:** Estrutura complexa. Melhor copiar de uma ação similar no jogo.

### dividend - Dividendos

```json
{"type": "dividend", "entity": "CORP_ID", "kind": "payout"}
```

**Valores de kind:** `"payout"` (distribuir), `"withhold"` (reter), `"half"` (metade).

### buy_train - Comprar trem

```json
{"type": "buy_train", "entity": "CORP_ID", "train": "TRAIN_ID", "price": N}
```

**Exemplo:** `{"type": "buy_train", "entity": "EC", "train": "3-0", "price": 180}`

### choose - Escolher opção

```json
{"type": "choose", "entity": "ENTITY", "choice": "CHOICE_VALUE"}
```

**Exemplo (escolher facção):** `{"type": "choose", "entity": "Lucas", "choice": "TEC"}`

### bid - Dar lance em leilão

```json
{"type": "bid", "entity": "PLAYER_NAME", "company": "COMPANY_SYM", "price": N}
```

### message - Mensagem no chat

```json
{"type": "message", "entity": "PLAYER_NAME", "message": "texto"}
```

---

## Fluxo para Inserir Ação

Quando o usuário pedir para inserir uma ação:

1. **Identificar tipo de jogo** (hotseat ou online)
2. **Identificar game ID**
3. **Identificar posição** onde inserir
4. **Identificar tipo da ação** e campos necessários:
   - Se o tipo está documentado acima → gerar JSON diretamente
   - Se não → perguntar quais campos são necessários
5. **Gerar os comandos** apropriados (console JS ou SQL)

**Exemplo de conversa:**

```
Usuário: insere um pass do Lucas na posição 101 do jogo hs_abc123_1
Kiro: Cole isso no console:

let game = JSON.parse(localStorage.getItem('hs_abc123_1'));
let posicao = 101;
let novaAcao = {"type": "pass", "entity": "Lucas"};
let antes = game.actions.slice(0, posicao);
let depois = game.actions.slice(posicao);
game.actions = [...antes, novaAcao, ...depois];
localStorage.setItem('hs_abc123_1', JSON.stringify(game));
console.log('Ação inserida na posição 101. Recarregue a página.');
```

---

## Optional Rules (Frost 1831)

### Regras Opcionais Disponíveis

| Symbol | Nome | Descrição |
|--------|------|-----------|
| `parliamentary_intervention` | Parliamentary Intervention | 2ª corp do jogador deve apoiar pelo menos 1 facção diferente da 1ª |
| `tight_government` | Tight Government | Todas as regulações começam em Tight (R1-R4 = 2) |
| `extra_train` | Extra 3-Train | Adiciona um trem 3 extra (6 total em vez de 5) |
| `bank_only_endgame` | Bank Break Only | Jogo termina apenas quando banco quebra (D train não dispara fim) |

### Gatilhos

Quando o usuário pedir para:
- "adicionar regra opcional X no jogo Y"
- "remover optional rule do jogo"
- "ativar parliamentary intervention"
- "desativar tight government"
- "ver regras opcionais do jogo"

### Comandos - Jogos Hotseat (Console do Navegador)

#### Ver regras opcionais atuais

```javascript
let game = JSON.parse(localStorage.getItem('GAME_ID'));
console.log('Optional Rules:', game.settings.optional_rules);
```

#### Adicionar regra opcional

```javascript
let game = JSON.parse(localStorage.getItem('GAME_ID'));
let rule = 'RULE_SYMBOL'; // ex: 'parliamentary_intervention'
if (!game.settings.optional_rules.includes(rule)) {
  game.settings.optional_rules.push(rule);
  localStorage.setItem('GAME_ID', JSON.stringify(game));
  console.log(`Regra '${rule}' adicionada! Recarregue a página.`);
} else {
  console.log(`Regra '${rule}' já está ativa.`);
}
```

#### Remover regra opcional

```javascript
let game = JSON.parse(localStorage.getItem('GAME_ID'));
let rule = 'RULE_SYMBOL'; // ex: 'parliamentary_intervention'
let idx = game.settings.optional_rules.indexOf(rule);
if (idx !== -1) {
  game.settings.optional_rules.splice(idx, 1);
  localStorage.setItem('GAME_ID', JSON.stringify(game));
  console.log(`Regra '${rule}' removida! Recarregue a página.`);
} else {
  console.log(`Regra '${rule}' não está ativa.`);
}
```

### Comandos - Jogos Online (Banco de Dados)

#### Ver regras opcionais atuais

```sql
SELECT id, settings->'optional_rules' as optional_rules
FROM games
WHERE id = GAME_ID;
```

#### Adicionar regra opcional

```sql
UPDATE games
SET settings = jsonb_set(
  settings,
  '{optional_rules}',
  (settings->'optional_rules') || '["RULE_SYMBOL"]'::jsonb
)
WHERE id = GAME_ID
AND NOT (settings->'optional_rules' @> '["RULE_SYMBOL"]');
```

#### Remover regra opcional

```sql
UPDATE games
SET settings = jsonb_set(
  settings,
  '{optional_rules}',
  (settings->'optional_rules') - 'RULE_SYMBOL'
)
WHERE id = GAME_ID;
```

#### Substituir todas as regras opcionais

```sql
UPDATE games
SET settings = jsonb_set(
  settings,
  '{optional_rules}',
  '["rule1", "rule2"]'::jsonb
)
WHERE id = GAME_ID;
```

#### Limpar todas as regras opcionais

```sql
UPDATE games
SET settings = jsonb_set(settings, '{optional_rules}', '[]'::jsonb)
WHERE id = GAME_ID;
```

### Exemplos de Uso

#### Exemplo 1: Adicionar Parliamentary Intervention em hotseat

```
Usuário: adiciona parliamentary intervention no jogo hs_abc123_1
Kiro: Cole isso no console do navegador:

let game = JSON.parse(localStorage.getItem('hs_abc123_1'));
let rule = 'parliamentary_intervention';
if (!game.settings.optional_rules.includes(rule)) {
  game.settings.optional_rules.push(rule);
  localStorage.setItem('hs_abc123_1', JSON.stringify(game));
  console.log(`Regra '${rule}' adicionada! Recarregue a página.`);
} else {
  console.log(`Regra '${rule}' já está ativa.`);
}
```

#### Exemplo 2: Remover Tight Government de jogo online

```
Usuário: remove tight_government do jogo 5432
Kiro: Execute no banco:

UPDATE games
SET settings = jsonb_set(
  settings,
  '{optional_rules}',
  (settings->'optional_rules') - 'tight_government'
)
WHERE id = 5432;
```

#### Exemplo 3: Ver regras ativas em jogo online

```
Usuário: quais regras opcionais estão ativas no jogo 10?
Kiro: Execute no banco:

SELECT id, settings->'optional_rules' as optional_rules
FROM games
WHERE id = 10;
```

---

## Copiar Jogo Online (com Substituição de Jogadores)

Quando precisar copiar um jogo para outro ID, substituindo jogadores.

### Regras Importantes

1. **Limite de 100 registros por operação** - O Railway limita inserções/updates, então sempre fazer em batches de 100
2. **Ordem de ações importa** - Sempre usar `ORDER BY action_id` ao copiar
3. **Campos a atualizar**:
   - `user_id` na tabela `game_users`
   - `user_id` na tabela `actions`
   - `action->>'entity'` quando `entity_type = 'player'`
   - `settings->'player_order'` na tabela `games`
   - `acting` na tabela `games`

### Passo a Passo Completo

#### 1. Limpar dados existentes do jogo destino

```sql
DELETE FROM actions WHERE game_id = DEST_ID;
```

```sql
DELETE FROM game_users WHERE game_id = DEST_ID;
```

#### 2. Copiar game_users (com substituição de jogador)

```sql
INSERT INTO game_users (game_id, user_id, created_at, updated_at)
SELECT DEST_ID, CASE WHEN user_id = OLD_USER THEN NEW_USER ELSE user_id END, created_at, updated_at
FROM game_users WHERE game_id = SOURCE_ID;
```

#### 3. Copiar ações em batches de 100

**Primeiro batch (action_id 1 a 100):**

```sql
INSERT INTO actions (game_id, user_id, action_id, action, created_at, updated_at)
SELECT DEST_ID, CASE WHEN user_id = OLD_USER THEN NEW_USER ELSE user_id END, action_id, action, created_at, updated_at
FROM actions WHERE game_id = SOURCE_ID AND action_id >= 1 AND action_id <= 100
ORDER BY action_id;
```

```sql
UPDATE actions 
SET action = jsonb_set(action, '{entity}', to_jsonb(NEW_USER::text))
WHERE game_id = DEST_ID 
AND action->>'entity' = OLD_USER::text
AND action->>'entity_type' = 'player'
AND action_id >= 1 AND action_id <= 100;
```

**Segundo batch (action_id 101 a 200):**

```sql
INSERT INTO actions (game_id, user_id, action_id, action, created_at, updated_at)
SELECT DEST_ID, CASE WHEN user_id = OLD_USER THEN NEW_USER ELSE user_id END, action_id, action, created_at, updated_at
FROM actions WHERE game_id = SOURCE_ID AND action_id >= 101 AND action_id <= 200
ORDER BY action_id;
```

```sql
UPDATE actions 
SET action = jsonb_set(action, '{entity}', to_jsonb(NEW_USER::text))
WHERE game_id = DEST_ID 
AND action->>'entity' = OLD_USER::text
AND action->>'entity_type' = 'player'
AND action_id >= 101 AND action_id <= 200;
```

**Repetir para batches subsequentes (201-300, 301-400, etc.)**

#### 4. Atualizar player_order no settings

```sql
UPDATE games 
SET settings = jsonb_set(settings, '{player_order}', '[FIRST_USER, SECOND_USER]')
WHERE id = DEST_ID;
```

**Nota:** A ordem no array define quem joga primeiro. Verificar ordem original:

```sql
SELECT user_id, created_at FROM game_users WHERE game_id = SOURCE_ID ORDER BY created_at;
```

#### 5. Atualizar acting (quem é a vez)

```sql
UPDATE games SET acting = '{NEW_USER}' WHERE id = DEST_ID;
```

**Nota:** `acting` é `integer[]`, não jsonb.

### Exemplo Completo: Copiar jogo 19 → 12, jogador 1 → 2

```sql
-- 1. Limpar destino
DELETE FROM actions WHERE game_id = 12;
DELETE FROM game_users WHERE game_id = 12;

-- 2. Copiar game_users
INSERT INTO game_users (game_id, user_id, created_at, updated_at)
SELECT 12, CASE WHEN user_id = 1 THEN 2 ELSE user_id END, created_at, updated_at
FROM game_users WHERE game_id = 19;

-- 3. Copiar ações batch 1 (1-100)
INSERT INTO actions (game_id, user_id, action_id, action, created_at, updated_at)
SELECT 12, CASE WHEN user_id = 1 THEN 2 ELSE user_id END, action_id, action, created_at, updated_at
FROM actions WHERE game_id = 19 AND action_id >= 1 AND action_id <= 100
ORDER BY action_id;

UPDATE actions 
SET action = jsonb_set(action, '{entity}', '"2"')
WHERE game_id = 12 
AND action->>'entity' = '1'
AND action->>'entity_type' = 'player'
AND action_id >= 1 AND action_id <= 100;

-- 4. Copiar ações batch 2 (101-200)
INSERT INTO actions (game_id, user_id, action_id, action, created_at, updated_at)
SELECT 12, CASE WHEN user_id = 1 THEN 2 ELSE user_id END, action_id, action, created_at, updated_at
FROM actions WHERE game_id = 19 AND action_id >= 101 AND action_id <= 200
ORDER BY action_id;

UPDATE actions 
SET action = jsonb_set(action, '{entity}', '"2"')
WHERE game_id = 12 
AND action->>'entity' = '1'
AND action->>'entity_type' = 'player'
AND action_id >= 101 AND action_id <= 200;

-- 5. Setar player_order (jogo 19 tinha 6 primeiro, depois 1→2)
UPDATE games 
SET settings = jsonb_set(settings, '{player_order}', '[6, 2]')
WHERE id = 12;

-- 6. Atualizar acting se necessário
UPDATE games SET acting = '{6}' WHERE id = 12;
```

### Verificar Resultado

```sql
SELECT COUNT(*) FROM actions WHERE game_id = 12;
SELECT MAX(action_id) FROM actions WHERE game_id = 12;
SELECT user_id FROM game_users WHERE game_id = 12;
SELECT settings->'player_order', acting FROM games WHERE id = 12;
```

---

## Incrementar esta Skill

Quando o usuário pedir algo novo relacionado a manipulação de jogos que não esteja documentado aqui, adicionar o comando/procedimento a esta skill para referência futura.
