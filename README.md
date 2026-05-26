# Request Module

> **Cliente HTTP genérico em PowerShell com retry automático, autenticação integrada e tratamento robusto de erros**

[![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue.svg)](https://github.com/PowerShell/PowerShell)
[![Version](https://img.shields.io/badge/version-3.2.0-green.svg)](CHANGELOG.md)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

---

## 📋 Índice

- [Visão Geral](#-visão-geral)
- [Características](#-características)
- [Instalação](#-instalação)
- [Quick Start](#-quick-start)
- [Autenticação](#-autenticação)
- [Exemplos Práticos](#-exemplos-práticos)
- [Cache e Performance](#-cache-e-performance)
- [Logging](#-logging)
- [Testes](#-testes)
- [Troubleshooting](#-troubleshooting)
- [Comparação com Flurl/RestSharp](#-comparação-com-flurlrestsharp)
- [Contribuindo](#-contribuindo)

---

## 🎯 Visão Geral

**Request** é um módulo PowerShell que simplifica consumo de APIs REST com:

- ✅ **3 métodos de autenticação** (Basic, Bearer, Session Cookie)
- ✅ **Retry automático** com backoff exponencial para erros temporários (5xx, 429)
- ✅ **Tratamento específico** de erros HTTP (400, 401, 403, 404, 429, 500-504)
- ✅ **Cache inteligente** com TTL configurável
- ✅ **Logging estruturado** via módulo Logger externo (6 níveis, múltiplos formatos)
- ✅ **Métodos convenientes** (Get, Post, Put, Delete, Patch)
- ✅ **Classes reutilizáveis** para herança em serviços customizados

---

## ✨ Características

### Autenticação Integrada

```powershell
# Basic Authentication
$request = [Request]::new('https://api.exemplo.com', 'user', 'password')

# Bearer Token (OAuth2/JWT)
$request = [Request]::new('https://api.exemplo.com', 'eyJhbGci...')

# Session Cookie (JSESSIONID para Jira, Confluence, etc.)
$config = [RequestConfig]::new('https://jira.linx.com.br')
$config.AuthType = [AuthType]::Session
$config.SessionId = '380BB1FE14778FA884E2B23596ACC5DF'
$request = [Request]::new($config)
```

### Retry Automático

Erros temporários (408, 429, 500-504) são automaticamente retentados com backoff exponencial:

- Tentativa 1: Imediato
- Tentativa 2: +2 segundos
- Tentativa 3: +4 segundos
- Máximo: 3 tentativas (configurável)

### Tratamento de Erros

Mensagens específicas para cada status HTTP:

| Status | Mensagem | Retry? |
|--------|----------|--------|
| 400 | Bad Request - Parâmetros inválidos | ❌ |
| 401 | Unauthorized - Token inválido ou expirado | ❌ |
| 403 | Forbidden - Sem permissão | ❌ |
| 404 | Not Found - Recurso não encontrado | ❌ |
| 429 | Too Many Requests - Rate limit | ✅ |
| 500-504 | Server errors | ✅ |

---

## 📦 Instalação

### Pré-requisitos

**IMPORTANTE**: Request module depende de 2 módulos externos:
- **Logger** v1.0.0+ (logging estruturado)
- **Cache** v1.0.0+ (cache com TTL)

```powershell
# 1. Instalar Logger module
cd ..\powershell-logger
Import-Module .\Logger.psd1

# 2. Instalar Cache module
cd ..\powershell-cache
Import-Module .\Cache.psd1

# 3. Voltar para Request
cd ..\request
```

### Opção 1: Clonar repositório (Recomendado para desenvolvimento)

```powershell
# Clonar repositório
git clone https://github.com/rpgchess/powershell-request.git
cd request-module

# Instalar dependências (Pester, PSScriptAnalyzer)
.\Install-Dependencies.ps1

# Importar módulo
Import-Module .\Request.psd1
```

### Opção 2: Copiar para módulos locais

```powershell
# Copiar para diretório de módulos
$modulePath = "$env:USERPROFILE\Documents\PowerShell\Modules\Request"
Copy-Item -Recurse -Path .\request -Destination $modulePath

# Importar
Import-Module Request
```

### Opção 3: Instalação manual de dependências

```powershell
# Pester 5.x (testes)
Install-Module -Name Pester -MinimumVersion 5.0 -Scope CurrentUser -Force

# PSScriptAnalyzer (validação de código)
Install-Module -Name PSScriptAnalyzer -Scope CurrentUser -Force
```

### Verificar instalação

```powershell
Get-Module Request -ListAvailable

# Verificar dependências
Get-Module Pester, PSScriptAnalyzer -ListAvailable
```

---

## 🚀 Quick Start

### Exemplo Básico (GET)

```powershell
using module '.\Request.psd1'

# Criar request sem autenticação
$request = [Request]::new('https://jsonplaceholder.typicode.com', '', '')
$request.Config.AuthType = [AuthType]::None

# GET simples
$posts = $request.Get('/posts')
Write-Host "Total de posts: $($posts.Count)"

# GET com ID
$post = $request.Get('/posts/1')
Write-Host "Título: $($post.title)"
```

### POST com JSON

```powershell
# Criar novo post
$newPost = @{
    title = 'Meu Post'
    body = 'Conteúdo do post'
    userId = 1
}

$result = $request.Post('/posts', $newPost)
Write-Host "Post criado com ID: $($result.id)"
```

### PUT (Atualizar)

```powershell
$updateData = @{
    id = 1
    title = 'Título Atualizado'
    body = 'Conteúdo atualizado'
    userId = 1
}

$updated = $request.Put('/posts/1', $updateData)
```

### DELETE

```powershell
$deleted = $request.Delete('/posts/1')
```

---

## 🔐 Autenticação

### Basic Authentication

```powershell
# Construtor direto
$request = [Request]::new('https://api.exemplo.com', 'username', 'password')

# Via config
$config = [RequestConfig]::new('https://api.exemplo.com', 'user', 'pass')
$request = [Request]::new($config)
```

### Bearer Token (OAuth2/JWT)

```powershell
# Construtor direto
$token = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...'
$request = [Request]::new('https://api.exemplo.com', $token)

# Via config
$config = [RequestConfig]::new('https://api.exemplo.com', $token)
$request = [Request]::new($config)
```

### Session Cookie (JSESSIONID)

Útil para Jira, Confluence e outras aplicações que usam cookies de sessão:

```powershell
# 1. Obter cookie do navegador (F12 → Application → Cookies → JSESSIONID)
$sessionId = '380BB1FE14778FA884E2B23596ACC5DF'

# 2. Configurar Request
$config = [RequestConfig]::new('https://jira.linx.com.br')
$config.AuthType = [AuthType]::Session
$config.SessionId = $sessionId
$config.CookieDomain = 'jira.linx.com.br'  # Opcional (auto-detecta)

# 3. Usar
$request = [Request]::new($config)
$issue = $request.Get('/rest/api/2/issue/RESHOP-14206')
```

**Importante**: Cookie expira após ~30min de inatividade. Copie novo JSESSIONID se receber erro 401.

---

## 💡 Exemplos Práticos

### GitHub API

```powershell
# Listar repositórios de usuário
$token = $env:GITHUB_TOKEN
$request = [Request]::new('https://api.github.com', $token)

$repos = $request.Get('/users/octocat/repos')
$repos | ForEach-Object {
    Write-Host "$($_.name) - $($_.description)"
}
```

### Jira API (Session Cookie)

```powershell
# Ver exemplo completo em: Invoke-JiraSessionExample.ps1
.\Invoke-JiraSessionExample.ps1 -SessionId "ABC123..." -IssueKey "SHOP-1234"
```

### Custom Headers

```powershell
# Headers customizados (ex: XML)
$customHeaders = @{
    'Content-Type' = 'application/xml'
    'Accept' = 'application/xml'
}

$result = $request.Post('/api/data', $xmlBody, $customHeaders)
```

---

## 🚀 Cache e Performance

### Usar Cache

**IMPORTANTE**: Requer Cache module v1.0.0+ (módulo externo).

```powershell
# Importar módulos necessários
Import-Module '..\powershell-cache\Cache.psd1'
Import-Module '.\Request.psd1'

# Criar cache (arquivo .cache)
$cache = [Cache]::new('github-repos.cache')

# Verificar se está em cache
$repos = $cache.Get('octocat-repos')

if ($null -eq $repos) {
    # Cache miss - buscar da API
    $request = [Request]::new('https://api.github.com', $env:GITHUB_TOKEN)
    $repos = $request.Get('/users/octocat/repos')
    
    # Salvar em cache (TTL: 5 minutos = 300 segundos)
    $cache.Set('octocat-repos', $repos, 300)
    $cache.Save()
    
    Write-Host "Dados obtidos da API" -ForegroundColor Yellow
} else {
    Write-Host "Dados obtidos do cache" -ForegroundColor Green
}

$repos | Format-Table name, description
```

### Invalidar Cache

```powershell
# Remover item específico
$cache.Remove('octocat-repos')

# Limpar todo o cache
$cache.Clear()

# Salvar mudanças
$cache.Save()
```

---

## 📊 Logging

### Configurar Logger

```powershell
using module '.\Request.psd1'

# Criar logger
$logger = [RequestLogger]::new([LogLevel]::DEBUG)

# Logs por nível
$logger.Debug('Request iniciado')
$logger.Info('Buscando dados da API')
$logger.Warn('Rate limit próximo do limite')
$logger.Error('Falha na requisição', $exception)
$logger.Success('Operação concluída')
```

### Integrar com Request

```powershell
# TODO: Integração futura
# Request module ainda não tem logging integrado nativo
# Usar Write-Verbose por enquanto
$VerbosePreference = 'Continue'
$result = $request.Get('/api/data')
```

---

## 🧪 Testes

### Setup Inicial (Primeira vez)

```powershell
# Instalar todas as dependências automaticamente
.\Install-Dependencies.ps1

# Ou instalar manualmente
Install-Module Pester -MinimumVersion 5.0 -Force
Install-Module PSScriptAnalyzer -Force
```

### Executar Testes Básicos

```powershell
# Teste standalone
.\Test-Request.ps1 -Verbose

# Teste com resultados completos
.\Test-Request.ps1 -ShowResults
```

### Executar Pester Tests

```powershell
# Executar todos os testes
Invoke-Pester .\Tests\Request.Tests.ps1

# Executar apenas testes unitários (skip integration)
Invoke-Pester .\Tests\Request.Tests.ps1 -ExcludeTag 'Integration'

# Com coverage
Invoke-Pester .\Tests\Request.Tests.ps1 -CodeCoverage .\Classes\*.ps1
```

### PSScriptAnalyzer

```powershell
# Analisar código
Invoke-ScriptAnalyzer -Path . -Recurse -Settings .vscode\PSScriptAnalyzerSettings.psd1
```

### Build Completo

```powershell
# Build completo (Clean + Analyze + Test)
.\Build.ps1

# Build sem testes
.\Build.ps1 -SkipTests

# Criar pacote para distribuição
.\Build.ps1 -Task Package -Configuration Release
```

---

## 🔧 Troubleshooting

### Erro 401 Unauthorized

**Causa**: Token/senha inválido ou expirado (Session Cookie)

**Solução**:
- **Basic/Bearer**: Verifique credenciais
- **Session**: Copie novo JSESSIONID do navegador (F12 → Cookies)

### Erro 429 Too Many Requests

**Causa**: Rate limit excedido

**Solução**:
- Aumentar `MaxRetries` em RequestConfig
- Implementar cache para reduzir requests
- Aguardar período de cooldown (varia por API)

### Erro 500-504 (Server Errors)

**Causa**: Erro no servidor (temporário ou permanente)

**Solução**:
- Módulo já tenta retry automático (3x por padrão)
- Verificar status da API (status page)
- Aumentar timeout se servidor lento

### Timeout

**Causa**: Requisição demorou mais que `TimeoutSeconds` (padrão: 30s)

**Solução**:
```powershell
$config.TimeoutSeconds = 120  # 2 minutos
```

### JSON Deserialization Error

**Causa**: Resposta não é JSON válido

**Solução**: Request module retorna objeto genérico com `StatusCode`, `Content`, `RawResponse`

---

## 📊 Comparação com Flurl/RestSharp

| Feature | Request Module | Flurl.Http | RestSharp |
|---------|----------------|------------|-----------|
| **Linguagem** | PowerShell (Classes) | C# | C# |
| **Retry automático** | ✅ (5xx, 429) | ✅ (plugin) | ✅ (via Polly) |
| **Auth integrada** | ✅ Basic/Bearer/Session | ✅ Basic/Bearer/OAuth | ✅ Basic/Bearer/OAuth |
| **Cache nativo** | ✅ Cache (externo) | ❌ (manual) | ❌ (manual) |
| **Logging** | ✅ Logger (externo) | ✅ (via ILogger) | ❌ (manual) |
| **Curva aprendizado** | Baixa (PowerShell) | Média (C# + Fluent) | Média (C# + Builder) |
| **Dependências** | Zero | Newtonsoft.Json | System.Text.Json |
| **Pipeline support** | ⚠️ Planejado v3.1 | N/A | N/A |
| **Async/Await** | ❌ (sync only) | ✅ | ✅ |

**Quando usar Request Module**:
- Scripts PowerShell/automação
- Prototipagem rápida
- Integração com AD/Exchange/Azure PowerShell
- Ambientes sem .NET SDK

**Quando usar Flurl/RestSharp**:
- Aplicações .NET (Web/Console/Desktop)
- Performance crítica (async/await)
- Necessita features avançadas (OAuth flow completo, multipart, streaming)

---

## 🤝 Contribuindo

Contribuições são bem-vindas! Para contribuir:

1. Fork o repositório
2. Clone e instale dependências:
   ```powershell
   git clone https://github.com/seu-usuario/request-module.git
   cd request-module
   .\Install-Dependencies.ps1
   ```
3. Crie branch para feature (`git checkout -b feature/nova-feature`)
4. Faça suas alterações
5. Execute validações:
   ```powershell
   .\Build.ps1  # Valida código e testes
   ```
6. Commit mudanças (`git commit -m 'Add: nova feature'`)
7. Push para branch (`git push origin feature/nova-feature`)
8. Abra Pull Request

### Guidelines

- Seguir padrões PowerShell (PSScriptAnalyzer sem erros)
- Adicionar testes Pester para novas features (coverage > 80%)
- Atualizar CHANGELOG.md com suas mudanças
- Documentar em comment-based help (.SYNOPSIS, .PARAMETER, .EXAMPLE)
- Build deve passar: `.\Build.ps1` retorna exit 0

### Estrutura de Arquivos

```
request/
├── Build.ps1                    # Script de build
├── Install-Dependencies.ps1     # Instalação de dependências
├── requirements.psd1            # Especificação de dependências
├── Classes/                     # Classes do módulo
├── Tests/                       # Testes Pester
├── .vscode/                     # Configurações VSCode
└── .gitignore                   # Git ignore rules
```

---

## 📝 Changelog

Ver [CHANGELOG.md](CHANGELOG.md) para histórico completo de versões.

---

## 📄 Licença

MIT License - Ver [LICENSE](LICENSE) para detalhes.

---

## 👤 Autor

**Claudio Almeida**  
GitHub: [@rpgchess](https://github.com/rpgchess)  
Empresa: Personal

---

## 🔗 Links

- [Documentação PowerShell Classes](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_classes)
- [Jira REST API](https://developer.atlassian.com/cloud/jira/platform/rest/v2/)
- [GitHub API](https://docs.github.com/en/rest)
- [HTTP Status Codes](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status)

---

**Última atualização**: 2026-05-25  
**Versão**: 3.0.0
