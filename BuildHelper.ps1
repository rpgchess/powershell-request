#Requires -Version 5.1
# BuildHelper.ps1 — Shared build automation for PowerShell modules
# Dot-source from each module's Build.ps1, then call Start-Build

$script:BH = $null

function Write-TaskHeader {
    [CmdletBinding()] param([string] $TaskName)
    Write-Host "`n$('=' * 70)" -ForegroundColor Cyan
    Write-Host "  TASK: $TaskName" -ForegroundColor Cyan
    Write-Host "$('=' * 70)" -ForegroundColor Cyan
}

function Write-TaskResult {
    [CmdletBinding()] param([string] $TaskName, [bool] $Success, [int] $DurationMs)
    $status = if ($Success) { '✓ SUCESSO' } else { '✗ FALHA' }
    $color = if ($Success) { 'Green' } else { 'Red' }
    Write-Host "`n$status - $TaskName ($DurationMs ms)" -ForegroundColor $color
}

function Invoke-Task {
    [CmdletBinding()] param([string] $Name, [scriptblock] $ScriptBlock)
    Write-TaskHeader -TaskName $Name
    $taskStart = Get-Date
    $success = $true
    try { & $ScriptBlock }
    catch {
        Write-Error "Erro na tarefa '$Name': $($_.Exception.Message)"
        $success = $false; $script:BH.ExitCode = 1
    }
    $duration = [int]((Get-Date) - $taskStart).TotalMilliseconds
    Write-TaskResult -TaskName $Name -Success $success -DurationMs $duration
    return $success
}

function Task-Clean {
    Write-Host "Limpando arquivos temporários..."
    foreach ($dir in @($script:BH.TestResults, $script:BH.PackageDir)) {
        if (Test-Path $dir) { Remove-Item $dir -Recurse -Force; Write-Host "  Removido: $dir" -ForegroundColor Gray }
    }
    foreach ($pattern in $script:BH.CleanPatterns) {
        $files = Get-ChildItem $script:BH.Root -Filter $pattern -File
        if ($files) { $files | Remove-Item -Force; Write-Host "  Removidos $($files.Count) arquivo(s) $pattern" -ForegroundColor Gray }
    }
    New-Item -ItemType Directory -Path $script:BH.TestResults -Force | Out-Null
    Write-Host "Limpeza concluída." -ForegroundColor Green
}

function Task-Analyze {
    Write-Host "Executando análise estática com PSScriptAnalyzer..."
    if (-not (Get-Module -ListAvailable -Name PSScriptAnalyzer)) {
        throw "PSScriptAnalyzer não instalado. Execute Install-Dependencies.ps1"
    }
    Import-Module PSScriptAnalyzer -ErrorAction Stop
    $filesToAnalyze = Get-ChildItem $script:BH.Root -Include '*.ps1', '*.psm1' -Recurse |
        Where-Object { $_.FullName -notlike '*\reports\*' -and $_.FullName -notlike '*\Package\*' }
    Write-Host "Analisando $($filesToAnalyze.Count) arquivo(s)..."
    $analyzeParams = @{ Severity = @('Warning', 'Error') }
    if (Test-Path $script:BH.SettingsPath) { $analyzeParams.Settings = $script:BH.SettingsPath }
    $results = $filesToAnalyze | Invoke-ScriptAnalyzer @analyzeParams
    if ($results) {
        Write-Host "`nProblemas encontrados:" -ForegroundColor Yellow
        $results | Format-Table Severity, RuleName, ScriptName, Line, Message -AutoSize
        $errorCount = ($results | Where-Object Severity -eq 'Error').Count
        if ($errorCount -gt 0) { throw "PSScriptAnalyzer encontrou $errorCount erro(s) crítico(s)" }
    } else { Write-Host "Nenhum problema encontrado." -ForegroundColor Green }
}

