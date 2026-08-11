# Treino

Registro de treino com persistência em `localStorage`. Página única, sem build e sem servidor — feita para abrir no celular na academia.

Atende duas pessoas, cada uma com o seu plano e o seu histórico:

| Pessoa | Treinos |
|---|---|
| Diénert | A (peito · tríceps), B (costas · bíceps), C (pernas) |
| Cida | A (quadríceps · glúteos), B (costas · bíceps · abdômen), C (posterior · glúteos), D (peito · ombros · tríceps) |

## O que faz

- **Seletor de pessoa** no topo. Cada uma tem seus treinos, seu histórico, sua sugestão de próximo treino e suas cargas de "última vez" — nada se mistura.
- **Treinos já cadastrados**, com séries e repetições alvo.
- **Uma linha por série**: `−` `carga` `+` `✓`, com alvos de 38–58px de largura por 42px de altura. Os `−`/`+` andam de 2,5 em 2,5 kg.
- **Teclado numérico próprio**: tocar na carga abre uma folha na parte de baixo da tela com teclas grandes e atalhos (−2,5 / +2,5 / +5 / +10). Não existe `<input>` de texto na lista — veja *Por que um teclado próprio* abaixo.
- **Destaque "agora"** no primeiro exercício incompleto. Ao terminar um exercício ele se recolhe num resumo verde e a tela rola sozinha para o próximo.
- **Carga herdada na hora**: definiu o peso da série 1, as seguintes já aparecem com ele. Corrigir a série 1 corrige as herdadas junto; um peso que você digitou à mão numa série específica nunca é sobrescrito (a herança é marcada com `auto` no registro). O botão *"↺ Repetir as cargas da última vez"* preenche o exercício inteiro com o que você fez da última vez.
- **Descanso automático** (50s por padrão, ajustável em Ajustes): começa ao marcar uma série, com barra fixa mostrando a contagem, `Pular` e `+15s`.
- **Alarme impossível de perder**: tela cheia vermelha piscando, sirene de dois tons e o nome da próxima série. Fecha ao tocar ou sozinho em 15s. Há um botão *Testar* em Ajustes, com diagnóstico do que este aparelho suporta.
- **Tela acesa** durante o descanso, via Screen Wake Lock.
- **Histórico** com total de treinos, treinos nos últimos 30 dias, volume acumulado e cada sessão expansível com as cargas.
- **Sugestão do próximo treino** no ciclo (A → B → C, ou A → B → C → D para a Cida), marcada com o selo *próximo* na aba.
- **Backup**: exportar/importar todo o histórico como `.json`.
- Tema claro/escuro/automático e registro retroativo (basta trocar a data no topo).

## Onde os dados ficam

Tudo fica no `localStorage` do navegador: os treinos na chave `treino-dienert:v1` e as preferências (descanso, tema) em `treino-dienert:prefs`. Nada é enviado para nenhum servidor.

Consequência prática: os dados são **por navegador e por dispositivo**. Trocou de celular ou limpou os dados do site, o histórico vai junto — use *Exportar backup* de vez em quando.

## Rodar localmente

Abra o `index.html` no navegador. Não precisa de servidor nem de dependências.

## Publicar no GitHub Pages

Com o repositório no GitHub, ative em **Settings → Pages → Source: Deploy from a branch → `main` / `/ (root)`**. O site fica em `https://<usuario>.github.io/<repo>/`.

## Editar os planos

Tudo fica na constante `PESSOAS`, no início do `<script>` do `index.html`:

```js
const PESSOAS = {
  dienert: { nome:"Diénert", planos:{
    A: { short:"Peito · Tríceps", ex:[
      { id:"a2", name:"Supino reto halteres pegada neutra", sets:3, reps:"12" },
      …
```

- `id` — identificador estável; é a chave do histórico e precisa ser **único entre todas as pessoas**. **Não mude o `id` de um exercício existente**, senão o histórico dele se perde. Os do Diénert são `a1…c8`, os da Cida `ca1…cd6`.
- `short` — rótulo da aba. Cabem ~15 caracteres com 3 treinos e ~10 com 4.
- `sets` / `reps` — alvo mostrado no card. `reps` é texto livre, então faixas como `"10–12"` funcionam (o cálculo de volume usa a ponta de baixo).
- `unit:"s"` — mede em segundos em vez de kg (ex.: prancha).
- `bw:true` — exercício de peso corporal; o campo mostra "livre" e some os `−`/`+`.

