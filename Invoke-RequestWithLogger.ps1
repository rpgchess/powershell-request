#Requires -Version 5.1

<#
.SYNOPSIS
    Exemplo de uso do Request module com Logger module integrado.

.DESCRIPTION
    Demonstra como usar Request module com logging estruturado via Logger module.
    Mostra diferentes níveis de log e formatos de saída.
    
    Pré-requisitos:
    - Request module v3.1.0+
    - Logger module v1.0.0+

.PARAMETER LogLevel
    Nível mínimo de log (DEBUG, INFO, WARN, ERROR).

.PARAMETER LogFormat
    Formato de saída (Simple, Detailed, Json).

.PARAMETER OutputFile
    Arquivo para salvar logs (opcional).

.EXAMPLE
    PS> .\Invoke-RequestWithLogger.ps1
    Executa exemplo com log padrão (INFO, Detailed).

.EXAMPLE
    PS> .\Invoke-RequestWithLogger.ps1 -LogLevel DEBUG -LogFormat Json
    Log detalhado em formato JSON.

.EXAMPLE
    PS> .\Invoke-RequestWithLogger.ps1 -OutputFile 'request.log'
    Salva logs em arquivo.

.NOTES
    Author: Claudio Almeida
    Date: 2026-05-26
    Version: 1.0.0
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [ValidateSet('DEBUG', 'INFO', 'WARN', 'ERROR')]
    [string] $LogLevel = 'INFO',
    
    [Parameter(Mandatory = $false)]
    [ValidateSet('Simple', 'Detailed', 'Json')]
    [string] $LogFormat = 'Detailed',
    
    [Parameter(Mandatory = $false)]
    [string] $OutputFile = ''
)

begin {
    # Importar Logger module
    $loggerPath = Join-Path $PSScriptRoot '..' 'powershell-logger' 'Logger.psd1'
    
    if (-not (Test-Path $loggerPath)) {
        Write-Error "Logger module não encontrado em: $loggerPath"
        Write-Host "Instale Logger module primeiro: cd ..\powershell-logger; Import-Module .\Logger.psd1" -ForegroundColor Yellow
        exit 1
    }
    
    Import-Module $loggerPath -Force
    
    # Configurar Logger
    $logConfig = [LoggerConfig]::new()
    $logConfig.MinLevel = [LogLevel]::$LogLevel
    $logConfig.Format = [LogFormat]::$LogFormat
    
    if ($OutputFile) {
        $logConfig.OutputFile = $OutputFile
    }
    
    $logger = [Logger]::new($logConfig)
    
    # Importar Request module
    Import-Module (Join-Path $PSScriptRoot 'Request.psd1') -Force
}

process {
    Write-Host "`n$('=' * 70)" -ForegroundColor Cyan
    Write-Host "  Request Module + Logger Module - Exemplo de Integração" -ForegroundColor Cyan
    Write-Host "$('=' * 70)" -ForegroundColor Cyan
    
    # Exemplo 1: GET com logging
    $logger.Info('Iniciando requisição GET para JSONPlaceholder')
    
    try {
        $request = [Request]::new('https://jsonplaceholder.typicode.com')
        $logger.Debug('Request configurado com base URL')
        
        $users = $request.Get('/users')
        $logger.Success("Sucesso! Recebidos $($users.Count) usuários")
        
        # Log detalhado do primeiro usuário
        if ($users.Count -gt 0) {
            $logger.Debug("Primeiro usuário: $($users[0].name) ($($users[0].email))")
        }
        
    } catch {
        $logger.Error('Falha na requisição GET', $_.Exception)
    }
    
    # Exemplo 2: POST com logging
    $logger.Info('Criando novo post via API')
    
    try {
        $newPost = @{
            title = 'Test Post'
            body = 'Conteúdo do post de teste'
            userId = 1
        }
        
        $logger.Debug("Payload: $(ConvertTo-Json $newPost -Compress)")
        
        $result = $request.Post('/posts', $newPost)
        
        if ($result.id) {
            $logger.Success("Post criado com ID: $($result.id)")
        } else {
            $logger.Warn('Post criado mas sem ID retornado')
        }
        
    } catch {
        $logger.Error('Falha ao criar post', $_.Exception)
    }
    
    # Exemplo 3: Simulando erro 404
    $logger.Info('Testando tratamento de erro 404')
    
    try {
        $notFound = $request.Get('/users/999999')
        $logger.Success('Requisição bem-sucedida')
        
    } catch {
        # Analisar tipo de erro HTTP
        if ($_.Exception.Message -match '404') {
            $logger.Warn('Recurso não encontrado (esperado para este teste)')
        } else {
            $logger.Error('Erro inesperado', $_.Exception)
        }
    }
    
    # Flush logs para arquivo (se configurado)
    if ($OutputFile) {
        $logger.Flush()
        $logger.Info("Logs salvos em: $OutputFile")
    }
}

end {
    Write-Host "`n$('=' * 70)" -ForegroundColor Cyan
    Write-Host "  Exemplo concluído!" -ForegroundColor Cyan
    Write-Host "$('=' * 70)`n" -ForegroundColor Cyan
    
    if ($OutputFile -and (Test-Path $OutputFile)) {
        Write-Host "Logs disponíveis em: $OutputFile" -ForegroundColor Gray
    }
}
