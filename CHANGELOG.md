# Changelog

Todas as mudanças notáveis do projeto Request Module serão documentadas aqui.

---

## [3.2.0] - 2026-05-26 (Modularização de Cache)

### 🔥 BREAKING CHANGES
- **RequestCache removido**: Módulo agora depende do Cache module externo
- **Nova dependência**: Cache v1.0.0+ (módulo standalone reutilizável)
- **API change**: `[RequestCache]` → `[Cache]`

### ✨ IMPROVEMENTS
- **Cache modularizado**: Usa Cache module com TTL, persistência e gerenciamento avançado
- **Cache avançado**: Novos métodos GetKeys(), GetStats(), RemoveExpired()
- **Múltiplos construtores**: `[Cache]::new('file')` ou `[Cache]::new('file', 'path')`
- **Parse robusto**: Usa DateTimeOffset para melhor precisão em datas
- **Redução de código**: RequestCache.ps1 removido (~120 linhas eliminadas)
- **Reutilização**: Cache pode ser usado em outros projetos PowerShell

### 📦 DEPENDENCIES
- **Logger Module**: v1.0.0+ (mantido de v3.1.0)
  - Instalar: `Import-Module '..\powershell-logger\Logger.psd1'`
- **Cache Module**: v1.0.0+ (novo)
  - Instalar: `Import-Module '..\powershell-cache\Cache.psd1'`
  - Features: TTL, persistência JSON, GetKeys(), GetStats(), RemoveExpired()
  - Testes: 37 unit tests (100% passing)

### 🛠️ MIGRATION
```powershell
# Antes (v3.1.0) - RequestCache interno
$cache = [RequestCache]::new('api-cache.cache')
$cache.Set('key', $data, 300)
$value = $cache.Get('key')

# Depois (v3.2.0) - Cache externo
Import-Module '..\powershell-cache\Cache.psd1'
$cache = [Cache]::new('api-cache')  # Extensão .cache automática
$cache.Set('key', $data, 300)
$value = $cache.Get('key')

# Novos métodos disponíveis
$keys = $cache.GetKeys()          # Lista chaves válidas
$stats = $cache.GetStats()        # Estatísticas
$removed = $cache.RemoveExpired() # Limpa expirados
```

### 📁 STRUCTURE CHANGES
```diff
request/
├── Core/
│   ├── RequestEnums.ps1
│   ├── RequestConfig.ps1
-   ├── RequestCache.ps1    # Removido
│   └── Request.ps1
```

---

## [3.1.0] - 2026-05-26 (Modularização de Logging)

### 🔥 BREAKING CHANGES
- **RequestLogger removido**: Módulo agora depende do Logger module externo
- **Nova dependência**: Logger v1.0.0+ (módulo standalone reutilizável)

### ✨ IMPROVEMENTS
- **Logging modularizado**: Usa Logger module com 6 níveis (DEBUG, INFO, WARN, ERROR, SUCCESS, FATAL)
- **Logging avançado**: Suporte a múltiplos formatos (Simple/Detailed/Json), saída para arquivo, buffer
- **Redução de código**: RequestLogger.ps1 removido (~100 linhas eliminadas)
- **Reutilização**: Logger pode ser usado em outros projetos PowerShell
- **Singleton pattern**: Logger.Instance() disponível para uso global

### 📦 DEPENDENCIES
- **Logger Module**: https://github.com/rpgchess/powershell-logger
  - Instalar: `Import-Module '..\powershell-logger\Logger.psd1'`
  - Features: 6 níveis, 3 formatos, file output, exception logging, buffer

### 🛠️ MIGRATION
```powershell
# Antes (v3.0.0) - RequestLogger interno
$logger = [RequestLogger]::new()
$logger.Info('Mensagem')

# Depois (v3.1.0) - Logger externo
Import-Module '..\powershell-logger\Logger.psd1'
$logger = [Logger]::new()
$logger.Info('Mensagem')
# Ou usar singleton
[Logger]::Instance().Info('Mensagem')
```

---

## [3.0.0] - 2026-05-25 (Refatoração Completa)

