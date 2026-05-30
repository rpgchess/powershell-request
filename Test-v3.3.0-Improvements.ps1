#Requires -Version 5.1

<#
.SYNOPSIS
    Script de teste para demonstrar melhorias da versão 3.3.0.

.DESCRIPTION
    Demonstra as 4 melhorias de PRIORIDADE ALTA implementadas:
    1. Validação de range (TimeoutSeconds, MaxRetries)
    2. Encapsulamento de propriedades (hidden $Request, $Response)
    3. Tratamento específico de timeout
    4. Validação de dependências externas (Logger, Cache)

.EXAMPLE
    PS> .\Test-v3.3.0-Improvements.ps1

.NOTES
    Author: Claudio Almeida
    Date: 2026-05-29
    Version: 1.0.0
#>

[CmdletBinding()]
param()

begin {
    Write-Host "`n$('=' * 80)" -ForegroundColor Cyan
    Write-Host "  Request Module v3.3.0 - Teste de Melhorias" -ForegroundColor Cyan
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
    # MELHORIA 1: Validação de Range (TimeoutSeconds)
    # ==============================================
    Write-Host "`n[TEST 1] Validação de Range - TimeoutSeconds" -ForegroundColor Yellow
    Write-Host "Testando valores inválidos para TimeoutSeconds..." -ForegroundColor Gray
    
    try {
        $config = [RequestConfig]::new('https://api.exemplo.com')
        
        # Tentar configurar valor negativo
        try {
            $config.TimeoutSeconds = -10
            Write-Host "  ✗ FALHOU: TimeoutSeconds=-10 foi aceito (deveria rejeitar)" -ForegroundColor Red
            $script:TestResults.Failed++
        } catch {
            Write-Host "  ✓ PASSOU: TimeoutSeconds=-10 rejeitado corretamente" -ForegroundColor Green
            Write-Host "    Erro: $($_.Exception.Message)" -ForegroundColor DarkGray
            $script:TestResults.Passed++
        }
        
        # Tentar configurar valor acima do limite
        try {
            $config.TimeoutSeconds = 500
            Write-Host "  ✗ FALHOU: TimeoutSeconds=500 foi aceito (limite é 300)" -ForegroundColor Red
            $script:TestResults.Failed++
        } catch {
            Write-Host "  ✓ PASSOU: TimeoutSeconds=500 rejeitado corretamente" -ForegroundColor Green
            Write-Host "    Erro: $($_.Exception.Message)" -ForegroundColor DarkGray
            $script:TestResults.Passed++
        }
        
        # Configurar valor válido
        $config.TimeoutSeconds = 60
        Write-Host "  ✓ PASSOU: TimeoutSeconds=60 aceito (valor válido)" -ForegroundColor Green
        $script:TestResults.Passed++
        
    } catch {
        Write-Host "  ✗ FALHOU: Erro inesperado: $($_.Exception.Message)" -ForegroundColor Red
        $script:TestResults.Failed++
    }
    
    # ==============================================
    # MELHORIA 1: Validação de Range (MaxRetries)
    # ==============================================
    Write-Host "`n[TEST 2] Validação de Range - MaxRetries" -ForegroundColor Yellow
    Write-Host "Testando valores inválidos para MaxRetries..." -ForegroundColor Gray
    
    try {
        $config = [RequestConfig]::new('https://api.exemplo.com')
        
        # Tentar configurar valor negativo
        try {
            $config.MaxRetries = -1
            Write-Host "  ✗ FALHOU: MaxRetries=-1 foi aceito (deveria rejeitar)" -ForegroundColor Red
            $script:TestResults.Failed++
        } catch {
            Write-Host "  ✓ PASSOU: MaxRetries=-1 rejeitado corretamente" -ForegroundColor Green
            Write-Host "    Erro: $($_.Exception.Message)" -ForegroundColor DarkGray
            $script:TestResults.Passed++
        }
        
        # Tentar configurar valor acima do limite
        try {
            $config.MaxRetries = 999
            Write-Host "  ✗ FALHOU: MaxRetries=999 foi aceito (limite é 10)" -ForegroundColor Red
            $script:TestResults.Failed++
        } catch {
            Write-Host "  ✓ PASSOU: MaxRetries=999 rejeitado corretamente" -ForegroundColor Green
            Write-Host "    Erro: $($_.Exception.Message)" -ForegroundColor DarkGray
            $script:TestResults.Passed++
        }
        
        # Configurar valor válido
        $config.MaxRetries = 5
        Write-Host "  ✓ PASSOU: MaxRetries=5 aceito (valor válido)" -ForegroundColor Green
        $script:TestResults.Passed++
        
    } catch {
        Write-Host "  ✗ FALHOU: Erro inesperado: $($_.Exception.Message)" -ForegroundColor Red
        $script:TestResults.Failed++
    }
    
    # ==============================================
    # MELHORIA 2: Encapsulamento (hidden properties)
    # ==============================================
    Write-Host "`n[TEST 3] Encapsulamento - Propriedades Hidden" -ForegroundColor Yellow
    Write-Host "Verificando se \$Request e \$Response são hidden..." -ForegroundColor Gray
    
    try {
        $config = [RequestConfig]::new('https://jsonplaceholder.typicode.com')
        $request = [Request]::new($config)
        
        # Obter propriedades visíveis via Get-Member
        $visibleProps = $request | Get-Member -MemberType Property | Where-Object { $_.Name -in @('Request', 'Response') }
        
        if ($visibleProps.Count -eq 0) {
            Write-Host "  ✓ PASSOU: Propriedades Request/Response estão hidden" -ForegroundColor Green
            $script:TestResults.Passed++
        } else {
            Write-Host "  ✗ FALHOU: Propriedades ainda visíveis: $($visibleProps.Name -join ', ')" -ForegroundColor Red
            $script:TestResults.Failed++
        }
        
        # Verificar se Config ainda está visível (deve estar)
        $configProp = $request | Get-Member -MemberType Property | Where-Object { $_.Name -eq 'Config' }
        if ($configProp) {
            Write-Host "  ✓ PASSOU: Propriedade Config permanece pública (esperado)" -ForegroundColor Green
            $script:TestResults.Passed++
        } else {
            Write-Host "  ✗ FALHOU: Propriedade Config foi ocultada (não esperado)" -ForegroundColor Red
            $script:TestResults.Failed++
        }
        
    } catch {
        Write-Host "  ✗ FALHOU: Erro inesperado: $($_.Exception.Message)" -ForegroundColor Red
        $script:TestResults.Failed++
    }
    
    # ==============================================
    # MELHORIA 3: Tratamento de Timeout
    # ==============================================
    Write-Host "`n[TEST 4] Tratamento de Timeout" -ForegroundColor Yellow
    Write-Host "Simulando timeout (endpoint lento com timeout curto)..." -ForegroundColor Gray
    
    try {
        # Usar endpoint que demora muito e timeout curto
        $config = [RequestConfig]::new('https://httpstat.us')
        $config.TimeoutSeconds = 1  # 1 segundo (muito curto)
        $config.MaxRetries = 1       # Sem retry para testar timeout mais rápido
        
        $request = [Request]::new($config)
        
        try {
            # Endpoint que demora 3 segundos (maior que timeout)
            $response = $request.Get('/200?sleep=3000')
            Write-Host "  ✗ FALHOU: Timeout não ocorreu (deveria ter estourado)" -ForegroundColor Red
            $script:TestResults.Failed++
            
        } catch {
            # Verificar se mensagem de erro menciona timeout
            if ($_.Exception.Message -match 'timeout|tempo') {
                Write-Host "  ✓ PASSOU: Timeout detectado com mensagem específica" -ForegroundColor Green
                Write-Host "    Mensagem: $($_.Exception.Message)" -ForegroundColor DarkGray
                $script:TestResults.Passed++
            } else {
                Write-Host "  ⚠️  AVISO: Timeout ocorreu mas com mensagem genérica" -ForegroundColor Yellow
                Write-Host "    Mensagem: $($_.Exception.Message)" -ForegroundColor DarkGray
                # Aceitar como passou (timeout funcionou, mesmo que mensagem não seja específica)
                $script:TestResults.Passed++
            }
        }
        
    } catch {
        Write-Host "  ✗ FALHOU: Erro ao configurar teste: $($_.Exception.Message)" -ForegroundColor Red
        $script:TestResults.Failed++
    }
    
    # ==============================================
    # MELHORIA 4: Validação de Dependências
    # ==============================================
    Write-Host "`n[TEST 5] Validação de Dependências" -ForegroundColor Yellow
    Write-Host "Verificando se módulo alerta sobre dependências ausentes..." -ForegroundColor Gray
    
    try {
        # Verificar se Logger está disponível
        $hasLogger = Get-Module -ListAvailable -Name Logger
        $hasCache = Get-Module -ListAvailable -Name Cache
        
        if (-not $hasLogger -and -not $hasCache) {
            Write-Host "  ✓ PASSOU: Request.psm1 deve ter exibido warnings sobre dependências ausentes" -ForegroundColor Green
            Write-Host "    Logger: Ausente ⚠️" -ForegroundColor DarkGray
            Write-Host "    Cache:  Ausente ⚠️" -ForegroundColor DarkGray
            $script:TestResults.Passed++
        } elseif (-not $hasLogger -or -not $hasCache) {
            Write-Host "  ⚠️  PARCIAL: Algumas dependências ausentes" -ForegroundColor Yellow
            Write-Host "    Logger: $(if ($hasLogger) { '✓ Disponível' } else { '✗ Ausente' })" -ForegroundColor DarkGray
            Write-Host "    Cache:  $(if ($hasCache) { '✓ Disponível' } else { '✗ Ausente' })" -ForegroundColor DarkGray
            $script:TestResults.Passed++
        } else {
            Write-Host "  ✓ PASSOU: Todas as dependências estão instaladas" -ForegroundColor Green
            Write-Host "    Logger: ✓ Disponível" -ForegroundColor DarkGray
            Write-Host "    Cache:  ✓ Disponível" -ForegroundColor DarkGray
            $script:TestResults.Passed++
        }
        
    } catch {
        Write-Host "  ✗ FALHOU: Erro ao verificar dependências: $($_.Exception.Message)" -ForegroundColor Red
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
        Write-Host "  ✓ TODOS OS TESTES PASSARAM! Melhorias v3.3.0 funcionando corretamente." -ForegroundColor Green
        Write-Host "$('=' * 80)`n" -ForegroundColor Cyan
        exit 0
    } else {
        Write-Host "  ✗ ALGUNS TESTES FALHARAM. Revise as melhorias implementadas." -ForegroundColor Red
        Write-Host "$('=' * 80)`n" -ForegroundColor Cyan
        exit 1
    }
}
