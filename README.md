# AngelUI

Biblioteca personalizada para Roblox/Luau, baseada na **Obsidian**. Mantém a API de tabs, groupboxes e controles, com a identidade visual do Angel Hub.

- Toggles com **ON/OFF**, cor e posição da bolinha.
- Cards suaves, temas Dark, Cobalt, Amethyst e Sakura Bloom.
- Destaque das abas independente do hover.
- Painel arrastável com identidade, versão, FPS e ping.
- Botão pequeno arrastável para reabrir o menu, com suporte a mouse e toque.
- Posições salvas entre execuções, ajustadas à resolução atual.
- Sidebar automática: ícones e nomes na janela maior; somente ícones na janela menor.
- Cursor original do Roblox, sem cursor personalizado por padrão.

## Uso

A biblioteca já está publicada em [foreverrrrrrr23/AngelUI](https://github.com/foreverrrrrrr23/AngelUI). Use a URL abaixo:

```lua
local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/foreverrrrrrr23/AngelUI/main/Library.lua"
))()

local Window = Library:CreateWindow({
    Title = "Meu Script",
    Version = "1.0",
    Icon = "rbxassetid://77132715337164",
    AngelTheme = "Sakura Bloom",
    StatusPanel = true,
    MobileButton = true,
    Persistence = { Enabled=true, Folder="AngelUI", Key="MeuScript" },
    AutoCompactSidebar = { CompactBelow=660, ExpandedWidth=144 },
})

local Tab = Window:AddTab({ Name="Main", Icon="home" })
local Box = Tab:AddLeftGroupbox("Options")
Box:AddToggle("MyOption", { Text="Enable feature", Default=false, Callback=function(value)
    print(value)
end })
```

`Example.lua` mostra controles e opções de aparência. É uma demonstração visual; não executa farms.

## Painel e botão pequeno

Na criação da janela:

```lua
StatusPanel = { Enabled = true, ReferenceViewport = Vector2.new(1920,1057) },
MobileButton = { Enabled = true },
```

Ou durante a execução:

```lua
Window:SetStatusPanelEnabled(false) -- ocultar FPS/ping
Window:SetStatusPanelEnabled(true)
Window:SetMobileButtonEnabled(false) -- ocultar botão de reabrir
Window:SetMobileButtonEnabled(true)
Window:GetOverlayOptions() -- { StatusPanel=boolean, MobileButton=boolean }
Window:RefreshStatusPanelIdentity({ Title="Angel Hub", Version="2.0", Name="Angel Hub", Private=true })
Window:SavePositions()
Window:RestorePositions()
Window:ResetOverlayPositions()
```

O botão pequeno aparece quando a janela principal está escondida. Toque abre o menu; arrastar move o botão sem abrir. No PC, `LeftControl` continua alternando a janela. Se você desabilitar o botão em um celular, disponibilize outro controle de reabertura no seu script.

As posições são salvas ao terminar o arraste e ao descarregar a biblioteca, sem escrita contínua a cada frame. O arquivo é `AngelUI/<Key>_layout.json`. Cada script deve ter uma `Key` própria. Apenas o layout é armazenado; nenhuma configuração de farm é acessada. Sem acesso a arquivos, a memória da sessão é usada como alternativa. `Persistence.Enabled=false` desabilita ambos.

## Sidebar e escala

```lua
AutoCompactSidebar = { CompactBelow=660, ExpandedWidth=144 },
Responsive = true,
```

`CompactBelow` usa a largura visível em pixels. Abaixo dela, a sidebar fica com ícones centralizados e 52 pixels lógicos de largura. Ao aumentar, os nomes voltam. A escala máxima padrão é 100%; a biblioteca reduz a interface para caber na tela.

```lua
Window:SetAutoCompactSidebarEnabled(false)
Window:SetAutoCompactSidebarEnabled(true)
Library:SetAngelTheme("Cobalt")
```

## Integração com Angel Hub

`integrations/AngelHub.lua` contém apenas o adaptador e a organização do menu do Angel Hub. As automações permanecem na source principal. Ele recebe dependências explicitamente pelo argumento `Context`, sem compartilhar escopo por `setfenv`.

Com a source `Angel-Hub-2.0-External-UI.lua`:

```lua
getgenv().AngelUIBaseURL = "https://raw.githubusercontent.com/foreverrrrrrr23/AngelUI/main"
-- Opcional: a source atual já usa esta URL por padrão.
```

Para uso local, copie `Library.lua` e `integrations/AngelHub.lua` para uma pasta `AngelUI` no workspace do executor e defina `getgenv().AngelUIBaseURL = ""` para escolher a instalação local. A instalação local deve conter os dois arquivos. Não publique a source principal do Angel Hub neste repositório.

## Estrutura e manutenção

```text
Library.lua                 # arquivo pronto para carregar por HTTP
Example.lua                 # exemplo da API
src/Library.lua             # janela, escala e sidebar
src/Style.lua               # temas, cards, abas e toggles
src/Overlays.lua            # painel FPS/ping, botão e arraste
src/Persistence.lua         # armazenamento do layout
integrations/AngelHub.lua   # adaptador do Angel Hub
vendor/Obsidian.lua         # snapshot da biblioteca original
tools/build.py              # gera Library.lua
LICENSE
THIRD_PARTY.md
```

Edite `src/` e gere o arquivo publicado:

```sh
python tools/build.py
python tools/build.py --check
```

`Library.lua` embute o snapshot da Obsidian e as extensões: o consumidor não precisa baixar a base separadamente. O snapshot evita mudanças inesperadas na API. Não substitua `vendor/Obsidian.lua` sem verificar a integração.

## Créditos

Base: [deividcomsono/Obsidian](https://github.com/deividcomsono/Obsidian). Referência enviada: [yukvx/ObsidianUi](https://github.com/yukvx/ObsidianUi), um fork da mesma biblioteca. Foi mantido o snapshot moderno que já funcionava no Angel Hub, pois o fork de referência usa uma API mais antiga.

Licença MIT. O aviso e a licença original estão preservados em `LICENSE`.
