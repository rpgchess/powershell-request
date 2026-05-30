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
    
    IMPORTANTE: Este módulo depende de módulos externos:
    - Logger v1.0.0+ (logging estruturado)
    - Cache v1.0.0+ (cache com TTL)
    
    Instale manualmente antes de usar:
    Import-Module '..\powershell-logger\Logger.psd1' -Force
    Import-Module '..\powershell-cache\Cache.psd1' -Force

.EXAMPLE
    # Uso direto
    using module '.\Request.psd1'
    
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
    Date: 2026-05-22
    Version: 3.3.0
    
    Dependências externas:
    - Logger v1.0.0+ : https://github.com/rpgchess/powershell-logger
    - Cache v1.0.0+  : https://github.com/rpgchess/powershell-cache
#>

# Validar dependências externas
$externalModules = @('Logger', 'Cache')
$missingModules = @()

foreach ($moduleName in $externalModules) {
    if (-not (Get-Module -ListAvailable -Name $moduleName)) {
        $missingModules += $moduleName
    }
}

if ($missingModules.Count -gt 0) {
    $modulesStr = $missingModules -join ', '
    Write-Warning "⚠️  Request module requer os seguintes módulos externos: $modulesStr"
    Write-Warning ""
    Write-Warning "Instale manualmente:"
    foreach ($module in $missingModules) {
        Write-Warning "  Import-Module '..\powershell-$($module.ToLower())\$module.psd1' -Force"
    }
    Write-Warning ""
    Write-Warning "Ou clone dos repositórios:"
    Write-Warning "  git clone https://github.com/rpgchess/powershell-logger"
    Write-Warning "  git clone https://github.com/rpgchess/powershell-cache"
}

# Classe Request carregada via ScriptsToProcess no manifesto .psd1

# Exportar tudo
Export-ModuleMember -Function * -Variable * -Alias * -Cmdlet *
