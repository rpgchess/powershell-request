<#
.SYNOPSIS
    Módulo Request - Cliente HTTP genérico com retry logic.

.DESCRIPTION
    Fornece classe base Request para implementação de clientes HTTP robustos.
    
    Recursos:
    - Retry automático para erros temporários (5xx, 429)
    - Backoff exponencial
    - Tratamento de erros HTTP específico
    - Suporte a JSON serialization/deserialization
    - Métodos convenientes (Get, Post, Put, Delete, Patch)
    
    A classe Request pode ser usada standalone ou como classe base para herança.
    
    ARQUITETURA - PADRÃO DE CARREGAMENTO VIA MANIFEST:
    Este módulo segue o padrão de carregamento via manifest (RequiredModules + ScriptsToProcess).
    Classes são carregadas via ScriptsToProcess no .psd1 (SEM 'using module' nos scripts individuais).
    Isso evita duplicação de tipos em PowerShell 5.1.
    
    Scripts externos devem usar 'Import-Module' (não 'using module'):
        Import-Module '.\Request.psd1' -Force
    
    IMPORTANTE: Este módulo depende de módulos externos:
    - Logger v1.0.0+ (logging estruturado)
    - Cache v1.0.0+ (cache com TTL)
    
    Instale manualmente antes de usar:
    Import-Module '..\powershell-logger\Logger.psd1' -Force
    Import-Module '..\powershell-cache\Cache.psd1' -Force

.EXAMPLE
    # Uso direto
    Import-Module '.\Request.psd1' -Force
    
    $config = [PSCustomObject]@{
        BaseUrl = 'https://api.exemplo.com'
        TimeoutSeconds = 30
        MaxRetries = 3
    }
    $config | Add-Member -MemberType ScriptMethod -Name GetBaseUrl -Value { return $this.BaseUrl }
    $config | Add-Member -MemberType ScriptMethod -Name GetDefaultHeaders -Value { 
        return @{ 'Authorization' = 'Bearer token' }
    }
    
    $request = [Request]::new($config)
    $users = $request.Get('/users')

.EXAMPLE
    # Herança em classe de serviço
    class MyApiService : Request {
        MyApiService([object] $Config) : base($Config) { }
        
        [PSCustomObject] GetUsers() {
            return $this.Get('/api/users')
        }
        
        [PSCustomObject] CreateUser([hashtable] $UserData) {
            return $this.Post('/api/users', $UserData)
        }
    }

.NOTES
    Author: Claudio Almeida
    Date: 2026-06-01
    Version: 3.6.0
    
    Changes v3.6.0:
    - Logger v1.0.0+ adicionado como RequiredModule
    - Write-Warning, Write-Verbose, Write-Error substituídos por Logger
    - Logging estruturado em todos os requests HTTP
    - Níveis: DEBUG (verbose), WARN (retry), ERROR (falhas)
    
    Changes v3.5.1:
    - Padrão de carregamento via manifest explicitamente documentado
    - Scripts de exemplo usam Import-Module (não 'using module')
    - Compatibilidade com PowerShell 5.1 otimizada
    
    Dependências externas:
    - Logger v1.0.0+ : https://github.com/rpgchess/powershell-logger (RequiredModule)
    - Cache v1.0.0+  : https://github.com/rpgchess/powershell-cache (opcional)
#>

# Classe Request carregada via ScriptsToProcess no manifesto .psd1

# Exportar tudo
Export-ModuleMember -Function * -Variable * -Alias * -Cmdlet *
