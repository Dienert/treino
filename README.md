# Treino Diénert

Registro de treino A/B/C com persistência em `localStorage`. Página única, sem build e sem servidor — feita para abrir no celular na academia.

## O que faz

- **Treinos A, B e C** já cadastrados, com séries e repetições alvo.
- **Uma linha por série**: campo de carga grande + botão ✓ de 60×42px, feito para ser acertado de primeira com a mão suada.
- **Destaque "agora"** no primeiro exercício incompleto. Ao terminar um exercício ele se recolhe num resumo verde e a tela rola sozinha para o próximo.
- **Carga herdada**: ao marcar uma série, a carga da anterior é preenchida sozinha. O botão *"↺ Repetir as cargas da última vez"* preenche o exercício inteiro com o que você fez da última vez.
- **Descanso automático** (50s por padrão, ajustável em Ajustes): começa ao marcar uma série, com barra fixa mostrando a contagem, `Pular` e `+15s`.
- **Alarme impossível de perder**: tela cheia vermelha piscando, sirene de dois tons por ~6s, vibração repetida e o nome da próxima série. Fecha ao tocar ou sozinho em 15s. Há um botão *Testar* em Ajustes.
- **Histórico** com total de treinos, treinos nos últimos 30 dias, volume acumulado e cada sessão expansível com as cargas.
- **Sugestão do próximo treino** no ciclo A → B → C, marcada com o selo *próximo* na aba.
- **Backup**: exportar/importar todo o histórico como `.json`.
- Tema claro/escuro/automático e registro retroativo (basta trocar a data no topo).

## Onde os dados ficam

Tudo fica no `localStorage` do navegador: os treinos na chave `treino-dienert:v1` e as preferências (descanso, tema) em `treino-dienert:prefs`. Nada é enviado para nenhum servidor.

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
- `bw:true` — exercício de peso corporal; o campo de carga mostra "livre".

O tempo de descanso se muda pela tela **Ajustes**, não no código.

## Sobre o alarme

O áudio só é liberado depois do primeiro toque na página — regra de autoplay do iOS/Android. Na prática ele já está pronto quando você marca a primeira série.

Os bipes são agendados dentro do `AudioContext` (`osc.start(t)` com `t` no futuro), e não por `setTimeout`. Isso importa porque navegadores estrangulam timers de JS em segundo plano, mas a agenda do Web Audio continua no horário certo. Ainda assim, o iOS *suspende* o `AudioContext` quando a tela é bloqueada — com a tela apagada o alarme é melhor-esforço, e a vibração cobre parte disso. Deixe a tela ligada durante o descanso.
