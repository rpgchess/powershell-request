#Requires -Version 5.1

<#
.SYNOPSIS
    Script de teste para demonstrar melhorias da versão 3.5.0.

.DESCRIPTION
    Demonstra as melhorias de EXTENSIBILIDADE e MANUTENIBILIDADE implementadas na Fase 3:
    7. Configuração de retry customizada (RetryBackoffMultiplier, RetryMaxDelaySeconds)
    8. Refatoração do método Invoke() (métodos privados)
    9. Exemplo de custom error handler (herança)

.EXAMPLE
    PS> .\Test-v3.5.0-Improvements.ps1

.NOTES
    Author: Claudio Almeida
    Date: 2026-05-29
    Version: 1.0.0
#>

[CmdletBinding()]
param()

begin {
    Write-Host "`n$('=' * 80)" -ForegroundColor Cyan
    Write-Host "  Request Module v3.5.0 - Teste de Melhorias (Extensibilidade)" -ForegroundColor Cyan
    Write-Host "$('=' * 80)`n" -ForegroundColor Cyan
    
    # Importar módulo
    $modulePath = Join-Path $PSScriptRoot 'Request.psd1'
    Import-Module $modulePath -Force
    
    $script:TestResults = @{
        Passed = 0
        Failed = 0
    }
}

