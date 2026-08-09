# Treino Diénert

Registro de treino A/B/C com persistência em `localStorage`. Página única, sem build e sem servidor — feita para abrir no celular na academia.

## O que faz

- **Treinos A, B e C** já cadastrados, com séries e repetições alvo.
- **Uma linha por série**: `−` `carga` `+` `✓`, com alvos de 38–58px de largura por 42px de altura. Os botões `−`/`+` (passo de 2,5kg) existem para você quase nunca precisar abrir o teclado.
- **Destaque "agora"** no primeiro exercício incompleto. Ao terminar um exercício ele se recolhe num resumo verde e a tela rola sozinha para o próximo.
- **Carga herdada**: ao marcar uma série, a carga da anterior é preenchida sozinha. O botão *"↺ Repetir as cargas da última vez"* preenche o exercício inteiro com o que você fez da última vez.
- **Descanso automático** (50s por padrão, ajustável em Ajustes): começa ao marcar uma série, com barra fixa mostrando a contagem, `Pular` e `+15s`.
- **Alarme impossível de perder**: tela cheia vermelha piscando, sirene de dois tons e o nome da próxima série. Fecha ao tocar ou sozinho em 15s. Há um botão *Testar* em Ajustes, com diagnóstico do que este aparelho suporta.
- **Tela acesa** durante o descanso, via Screen Wake Lock.
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

## Sobre o alarme (e o iPhone)

O alarme tem dois caminhos de som, de propósito:

1. **Um elemento `<audio>`** tocando um WAV de sirene gerado em tempo de execução (`makeAlarmClip`). É o caminho principal, porque **a chave lateral do iPhone no silencioso silencia o Web Audio no Safari, mas não silencia um `<audio>`**. O app também declara `navigator.audioSession.type = "playback"` quando disponível.
2. **Osciladores do Web Audio** agendados com antecedência (`osc.start(t)` com `t` no futuro) para a contagem 3-2-1 e o alarme. Como a agenda vive dentro do `AudioContext` e não em `setTimeout`, ela sobrevive ao estrangulamento de timers de JS quando o navegador vai para segundo plano.

Ambos só destravam dentro de um gesto do usuário. O clipe começa com 0,15s de silêncio justamente para o destravamento (`play()` seguido de `pause()` imediato) não deixar escapar nenhum ruído.

**O volume do alarme é o volume de mídia do aparelho** — se estiver baixo, o alarme fica baixo, mesmo com o toque alto.

### Vibração: não existe no iPhone

O Safari no iOS não implementa a Vibration API. Nenhuma página web consegue vibrar um iPhone — não é limitação deste app. A tela **Ajustes** mostra o que o seu aparelho de fato suporta. Em Android o app vibra normalmente.

### Tela bloqueada

Durante o descanso o app pede um Screen Wake Lock para a tela não apagar. Se você bloquear a tela na mão, o iOS suspende o áudio e o alarme é melhor-esforço.
