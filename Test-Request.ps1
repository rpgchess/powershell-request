#Requires -Version 5.1
using module '.\Request.psd1'

<#
.SYNOPSIS
    Testa funcionalidade básica do módulo Request.

.DESCRIPTION
    Script de teste standalone para validar operações HTTP do módulo Request.
    Executa testes de GET, POST, PUT, DELETE contra API pública (JSONPlaceholder).
    Não requer dependências externas além do módulo Request.
    
    Pré-requisitos:
    - Módulo Request instalado ou disponível no diretório atual
    - Conexão com internet (acesso a jsonplaceholder.typicode.com)

.PARAMETER Verbose
    Exibe logs detalhados de cada requisição HTTP.

.PARAMETER ShowResults
    Exibe conteúdo completo das respostas HTTP.

.EXAMPLE
    PS> .\Test-Request.ps1
    Executa testes básicos com saída resumida.

.EXAMPLE
    PS> .\Test-Request.ps1 -Verbose
    Executa testes com logs detalhados de cada requisição.

.EXAMPLE
    PS> .\Test-Request.ps1 -ShowResults
    Executa testes e exibe conteúdo completo das respostas.

.NOTES
    Author: Claudio Almeida
    Date: 2026-05-25
    Version: 3.0.0
    Requires: Request Module v3.0.0+
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [Alias('Show', 'Display')]
    [switch] $ShowResults
)

begin {
    # Validar pré-requisitos
    if (-not (Get-Command -Name Invoke-WebRequest -ErrorAction SilentlyContinue)) {
        Write-Error "Invoke-WebRequest não disponível. PowerShell 3.0+ requerido."
        exit 1
    }
    
    # Configuração
    $script:TestApiUrl = 'https://jsonplaceholder.typicode.com'
    $script:TestsPassed = 0
    $script:TestsFailed = 0
}

process {
    Write-Host "`n=== Teste do Módulo Request ===" -ForegroundColor Cyan

    # Criar configuração mock para teste
    $config = [RequestConfig]::new($script:TestApiUrl, 'test@teste.com', 'senha123')
    $config.AuthType = [AuthType]::None  # Sem autenticação para este teste

    Write-Host "`n1. Testando classe Request..." -ForegroundColor Yellow

    try {
        $request = [Request]::new($config)
        Write-Host "   ✓ Instância criada com sucesso" -ForegroundColor Green
        $script:TestsPassed++
    } catch {
        Write-Host "   ✗ Erro ao criar instância: $($_.Exception.Message)" -ForegroundColor Red
        $script:TestsFailed++
        throw
    }

    Write-Host "`n2. Testando método GET..." -ForegroundColor Yellow

    try {
        $posts = $request.Get('/posts/1')
        Write-Host "   ✓ GET bem-sucedido" -ForegroundColor Green
        Write-Host "   Post ID: $($posts.id) - Título: $($posts.title)" -ForegroundColor Gray
        
        if ($ShowResults) {
            Write-Host "`n   Resposta completa:" -ForegroundColor Cyan
            $posts | ConvertTo-Json -Depth 5 | Write-Host -ForegroundColor Gray
        }
        
        $script:TestsPassed++
    } catch {
        Write-Host "   ✗ Erro no GET: $($_.Exception.Message)" -ForegroundColor Red
        $script:TestsFailed++
    }

    Write-Host "`n3. Testando método POST..." -ForegroundColor Yellow

    try {
        $newPost = @{
            title  = 'Teste PowerShell Request'
            body   = 'Corpo do post de teste'
            userId = 1
        }
        
        $result = $request.Post('/posts', $newPost)
        Write-Host "   ✓ POST bem-sucedido" -ForegroundColor Green
        Write-Host "   Novo post ID: $($result.id)" -ForegroundColor Gray
        
        if ($ShowResults) {
            Write-Host "`n   Resposta completa:" -ForegroundColor Cyan
            $result | ConvertTo-Json -Depth 5 | Write-Host -ForegroundColor Gray
        }
        
        $script:TestsPassed++
    } catch {
        Write-Host "   ✗ Erro no POST: $($_.Exception.Message)" -ForegroundColor Red
        $script:TestsFailed++
    }

    Write-Host "`n4. Testando método PUT..." -ForegroundColor Yellow

    try {
        $updatePost = @{
            id     = 1
            title  = 'Post atualizado'
            body   = 'Corpo atualizado'
            userId = 1
        }
        
        $updated = $request.Put('/posts/1', $updatePost)
        Write-Host "   ✓ PUT bem-sucedido" -ForegroundColor Green
        Write-Host "   Post atualizado: $($updated.title)" -ForegroundColor Gray
        
        if ($ShowResults) {
            Write-Host "`n   Resposta completa:" -ForegroundColor Cyan
            $updated | ConvertTo-Json -Depth 5 | Write-Host -ForegroundColor Gray
        }
        
        $script:TestsPassed++
    } catch {
        Write-Host "   ✗ Erro no PUT: $($_.Exception.Message)" -ForegroundColor Red
        $script:TestsFailed++
    }

    Write-Host "`n5. Testando método DELETE..." -ForegroundColor Yellow

    try {
        $deleted = $request.Delete('/posts/1')
        Write-Host "   ✓ DELETE bem-sucedido" -ForegroundColor Green
        
        if ($ShowResults) {
            Write-Host "`n   Resposta:" -ForegroundColor Cyan
            $deleted | ConvertTo-Json -Depth 5 | Write-Host -ForegroundColor Gray
        }
        
        $script:TestsPassed++
    } catch {
        Write-Host "   ✗ Erro no DELETE: $($_.Exception.Message)" -ForegroundColor Red
        $script:TestsFailed++
    }
}

end {
    # Resumo dos testes
    Write-Host "`n=== Resumo dos Testes ===" -ForegroundColor Cyan
    Write-Host "   Sucesso: $script:TestsPassed" -ForegroundColor Green
    Write-Host "   Falhas:  $script:TestsFailed" -ForegroundColor $(if ($script:TestsFailed -eq 0) { 'Green' } else { 'Red' })
    Write-Host "   Total:   $($script:TestsPassed + $script:TestsFailed)" -ForegroundColor Cyan
    
    if ($script:TestsFailed -eq 0) {
        Write-Host "`nMódulo Request funcionando corretamente!`n" -ForegroundColor Green
        exit 0
    } else {
        Write-Host "`nAlguns testes falharam. Verifique os erros acima.`n" -ForegroundColor Red
        exit 1
    }
}
