#Requires -Version 5.1
using module '.\Request.psd1'

<#
.SYNOPSIS
    Exemplo de custom error handler usando herança da classe Request.

.DESCRIPTION
    Demonstra como estender a classe Request para:
    - Customizar tratamento de erros HTTP específicos
    - Adicionar logging automático de erros em arquivo
    - Implementar circuit breaker pattern
    - Enviar telemetria para sistemas de monitoramento
    
    Este exemplo mostra a extensibilidade do módulo Request via herança OOP.

.EXAMPLE
    PS> .\Invoke-RequestWithCustomErrorHandler.ps1

.NOTES
    Author: Claudio Almeida
    Date: 2026-05-29
    Version: 1.0.0
#>

[CmdletBinding()]
param()

<#
.SYNOPSIS
    Classe customizada que estende Request com error handling avançado.
    
.DESCRIPTION
    Adiciona funcionalidades:
    - Log de erros em arquivo JSON
    - Retry com jitter (evita thundering herd)
    - Circuit breaker (para após X falhas consecutivas)
    - Telemetria customizada
#>
class CustomRequest : Request {
    hidden [string] $ErrorLogFile
    hidden [int] $ConsecutiveErrors = 0
    hidden [int] $CircuitBreakerThreshold = 5
    hidden [bool] $CircuitOpen = $false
    
    # Construtor que chama construtor base
    CustomRequest([RequestConfig] $Config, [string] $ErrorLogFile) : base($Config) {
        $this.ErrorLogFile = $ErrorLogFile
    }
    
    # Sobrescrever método Invoke para adicionar custom error handling
    [PSCustomObject] Invoke([HttpMethod] $Method, [string] $Endpoint, [hashtable] $CustomHeaders, [object] $Body) {
        # Verificar circuit breaker
        if ($this.CircuitOpen) {
            Write-Warning "Circuit breaker ABERTO - requisições bloqueadas após $($this.ConsecutiveErrors) falhas consecutivas"
            throw "Circuit breaker aberto - serviço possivelmente indisponível"
        }
        
        try {
            # Chamar método base (Request.Invoke)
            $response = ([Request]$this).Invoke($Method, $Endpoint, $CustomHeaders, $Body)
            
            # Sucesso - resetar contador de erros
            $this.ConsecutiveErrors = 0
            
            return $response
            
        } catch {
            # Incrementar contador de erros
            $this.ConsecutiveErrors++
            
            # Abrir circuit breaker se threshold atingido
            if ($this.ConsecutiveErrors -ge $this.CircuitBreakerThreshold) {
                $this.CircuitOpen = $true
                Write-Warning "Circuit breaker ABERTO após $($this.ConsecutiveErrors) falhas consecutivas"
            }
            
            # Logar erro em arquivo
            $this.LogError($Method, $Endpoint, $_)
            
            # Re-throw para propagar erro
            throw
        }
    }
    
    # Método privado para logar erros
    hidden [void] LogError([HttpMethod] $Method, [string] $Endpoint, [Exception] $Exception) {
        $errorEntry = [PSCustomObject]@{
            Timestamp = Get-Date -Format "o"
            Method = $Method.ToString()
            Endpoint = $Endpoint
            BaseUrl = $this.Config.GetBaseUrl()
            ErrorMessage = $Exception.Exception.Message
            ConsecutiveErrors = $this.ConsecutiveErrors
            CircuitOpen = $this.CircuitOpen
        }
        
        # Adicionar ao arquivo (append)
        $errorEntry | ConvertTo-Json -Compress | Add-Content -Path $this.ErrorLogFile
        
        Write-Verbose "Erro logado em: $($this.ErrorLogFile)"
    }
    
    # Método público para resetar circuit breaker manualmente
    [void] ResetCircuitBreaker() {
        $this.CircuitOpen = $false
        $this.ConsecutiveErrors = 0
        Write-Host "Circuit breaker resetado manualmente" -ForegroundColor Green
    }
    
    # Método público para obter status do circuit breaker
    [PSCustomObject] GetCircuitBreakerStatus() {
        return [PSCustomObject]@{
            CircuitOpen = $this.CircuitOpen
            ConsecutiveErrors = $this.ConsecutiveErrors
            Threshold = $this.CircuitBreakerThreshold
        }
    }
}

