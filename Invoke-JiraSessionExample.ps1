#Requires -Version 5.1
using module '.\Request.psd1'

<#
.SYNOPSIS
    Demonstra integração com Jira API usando autenticação Session (JSESSIONID).

.DESCRIPTION
    Script de exemplo que mostra como usar o Request module v3.0.0+ com cookie JSESSIONID
    copiado do navegador para evitar CAPTCHA e rate limit do Jira.
    
    O cookie JSESSIONID mantém sessão ativa do navegador, permitindo:
    - Evitar autenticação Basic repetida (que pode triggar CAPTCHA)
    - Compartilhar mesma sessão do navegador
    - Acessar recursos protegidos por SSO
    
    Pré-requisitos:
    - Módulo Request v3.0.0+ instalado
    - Sessão ativa no Jira via navegador
    - Cookie JSESSIONID válido (obtido via F12 → Application → Cookies)
    
    Importante: Cookie expira após ~30min de inatividade ou logout no navegador.

.PARAMETER IssueKey
    Chave da issue do Jira (ex: RESHOP-14206, SHOP-1234).
    Default: RESHOP-14206

.PARAMETER SessionId
    Valor do cookie JSESSIONID copiado do navegador.
    Obter em: F12 → Application → Cookies → jira.linx.com.br → JSESSIONID
    
    Obrigatório e validado como não-vazio.

.PARAMETER BaseUrl
    URL base do Jira (ex: https://jira.linx.com.br).
    Default: https://jira.linx.com.br

.PARAMETER ShowDescription
    Exibe descrição completa da issue (primeiros 500 caracteres).

.EXAMPLE
    PS> .\Invoke-JiraSessionExample.ps1 -SessionId "380BB1FE14778FA884E2B23596ACC5DF"
    Busca issue RESHOP-14206 (padrão) usando cookie de sessão.

.EXAMPLE
    PS> .\Invoke-JiraSessionExample.ps1 -IssueKey "SHOP-1234" -SessionId "ABC123..."
    Busca issue específica com cookie fornecido.

.EXAMPLE
    PS> .\Invoke-JiraSessionExample.ps1 -SessionId "XYZ789..." -ShowDescription
    Busca issue e exibe descrição completa.

.EXAMPLE
    PS> .\Invoke-JiraSessionExample.ps1 -SessionId "XYZ789..." -BaseUrl "https://jira.example.com"
    Usa Jira instance customizado.

.NOTES
    Author: Claudio Almeida
    Date: 2026-05-25
    Version: 3.0.0
    Requires: Request Module v3.0.0+
    
    Troubleshooting:
    - 401 Unauthorized: Cookie expirado, copie novo JSESSIONID
    - 403 Forbidden: Sem permissão para acessar projeto/issue
    - 404 Not Found: Issue não existe ou projeto inacessível
    
    Como obter JSESSIONID:
    1. Abrir Jira no navegador e fazer login
    2. F12 → Application → Cookies → jira.linx.com.br
    3. Copiar valor de JSESSIONID
    4. Executar script com -SessionId "valor_copiado"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false, Position = 0)]
    [Alias('Key', 'Issue')]
    [ValidateNotNullOrEmpty()]
    [string] $IssueKey = "RESHOP-14206",
    
    [Parameter(Mandatory = $true, Position = 1)]
    [Alias('Cookie', 'JSESSIONID')]
    [ValidateNotNullOrEmpty()]
    [string] $SessionId,
    
    [Parameter(Mandatory = $false)]
    [Alias('Url', 'JiraUrl')]
    [ValidateNotNullOrEmpty()]
    [string] $BaseUrl = "https://jira.linx.com.br",
    
    [Parameter(Mandatory = $false)]
    [Alias('Desc', 'Description')]
    [switch] $ShowDescription
)

begin {
    # Validar pré-requisitos
    if (-not (Get-Command -Name Invoke-WebRequest -ErrorAction SilentlyContinue)) {
        Write-Error "Invoke-WebRequest não disponível. PowerShell 3.0+ requerido."
        exit 1
    }
    
    # Validar formato do SessionId (básico)
    if ($SessionId.Length -lt 10) {
        Write-Error "SessionId parece inválido (muito curto). Verifique se copiou corretamente."
        exit 1
    }
    
    Write-Verbose "Configuração validada com sucesso"
}

