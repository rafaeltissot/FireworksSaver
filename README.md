# 🎆 Fireworks for macOS (`Fireworks.saver`)

<p align="center">
  <b>Um protetor de tela nativo, elegante e altamente personalizável de fogos de artifício para macOS.</b><br>
  <i>An elegant, ultra-smooth and highly customizable fireworks screen saver for macOS.</i>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Platform-macOS_14.0+-black?logo=apple" alt="macOS 14+">
  <img src="https://img.shields.io/badge/Architecture-Universal_(Apple_Silicon_%26_Intel)-orange" alt="Universal Binary">
  <img src="https://img.shields.io/badge/Language-Swift_6-F05138?logo=swift&logoColor=white" alt="Swift 6">
  <img src="https://img.shields.io/badge/License-MIT-blue.svg" alt="License: MIT">
</p>

---

## ✨ Destaques / Features

- ⚡️ **100% Nativo em Swift:** Construído com `ScreenSaver.framework` e `AppKit`, sem dependências pesadas ou frameworks web.
- ⏰ **Relógio Retrô Estilo Fliqlo:** Relógio flip mecânico com placas arredondadas em carvão escuro, fenda de dobradiça, numerais nítidos e **animação 2.5D de virada de folha (*flip card*)** a cada minuto.
  - Suporte a formato **24 horas** ou **12 horas** (com indicador AM/PM).
  - Escala ajustável: Pequeno (75%), Médio (100%) ou Grande (125%).
  - Opção para ativar ou desativar o relógio a qualquer momento.
- 🍏 **Universal Binary:** Suporte nativo completo para **Apple Silicon (M1/M2/M3/M4)** e **Intel (x86_64)**.
- ⚙️ **Painel de Opções Nativo:** Integração completa com os Ajustes do Sistema do macOS através do botão **"Opções..."** (*Configure Sheet*).
- 🎨 **6 Paletas de Cores Temáticas + Explosões Multicoloridas:**
  - **Multicolorido Vibrante (20 cores):** Espectro completo com 20 cores de alta saturação e explosões bicolores, tricolores e buquês arco-íris.
  - **Dourado & Réveillon:** 8 tons elegantes de ouro clássico, champanhe, âmbar imperial, ouro rosé, prata e pérola.
  - **Neon / Cyberpunk:** 10 tons elétricos de ciano laser, magenta, ultravioleta, verde matrix e amarelo ácido.
  - **Fogo & Brasas:** 8 tons vulcânicos de carmesim, laranja labareda, âmbar solar e chama incandescente.
  - **Gelo & Aurora Boreal:** 8 tons polares de ciano ártico, verde aurora, menta, índigo magnético e violeta boreal.
  - **Carnaval / Tropical:** 10 tons festivos de rosa tropical, turquesa caribe, sol dourado, verde limão, tangerina e açaí.
- 🚀 **Física Totalmente Ajustável:**
  - **Frequência de lançamentos:** De um ritmo calmo (1) até festa contínua (10).
  - **Velocidade dos foguetes:** Lenta, Normal, Rápida ou Turbo.
  - **Densidade de partículas:** Leve (~30), Equilibrado (~60), Intenso (~100) ou Espetacular (~150).
  - **Tamanho das partículas:** Pequenas, Médias ou Grandes, com abertura ampla proporcional à tela.
  - **Gravidade personalizável:** Flutuante / Lua (0.05), Normal / Terra (0.12) ou Pesada (0.22).
  - **Modo de Energia:** Econômico / Silencioso (30 FPS), Equilibrado (45 FPS) ou Máximo (60 FPS).
  - **Rastro cintilante:** Fagulhas e faíscas brilhantes durante a subida de cada foguete.
- 🔋 **Arquitetura Ultraleve (`CALayer` Pool):** Composição 100% acelerada por hardware via `WindowServer` (~1% a 2% de CPU), mantendo o Mac frio e silencioso mesmo em uso prolongado.

---

## 📥 Como Instalar / How to Install

### Opção 1: Instalação Manual (Recomendada para Usuários)

1. Baixe o arquivo `Fireworks-macOS.zip` mais recente das [Releases](https://github.com/rafaeltissot/FireworksSaver/releases).
2. Dê um duplo clique no arquivo ZIP para descompactá-lo e obter o arquivo `Fireworks.saver`.
3. Dê um duplo clique no arquivo `Fireworks.saver`. O macOS perguntará se deseja instalar o protetor de tela para o seu usuário.
4. Clique em **Instalar**.

> 💡 **Dica alternativa:** Você também pode mover manualmente o arquivo `Fireworks.saver` para a pasta:  
> `~/Library/Screen Savers/` (para abrir a pasta no Finder, use `Cmd + Shift + G` e cole o caminho).

---

### Opção 2: Compilar a Partir do Código Fonte (Para Desenvolvedores)

Se você tem o Xcode ou as Swift Command Line Tools instaladas:

```bash
# Clone o repositório
git clone https://github.com/rafaeltissot/FireworksSaver.git
cd FireworksSaver

# Execute o script de compilação e instalação
chmod +x build.sh
./build.sh
```

O script irá:
1. Compilar o código em arquitetura Universal (`arm64` e `x86_64`) com otimização `-O`.
2. Assinar o pacote via `codesign`.
3. Instalar automaticamente em `~/Library/Screen Savers/Fireworks.saver`.
4. Gerar o pacote `build/Fireworks-macOS.zip` pronto para distribuição.

---

## ⚙️ Como Configurar no macOS

1. Abra os **Ajustes do Sistema** (*System Settings*) no Mac.
2. Acesse a seção **Protetor de Tela** (*Screen Saver*).
3. Na lista "Outros" (*Other*), selecione **Fireworks**.
4. Clique no botão **"Opções..."** ao lado do nome do protetor.
5. Ajuste os parâmetros de frequência, velocidade, partículas, gravidade e paleta de cores.
6. Clique em **OK** para aplicar imediatamente.

---

## 🗑️ Como Desinstalar / How to Uninstall

Para remover o protetor de tela do seu sistema, execute no Terminal:

```bash
rm -rf ~/Library/Screen\ Savers/Fireworks.saver
```

Ou acesse `~/Library/Screen Savers/` pelo Finder e mova `Fireworks.saver` para o Lixo.

---

## 🛠️ Requisitos de Sistema / Requirements

- **macOS:** macOS Sonoma 14.0 ou posterior (incluindo macOS Sequoia 15.0+).
- **Processador:** Apple Silicon (M1/M2/M3/M4) ou processador Intel de 64 bits.

---

## 📄 Licença / License

Distribuído sob a licença **MIT**. Consulte o arquivo [`LICENSE`](LICENSE) para mais detalhes.

---

<p align="center">
  Desenvolvido com carinho por <b><a href="https://github.com/rafaeltissot">Joao Rafael Tissot</a></b>.
</p>