Adicionar uma terceira pessoa é só acrescentar uma entrada em `PESSOAS`; o seletor no topo e o número de abas se ajustam sozinhos.

### Formato do armazenamento

As sessões são gravadas em `db.sessions`, com chave `data|pessoa|treino`. A versão original do app, de quando só havia um plano, usava `data|treino` — a função `migrar()` converte essas chaves na primeira abertura e marca as sessões antigas como do Diénert, sem perder nada.

O tempo de descanso se muda pela tela **Ajustes**, não no código.

## Por que um teclado próprio

O Safari do iPhone dá zoom ao focar um campo de texto, e o zoom empurrava o botão `✓` para fora da tela. A receita conhecida — `font-size` de no mínimo 16px — **não resolveu**: o campo estava com 17px e o zoom continuou.

Em vez de continuar tentando adivinhar o gatilho, a lista simplesmente não tem mais nenhum `<input>`. A carga é um `<button>` que abre uma folha com teclado próprio. Sem campo de texto não há foco, não há teclado nativo e o zoom fica impossível por construção. De quebra, o teclado do sistema também não cobre mais metade da tela.

O único `<input>` que sobrou é o seletor de data no topo, que abre um seletor de roda e não um teclado.

## Sobre o alarme (e o iPhone)

O alarme é **um elemento `<audio>`** tocando um WAV de sirene gerado em tempo de execução (`makeAlarmClip`), destravado no primeiro toque na tela. O clipe começa com 0,15s de silêncio de propósito: o destravamento faz `play()` seguido de `pause()` imediato, e assim não escapa ruído nenhum.

**Não há Web Audio aqui, e isso é deliberado.** No iOS, só instanciar um `AudioContext` já toma a sessão de áudio e **para** o que estiver tocando no Spotify.

### Convivendo com o Spotify

Quem decide isso é `navigator.audioSession.type`, em *Ajustes → Com música tocando*:

| Modo | `type` | O que acontece |
|---|---|---|
| Alarme acima de tudo *(padrão)* | `playback` | Sempre toca; a música para e não volta |
| Pausar e retomar | `transient-solo` | Deveria tocar e devolver a música |
| Só abaixar | `transient` | Deveria abaixar a música e tocar por cima |

**Testado num iPhone com iOS 26: só `playback` emite som.** Nos outros dois o Safari aceita o `play()` e a sessão de áudio é tomada — o Spotify pausa — mas nada é audível. Por isso o padrão é `playback`, apesar de interromper a música: alarme que não toca não serve para nada. Os outros modos seguem disponíveis porque funcionam em Android e o comportamento do iOS pode mudar.

A sirene dura 8s e some antes se você tocar na tela, para encurtar a interrupção.

Fora do alarme a sessão fica em `ambient`, que não toma o áudio de ninguém. O tipo é declarado **imediatamente antes do `play()`** (o iOS aplica a categoria quando a reprodução começa) e devolvido para `ambient` quando o alarme para. Se o `play()` for recusado no modo escolhido, há um fallback automático para `playback`.

**O volume do alarme é o volume de mídia do aparelho** — se estiver baixo, o alarme fica baixo, mesmo com o toque alto.

### Tela bloqueada: o alarme não toca, e não tem como

Com a tela bloqueada ou o Safari em segundo plano, o iOS congela os timers de JS e suspende o áudio da página. **Nenhum site consegue tocar som ou emitir alerta de fora dele** — não é limitação deste app, é como a plataforma funciona. Notificação local agendada também não existe para web no iOS.

O que dá para fazer, e está feito:

- durante o descanso o app pede um **Screen Wake Lock**, então a tela não apaga sozinha — deixe o celular destravado e o alarme toca normalmente;
- se você bloquear na mão, ao voltar ao app o relógio é recalculado pelo horário real e **o alarme dispara na hora**, atrasado mas dispara.

A tela **Ajustes** mostra o estado real do wake lock e do áudio no seu aparelho.

### Vibração: não existe no iPhone

O Safari no iOS não implementa a Vibration API. Nenhuma página web consegue vibrar um iPhone. Em Android o app vibra normalmente.