function Task-Test {
    if ($script:BH.SkipTests) { Write-Host "Testes pulados (SkipTests)" -ForegroundColor Yellow; return }
    Write-Host "Executando testes com Pester..."
    if (-not (Get-Module -ListAvailable -Name Pester)) { throw "Pester não instalado. Execute Install-Dependencies.ps1" }
    Import-Module Pester -MinimumVersion 5.0 -ErrorAction Stop
    if (-not (Test-Path $script:BH.TestResults)) { New-Item -ItemType Directory -Path $script:BH.TestResults -Force | Out-Null }
    $pesterConfig = New-PesterConfiguration
    $pesterConfig.Run.Path = $script:BH.TestsDir
    $pesterConfig.Run.Exit = $false
    $pesterConfig.Run.PassThru = $true
    $pesterConfig.Output.Verbosity = 'Detailed'
    $pesterConfig.TestResult.Enabled = $true
    $pesterConfig.TestResult.OutputPath = Join-Path $script:BH.TestResults 'TestResults.xml'
    $pesterConfig.TestResult.OutputFormat = 'NUnitXml'
    $pesterConfig.CodeCoverage.Enabled = ($script:BH.Configuration -eq 'Release')
    if ($script:BH.Configuration -eq 'Release') {
        $pesterConfig.CodeCoverage.OutputPath = Join-Path $script:BH.TestResults 'Coverage.xml'
        $pesterConfig.CodeCoverage.OutputFormat = 'JaCoCo'
    }
    $result = Invoke-Pester -Configuration $pesterConfig
    Write-Host "`nResumo dos Testes:" -ForegroundColor Cyan
    Write-Host "  Passou: $($result.PassedCount)" -ForegroundColor Green
    Write-Host "  Falhou: $($result.FailedCount)" -ForegroundColor $(if ($result.FailedCount -eq 0) { 'Green' } else { 'Red' })
    Write-Host "  Pulado: $($result.SkippedCount)" -ForegroundColor Yellow
    Write-Host "  Total:  $($result.TotalCount)" -ForegroundColor Cyan
    Write-Host "  Duração: $([int]$result.Duration.TotalMilliseconds) ms" -ForegroundColor Gray
    if ($result.FailedCount -gt 0) { throw "$($result.FailedCount) teste(s) falharam" }
}

function Task-Build {
    Write-Host "Validando manifest e estrutura do módulo..."
    if (-not (Test-Path $script:BH.ManifestPath)) { throw "Manifest não encontrado: $($script:BH.ManifestPath)" }
    try {
        $manifest = Test-ModuleManifest -Path $script:BH.ManifestPath -ErrorAction Stop
        Write-Host "  ✓ Manifest válido" -ForegroundColor Green
        Write-Host "    Nome: $($manifest.Name)  Versão: $($manifest.Version)  Autor: $($manifest.Author)" -ForegroundColor Gray
    } catch { throw "Manifest inválido: $($_.Exception.Message)" }
    foreach ($file in $script:BH.RequiredFiles) {
        $path = Join-Path $script:BH.Root $file
        if (-not (Test-Path $path)) { throw "Arquivo obrigatório não encontrado: $file" }
    }
    Write-Host "  ✓ Estrutura válida" -ForegroundColor Green
}

function Task-Package {
    Write-Host "Criando pacote ZIP para distribuição..."
    if (-not (Test-Path $script:BH.PackageDir)) { New-Item -ItemType Directory -Path $script:BH.PackageDir -Force | Out-Null }
    $manifest = Test-ModuleManifest -Path $script:BH.ManifestPath -ErrorAction Stop
    $version = $manifest.Version.ToString()
    $packageName = "$($script:BH.ModuleName)-v$version-$($script:BH.Configuration).zip"
    $packagePath = Join-Path $script:BH.PackageDir $packageName
    $tempDir = Join-Path $env:TEMP "$($script:BH.ModuleName)-$version-$(Get-Date -Format 'yyyyMMddHHmmss')"
    if (Test-Path $tempDir) { Remove-Item $tempDir -Recurse -Force }
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
    foreach ($pattern in $script:BH.PackageFiles) {
        $items = Get-ChildItem (Join-Path $script:BH.Root $pattern) -Recurse -ErrorAction SilentlyContinue
        foreach ($item in $items) {
            $relativePath = $item.FullName.Replace($script:BH.Root, '').TrimStart('\')
            $destination = Join-Path $tempDir $relativePath
            $destDir = Split-Path $destination -Parent
            if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }
            Copy-Item $item.FullName -Destination $destination -Force
        }
    }
    if (Test-Path $packagePath) { Remove-Item $packagePath -Force }
    Compress-Archive -Path "$tempDir\*" -DestinationPath $packagePath -Force
    Remove-Item $tempDir -Recurse -Force
    Write-Host "  ✓ Pacote criado: $packageName" -ForegroundColor Green
    Write-Host "    Path: $packagePath" -ForegroundColor Gray
    Write-Host "    Tamanho: $([math]::Round((Get-Item $packagePath).Length / 1KB, 2)) KB" -ForegroundColor Gray
}

