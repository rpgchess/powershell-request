#Requires -Version 5.1

<#
.SYNOPSIS
    Instala dependências do projeto Request usando PSResourceGet.

.DESCRIPTION
    Script de bootstrap que instala todas as dependências necessárias para desenvolvimento
    e teste do módulo Request. Usa PSResourceGet (PowerShell 7+) ou PowerShellGet (5.1).
    
    Dependências instaladas:
    - Pester 5.x (testes automatizados)
    - PSScriptAnalyzer (validação de código)
    - powershell-yaml (opcional - config files)
    - Plaster (opcional - templates)
    
    Pré-requisitos:
    - PowerShell 5.1+ ou PowerShell 7+
    - Conexão com internet (acesso ao PSGallery)

.PARAMETER Force
    Força reinstalação de dependências mesmo se já instaladas.

.PARAMETER SkipOptional
    Pula instalação de dependências opcionais (powershell-yaml, Plaster).

.PARAMETER Scope
    Escopo de instalação: CurrentUser (padrão) ou AllUsers (requer admin).

.EXAMPLE
    PS> .\Install-Dependencies.ps1
    Instala dependências no escopo CurrentUser.

.EXAMPLE
    PS> .\Install-Dependencies.ps1 -Force
    Força reinstalação de todas as dependências.

.EXAMPLE
    PS> .\Install-Dependencies.ps1 -SkipOptional
    Instala apenas dependências obrigatórias (Pester, PSScriptAnalyzer).

.EXAMPLE
    PS> .\Install-Dependencies.ps1 -Scope AllUsers
    Instala dependências para todos os usuários (requer admin).

.NOTES
    Author: Claudio Almeida
    Date: 2026-05-25
    Version: 3.0.0
    Requires: PowerShell 5.1+
    
    PSResourceGet vs PowerShellGet:
    - PowerShell 7+: Usa Microsoft.PowerShell.PSResourceGet (moderno)
    - PowerShell 5.1: Usa PowerShellGet (legacy)
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [switch] $Force,
    
    [Parameter(Mandatory = $false)]
    [Alias('SkipOptionals')]
    [switch] $SkipOptional,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet('CurrentUser', 'AllUsers')]
    [string] $Scope = 'CurrentUser'
)

begin {
    $ErrorActionPreference = 'Stop'
    
    # Cores para output
    $script:Colors = @{
        Header  = 'Cyan'
        Success = 'Green'
        Warning = 'Yellow'
        Error   = 'Red'
        Info    = 'Gray'
    }
    
    # Estatísticas
    $script:Stats = @{
        Installed = 0
        Skipped   = 0
        Failed    = 0
    }
    
    # Definir dependências
    $script:Dependencies = @{
        Required = @(
            @{
                Name           = 'Pester'
                MinVersion     = '5.0.0'
                MaxVersion     = '6.0.0'
                Description    = 'Framework de testes automatizados'
                ImportAfter    = $true
            }
            @{
                Name           = 'PSScriptAnalyzer'
                MinVersion     = '1.21.0'
                MaxVersion     = '2.0.0'
                Description    = 'Validação e análise de código'
                ImportAfter    = $true
            }
        )
        Optional = @(
            @{
                Name           = 'powershell-yaml'
                MinVersion     = '0.4.0'
                MaxVersion     = '1.0.0'
                Description    = 'Suporte a arquivos YAML'
                ImportAfter    = $false
            }
            @{
                Name           = 'Plaster'
                MinVersion     = '1.1.3'
                MaxVersion     = '2.0.0'
                Description    = 'Templates e scaffolding'
                ImportAfter    = $false
            }
        )
    }
    
    function Write-Header {
        param([string] $Message)
        Write-Host "`n$('=' * 70)" -ForegroundColor $script:Colors.Header
        Write-Host "  $Message" -ForegroundColor $script:Colors.Header
        Write-Host "$('=' * 70)" -ForegroundColor $script:Colors.Header
    }
    
    function Write-Step {
        param([string] $Message)
        Write-Host "`n$Message" -ForegroundColor $script:Colors.Info
    }
    
    function Test-ModuleInstalled {
        param(
            [string] $Name,
            [string] $MinVersion
        )
        
        $module = Get-Module -ListAvailable -Name $Name | 
            Where-Object { $_.Version -ge [Version]$MinVersion } |
            Select-Object -First 1
        
        return $null -ne $module
    }
}

