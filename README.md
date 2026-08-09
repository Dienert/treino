# Treino Diénert

Registro de treino A/B/C com persistência em `localStorage`. Página única, sem build e sem servidor — feita para abrir no celular na academia.

## O que faz

- **Treinos A, B e C** já cadastrados, com séries e repetições alvo.
- **Marcar série por série** e anotar a carga (kg) de cada uma.
- **Descanso automático de 50s**: ao marcar uma série o cronômetro começa sozinho e dispara um alarme sonoro + vibração no fim. Toque no cronômetro para cancelar.
- **"Última vez"**: mostra as cargas usadas na última vez que você fez aquele exercício, para saber se dá pra subir.
- **Sugestão do próximo treino** seguindo o ciclo A → B → C a partir do último treino concluído (ponto azul na aba).
- **Histórico** com data, séries feitas, cargas e volume acumulado.
- **Backup**: exportar/importar todo o histórico como `.json`.
- Tema claro/escuro e registro retroativo (basta trocar a data).

## Onde os dados ficam

Tudo fica no `localStorage` do navegador, na chave `treino-dienert:v1`. Nada é enviado para nenhum servidor.

Consequência prática: os dados são **por navegador e por dispositivo**. Trocou de celular ou limpou os dados do site, o histórico vai junto — use *Exportar backup* de vez em quando.

## Rodar localmente

Abra o `index.html` no navegador. Não precisa de servidor nem de dependências.

## Publicar no GitHub Pages

Com o repositório no GitHub, ative em **Settings → Pages → Source: Deploy from a branch → `main` / `/ (root)`**. O site fica em `https://<usuario>.github.io/<repo>/`.

## Editar o plano de treino

Os exercícios ficam na constante `PLAN`, no início do `<script>` do `index.html`:

```js
{ id:"a2", name:"Supino reto halteres pegada neutra", sets:3, reps:"12" }
```

- `id` — identificador estável; é a chave do histórico. **Não mude o `id` de um exercício existente**, senão o histórico dele se perde.
- `sets` / `reps` — alvo mostrado no card.
- `unit:"s"` — mede em segundos em vez de kg (ex.: prancha).
- `bw:true` — exercício de peso corporal; o campo de carga vira opcional.

Para mudar o tempo de descanso, ajuste `REST_SECONDS`.