### 🎉 BREAKING CHANGES
- **Estrutura refatorada**: Scripts seguem padrões PowerShell rigorosos (comment-based help, begin/process/end, validações)
- **Example-Jira-Session.ps1 → Invoke-JiraSessionExample.ps1**: Renomeado para seguir convenção Verb-Noun
- **DELETE requests**: Agora retorna objeto com `StatusCode` e `Success` para respostas vazias (JSON `{}`)

### ✨ NEW FEATURES
- **RequestCache class**: Cache inteligente com TTL configurável e persistência em arquivos `.cache`
  - Métodos: Get, Set, Remove, Clear, Contains
  - Auto-invalidação por TTL (Time To Live)
  - Suporte a chave-valor com serialização JSON
  
- **RequestLogger class**: Logging estruturado com níveis e cores
  - Níveis: DEBUG, INFO, WARN, ERROR, SUCCESS
  - Timestamp configurável
  - Color-coded output por nível
  
- **Pester 5.x Tests**: Suite completa de testes automatizados
  - 23 testes unitários e integração
  - Coverage: RequestConfig validation, Request instantiation, HTTP methods, auth, error handling
  - Tag 'Integration' para testes que dependem de API externa
  
- **PSScriptAnalyzer Config**: Validação rigorosa de qualidade de código
  - Rules: approved verbs, no aliases, consistent indentation/whitespace, correct casing
  - Exclusões apropriadas para HTTP auth (Username/Password params)

### 📖 IMPROVEMENTS - Documentation
- **README.md completo**: Quick Start, exemplos práticos, troubleshooting, comparação com Flurl/RestSharp
- **Comment-based help**: Todos os scripts com .SYNOPSIS, .DESCRIPTION, .PARAMETER, .EXAMPLE, .NOTES
- **Validação de parâmetros**: ValidateNotNullOrEmpty, ValidateSet, Aliases em todos os scripts
- **Exemplos práticos**: GitHub API, Jira API, custom headers

### 🏗️ IMPROVEMENTS - Code Structure
- **Test-Request.ps1**: Refatorado com estrutura begin/process/end, contador de testes, exit codes apropriados
- **Invoke-JiraSessionExample.ps1**: Validações robustas, mensagens de erro específicas por status HTTP, help completo
- **Request.ps1**: Lógica melhorada para DELETE com JSON vazio, retorna Success = $true consistentemente

### 📊 QUALITY METRICS
- **PSScriptAnalyzer**: 0 erros críticos, 22 warnings aceitáveis (formatação/BOM)
- **Pester Tests**: 23 passed, 0 failed (100% success rate)
- **Code Coverage**: Classes principais cobertas (RequestConfig, Request, HTTP methods)
- **Naming Conventions**: 100% compliance com Verb-Noun

### 🔧 TECHNICAL IMPROVEMENTS
- **ScriptsToProcess**: Adicionados RequestCache.ps1 e RequestLogger.ps1 ao manifesto
- **Module Tags**: Adicionado 'Cache' e 'Logging' às tags do PSData
- **Error Handling**: Melhor tratamento de JSON vazio em DELETE requests
- **Test Isolation**: BeforeAll/AfterAll apropriados, cleanup de módulo

### 🛠️ DEVOPS & BUILD
- **Install-Dependencies.ps1**: Gerenciamento automático de dependências (Pester, PSScriptAnalyzer)
  - Suporta PSResourceGet (PowerShell 7+) e PowerShellGet (5.1)
  - Dependências obrigatórias e opcionais
  - Validação pós-instalação
  
- **Build.ps1**: Script de build completo
  - Tasks: Clean, Analyze, Test, Package
  - Configurações: Debug/Release
  - Geração de relatórios de teste
  - Empacotamento para distribuição (.zip)
  
- **requirements.psd1**: Especificação de dependências PSResourceGet
  - Pester 5.x, PSScriptAnalyzer 1.21+
  - powershell-yaml, Plaster (opcionais)
  
- **.gitignore**: Regras Git para cache, logs, build outputs

---

## [2.1.0] - 2026-05-23

