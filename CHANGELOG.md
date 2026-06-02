# Changelog

Todas as mudanças notáveis do projeto Request Module serão documentadas aqui.

---

## [3.6.0] - 2026-06-01 (Integração Logger)

### 📋 LOGGING
- **Logger v1.0.0+ como RequiredModule**: Carregamento automático do módulo Logger
- **Write-* Substituídos**: Write-Warning, Write-Verbose, Write-Error substituídos por Logger estruturado
- **Logging Estruturado**: Todos os requests HTTP registrados com contexto completo
- **Níveis de Log**: DEBUG (verbose), WARN (retry), ERROR (falhas HTTP)

### 🔧 IMPLEMENTAÇÃO
- **InitializeLogger()**: Método privado para criar instância Logger na classe Request
- **$Logger Hidden**: Propriedade privada para armazenar instância do Logger
- **Fallback Graceful**: Se Logger não disponível, continua funcionando (usa Write-Warning)

### 🎯 BENEFITS
- 📊 Observability aprimorada com logging estruturado
- 🔍 Rastreamento completo de requests/retries/erros via Logger
- 📁 Logs podem ser salvos em arquivo configurando LoggerConfig
- 🚫 Sem Write-Host/Write-Verbose poluindo saída do console

### 📝 BREAKING CHANGES
**Dependência Adicionada**: Logger v1.0.0+ agora é RequiredModule (instalar antes de usar)

```powershell
# Instalar Logger antes de importar Request
Import-Module '..\powershell-logger\Logger.psd1' -Force
Import-Module '.\Request.psd1' -Force
```

### 🔄 MIGRATION GUIDE
Nenhuma alteração no código do usuário necessária. Logger é transparente.

---

## [3.5.1] - 2026-06-01 (Padrão de Carregamento via Manifest)

