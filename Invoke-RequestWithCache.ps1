#Requires -Modules Cache, Logger

<#
.SYNOPSIS
    Exemplo de uso do Request module v3.2.0 com Cache module externo.

.DESCRIPTION
    Demonstra como usar Request com Cache modularizado:
    - Importação correta dos módulos (Cache + Logger + Request)
    - Uso do [Cache] para cachear respostas HTTP
    - Integração com Logger para logging estruturado
    - Padrão de cache miss/hit

.EXAMPLE
    PS> .\Invoke-RequestWithCache.ps1
    Busca usuário do GitHub com cache.

.NOTES
    Author: Claudio Almeida
    Date: 2026-05-26
    Version: 3.2.0
    
    Prerequisites:
    - Cache module v1.0.0+ : Import-Module '..\powershell-cache\Cache.psd1'
    - Logger module v1.0.0+ : Import-Module '..\powershell-logger\Logger.psd1'
    - Request module v3.2.0+ : Import-Module '.\Request.psd1'
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string] $Username = 'octocat',
    
    [Parameter(Mandatory = $false)]
    [int] $CacheTtl = 300  # 5 minutos
)

begin {
    Write-Host "`n$('=' * 70)" -ForegroundColor Cyan
    Write-Host "  Request v3.2.0 + Cache Module - Example" -ForegroundColor Cyan
    Write-Host "$('=' * 70)`n" -ForegroundColor Cyan
    
    # Verificar se módulos estão importados
    $requiredModules = @('Cache', 'Logger', 'Request')
    foreach ($module in $requiredModules) {
        if (-not (Get-Module -Name $module)) {
            Write-Host "✗ Módulo $module não importado. Execute:" -ForegroundColor Red
            Write-Host "  Import-Module '..\powershell-$($module.ToLower())\$module.psd1'" -ForegroundColor Yellow
            return
        }
    }
    
    Write-Host "✓ Módulos carregados: Cache, Logger, Request`n" -ForegroundColor Green
}

process {
    try {
        # Criar instâncias
        Write-Host "Configurando..." -ForegroundColor Yellow
        
        $cache = [Cache]::new('github-api')
        $logger = [Logger]::Instance()
        $request = [Request]::new('https://api.github.com')
        
        Write-Host "✓ Cache: $($cache.CacheFile)" -ForegroundColor Green
        Write-Host "✓ Logger: Singleton instance" -ForegroundColor Green
        Write-Host "✓ Request: GitHub API`n" -ForegroundColor Green
        
        # Definir chave de cache
        $cacheKey = "user-$Username"
        
        # Tentar obter do cache
        Write-Host "Verificando cache..." -ForegroundColor Yellow
        $user = $cache.Get($cacheKey)
        
        if ($null -eq $user) {
            # Cache miss - buscar da API
            Write-Host "✗ Cache miss - buscando da API..." -ForegroundColor Red
            $logger.Info("Cache miss for user: $Username")
            
            $user = $request.Get("/users/$Username")
            
            # Salvar no cache
            $cache.Set($cacheKey, $user, $CacheTtl)
            $cache.Save()
            
            $logger.Success("User cached: $Username (TTL: $CacheTtl seconds)")
            Write-Host "✓ Dados salvos em cache (TTL: $CacheTtl segundos)`n" -ForegroundColor Green
            
        } else {
            # Cache hit
            Write-Host "✓ Cache hit! Dados do cache`n" -ForegroundColor Green
            $logger.Info("Cache hit for user: $Username")
        }
        
        # Exibir dados do usuário
        Write-Host "$('=' * 70)" -ForegroundColor Cyan
        Write-Host "  USER DATA" -ForegroundColor Cyan
        Write-Host "$('=' * 70)" -ForegroundColor Cyan
        Write-Host "Login:        $($user.login)" -ForegroundColor White
        Write-Host "Name:         $($user.name)" -ForegroundColor White
        Write-Host "Company:      $($user.company)" -ForegroundColor White
        Write-Host "Location:     $($user.location)" -ForegroundColor White
        Write-Host "Repos:        $($user.public_repos)" -ForegroundColor White
        Write-Host "Followers:    $($user.followers)" -ForegroundColor White
        Write-Host "Following:    $($user.following)" -ForegroundColor White
        Write-Host "Created:      $($user.created_at)" -ForegroundColor White
        Write-Host "$('=' * 70)`n" -ForegroundColor Cyan
        
        # Estatísticas do cache
        Write-Host "Cache Statistics:" -ForegroundColor Yellow
        $stats = $cache.GetStats()
        Write-Host "  Total entries:   $($stats.TotalEntries)" -ForegroundColor White
        Write-Host "  Valid entries:   $($stats.ValidEntries)" -ForegroundColor White
        Write-Host "  Expired entries: $($stats.ExpiredEntries)" -ForegroundColor White
        
        # Listar chaves válidas
        $keys = $cache.GetKeys()
        if ($keys.Count -gt 0) {
            Write-Host "`nValid cache keys:" -ForegroundColor Yellow
            foreach ($key in $keys) {
                Write-Host "  - $key" -ForegroundColor Gray
            }
        }
        
        Write-Host ""
        
    } catch {
        $logger.Error("Failed to fetch user", $_.Exception)
        Write-Host "✗ Erro: $($_.Exception.Message)" -ForegroundColor Red
        throw
    }
}

end {
    Write-Host "$('=' * 70)" -ForegroundColor Cyan
    Write-Host "  ✓ Example completed!" -ForegroundColor Cyan
    Write-Host "$('=' * 70)`n" -ForegroundColor Cyan
    
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "  1. Execute novamente para ver cache hit" -ForegroundColor Gray
    Write-Host "  2. Aguarde $CacheTtl segundos para expiração" -ForegroundColor Gray
    Write-Host "  3. Use -Username 'outro-usuario' para testar com outro usuário`n" -ForegroundColor Gray
}