process {
    Write-Host "`n================================================" -ForegroundColor Cyan
    Write-Host "  JIRA API - Autenticação Session (JSESSIONID)" -ForegroundColor Yellow
    Write-Host "================================================" -ForegroundColor Cyan

    Write-Host "`nConfigurando Request com Session Cookie..." -ForegroundColor Cyan

    try {
        # 1. Configurar RequestConfig com Session
        $config = [RequestConfig]::new($BaseUrl)
        $config.AuthType = [AuthType]::Session
        $config.SessionId = $SessionId
        $config.CookieDomain = ([System.Uri]$BaseUrl).Host

        Write-Host "  BaseUrl: $BaseUrl" -ForegroundColor Gray
        Write-Host "  AuthType: $($config.AuthType)" -ForegroundColor Gray
        Write-Host "  SessionId: $($SessionId.Substring(0, [Math]::Min(10, $SessionId.Length)))..." -ForegroundColor Gray
        Write-Host "  CookieDomain: $($config.CookieDomain)" -ForegroundColor Gray

        # 2. Validar configuração
        if (-not $config.IsValid()) {
            throw "Configuração inválida. Verifique se SessionId está preenchido."
        }

        Write-Host "  ✓ Configuração válida" -ForegroundColor Green

        # 3. Criar Request
        $request = [Request]::new($config)

        Write-Host "`nBuscando issue $IssueKey..." -ForegroundColor Cyan

        # 4. Fazer requisição GET
        $issue = $request.Get("/rest/api/2/issue/$IssueKey")
        
        # 5. Exibir resultado
        Write-Host "`n================================================" -ForegroundColor Green
        Write-Host "  ✓ SUCESSO - Issue obtida com Session Cookie" -ForegroundColor Green
        Write-Host "================================================" -ForegroundColor Green
        
        Write-Host "`nKey:        $($issue.key)" -ForegroundColor Yellow
        Write-Host "Resumo:     $($issue.fields.summary)" -ForegroundColor White
        Write-Host "Projeto:    $($issue.fields.project.name)" -ForegroundColor White
        Write-Host "Tipo:       $($issue.fields.issuetype.name)" -ForegroundColor White
        Write-Host "Status:     $($issue.fields.status.name)" -ForegroundColor Cyan
        Write-Host "Prioridade: $($issue.fields.priority.name)" -ForegroundColor White
        
        if ($issue.fields.assignee) {
            Write-Host "Assignee:   $($issue.fields.assignee.displayName)" -ForegroundColor White
        } else {
            Write-Host "Assignee:   Não atribuído" -ForegroundColor Gray
        }
        
        Write-Host "`nCriado em:  $($issue.fields.created)" -ForegroundColor Gray
        Write-Host "Atualizado: $($issue.fields.updated)" -ForegroundColor Gray
        
        # Descrição (se solicitado)
        if ($ShowDescription -and $issue.fields.description) {
            Write-Host "`n------------------------------------------------" -ForegroundColor Cyan
            Write-Host "DESCRIÇÃO:" -ForegroundColor Cyan
            Write-Host "------------------------------------------------" -ForegroundColor Cyan
            
            $description = $issue.fields.description
            $maxLength = 500
            
            if ($description.Length -gt $maxLength) {
                Write-Host "$($description.Substring(0, $maxLength))..." -ForegroundColor White
            } else {
                Write-Host $description -ForegroundColor White
            }
        }
        
        Write-Host "`n------------------------------------------------" -ForegroundColor Cyan
        Write-Host "Link: $BaseUrl/browse/$IssueKey" -ForegroundColor Blue
        Write-Host "================================================`n" -ForegroundColor Green
        
        Write-Host "💡 Dica: Cookie expira após ~30min de inatividade" -ForegroundColor Yellow
        Write-Host "   Copie um novo JSESSIONID se receber erro 401/403`n" -ForegroundColor Yellow
        
    } catch [System.Net.WebException] {
        Write-Host "`n================================================" -ForegroundColor Red
        Write-Host "  ✗ ERRO ao buscar issue" -ForegroundColor Red
        Write-Host "================================================" -ForegroundColor Red
        
        $statusCode = $_.Exception.Response.StatusCode.value__
        Write-Host "`nStatus Code: $statusCode" -ForegroundColor Yellow
        Write-Host "Erro: $($_.Exception.Message)" -ForegroundColor Yellow
        
        switch ($statusCode) {
            401 {
                Write-Host "`nCausa:" -ForegroundColor Cyan
                Write-Host "  • Cookie JSESSIONID expirado ou inválido" -ForegroundColor Gray
                Write-Host "`nSolução:" -ForegroundColor Cyan
                Write-Host "  1. Abra o Jira no navegador e faça login" -ForegroundColor Gray
                Write-Host "  2. Pressione F12 → Application → Cookies" -ForegroundColor Gray
                Write-Host "  3. Copie novo valor de JSESSIONID" -ForegroundColor Gray
                Write-Host "  4. Execute novamente com novo cookie" -ForegroundColor Gray
            }
            403 {
                Write-Host "`nCausa:" -ForegroundColor Cyan
                Write-Host "  • Sem permissão para acessar esta issue" -ForegroundColor Gray
                Write-Host "  • Cookie válido mas sem acesso ao projeto" -ForegroundColor Gray
            }
            404 {
                Write-Host "`nCausa:" -ForegroundColor Cyan
                Write-Host "  • Issue $IssueKey não existe" -ForegroundColor Gray
                Write-Host "  • Projeto não existe ou não tem acesso" -ForegroundColor Gray
            }
            default {
                Write-Host "`nErro HTTP $statusCode não esperado." -ForegroundColor Gray
            }
        }
        
        Write-Host ""
        exit 1
        
    } catch {
        Write-Host "`n✗ Erro inesperado: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "$($_.ScriptStackTrace)" -ForegroundColor Gray
        exit 1
    }
}

end {
    Write-Verbose "Script concluído com sucesso"
}
