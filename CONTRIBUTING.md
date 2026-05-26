# Request Module - Development Guide

> **Guia de desenvolvimento para contribuidores do módulo Request**

---

## 📋 Quick Start para Desenvolvedores

### 1. Clone e Setup Inicial

```powershell
# Clonar repositório
git clone https://github.com/rpgchess/powershell-request.git
cd request-module

# Instalar dependências (automático)
.\Install-Dependencies.ps1

# Verificar instalação
Get-Module Pester, PSScriptAnalyzer -ListAvailable
```

### 2. Workflow de Desenvolvimento

```powershell
# 1. Criar branch para feature
git checkout -b feature/minha-feature

# 2. Fazer alterações nos arquivos

# 3. Validar código
.\Build.ps1 -Task Analyze

# 4. Executar testes
.\Build.ps1 -Task Test

# 5. Build completo
.\Build.ps1

# 6. Commit e push
git add .
git commit -m "Add: minha feature"
git push origin feature/minha-feature
```

---

## 🛠️ Scripts de Build

### Install-Dependencies.ps1

Instala todas as dependências necessárias para desenvolvimento.

**Uso básico**:
```powershell
.\Install-Dependencies.ps1
```

**Opções**:
- `-Force`: Reinstala mesmo se já instalado
- `-SkipOptional`: Pula dependências opcionais
- `-Scope AllUsers`: Instala para todos os usuários (requer admin)

**Dependências**:
- **Obrigatórias**: Pester 5.x, PSScriptAnalyzer 1.21+
- **Opcionais**: powershell-yaml, Plaster

---

### Build.ps1

Script de build completo com múltiplas tarefas.

**Tasks disponíveis**:

#### Clean
Remove arquivos temporários e cria estrutura de diretórios.
```powershell
.\Build.ps1 -Task Clean
```

#### Analyze
Valida código com PSScriptAnalyzer (0 erros críticos obrigatório).
```powershell
.\Build.ps1 -Task Analyze
```

#### Test
Executa testes Pester (23+ testes, 100% pass rate esperado).
```powershell
.\Build.ps1 -Task Test
```

#### Build
Clean + Analyze + Test (tarefa padrão).
```powershell
.\Build.ps1
```

#### Package
Cria arquivo .zip para distribuição.
```powershell
.\Build.ps1 -Task Package -Configuration Release
```

#### All
Executa todas as tarefas (Build + Package).
```powershell
.\Build.ps1 -Task All -Configuration Release
```

**Opções**:
- `-Configuration Debug|Release`: Modo de build (padrão: Debug)
- `-SkipTests`: Pula execução de testes Pester

---

## 📁 Estrutura de Arquivos

```
request/
├── Request.psd1                 # Module manifest (v3.0.0)
├── Request.psm1                 # Module loader
├── Build.ps1                    # Build script
├── Install-Dependencies.ps1     # Dependency manager
├── requirements.psd1            # Dependency specification
├── Test-Request.ps1             # Standalone tests
├── Invoke-JiraSessionExample.ps1 # Example usage
├── Test-Session-Authentication.ps1
├── README.md                    # Documentation
├── CHANGELOG.md                 # Version history
├── CONTRIBUTING.md              # (este arquivo)
├── .gitignore                   # Git ignore rules
│
├── .vscode/
│   └── PSScriptAnalyzerSettings.psd1  # Code quality config
│
├── Core/
│   ├── RequestEnums.ps1         # Enums (HttpMethod, AuthType)
│   ├── RequestConfig.ps1        # Configuration class
│   └── Request.ps1              # Main Request class
│
├── Tests/
│   └── Request.Tests.ps1        # Pester 5.x tests
│
├── Package/                     # Build output (git ignored)
│   └── Request-v3.2.0.zip       # Distribution package
│
└── out/                         # Test output (git ignored)

**Módulos Externos** (dependências):
- `powershell-logger/` - Logger v1.0.0+ (logging estruturado)
- `powershell-cache/`  - Cache v1.0.0+ (cache com TTL)
```

---

## ✅ Checklist de Pull Request

Antes de abrir PR, garanta que:

