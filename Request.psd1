@{
    ModuleVersion = '3.2.0'
    GUID = 'f9e8d7c6-b5a4-3210-9876-543210fedcba'
    Author = 'Claudio Almeida'
    CompanyName = 'Personal'
    Copyright = '(c) 2026 Personal. All rights reserved.'
    Description = 'Módulo Request - Cliente HTTP genérico com retry logic, autenticação integrada (Basic/Bearer/Session), cache inteligente (módulo externo), logging estruturado e tratamento robusto de erros'
    PowerShellVersion = '5.1'
    
    RootModule = 'Request.psm1'
    
    # Classes e enums carregados antes do módulo (essencial para 'using module')
    ScriptsToProcess = @(
        'Core\RequestEnums.ps1',
        'Core\RequestConfig.ps1',
        'Core\Request.ps1'
    )
    
    # Nota: Módulos externos devem ser importados manualmente:
    # - Logger v1.0.0+ : Import-Module '..\powershell-logger\Logger.psd1' -Force
    # - Cache v1.0.0+  : Import-Module '..\powershell-cache\Cache.psd1' -Force
    
    FunctionsToExport = @()
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
    
    PrivateData = @{
        PSData = @{
            Tags = @('HTTP', 'REST', 'API', 'Request', 'Retry', 'Client', 'Authentication', 'Basic', 'Bearer', 'Session', 'Cache', 'Logging')
            ProjectUri = 'https://github.com/rpgchess/powershell-request'
            ReleaseNotes = @'
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
