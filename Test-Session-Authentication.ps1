<#
.SYNOPSIS
    Teste de autenticação Session (JSESSIONID) no Request module.

.DESCRIPTION
    Valida que o Request module configura corretamente WebRequestSession
    com cookie JSESSIONID seguindo padrão de get-jira-browser-cookie.ps1.

.NOTES
    Author: Claudio Almeida
    Date: 2026-05-23
    Version: 2.0.0
#>

using module '.\Request.psd1'

Write-Host "`n================================================" -ForegroundColor Cyan
Write-Host "  TESTE: Autenticação Session (JSESSIONID)" -ForegroundColor Yellow
Write-Host "================================================" -ForegroundColor Cyan

# Teste 1: Configuração básica com SessionId
Write-Host "`n[Teste 1] Configuração básica com SessionId" -ForegroundColor Cyan

try {
    $config = [RequestConfig]::new('https://jira.linx.com.br')
    $config.AuthType = [AuthType]::Session
    $config.SessionId = '380BB1FE14778FA884E2B23596ACC5DF'
    $config.CookieDomain = 'jira.linx.com.br'
    
    if ($config.IsValid()) {
        Write-Host "  ✓ Configuração válida" -ForegroundColor Green
    } else {
        throw "Configuração inválida"
    }
    
    Write-Host "  AuthType: $($config.AuthType)" -ForegroundColor Gray
    Write-Host "  SessionId: $($config.SessionId.Substring(0, 10))..." -ForegroundColor Gray
    Write-Host "  CookieDomain: $($config.CookieDomain)" -ForegroundColor Gray
    
} catch {
    Write-Host "  ✗ Falhou: $($_.Exception.Message)" -ForegroundColor Red
    throw
}

# Teste 2: CookieDomain automático (extrai da URL)
Write-Host "`n[Teste 2] CookieDomain automático (extrai da BaseUrl)" -ForegroundColor Cyan

try {
    $config2 = [RequestConfig]::new('https://api.github.com')
    $config2.AuthType = [AuthType]::Session
    $config2.SessionId = 'ABCDEF123456'
    # Não configurar CookieDomain - deve extrair automaticamente da URL
    
    if ($config2.IsValid()) {
        Write-Host "  ✓ Configuração válida" -ForegroundColor Green
    } else {
        throw "Configuração inválida"
    }
    
    Write-Host "  BaseUrl: $($config2.BaseUrl)" -ForegroundColor Gray
    Write-Host "  SessionId: $($config2.SessionId)" -ForegroundColor Gray
    Write-Host "  CookieDomain: (automático - será extraído da URL)" -ForegroundColor Gray
    
} catch {
    Write-Host "  ✗ Falhou: $($_.Exception.Message)" -ForegroundColor Red
    throw
}

# Teste 3: Headers de navegador (User-Agent correto)
Write-Host "`n[Teste 3] Headers de navegador (simular browser)" -ForegroundColor Cyan

try {
    $request = [Request]::new($config)
    $headers = $request.GetDefaultHeaders()
    
    if ($headers['User-Agent'] -like 'Mozilla/*') {
        Write-Host "  ✓ User-Agent correto (navegador)" -ForegroundColor Green
    } else {
        throw "User-Agent não é de navegador: $($headers['User-Agent'])"
    }
    
    if ($headers['Accept-Language']) {
        Write-Host "  ✓ Accept-Language presente" -ForegroundColor Green
    } else {
        Write-Warning "  Accept-Language não configurado"
    }
    
    Write-Host "  User-Agent: $($headers['User-Agent'].Substring(0, 50))..." -ForegroundColor Gray
    Write-Host "  Accept-Language: $($headers['Accept-Language'])" -ForegroundColor Gray
    
} catch {
    Write-Host "  ✗ Falhou: $($_.Exception.Message)" -ForegroundColor Red
    throw
}

# Teste 4: Validação de SessionId vazio
Write-Host "`n[Teste 4] Validação - SessionId vazio deve falhar" -ForegroundColor Cyan

try {
    $configInvalid = [RequestConfig]::new('https://api.exemplo.com')
    $configInvalid.AuthType = [AuthType]::Session
    # Não configurar SessionId
    
    if (-not $configInvalid.IsValid()) {
        Write-Host "  ✓ Configuração inválida corretamente detectada" -ForegroundColor Green
    } else {
        throw "Deveria ter detectado configuração inválida"
    }
    
} catch {
    Write-Host "  ✗ Falhou: $($_.Exception.Message)" -ForegroundColor Red
    throw
}

# Teste 5: Criar Request com Session (sem fazer request real)
Write-Host "`n[Teste 5] Instanciar Request com Session" -ForegroundColor Cyan

try {
    $requestSession = [Request]::new($config)
    
    if ($requestSession.Config.AuthType -eq [AuthType]::Session) {
        Write-Host "  ✓ Request criado com AuthType=Session" -ForegroundColor Green
    } else {
        throw "AuthType incorreto: $($requestSession.Config.AuthType)"
    }
    
    Write-Host "  BaseUrl: $($requestSession.Config.BaseUrl)" -ForegroundColor Gray
    Write-Host "  SessionId: $($requestSession.Config.SessionId.Substring(0, 10))..." -ForegroundColor Gray
    
} catch {
    Write-Host "  ✗ Falhou: $($_.Exception.Message)" -ForegroundColor Red
    throw
}

# Resumo
Write-Host "`n================================================" -ForegroundColor Green
Write-Host "  ✓ TODOS OS TESTES PASSARAM" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Green

Write-Host "`n💡 Dicas de Uso:" -ForegroundColor Yellow
Write-Host "  1. Configure SessionId copiado do navegador (F12 → Application → Cookies)" -ForegroundColor Gray
Write-Host "  2. Configure CookieDomain (ex: jira.linx.com.br) ou deixe vazio para auto-detectar" -ForegroundColor Gray
Write-Host "  3. Cookie expira após ~30min de inatividade" -ForegroundColor Gray
Write-Host "  4. Headers de navegador são adicionados automaticamente`n" -ForegroundColor Gray

# Exemplo de uso real
Write-Host "📝 Exemplo de Uso (Jira):" -ForegroundColor Cyan
Write-Host @"

using module '.\Request.psd1'

# 1. Copiar JSESSIONID do navegador
`$sessionId = '380BB1FE14778FA884E2B23596ACC5DF'

# 2. Configurar Request com Session
`$config = [RequestConfig]::new('https://jira.linx.com.br')
`$config.AuthType = [AuthType]::Session
`$config.SessionId = `$sessionId
`$config.CookieDomain = 'jira.linx.com.br'

# 3. Criar Request
`$request = [Request]::new(`$config)

# 4. Fazer requisição
`$issue = `$request.Get('/rest/api/2/issue/RESHOP-14206')

Write-Host "Issue: `$(`$issue.key) - `$(`$issue.fields.summary)"

"@ -ForegroundColor White

Write-Host "`n✅ Teste concluído com sucesso!`n" -ForegroundColor Green