function Task-All {
    $tasks = @('Clean', 'Analyze', 'Test', 'Build', 'Package')
    foreach ($tn in $tasks) {
        if ($script:BH.SkipTests -and $tn -eq 'Test') { continue }
        $success = Invoke-Task -Name $tn -ScriptBlock { & "Task-$tn" }
        if (-not $success) { Write-Error "Build falhou na tarefa: $tn"; return }
    }
    Write-Host "`n$('=' * 70)" -ForegroundColor Green
    Write-Host "  BUILD COMPLETO COM SUCESSO!" -ForegroundColor Green
    Write-Host "$('=' * 70)" -ForegroundColor Green
}

function Start-Build {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false, Position = 0)]
        [ValidateSet('Clean', 'Analyze', 'Test', 'Build', 'Package', 'All')]
        [string] $Task = 'Build',

        [Parameter(Mandatory = $false)]
        [ValidateSet('Debug', 'Release')]
        [string] $Configuration = 'Debug',

        [Parameter(Mandatory = $false)]
        [switch] $SkipTests,

        [Parameter(Mandatory)] [string] $ModuleName,
        [Parameter(Mandatory)] [string] $ManifestFileName,
        [Parameter(Mandatory)] [string[]] $RequiredFiles,
        [Parameter(Mandatory)] [string[]] $PackageFiles,
        [string[]] $CleanPatterns = @()
    )

    $script:BH = @{
        ModuleName    = $ModuleName
        Root          = $PSScriptRoot
        ManifestPath  = Join-Path $PSScriptRoot $ManifestFileName
        TestsDir      = Join-Path $PSScriptRoot 'Tests'
        TestResults   = Join-Path $PSScriptRoot 'Tests' 'reports'
        PackageDir    = Join-Path $PSScriptRoot 'Package'
        SettingsPath  = Join-Path $PSScriptRoot 'PSScriptAnalyzerSettings.psd1'
        RequiredFiles = $RequiredFiles
        PackageFiles  = $PackageFiles
        CleanPatterns = $CleanPatterns
        Task          = $Task
        Configuration = $Configuration
        SkipTests     = $SkipTests.IsPresent
        ExitCode      = 0
        StartTime     = Get-Date
    }

    Write-Host "`n$('=' * 70)" -ForegroundColor Cyan
    Write-Host "  $ModuleName Module - Build Script" -ForegroundColor Cyan
    Write-Host "$('=' * 70)" -ForegroundColor Cyan
    Write-Host "  Tarefa: $Task  Configuração: $Configuration  Pular Testes: $($script:BH.SkipTests)" -ForegroundColor Gray

    try {
        if ($Task -eq 'All') { Task-All }
        else { Invoke-Task -Name $Task -ScriptBlock { & "Task-$Task" } }
    } catch {
        Write-Error "Build falhou: $($_.Exception.Message)"
        $script:BH.ExitCode = 1
    } finally {
        $duration = [int]((Get-Date) - $script:BH.StartTime).TotalSeconds
        Write-Host "`n$('=' * 70)" -ForegroundColor Cyan
        Write-Host "  Build finalizado em $duration segundos" -ForegroundColor Cyan
        Write-Host "$('=' * 70)" -ForegroundColor Cyan
    }

    exit $script:BH.ExitCode
}