process {
    Write-Header "Instalação de Dependências - Request Module v3.0.0"
    
    Write-Host "`nConfiguração:" -ForegroundColor $script:Colors.Info
    Write-Host "  PowerShell: $($PSVersionTable.PSVersion)" -ForegroundColor Gray
    Write-Host "  Escopo: $Scope" -ForegroundColor Gray
    Write-Host "  Força reinstalação: $Force" -ForegroundColor Gray
    Write-Host "  Pular opcionais: $SkipOptional" -ForegroundColor Gray
    
    # Detectar qual gerenciador de pacotes usar
    $usePSResourceGet = $PSVersionTable.PSVersion.Major -ge 7
    
    if ($usePSResourceGet) {
        Write-Step "Detectado PowerShell 7+ - Usando PSResourceGet"
        
        # Verificar se PSResourceGet está disponível
        if (-not (Get-Module -ListAvailable -Name Microsoft.PowerShell.PSResourceGet)) {
            Write-Warning "PSResourceGet não instalado. Instalando..."
            try {
                Install-Module -Name Microsoft.PowerShell.PSResourceGet -Force -Scope $Scope -AllowClobber
                Import-Module Microsoft.PowerShell.PSResourceGet -Force
                Write-Host "  ✓ PSResourceGet instalado" -ForegroundColor $script:Colors.Success
            } catch {
                Write-Warning "Falha ao instalar PSResourceGet. Usando PowerShellGet fallback."
                $usePSResourceGet = $false
            }
        }
    } else {
        Write-Step "Detectado PowerShell 5.1 - Usando PowerShellGet"
    }
    
    # Instalar dependências obrigatórias
    Write-Header "Instalando Dependências Obrigatórias"
    
    foreach ($dep in $script:Dependencies.Required) {
        Write-Host "`n[$($dep.Name)]" -ForegroundColor $script:Colors.Header
        Write-Host "  Descrição: $($dep.Description)" -ForegroundColor Gray
        Write-Host "  Versão: $($dep.MinVersion) - $($dep.MaxVersion)" -ForegroundColor Gray
        
        # Verificar se já está instalado
        if (-not $Force -and (Test-ModuleInstalled -Name $dep.Name -MinVersion $dep.MinVersion)) {
            Write-Host "  ✓ Já instalado (use -Force para reinstalar)" -ForegroundColor $script:Colors.Success
            $script:Stats.Skipped++
            continue
        }
        
        try {
            if ($usePSResourceGet) {
                # PSResourceGet (PowerShell 7+)
                $params = @{
                    Name       = $dep.Name
                    Repository = 'PSGallery'
                    Scope      = $Scope
                    TrustRepository = $true
                }
                
                if ($dep.MinVersion) {
                    $params['Version'] = "[${($dep.MinVersion)},${($dep.MaxVersion)})"
                }
                
                Install-PSResource @params
            } else {
                # PowerShellGet (PowerShell 5.1)
                $params = @{
                    Name               = $dep.Name
                    Scope              = $Scope
                    Force              = $Force
                    AllowClobber       = $true
                    SkipPublisherCheck = $true
                }
                
                if ($dep.MinVersion) {
                    $params['MinimumVersion'] = $dep.MinVersion
                }
                
                if ($dep.MaxVersion) {
                    $params['MaximumVersion'] = $dep.MaxVersion
                }
                
                Install-Module @params
            }
            
            # Importar módulo se solicitado
            if ($dep.ImportAfter) {
                Import-Module $dep.Name -Force -ErrorAction SilentlyContinue
            }
            
            Write-Host "  ✓ Instalado com sucesso" -ForegroundColor $script:Colors.Success
            $script:Stats.Installed++
            
        } catch {
            Write-Host "  ✗ Falha: $($_.Exception.Message)" -ForegroundColor $script:Colors.Error
            $script:Stats.Failed++
        }
    }
    
    # Instalar dependências opcionais
    if (-not $SkipOptional) {
        Write-Header "Instalando Dependências Opcionais"
        
        foreach ($dep in $script:Dependencies.Optional) {
            Write-Host "`n[$($dep.Name)]" -ForegroundColor $script:Colors.Header
            Write-Host "  Descrição: $($dep.Description)" -ForegroundColor Gray
            Write-Host "  Versão: $($dep.MinVersion) - $($dep.MaxVersion)" -ForegroundColor Gray
            
            # Verificar se já está instalado
            if (-not $Force -and (Test-ModuleInstalled -Name $dep.Name -MinVersion $dep.MinVersion)) {
                Write-Host "  ✓ Já instalado (use -Force para reinstalar)" -ForegroundColor $script:Colors.Success
                $script:Stats.Skipped++
                continue
            }
            
            try {
                if ($usePSResourceGet) {
                    # PSResourceGet (PowerShell 7+)
                    $params = @{
                        Name       = $dep.Name
                        Repository = 'PSGallery'
                        Scope      = $Scope
                        TrustRepository = $true
                    }
                    
                    if ($dep.MinVersion) {
                        $params['Version'] = "[${($dep.MinVersion)},${($dep.MaxVersion)})"
                    }
                    
                    Install-PSResource @params
                } else {
                    # PowerShellGet (PowerShell 5.1)
                    $params = @{
                        Name               = $dep.Name
                        Scope              = $Scope
                        Force              = $Force
                        AllowClobber       = $true
                        SkipPublisherCheck = $true
                    }
                    
                    if ($dep.MinVersion) {
                        $params['MinimumVersion'] = $dep.MinVersion
                    }
                    
                    if ($dep.MaxVersion) {
                        $params['MaximumVersion'] = $dep.MaxVersion
                    }
                    
                    Install-Module @params
                }
                
                # Importar módulo se solicitado
                if ($dep.ImportAfter) {
                    Import-Module $dep.Name -Force -ErrorAction SilentlyContinue
                }
                
                Write-Host "  ✓ Instalado com sucesso" -ForegroundColor $script:Colors.Success
                $script:Stats.Installed++
                
            } catch {
                Write-Host "  ⚠ Falha (opcional): $($_.Exception.Message)" -ForegroundColor $script:Colors.Warning
                Write-Host "    Você pode continuar sem este módulo" -ForegroundColor Gray
                $script:Stats.Skipped++
            }
        }
    } else {
        Write-Step "Pulando dependências opcionais (-SkipOptional)"
    }
}

