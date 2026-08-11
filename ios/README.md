# Treino — App nativo iOS (SwiftUI)

Porta nativa do site `index.html` para iOS, feita em **SwiftUI + ActivityKit**.
Mesma lógica (pessoas, planos A–D, herança de carga, sugestão do ciclo,
histórico, backup `.json`) e o que só o nativo entrega:

- **Áudio por cima do Spotify** — `AVAudioSession` com `.duckOthers + .mixWithOthers`: abaixa a música e toca a sirene por cima, sem parar de tocar (ajustável em Ajustes → *Com música tocando*).
- **Alarme com a tela bloqueada** — notificação local `interruptionLevel = .timeSensitive`, que dispara travada e atravessa o Modo Foco.
- **Live Activity na Dynamic Island** — a contagem do descanso na ilha e na tela de bloqueio, sem abrir o app.
- **Haptics de verdade** — `UINotificationFeedbackGenerator(.warning)` no alarme, impacto ao marcar série.
- **Tela acesa no descanso** — `isIdleTimerDisabled` enquanto o cronômetro roda.
- **Áudio em segundo plano** — modo de fundo `audio` declarado para a sirene.

O histórico é gravado em JSON no mesmo formato do backup do site — dá para
**importar o seu `.json`** direto e continuar de onde parou (Ajustes → *Importar backup*).

---

## Pré-requisitos

- Um **Mac** com **Xcode 15 ou superior** (App Store).
- Um **iPhone com iOS 16.1+** (a Dynamic Island é do 14 Pro/Pro Max pra cima; o
  resto funciona em qualquer iPhone com iOS 16.1).
- Seu **Apple ID** normal — não precisa pagar os US$ 99. (Sem o Developer Program
  o app expira a cada 7 dias e precisa ser reinstalado pelo Xcode.)

## Abrir e rodar (5 passos)

1. **Abra o projeto**: `ios/Treino.xcodeproj` (duplo-clique).

2. **Assine com o seu Apple ID**: selecione o alvo **Treino** → aba
   **Signing & Capabilities** → marque *Automatically manage signing* → em *Team*,
   escolha o seu Apple ID (adicione em *Add an Account…* se não aparecer).
   Repita no alvo **TreinoWidget**.

3. **Bundle IDs únicos**: o Xcode pode reclamar que `com.dienert.treino` já existe.
   Se reclamar, troque por algo seu, mantendo o par:
   - App: `com.SEUNOME.treino`
   - Widget: `com.SEUNOME.treino.TreinoWidget`

4. **App Group** (necessário para o widget): nos **dois** alvos, em
   *Signing & Capabilities*, confirme a capability **App Groups** com o grupo
   `group.com.dienert.treino`. Se você mudou o bundle prefix no passo 3, crie/ative
   o grupo `group.com.SEUNOME.treino` nos dois alvos **e** atualize a constante em
   `Treino/AppConfig.swift` e os dois arquivos `.entitlements`.

   > As capabilities **Push Notifications** e **Time Sensitive Notifications** já
   > vêm declaradas nos entitlements; o Xcode as registra ao assinar.

5. **Conecte o iPhone pelo cabo**, escolha-o na barra de destino do Xcode e aperte
   **▶︎ Run**. Na primeira vez o iPhone pede para confiar no desenvolvedor em
   *Ajustes → Geral → Gerenciamento de VPN e Dispositivo*.

Ao abrir pela primeira vez o app pede permissão de **Notificações** — aceite, é o
que faz o alarme tocar com a tela bloqueada.

## Testando o alarme

- Ajustes → **Alarme → Testar**: dispara a tela cheia + sirene + haptic na hora.
- Com o **Spotify tocando**, troque o modo em *Com música tocando* e teste: em
  **Só abaixar** a música baixa e a sirene entra por cima; ao fim, volta.
- Para o **alarme de fundo**: comece um descanso, **bloqueie a tela** e espere —
  a notificação time-sensitive dispara travada. A Live Activity aparece na ilha /
  tela de bloqueio durante a contagem.

## Estrutura

```
ios/
  Treino.xcodeproj           # projeto pronto (dois alvos)
  project.yml                # fallback XcodeGen (veja abaixo)
  Treino/                    # alvo do app
    TreinoApp.swift          # entrada
    AppConfig.swift          # App Group id (compartilhado)
    Models/                  # Exercise, Session, DB, Store (lógica portada do site)
    Theme/Theme.swift        # paleta clara/escura das variáveis CSS
    Audio/                   # AVAudioSession, notificações, cronômetro/alarme
    LiveActivity/            # RestAttributes (compartilhado) + controller
    Views/                   # UI SwiftUI (treino, histórico, ajustes, alarme, teclado…)
    Assets.xcassets          # ícone + accent color
    Info.plist, *.entitlements
  TreinoWidget/              # alvo da extensão (Live Activity)
    TreinoWidgetBundle.swift, RestLiveActivity.swift
    Info.plist, *.entitlements
```

## Se o projeto não abrir / precisar recriar

O `.xcodeproj` foi montado à mão (dois alvos). Se algo destoar da sua versão do
Xcode, dá para regenerá-lo do zero a partir do `project.yml`:

```bash
brew install xcodegen
cd ios
xcodegen generate      # reescreve Treino.xcodeproj
```

Depois é só reabrir e refazer os passos 2–4 (Team e App Group).

## O que ainda precisa de você

- Rodar o `xcode-select --install` / instalar o Xcode (interativo e pesado).
- Conectar o iPhone e assinar com o seu Team no primeiro build.

O ícone atual é um placeholder (halter branco em fundo azul) — troque em
`Assets.xcassets/AppIcon` quando quiser.

## Notas de plataforma

- **Cronômetro em segundo plano**: quem garante o disparo com a tela bloqueada é a
  *notificação time-sensitive* agendada no início do descanso — o iOS não mantém
  timers de JS/Swift vivos travado sem áudio contínuo. A Live Activity mostra a
  contagem; a notificação faz o alarme.
- **Live Activity**: precisa estar ligada em *Ajustes do iOS → Treino → Atividades ao vivo*.
  Em iPhones sem Dynamic Island ela aparece na tela de bloqueio.
- Os dados ficam **só no aparelho** (container do app / App Group). Exporte o
  backup de vez em quando.
