# Trabalho Prático 1: Agentes Inteligentes

Este projeto NetLogo foi desenvolvido como parte da cadeira de Inteligência Artificial (IA) na Universidade de Trás-os-Montes e Alto Douro (UTAD) no ano letivo 2024/2025 por **José Pedro Meireles Alves** e **Diogo Aperta**.

O modelo simula um ambiente onde um agente "Cleaner" limpa áreas poluídas por agentes "Polluters". O Cleaner possui um sistema de recarregamento de energia via painéis solares/base e pode usar uma bomba para limpar grandes áreas de uma vez. O modelo inclui vários parâmetros ajustáveis e funcionalidades adicionais, como a execução de efeitos sonoros e usa A* para encontar s melhores caminhos.

## Requisitos do Sistema

Para rodar este modelo corretamente, você precisará ter os seguintes requisitos:

### 1. NetLogo

- **Versão recomendada**: NetLogo 6.0 ou superior.

### 2. Python com Pygame

Alguns efeitos sonoros no modelo são executados usando Python e a biblioteca `pygame`. Portanto, é necessário ter Python instalado, juntamente com o pacote `pygame`.

#### Instalação do Python
- **Versão recomendada**: Python 3.x.
- Você pode baixar Python em [https://www.python.org/downloads/](https://www.python.org/downloads/).

#### Instalação do Pygame
Após instalar o Python, abra um terminal ou prompt de comando e execute o seguinte comando para instalar o Pygame:

```bash
pip install pygame