end {
    # Resumo
    Write-Header "Resumo da Instalação"
    
    Write-Host "`nEstatísticas:" -ForegroundColor $script:Colors.Info
    Write-Host "  ✓ Instalados: $($script:Stats.Installed)" -ForegroundColor $script:Colors.Success
    Write-Host "  ⊘ Pulados: $($script:Stats.Skipped)" -ForegroundColor $script:Colors.Warning
    Write-Host "  ✗ Falhas: $($script:Stats.Failed)" -ForegroundColor $(if ($script:Stats.Failed -gt 0) { $script:Colors.Error } else { $script:Colors.Success })
    
    # Verificar instalação
    Write-Host "`nVerificando instalação:" -ForegroundColor $script:Colors.Info
    
    $allDeps = $script:Dependencies.Required
    if (-not $SkipOptional) {
        $allDeps += $script:Dependencies.Optional
    }
    
    foreach ($dep in $allDeps) {
        $installed = Test-ModuleInstalled -Name $dep.Name -MinVersion $dep.MinVersion
        $icon = if ($installed) { '✓' } else { '✗' }
        $color = if ($installed) { $script:Colors.Success } else { $script:Colors.Warning }
        
        Write-Host "  $icon $($dep.Name)" -ForegroundColor $color
        
        if ($installed) {
            $module = Get-Module -ListAvailable -Name $dep.Name | 
                Sort-Object Version -Descending | 
                Select-Object -First 1
            Write-Host "    Versão: $($module.Version)" -ForegroundColor Gray
        }
    }
    
    # Mensagem final
    if ($script:Stats.Failed -eq 0) {
        Write-Host "`n✓ Todas as dependências foram instaladas com sucesso!" -ForegroundColor $script:Colors.Success
        Write-Host "`nPróximos passos:" -ForegroundColor $script:Colors.Info
        Write-Host "  1. Executar testes: Invoke-Pester .\Tests\Request.Tests.ps1" -ForegroundColor Gray
        Write-Host "  2. Validar código: Invoke-ScriptAnalyzer -Path . -Recurse" -ForegroundColor Gray
        Write-Host "  3. Testar módulo: .\Test-Request.ps1`n" -ForegroundColor Gray
        
        exit 0
    } else {
        Write-Host "`n⚠ Algumas dependências falharam na instalação." -ForegroundColor $script:Colors.Warning
        Write-Host "   Verifique os erros acima e tente novamente.`n" -ForegroundColor Gray
        
        exit 1
    }
}