### 📋 DOCUMENTATION
- **Padrão Manifest Explicitamente Documentado**: Request.psm1 agora documenta claramente o padrão de carregamento via manifest (RequiredModules + ScriptsToProcess)
- **Request.psd1 Atualizado**: ScriptsToProcess agora inclui comentário explicando que NÃO deve usar `using module` nos arquivos Core/*.ps1
- **Compatibilidade PS 5.1**: Evita duplicação de tipos quando usado via `Import-Module`

### 🔧 SCRIPTS EXTERNOS
- **Test-Request.ps1**: Substituído `using module` por `Import-Module` + documentação do padrão
- **Invoke-JiraSessionExample.ps1**: Substituído `using module` por `Import-Module` + nota explicativa
- **Invoke-RequestWithCustomErrorHandler.ps1**: Substituído `using module` por `Import-Module` + nota explicativa
- **Test-Session-Authentication.ps1**: Substituído `using module` por `Import-Module` em 2 ocorrências + exemplo atualizado

### 🎯 BENEFITS
- **Compatibilidade**: Melhor compatibilidade com PowerShell 5.1 (evita erro "Cannot convert X to X")
- **Consistência**: Todos os scripts de exemplo seguem o mesmo padrão
- **Documentação**: Padrão claramente documentado para desenvolvedores que herdam de Request
- **Manutenibilidade**: Padrão alinhado com powershell-module-patterns.md (memória do repositório)

### 📝 BREAKING CHANGES
**NENHUM** - Mudanças apenas em documentação e scripts de exemplo. Não há breaking changes no módulo.

### 🔄 MIGRATION GUIDE
Scripts externos que usam o módulo Request devem usar `Import-Module` ao invés de `using module`:

```powershell
# ❌ Antigo (pode causar duplicação de tipos em PS 5.1)
using module '.\Request.psd1'

# ✅ Novo (padrão recomendado)
Import-Module '.\Request.psd1' -Force
```

---

## [3.5.0] - 2026-05-29 (Extensibilidade e Manutenibilidade)

### 🛠️ CODE REFACTORING
- **Método Invoke() Refatorado**: Reduzido de ~150 linhas para ~50 linhas
  - Extraídos 5 métodos privados para melhor organização
  - Aplicado princípio SRP (Single Responsibility Principle)
  - Código mais legível, testável e manutenível

### ⚙️ NEW FEATURES - Retry Customizável
- **RetryBackoffMultiplier**: Configura multiplicador do backoff exponencial
  - Range: 1.0 a 10.0
  - Default: 2.0 (backoff padrão: 2^attempt)
  - Exemplo: 1.5 para backoff mais lento, 3.0 para backoff mais agressivo
  
- **RetryMaxDelaySeconds**: Limite superior do delay entre retries
  - Range: 1 a 300 segundos
  - Default: 60 segundos
  - Previne esperas excessivas em APIs com rate limit alto

### 🔧 NEW METHODS - Métodos Privados (Hidden)
- **BuildRequestParams()**: Constrói hashtable de parâmetros para Invoke-WebRequest
- **CreateSessionCookie()**: Cria WebRequestSession com cookie JSESSIONID
- **ParseResponse()**: Processa resposta HTTP (JSON, raw, vazio)
- **ShouldRetry()**: Decide se deve fazer retry baseado em status code
- **CalculateRetryDelay()**: Calcula delay customizado usando RetryBackoffMultiplier e RetryMaxDelaySeconds

### 📚 EXAMPLES - Extensibilidade
- **Invoke-RequestWithCustomErrorHandler.ps1**: Exemplo completo de herança
  - Custom error handler com circuit breaker pattern
  - Logging automático de erros em arquivo JSON
  - Telemetria customizada (consecutive errors)
  - Demonstra como estender Request class via OOP

### 🎯 BENEFITS
- **Manutenibilidade**: Código mais fácil de entender e modificar
- **Testabilidade**: Métodos privados isolados facilitam unit testing
- **Extensibilidade**: Exemplo prático de como estender via herança
- **Flexibilidade**: Retry customizável para diferentes APIs (GitHub 60s, Twitter 15min)
- **Redução de Bugs**: Lógica isolada reduz efeitos colaterais

### 📊 TECHNICAL DETAILS
```powershell
# Retry customizado para API com rate limit diferente
$config = [RequestConfig]::new('https://api.github.com', $token)
$config.RetryBackoffMultiplier = 1.5  # Backoff mais lento (1.5^attempt)
$config.RetryMaxDelaySeconds = 120    # Máximo 2 minutos de espera

$request = [Request]::new($config)
$repos = $request.Get('/user/repos')

# Herança para custom error handling
class MyCustomRequest : Request {
    MyCustomRequest([RequestConfig] $Config) : base($Config) { }
    
    [PSCustomObject] Invoke([HttpMethod] $Method, [string] $Endpoint, [hashtable] $CustomHeaders, [object] $Body) {
        try {
            return ([Request]$this).Invoke($Method, $Endpoint, $CustomHeaders, $Body)
        } catch {
            # Custom logic aqui (logging, telemetry, circuit breaker, etc.)
            throw
        }
    }
}
```

### ⚡ IMPACT
- **Breaking Changes**: Nenhum (métodos privados são hidden, retry usa defaults existentes)
- **Performance**: Sem impacto (refatoração não muda algoritmo)
- **Code Quality**: ✅ Redução de 66% na complexidade do método Invoke()
- **Maintainability**: ✅ SRP aplicado, cada método tem uma responsabilidade

---

## [3.4.0] - 2026-05-29 (Observability e Segurança)

### ✨ NEW FEATURES
- **GetMetrics()**: Método público para obter estatísticas de performance
  - `TotalRequests`: Total de requisições realizadas
  - `TotalRetries`: Total de tentativas de retry
  - `TotalErrors`: Total de erros encontrados
  - `RetryRate`: Taxa de retry em percentual
  - `ErrorRate`: Taxa de erro em percentual
  - `LastRequestDuration`: Duração do último request em milissegundos

### 🔍 IMPROVEMENTS - Observability
- **Stopwatch Automático**: Mede duração de cada request automaticamente
- **Contadores Inteligentes**: TotalRequests, TotalRetries e TotalErrors incrementados automaticamente
- **Métricas Opt-in**: GetMetrics() disponível quando necessário, sem overhead se não usado
- **Performance Tracking**: Visibilidade de performance em produção para diagnóstico

### 🔒 SECURITY - Sanitização de Logs
- **ToString() Sanitizado**: Credenciais nunca exibidas (nem parcialmente)
  - `Token: [REDACTED]` ao invés de `Token: eyJhbGci...`
  - `Password: [REDACTED]` ao invés de mostrar username sem password
  - `SessionId: [REDACTED]` ao invés de `Session: 380BB1FE14...`
- **Safe para Produção**: Logs podem ser compartilhados sem risco de vazamento
- **Previne Vazamento Acidental**: Proteção contra copy-paste de logs com credenciais

### 🐛 FIXES
- **Métricas Consistentes**: Stopwatch parado corretamente em todos os caminhos de erro
- **Contadores Precisos**: TotalRetries incrementado apenas em retry real (não em primeira tentativa)

### 📚 TECHNICAL DETAILS
```powershell
# Uso de métricas
$request = [Request]::new('https://api.exemplo.com', 'token')
$request.Get('/users')
$request.Get('/posts')
$request.Get('/comments')

$metrics = $request.GetMetrics()
# Resultado:
# TotalRequests   : 3
# TotalRetries    : 0
# TotalErrors     : 0
# RetryRate       : 0%
# ErrorRate       : 0%
# LastRequestDuration : 250ms
```

### ⚡ IMPACT
- **Breaking Changes**: Nenhum (métricas são novas features)
- **Performance**: Overhead mínimo (Stopwatch é leve, contadores são simples)
- **Security**: ✅ Logs 100% sanitizados
- **Observability**: ✅ Diagnóstico facilitado em produção

---

## [3.3.0] - 2026-05-29 (Melhorias de Qualidade e Robustez)

### ✨ IMPROVEMENTS
- **Validação de Configuração**: `RequestConfig.TimeoutSeconds` agora aceita apenas valores entre 1-300 segundos (ValidateRange)
- **Validação de Retry**: `RequestConfig.MaxRetries` agora aceita apenas valores entre 0-10 tentativas (ValidateRange)
- **Encapsulamento**: Propriedades `Request.$Request` e `Request.$Response` agora são `hidden` (melhor encapsulamento)
- **Tratamento de Timeout**: Adicionado catch específico para `[System.TimeoutException]` com mensagem descritiva
- **Validação de Dependências**: Request.psm1 agora valida presença de módulos Logger e Cache ao carregar, exibindo warnings informativos se ausentes

### 🐛 FIXES
- **Configurações Inválidas**: Previne valores negativos ou excessivos em TimeoutSeconds/MaxRetries que causavam erros runtime
- **Diagnóstico de Timeout**: Erros de timeout agora têm mensagem específica ao invés de genérica, facilitando troubleshooting

### 📚 DOCUMENTATION
- **Request.psm1**: Documentação atualizada com dependências externas e links para instalação
- **Comment-based help**: Melhorado .NOTES com instruções de instalação de dependências

### 🔧 TECHNICAL DETAILS
```powershell
# Antes (v3.2.0) - Sem validação
$config = [RequestConfig]::new('https://api.exemplo.com')
$config.TimeoutSeconds = -10  # ❌ Aceito mas causa erro runtime
$config.MaxRetries = 999      # ❌ Aceito mas ineficiente

# Depois (v3.3.0) - Com validação
$config = [RequestConfig]::new('https://api.exemplo.com')
$config.TimeoutSeconds = -10  # ✅ Erro imediato: ValidateRange(1, 300)
$config.MaxRetries = 999      # ✅ Erro imediato: ValidateRange(0, 10)
```

### ⚡ IMPACT
- **Breaking Changes**: Nenhum (mudanças são aditivas ou melhoram validação)
- **Performance**: Sem impacto
- **Security**: Melhor encapsulamento de propriedades internas
- **Usability**: Erros mais claros e prevenção de configurações inválidas

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