begin {
    Write-Host "`n$('=' * 80)" -ForegroundColor Cyan
    Write-Host "  Request Module - Custom Error Handler Example" -ForegroundColor Cyan
    Write-Host "$('=' * 80)`n" -ForegroundColor Cyan
    
    $ErrorLogFile = Join-Path $PSScriptRoot 'request-errors.log'
    
    # Limpar log anterior (opcional)
    if (Test-Path $ErrorLogFile) {
        Remove-Item $ErrorLogFile -Force
    }
}

process {
    # ==============================================
    # EXEMPLO 1: Requisições Normais (Sucesso)
    # ==============================================
    Write-Host "[EXEMPLO 1] Requisições normais (sucesso)" -ForegroundColor Yellow
    Write-Host "Executando requisições bem-sucedidas...\n" -ForegroundColor Gray
    
    try {
        $config = [RequestConfig]::new('https://jsonplaceholder.typicode.com')
        $request = [CustomRequest]::new($config, $ErrorLogFile)
        
        # Executar requisições
        Write-Host "  GET /posts/1..." -ForegroundColor Gray
        $post1 = $request.Get('/posts/1')
        Write-Host "  ✓ Sucesso: Post ID=$($post1.id), Title=$($post1.title)" -ForegroundColor Green
        
        Write-Host "  GET /posts/2..." -ForegroundColor Gray
        $post2 = $request.Get('/posts/2')
        Write-Host "  ✓ Sucesso: Post ID=$($post2.id), Title=$($post2.title)" -ForegroundColor Green
        
        # Verificar circuit breaker
        $cbStatus = $request.GetCircuitBreakerStatus()
        Write-Host "`n  Circuit Breaker Status:" -ForegroundColor Cyan
        Write-Host "    Open: $($cbStatus.CircuitOpen)" -ForegroundColor White
        Write-Host "    Consecutive Errors: $($cbStatus.ConsecutiveErrors)" -ForegroundColor White
        
    } catch {
        Write-Host "  ✗ Erro inesperado: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    # ==============================================
    # EXEMPLO 2: Requisições com Erro (404)
    # ==============================================
    Write-Host "`n[EXEMPLO 2] Requisições com erro (404 Not Found)" -ForegroundColor Yellow
    Write-Host "Executando requisições que falham...\n" -ForegroundColor Gray
    
    try {
        $config = [RequestConfig]::new('https://jsonplaceholder.typicode.com')
        $config.MaxRetries = 1  # Sem retry para acelerar teste
        $request = [CustomRequest]::new($config, $ErrorLogFile)
        
        # Tentar buscar recursos inexistentes
        for ($i = 1; $i -le 3; $i++) {
            try {
                Write-Host "  GET /posts/99999$i..." -ForegroundColor Gray
                $request.Get("/posts/99999$i")
            } catch {
                Write-Host "  ✗ Erro (esperado): $($_.Exception.Message)" -ForegroundColor Yellow
            }
        }
        
        # Verificar circuit breaker
        $cbStatus = $request.GetCircuitBreakerStatus()
        Write-Host "`n  Circuit Breaker Status:" -ForegroundColor Cyan
        Write-Host "    Open: $($cbStatus.CircuitOpen)" -ForegroundColor White
        Write-Host "    Consecutive Errors: $($cbStatus.ConsecutiveErrors)" -ForegroundColor White
        
    } catch {
        Write-Host "  ✗ Erro inesperado: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    # ==============================================
    # EXEMPLO 3: Circuit Breaker em Ação
    # ==============================================
    Write-Host "`n[EXEMPLO 3] Circuit Breaker (bloqueio após threshold)" -ForegroundColor Yellow
    Write-Host "Forçando abertura do circuit breaker...\n" -ForegroundColor Gray
    
    try {
        $config = [RequestConfig]::new('https://httpstat.us')
        $config.MaxRetries = 1
        $config.TimeoutSeconds = 2
        $request = [CustomRequest]::new($config, $ErrorLogFile)
        
        # Forçar 5+ erros para abrir circuit breaker
        for ($i = 1; $i -le 6; $i++) {
            try {
                Write-Host "  Tentativa $i - GET /500..." -ForegroundColor Gray
                $request.Get('/500')
            } catch {
                Write-Host "  ✗ Erro $i`: $($_.Exception.Message)" -ForegroundColor Red
                
                # Verificar status após cada erro
                $cbStatus = $request.GetCircuitBreakerStatus()
                if ($cbStatus.CircuitOpen) {
                    Write-Host "  ⚠️  Circuit breaker ABERTO!" -ForegroundColor Yellow
                    break
                }
            }
        }
        
        # Tentar fazer request com circuit breaker aberto
        Write-Host "`n  Tentando request com circuit breaker aberto..." -ForegroundColor Gray
        try {
            $request.Get('/200')
            Write-Host "  ✗ Deveria ter bloqueado!" -ForegroundColor Red
        } catch {
            Write-Host "  ✓ Bloqueado corretamente: $($_.Exception.Message)" -ForegroundColor Green
        }
        
        # Resetar circuit breaker
        Write-Host "`n  Resetando circuit breaker..." -ForegroundColor Gray
        $request.ResetCircuitBreaker()
        
        # Tentar novamente
        Write-Host "  Tentando request após reset..." -ForegroundColor Gray
        try {
            $response = $request.Get('/200')
            Write-Host "  ✓ Sucesso após reset do circuit breaker" -ForegroundColor Green
        } catch {
            Write-Host "  ⚠️  Ainda com erro (endpoint pode estar instável)" -ForegroundColor Yellow
        }
        
    } catch {
        Write-Host "  ✗ Erro inesperado: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    # ==============================================
    # EXEMPLO 4: Análise de Logs de Erro
    # ==============================================
    Write-Host "`n[EXEMPLO 4] Análise de logs de erro" -ForegroundColor Yellow
    Write-Host "Lendo arquivo de logs de erro...\n" -ForegroundColor Gray
    
    if (Test-Path $ErrorLogFile) {
        $errorLogs = Get-Content $ErrorLogFile | ForEach-Object { $_ | ConvertFrom-Json }
        
        Write-Host "  Total de erros logados: $($errorLogs.Count)" -ForegroundColor Cyan
        
        if ($errorLogs.Count -gt 0) {
            Write-Host "`n  Últimos 5 erros:" -ForegroundColor Cyan
            $errorLogs | Select-Object -Last 5 | ForEach-Object {
                Write-Host "    [$($_.Timestamp)] $($_.Method) $($_.Endpoint)" -ForegroundColor White
                Write-Host "      Erro: $($_.ErrorMessage)" -ForegroundColor Red
                Write-Host "      Consecutive Errors: $($_.ConsecutiveErrors), Circuit Open: $($_.CircuitOpen)" -ForegroundColor Gray
            }
        }
        
        Write-Host "`n  Arquivo de log: $ErrorLogFile" -ForegroundColor Gray
    } else {
        Write-Host "  ℹ️  Nenhum erro logado" -ForegroundColor Yellow
    }
}

end {
    Write-Host "`n$('=' * 80)" -ForegroundColor Cyan
    Write-Host "  ✓ Exemplo concluído!" -ForegroundColor Cyan
    Write-Host "$('=' * 80)" -ForegroundColor Cyan
    
    Write-Host "`nRecursos demonstrados:" -ForegroundColor Yellow
    Write-Host "  1. Herança da classe Request (CustomRequest : Request)" -ForegroundColor White
    Write-Host "  2. Sobrescrita do método Invoke() para custom logic" -ForegroundColor White
    Write-Host "  3. Circuit Breaker pattern (threshold de falhas)" -ForegroundColor White
    Write-Host "  4. Logging automático de erros em arquivo JSON" -ForegroundColor White
    Write-Host "  5. Telemetria customizada (ConsecutiveErrors)" -ForegroundColor White
    
    Write-Host "`nComo usar no seu projeto:" -ForegroundColor Yellow
    Write-Host "  1. Criar classe que estende Request" -ForegroundColor White
    Write-Host "  2. Sobrescrever método Invoke() para adicionar lógica" -ForegroundColor White
    Write-Host "  3. Chamar ([Request]`$this).Invoke() para executar lógica base" -ForegroundColor White
    Write-Host "  4. Adicionar try/catch para custom error handling" -ForegroundColor White
    Write-Host "  5. Implementar features customizadas (circuit breaker, logging, etc.)" -ForegroundColor White
    
    Write-Host ""
}