- [ ] **Código valida**: `.\Build.ps1 -Task Analyze` sem erros
- [ ] **Testes passam**: `.\Build.ps1 -Task Test` 100% pass
- [ ] **Help completo**: Todos os scripts têm .SYNOPSIS, .PARAMETER, .EXAMPLE
- [ ] **Testes adicionados**: Novas features têm testes Pester
- [ ] **CHANGELOG atualizado**: Documentar mudanças em CHANGELOG.md
- [ ] **README atualizado**: Se aplicável, atualizar exemplos
- [ ] **Build limpo**: `.\Build.ps1` retorna exit 0
- [ ] **Commit messages**: Formato "Add|Fix|Change: descrição"

---

## 🧪 Desenvolvimento de Testes

### Estrutura de Teste Pester

```powershell
Describe 'Minha Feature' {
    BeforeAll {
        # Setup global
        $script:testConfig = [RequestConfig]::new('https://api.test.com')
    }
    
    Context 'Cenário de Teste' {
        It 'Deve fazer X quando Y' {
            # Arrange
            $request = [Request]::new($script:testConfig)
            
            # Act
            $result = $request.Get('/endpoint')
            
            # Assert
            $result.Status | Should -Be 200
        }
    }
    
    AfterAll {
        # Cleanup
    }
}
```

### Tags de Teste

- **Integration**: Testes que chamam APIs externas (JSONPlaceholder)
- **Unit**: Testes unitários (sem dependências externas)

```powershell
# Executar apenas unit tests
Invoke-Pester .\Tests\Request.Tests.ps1 -ExcludeTag 'Integration'

# Executar apenas integration tests
Invoke-Pester .\Tests\Request.Tests.ps1 -Tag 'Integration'
```

---

## 📝 Padrões de Código

### Comment-Based Help (OBRIGATÓRIO)

```powershell
<#
.SYNOPSIS
    Breve descrição em 1 linha.

.DESCRIPTION
    Descrição detalhada do que o script faz.
    Pré-requisitos, dependências.

.PARAMETER NomeParametro
    Descrição do parâmetro.

.EXAMPLE
    PS> .\Script.ps1 -Param 'Valor'
    Descrição do exemplo.

.NOTES
    Author: Seu Nome
    Date: YYYY-MM-DD
    Version: X.Y.Z
#>
```

### Validação de Parâmetros

```powershell
param(
    [Parameter(Mandatory = $false, Position = 0)]
    [Alias('Nome', 'ID')]
    [ValidateNotNullOrEmpty()]
    [string] $ParameterName,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet('Option1', 'Option2')]
    [string] $Mode = 'Option1'
)
```

### Estrutura begin/process/end

```powershell
begin {
    # Validações, inicializações
}

process {
    try {
        # Lógica principal
    } catch {
        # Error handling
        throw
    }
}

end {
    # Cleanup, retorno
}
```

---

## 🚀 Versionamento

Seguimos [Semantic Versioning](https://semver.org/):

- **MAJOR** (X.0.0): Breaking changes
- **MINOR** (0.X.0): Novas features (backward compatible)
- **PATCH** (0.0.X): Bug fixes

### Atualizar Versão

1. Editar `Request.psd1`:
   ```powershell
   ModuleVersion = '3.1.0'  # Nova versão
   ```

2. Atualizar `CHANGELOG.md`:
   ```markdown
   ## [3.1.0] - YYYY-MM-DD
   ### Added
   - Nova feature X
   ```

3. Criar tag Git:
   ```powershell
   git tag -a v3.1.0 -m "Release v3.1.0"
   git push origin v3.1.0
   ```

---

## 🐛 Debugging

### Verbose Output

```powershell
$VerbosePreference = 'Continue'
.\Test-Request.ps1
```

### Debug Mode

```powershell
$DebugPreference = 'Continue'
Import-Module .\Request.psd1 -Force
```

### PSScriptAnalyzer Específico

```powershell
# Analisar arquivo específico
Invoke-ScriptAnalyzer -Path .\Classes\Request.ps1 -Settings .vscode\PSScriptAnalyzerSettings.psd1
```

---

## 📞 Suporte

- **Issues**: https://github.com/rpgchess/powershell-request/issues
- **Discussions**: https://github.com/rpgchess/powershell-request/discussions
- **Email**: rpgchess@gmail.com

---

**Última atualização**: 2026-05-25  
**Versão**: 3.0.0
