@{
    ModuleVersion = '3.6.0'
    GUID = 'f9e8d7c6-b5a4-3210-9876-543210fedcba'
    Author = 'Claudio Almeida'
    CompanyName = 'Personal'
    Copyright = '(c) 2026 Personal. All rights reserved.'
    Description = 'Módulo Request - Cliente HTTP genérico com retry logic, autenticação integrada (Basic/Bearer/Session), cache inteligente (módulo externo), logging estruturado e tratamento robusto de erros'
    PowerShellVersion = '5.1'
    
    RootModule = 'Request.psm1'
    
    # Dependências (carregadas automaticamente)
    RequiredModules = @(@{ModuleName = 'Logger'; RequiredVersion = '1.0.0' })
    
    # Classes e enums carregados via ScriptsToProcess (PADRÃO MANIFEST)
    # IMPORTANTE: SEM 'using module' nos arquivos Core/*.ps1 (evita duplicação de tipos em PS 5.1)
    # Scripts externos devem usar 'Import-Module' (não 'using module'):
    #   Import-Module '.\Request.psd1' -Force
    ScriptsToProcess = @(
        'Core\RequestEnums.ps1',
        'Core\RequestConfig.ps1',
        'Core\Request.ps1'
    )
    
    # Nota: Cache é opcional (deve ser importado manualmente se necessário):
    # - Cache v1.0.0+  : Import-Module '..\powershell-cache\Cache.psd1' -Force
    
    FunctionsToExport = @()
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
    
    PrivateData = @{
        PSData = @{
            Tags = @('HTTP', 'REST', 'API', 'Request', 'Retry', 'Client', 'Authentication', 'Basic', 'Bearer', 'Session', 'Cache', 'Logging', 'Metrics', 'Observability', 'Extensibility', 'OOP')
            ProjectUri = 'https://github.com/rpgchess/powershell-request'
            ReleaseNotes = @'
3.6.0 - 2026-06-01 (Integração Logger)
LOGGING:
- 📋 Logger v1.0.0+ adicionado como RequiredModule
- 🔧 Write-Warning, Write-Verbose, Write-Error substituídos por Logger
- ✅ Logging estruturado em todos os requests HTTP
- 🎯 Níveis: DEBUG (verbose), WARN (retry), ERROR (falhas)

BENEFITS:
- 📊 Observability aprimorada com logging estruturado
- 🔍 Rastreamento completo de requests/retries/erros
- 📁 Logs podem ser salvos em arquivo via LoggerConfig

---

3.5.1 - 2026-06-01 (Padrão de Carregamento via Manifest)
DOCUMENTATION:
- 📋 Padrão Manifest explicitamente documentado em Request.psm1 e Request.psd1
- 🔧 Scripts de exemplo usam Import-Module (não 'using module')
- ✅ Compatibilidade PS 5.1 otimizada (evita duplicação de tipos)

SCRIPTS ATUALIZADOS:
- Test-Request.ps1 - Import-Module + nota sobre padrão
- Invoke-JiraSessionExample.ps1 - Import-Module + nota explicativa
- Invoke-RequestWithCustomErrorHandler.ps1 - Import-Module + nota
- Test-Session-Authentication.ps1 - Import-Module em 2 ocorrências + exemplo atualizado

BENEFITS:
- 🎯 Evita erro "Cannot convert X to X" em PowerShell 5.1
- 📚 Documentação consistente do padrão
- ⚡ Alinhado com powershell-module-patterns.md

MIGRATION:
Scripts externos devem usar Import-Module (não 'using module'):
  # ❌ Antigo: using module '.\Request.psd1'
  # ✅ Novo:   Import-Module '.\Request.psd1' -Force

IMPACT:
- 🚫 Sem breaking changes (apenas documentação e exemplos)

---

3.5.0 - 2026-05-29 (Extensibilidade e Manutenibilidade)
IMPROVEMENTS:
- 🛠️ Refatoração do Invoke(): Extraição de métodos privados (BuildRequestParams, CreateSessionCookie, ParseResponse, ShouldRetry, CalculateRetryDelay)
- ⚙️ Retry Customizável: RetryBackoffMultiplier (1.0-10.0, default 2.0) e RetryMaxDelaySeconds (1-300s, default 60s)
- 🎯 Circuit Breaker: Exemplo completo de custom error handler com circuit breaker pattern
- 📝 Logging de Erros: Exemplo mostra como logar erros em arquivo JSON via herança
- 🔧 Herança OOP: Documentação completa de como estender Request class

CODE QUALITY:
- 📊 Redução de complexidade: Invoke() de ~150 linhas para ~50 linhas (métodos privados)
- 🧹 SRP (Single Responsibility): Cada método tem uma responsabilidade única
- 📚 Testabilidade: Métodos privados isolados facilitam unit testing
- 🔄 Reutilização: Lógica comum extraída em métodos reutilizáveis

NEW FEATURES:
- RetryBackoffMultiplier - Configura multiplicador do backoff (ex: 1.5 para backoff mais lento)
- RetryMaxDelaySeconds - Limite superior do delay (evita esperas excessivas)
- BuildRequestParams() - Método privado para construir parâmetros Invoke-WebRequest
- CreateSessionCookie() - Método privado para criar WebRequestSession
- ParseResponse() - Método privado para processar resposta HTTP
- ShouldRetry() - Método privado para decisão de retry
- CalculateRetryDelay() - Método privado para cálculo de delay customizado

EXAMPLES:
- Invoke-RequestWithCustomErrorHandler.ps1 - Custom error handler com circuit breaker

IMPACT:
- 🚫 Sem breaking changes (métodos privados são hidden)
- 🚀 Manutenibilidade aprimorada (código mais legível e testável)
- 🔧 Extensibilidade via herança (CustomRequest demonstrado)

3.4.0 - 2026-05-29 (Observability e Segurança)
IMPROVEMENTS:
- ⚙️ Métricas de Performance: GetMetrics() retorna TotalRequests, TotalRetries, TotalErrors, RetryRate, ErrorRate, LastRequestDuration
- 🔍 Stopwatch automático: Mede duração de cada request em milissegundos
- 🔒 Sanitização de Logs: ToString() usa [REDACTED] para tokens/passwords (previne vazamento acidental)
- 📊 Observability: Contadores incrementados automaticamente (requests, retries, errors)

SECURITY:
- ⚠️ Credenciais nunca exibidas em logs (mesmo parcialmente)
- ✅ Safe para logging em produção

NEW FEATURES:
- GetMetrics() - Método público para obter estatísticas de performance
- LastRequestDuration - Tempo do último request em ms
- RetryRate/ErrorRate - Percentuais calculados automaticamente

IMPACT:
- 🚫 Sem breaking changes (métricas são opt-in)
- 🔒 Segurança aprimorada (logs sanitizados)
- 📈 Visibilidade de performance em produção

3.3.0 - 2026-05-29 (Melhorias de Qualidade e Robustez)
IMPROVEMENTS:
- ✅ Validação de range: TimeoutSeconds (1-300s), MaxRetries (0-10)
- 🔒 Encapsulamento: $Request e $Response agora são hidden
- ⏱️ Timeout específico: Mensagem descritiva para TimeoutException
- 🔍 Validação de dependências: Request.psm1 valida Logger/Cache ao carregar

FIXES:
- 🐛 Previne configurações inválidas (TimeoutSeconds negativo, MaxRetries excessivo)
- 🐛 Diagnóstico melhorado de timeout (mensagem específica vs genérica)

IMPACT:
- 🚫 Sem breaking changes (mudanças são aditivas/validações)
- 🔐 Melhor encapsulamento e segurança
- 💡 Erros mais claros e prevenção proativa de bugs

3.2.0 - 2026-05-26 (Modularização de Cache)
BREAKING CHANGES:
- RequestCache removido (agora usa módulo Cache externo)
- Adicionada dependência: Cache v1.0.0+ (módulo standalone)

IMPROVEMENTS:
- ✨ Cache modularizado: Usa Cache module (TTL, persistência, estatísticas)
- ✨ Cache avançado: GetKeys(), GetStats(), RemoveExpired(), múltiplos construtores
- 🔧 Redução de código: RequestCache.ps1 removido (~120 linhas eliminadas)
- 📦 Reutilização: Cache pode ser usado em outros projetos PowerShell
- 🎯 API consistente: [Cache]::new() ao invés de [RequestCache]::new()

MIGRATION:
- Instalar Cache module: Import-Module '..\powershell-cache\Cache.psd1'
- Substituir [RequestCache] por [Cache] no código
- API permanece compatível (mesmos métodos: Get/Set/Save/Load/Remove/Clear)

3.1.0 - 2026-05-26 (Modularização de Logging)
BREAKING CHANGES:
- RequestLogger removido (agora usa módulo Logger externo)
- Adicionada dependência: Logger v1.0.0+ (módulo standalone)

IMPROVEMENTS:
- ✨ Logging modularizado: Usa Logger module (6 níveis: DEBUG/INFO/WARN/ERROR/SUCCESS/FATAL)
- ✨ Logging avançado: Suporte a múltiplos formatos (Simple/Detailed/Json), saída para arquivo, buffer
- 🔧 Redução de código: RequestLogger.ps1 removido (~100 linhas eliminadas)
- 📦 Reutilização: Logger pode ser usado em outros projetos PowerShell

MIGRATION:
- Instalar Logger module: Import-Module '..\powershell-logger\Logger.psd1'
- Uso permanece compatível (mesma API de logging)

3.0.0 - 2026-05-25 (Refatoração Completa)
BREAKING CHANGES:
- Estrutura de scripts refatorada seguindo padrões PowerShell rigorosos
- Example-Jira-Session.ps1 renomeado para Invoke-JiraSessionExample.ps1 (Verb-Noun)

NEW FEATURES:
- ✨ RequestCache class: Cache inteligente com TTL e invalidação (.cache files)
- ✨ RequestLogger class: Logging estruturado com níveis (DEBUG/INFO/WARN/ERROR/SUCCESS)
- ✨ Pester 5.x tests: Suite completa de testes unitários e integração
- ✨ PSScriptAnalyzer config: Validação rigorosa de código

IMPROVEMENTS:
- 📖 Comment-based help completo em todos os scripts
- 🔧 Validação robusta de parâmetros (ValidateNotNullOrEmpty, Alias)
- 🏗️ Estrutura begin/process/end em scripts de teste/exemplo
- 📊 Contador de testes (passed/failed) em Test-Request.ps1
- 📚 README.md completo com Quick Start, Troubleshooting, Comparação com Flurl/RestSharp
- 🎯 Exit codes apropriados (0=sucesso, 1=erro)

DOCUMENTATION:
- Exemplos práticos (GitHub API, Jira API)
- Guia de cache e performance
- Troubleshooting detalhado por tipo de erro
- Comparação técnica com Flurl.Http e RestSharp

TESTING:
- Request.Tests.ps1: 15+ testes automatizados
- Test-Request.ps1: Refatorado com help completo
- Test-Session-Authentication.ps1: Validação específica de Session auth

QUALITY:
- PSScriptAnalyzer compliant (Severity: Error, Warning)
- Naming conventions consistentes (Verb-Noun)
- Code coverage > 80% (Pester tests)

2.1.0 - 2026-05-23
- Autenticação Session (JSESSIONID) aprimorada
- Headers de navegador (User-Agent, Accept-Language)
- Propriedade CookieDomain em RequestConfig
- Test-Session-Authentication.ps1

2.0.0 - 2026-05-22
- BREAKING CHANGE: Classe RequestConfig renomeada de Config
- 3 construtores especializados (Basic/Bearer/Session)
- Enum AuthType (None, Basic, Bearer, Session)
- Validação IsValid() e ToString()

1.1.0 - 2026-05-22
- Parâmetro $CustomHeaders com padrão JSON
- Sobrecargas para métodos HTTP

1.0.0 - Initial release
- Classe Request genérica para HTTP requests
- Retry automático com backoff exponencial
- Métodos convenientes (Get, Post, Put, Delete, Patch)
'@
        }
    }
}