### ✨ Added
- **Autenticação Session (JSESSIONID) Aprimorada**
  - Implementado WebRequestSession com `System.Net.Cookie` correto
  - Cookie configurado com propriedades: Domain, Path, Secure, HttpOnly
  - Seguindo padrão de `get-jira-browser-cookie.ps1` para compatibilidade com APIs que validam cookies
  
- **Propriedade CookieDomain em RequestConfig**
  - Permite configurar domínio do cookie JSESSIONID (ex: `jira.linx.com.br`)
  - Auto-detecta domínio da BaseUrl se não configurado
  
- **Headers de Navegador**
  - User-Agent atualizado para `Mozilla/5.0` (simula Chrome 120)
  - Adicionado `Accept-Language: pt-BR,pt;q=0.9` para evitar detecção de bot
  
- **Test-Session-Authentication.ps1**
  - Script de teste completo para validar autenticação Session
  - 5 testes automatizados (config, auto-domain, headers, validação, instanciação)

### 🔧 Changed
- **GetDefaultHeaders()**: Removida lógica incorreta de adicionar JSESSIONID como header simples
- **Invoke()**: Adicionada criação de WebRequestSession quando `AuthType = Session`
- **User-Agent**: Mudado de `PowerShell-Request/2.0` para User-Agent de navegador real

### 🐛 Fixed
- **Cookie não funcionava**: APIs que validam cookies corretamente (Jira, Confluence) agora funcionam
- **Detecção de bot**: Headers de navegador evitam bloqueio por APIs com proteção anti-bot

### 📚 Documentation
- Exemplo de uso com Jira API em `Test-Session-Authentication.ps1`
- Documentação de CookieDomain automático vs manual

---

## [2.0.0] - 2026-05-22

### ✨ Added
- Suporte a 3 tipos de autenticação via construtores:
  - Basic: Username/Password (Base64)
  - Bearer: Token OAuth2/JWT
  - Session: Cookie JSESSIONID
- Classe `RequestConfig` com validação por tipo de autenticação
- Enum `AuthType` (None, Basic, Bearer, Session)
- Headers customizados com padrão JSON (`Content-Type`, `Accept`)
- Retry logic com exponential backoff (408, 429, 5xx)
- Tratamento de erros HTTP específicos (400, 401, 403, 404, 429, 500)

### 🔧 Changed
- Renomeado método `Request()` → `Invoke()` para evitar conflito com nome da classe
- Headers padrão agora incluem autenticação automática baseada em `AuthType`

### 📦 Infrastructure
- ScriptsToProcess: Enums.ps1, RequestConfig.ps1, Request.ps1
- Versão inicial: 2.0.0

---

## [1.1.0] - 2026-05-21

### ✨ Added
- Parâmetro `$CustomHeaders` com padrão JSON
- Merge de headers: Config → JSON defaults → Custom headers

---

## [1.0.0] - 2026-05-20

### ✨ Initial Release
- Classe `Request` básica para HTTP requests
- Suporte a GET, POST, PUT, DELETE, PATCH
- Timeout configurável
- Retry logic básico

---

## Uso com Jira (JSESSIONID)

### Antes (v2.0.0) - ❌ Não funcionava
```powershell
$config = [RequestConfig]::new('https://jira.linx.com.br')
$config.AuthType = [AuthType]::Session
$config.SessionId = 'ABC123'
# Cookie adicionado como header simples - APIs rejeitavam
```

### Depois (v2.1.0) - ✅ Funciona
```powershell
$config = [RequestConfig]::new('https://jira.linx.com.br')
$config.AuthType = [AuthType]::Session
$config.SessionId = '380BB1FE14778FA884E2B23596ACC5DF'
$config.CookieDomain = 'jira.linx.com.br'  # Opcional (auto-detecta se omitido)

$request = [Request]::new($config)
$issue = $request.Get('/rest/api/2/issue/RESHOP-14206')
# Cookie configurado corretamente via WebRequestSession
```

---

**Autor:** Claudio Almeida  
**Projeto:** https://github.com/rpgchess/powershell-request