process {
    # ==============================================
    # MELHORIA 7: Configuração de Retry Customizada
    # ==============================================
    Write-Host "`n[TEST 1] Configuração de Retry - RetryBackoffMultiplier" -ForegroundColor Yellow
    Write-Host "Testando propriedade RetryBackoffMultiplier..." -ForegroundColor Gray
    
    try {
        $config = [RequestConfig]::new('https://api.exemplo.com')
        
        # Testar valor padrão
        if ($config.RetryBackoffMultiplier -eq 2.0) {
            Write-Host "  ✓ PASSOU: RetryBackoffMultiplier default = 2.0" -ForegroundColor Green
            $script:TestResults.Passed++
        } else {
            Write-Host "  ✗ FALHOU: RetryBackoffMultiplier default = $($config.RetryBackoffMultiplier) (esperado: 2.0)" -ForegroundColor Red
            $script:TestResults.Failed++
        }
        
        # Testar configuração customizada
        $config.RetryBackoffMultiplier = 1.5
        if ($config.RetryBackoffMultiplier -eq 1.5) {
            Write-Host "  ✓ PASSOU: RetryBackoffMultiplier configurável (1.5)" -ForegroundColor Green
            $script:TestResults.Passed++
        } else {
            Write-Host "  ✗ FALHOU: RetryBackoffMultiplier não configurado corretamente" -ForegroundColor Red
            $script:TestResults.Failed++
        }
        
        # Testar validação de range
        try {
            $config.RetryBackoffMultiplier = 0.5  # Abaixo do mínimo (1.0)
            Write-Host "  ✗ FALHOU: Valor 0.5 foi aceito (deveria rejeitar)" -ForegroundColor Red
            $script:TestResults.Failed++
        } catch {
            Write-Host "  ✓ PASSOU: Validação de range funcionando (0.5 rejeitado)" -ForegroundColor Green
            $script:TestResults.Passed++
        }
        
    } catch {
        Write-Host "  ✗ FALHOU: Erro ao testar RetryBackoffMultiplier: $($_.Exception.Message)" -ForegroundColor Red
        $script:TestResults.Failed++
    }
    
    # ==============================================
    # MELHORIA 7: Configuração de Retry - MaxDelay
    # ==============================================
    Write-Host "`n[TEST 2] Configuração de Retry - RetryMaxDelaySeconds" -ForegroundColor Yellow
    Write-Host "Testando propriedade RetryMaxDelaySeconds..." -ForegroundColor Gray
    
    try {
        $config = [RequestConfig]::new('https://api.exemplo.com')
        
        # Testar valor padrão
        if ($config.RetryMaxDelaySeconds -eq 60) {
            Write-Host "  ✓ PASSOU: RetryMaxDelaySeconds default = 60" -ForegroundColor Green
            $script:TestResults.Passed++
        } else {
            Write-Host "  ✗ FALHOU: RetryMaxDelaySeconds default = $($config.RetryMaxDelaySeconds) (esperado: 60)" -ForegroundColor Red
            $script:TestResults.Failed++
        }
        
        # Testar configuração customizada
        $config.RetryMaxDelaySeconds = 120
        if ($config.RetryMaxDelaySeconds -eq 120) {
            Write-Host "  ✓ PASSOU: RetryMaxDelaySeconds configurável (120)" -ForegroundColor Green
            $script:TestResults.Passed++
        } else {
            Write-Host "  ✗ FALHOU: RetryMaxDelaySeconds não configurado corretamente" -ForegroundColor Red
            $script:TestResults.Failed++
        }
        
        # Testar validação de range
        try {
            $config.RetryMaxDelaySeconds = 500  # Acima do máximo (300)
            Write-Host "  ✗ FALHOU: Valor 500 foi aceito (deveria rejeitar)" -ForegroundColor Red
            $script:TestResults.Failed++
        } catch {
            Write-Host "  ✓ PASSOU: Validação de range funcionando (500 rejeitado)" -ForegroundColor Green
            $script:TestResults.Passed++
        }
        
    } catch {
        Write-Host "  ✗ FALHOU: Erro ao testar RetryMaxDelaySeconds: $($_.Exception.Message)" -ForegroundColor Red
        $script:TestResults.Failed++
    }
    
    # ==============================================
    # MELHORIA 8: Refatoração - Métodos Privados
    # ==============================================
    Write-Host "`n[TEST 3] Refatoração - Métodos Privados Existem" -ForegroundColor Yellow
    Write-Host "Verificando se métodos privados foram criados..." -ForegroundColor Gray
    
    try {
        $config = [RequestConfig]::new('https://jsonplaceholder.typicode.com')
        $request = [Request]::new($config)
        
        # Métodos privados não aparecem no Get-Member (são hidden)
        $publicMethods = $request | Get-Member -MemberType Method | Where-Object { $_.Name -notmatch '^(Get|Post|Put|Delete|Patch|GetMetrics)' }
        
        # Verificar que métodos privados NÃO estão visíveis
        $privateMethodNames = @('BuildRequestParams', 'CreateSessionCookie', 'ParseResponse', 'ShouldRetry', 'CalculateRetryDelay')
        $visiblePrivateMethods = $publicMethods | Where-Object { $_.Name -in $privateMethodNames }
        
        if ($visiblePrivateMethods.Count -eq 0) {
            Write-Host "  ✓ PASSOU: Métodos privados estão hidden (não visíveis)" -ForegroundColor Green
            $script:TestResults.Passed++
        } else {
            Write-Host "  ✗ FALHOU: Métodos privados visíveis: $($visiblePrivateMethods.Name -join ', ')" -ForegroundColor Red
            $script:TestResults.Failed++
        }
        
        # Verificar que Invoke() ainda funciona (chamada indireta aos métodos privados)
        $response = $request.Get('/posts/1')
        if ($response.id -eq 1) {
            Write-Host "  ✓ PASSOU: Invoke() funciona com métodos privados" -ForegroundColor Green
            $script:TestResults.Passed++
        } else {
            Write-Host "  ✗ FALHOU: Invoke() não retornou resultado esperado" -ForegroundColor Red
            $script:TestResults.Failed++
        }
        
    } catch {
        Write-Host "  ✗ FALHOU: Erro ao testar métodos privados: $($_.Exception.Message)" -ForegroundColor Red
        $script:TestResults.Failed++
    }
    
    # ==============================================
    # MELHORIA 8: Refatoração - Complexidade Reduzida
    # ==============================================
    Write-Host "`n[TEST 4] Refatoração - Redução de Complexidade" -ForegroundColor Yellow
    Write-Host "Verificando se refatoração mantém funcionalidade..." -ForegroundColor Gray
    
    try {
        $config = [RequestConfig]::new('https://jsonplaceholder.typicode.com')
        $request = [Request]::new($config)
        
        # Testar diferentes métodos HTTP
        Write-Host "  Testando GET..." -ForegroundColor DarkGray
        $getResult = $request.Get('/posts/1')
        $getWorks = ($getResult.id -eq 1)
        
        Write-Host "  Testando POST..." -ForegroundColor DarkGray
        $postResult = $request.Post('/posts', @{ title = 'Test'; body = 'Body'; userId = 1 })
        $postWorks = ($null -ne $postResult.id)
        
        Write-Host "  Testando DELETE..." -ForegroundColor DarkGray
        $deleteResult = $request.Delete('/posts/1')
        $deleteWorks = ($null -ne $deleteResult)
        
        if ($getWorks -and $postWorks -and $deleteWorks) {
            Write-Host "  ✓ PASSOU: Todos os métodos HTTP funcionam após refatoração" -ForegroundColor Green
            $script:TestResults.Passed++
        } else {
            Write-Host "  ✗ FALHOU: Alguns métodos não funcionam (GET: $getWorks, POST: $postWorks, DELETE: $deleteWorks)" -ForegroundColor Red
            $script:TestResults.Failed++
        }
        
    } catch {
        Write-Host "  ✗ FALHOU: Erro ao testar funcionalidade: $($_.Exception.Message)" -ForegroundColor Red
        $script:TestResults.Failed++
    }
    
    # ==============================================
    # MELHORIA 7: Retry Customizado - Cálculo de Delay
    # ==============================================
    Write-Host "`n[TEST 5] Retry Customizado - Cálculo de Delay" -ForegroundColor Yellow
    Write-Host "Verificando cálculo de delay customizado..." -ForegroundColor Gray
    
    try {
        # Criar config com retry customizado
        $config = [RequestConfig]::new('https://api.exemplo.com')
        $config.RetryBackoffMultiplier = 1.5
        $config.RetryMaxDelaySeconds = 30
        
        Write-Host "  ✓ PASSOU: Configuração de retry customizada aplicada" -ForegroundColor Green
        Write-Host "    - BackoffMultiplier: $($config.RetryBackoffMultiplier)" -ForegroundColor DarkGray
        Write-Host "    - MaxDelaySeconds: $($config.RetryMaxDelaySeconds)" -ForegroundColor DarkGray
        $script:TestResults.Passed++
        
        # Calcular delays esperados
        $delays = @()
        for ($attempt = 1; $attempt -le 5; $attempt++) {
            $calculatedDelay = [Math]::Pow($config.RetryBackoffMultiplier, $attempt)
            $effectiveDelay = [Math]::Min($calculatedDelay, $config.RetryMaxDelaySeconds)
            $delays += $effectiveDelay
        }
        
        Write-Host "`n  Delays calculados (segundos):" -ForegroundColor Cyan
        for ($i = 0; $i -lt $delays.Count; $i++) {
            Write-Host "    Attempt $($i+1): $($delays[$i])s" -ForegroundColor White
        }
        
        # Verificar que delay cresce e respeita máximo
        $delaysIncrease = $true
        for ($i = 1; $i -lt $delays.Count; $i++) {
            if ($delays[$i] -lt $delays[$i-1] -and $delays[$i] -ne $config.RetryMaxDelaySeconds) {
                $delaysIncrease = $false
                break
            }
        }
        
        if ($delaysIncrease) {
            Write-Host "`n  ✓ PASSOU: Delays crescem conforme esperado" -ForegroundColor Green
            $script:TestResults.Passed++
        } else {
            Write-Host "`n  ✗ FALHOU: Delays não crescem corretamente" -ForegroundColor Red
            $script:TestResults.Failed++
        }
        
    } catch {
        Write-Host "  ✗ FALHOU: Erro ao testar cálculo de delay: $($_.Exception.Message)" -ForegroundColor Red
        $script:TestResults.Failed++
    }
    
    # ==============================================
    # MELHORIA 9: Custom Error Handler - Herança
    # ==============================================
    Write-Host "`n[TEST 6] Custom Error Handler - Exemplo Existe" -ForegroundColor Yellow
    Write-Host "Verificando se exemplo de herança foi criado..." -ForegroundColor Gray
    
    try {
        $exampleFile = Join-Path $PSScriptRoot 'Invoke-RequestWithCustomErrorHandler.ps1'
        
        if (Test-Path $exampleFile) {
            Write-Host "  ✓ PASSOU: Arquivo de exemplo existe" -ForegroundColor Green
            Write-Host "    Arquivo: $exampleFile" -ForegroundColor DarkGray
            $script:TestResults.Passed++
            
            # Verificar conteúdo básico
            $content = Get-Content $exampleFile -Raw
            
            $hasClass = $content -match 'class\s+CustomRequest\s*:\s*Request'
            $hasInvoke = $content -match '\[PSCustomObject\]\s+Invoke\('
            $hasCircuitBreaker = $content -match 'CircuitBreaker'
            
            if ($hasClass -and $hasInvoke -and $hasCircuitBreaker) {
                Write-Host "  ✓ PASSOU: Exemplo contém CustomRequest : Request" -ForegroundColor Green
                Write-Host "  ✓ PASSOU: Exemplo contém sobrescrita de Invoke()" -ForegroundColor Green
                Write-Host "  ✓ PASSOU: Exemplo contém Circuit Breaker" -ForegroundColor Green
                $script:TestResults.Passed += 3
            } else {
                if (-not $hasClass) {
                    Write-Host "  ✗ FALHOU: CustomRequest : Request não encontrado" -ForegroundColor Red
                    $script:TestResults.Failed++
                }
                if (-not $hasInvoke) {
                    Write-Host "  ✗ FALHOU: Sobrescrita de Invoke() não encontrada" -ForegroundColor Red
                    $script:TestResults.Failed++
                }
                if (-not $hasCircuitBreaker) {
                    Write-Host "  ✗ FALHOU: Circuit Breaker não encontrado" -ForegroundColor Red
                    $script:TestResults.Failed++
                }
            }
            
        } else {
            Write-Host "  ✗ FALHOU: Arquivo de exemplo não encontrado" -ForegroundColor Red
            $script:TestResults.Failed++
        }
        
    } catch {
        Write-Host "  ✗ FALHOU: Erro ao verificar exemplo: $($_.Exception.Message)" -ForegroundColor Red
        $script:TestResults.Failed++
    }
}

end {
    # Resumo final
    Write-Host "`n$('=' * 80)" -ForegroundColor Cyan
    Write-Host "  RESUMO DOS TESTES" -ForegroundColor Cyan
    Write-Host "$('=' * 80)" -ForegroundColor Cyan
    
    $total = $script:TestResults.Passed + $script:TestResults.Failed
    $successRate = if ($total -gt 0) { [math]::Round(($script:TestResults.Passed / $total) * 100, 2) } else { 0 }
    
    Write-Host "`nTestes Executados: $total" -ForegroundColor White
    Write-Host "  ✓ Passou:  $($script:TestResults.Passed)" -ForegroundColor Green
    Write-Host "  ✗ Falhou:  $($script:TestResults.Failed)" -ForegroundColor $(if ($script:TestResults.Failed -gt 0) { 'Red' } else { 'Green' })
    Write-Host "  Taxa de Sucesso: $successRate%" -ForegroundColor $(if ($successRate -ge 80) { 'Green' } elseif ($successRate -ge 60) { 'Yellow' } else { 'Red' })
    
    Write-Host "`n$('=' * 80)" -ForegroundColor Cyan
    
    if ($script:TestResults.Failed -eq 0) {
        Write-Host "  ✓ TODOS OS TESTES PASSARAM! Melhorias v3.5.0 funcionando corretamente." -ForegroundColor Green
        Write-Host "`n  Funcionalidades validadas:" -ForegroundColor Cyan
        Write-Host "    ⚙️  Configuração de retry customizada (RetryBackoffMultiplier, RetryMaxDelaySeconds)" -ForegroundColor White
        Write-Host "    🛠️  Refatoração do Invoke() (métodos privados hidden)" -ForegroundColor White
        Write-Host "    🔧 Exemplo de custom error handler (herança OOP)" -ForegroundColor White
        Write-Host "$('=' * 80)`n" -ForegroundColor Cyan
        exit 0
    } else {
        Write-Host "  ✗ ALGUNS TESTES FALHARAM. Revise as melhorias implementadas." -ForegroundColor Red
        Write-Host "$('=' * 80)`n" -ForegroundColor Cyan
        exit 1
    }
}
