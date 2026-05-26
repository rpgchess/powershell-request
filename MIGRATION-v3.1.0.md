# Migração Request v3.0 → v3.1.0

**Data**: 2026-05-26  
**Tipo**: Modularização de Logging

---

## 📊 Resumo das Mudanças

### Arquivos Removidos
- ✅ `Classes/RequestLogger.ps1` (3.45 KB, ~100 linhas)

### Arquivos Modificados
- ✅ `Request.psd1` (v3.0.0 → v3.1.0)
- ✅ `README.md` (seção de instalação atualizada)
- ✅ `CHANGELOG.md` (release notes v3.1.0)
- ✅ `requirements.psd1` (nota sobre Logger)

### Arquivos Criados
- ✅ `Invoke-RequestWithLogger.ps1` (exemplo de integração)

---

## 🔄 Antes vs Depois

### Estrutura de Classes

**Antes (v3.0.0)** - 5 arquivos:
```
Classes/
├── RequestEnums.ps1
├── RequestConfig.ps1
├── RequestCache.ps1
├── RequestLogger.ps1   ← REMOVIDO
└── Request.ps1
```

**Depois (v3.1.0)** - 4 arquivos:
```
Classes/
├── RequestEnums.ps1
├── RequestConfig.ps1
├── RequestCache.ps1
└── Request.ps1
```

### Request.psd1

**Antes**:
```powershell
ScriptsToProcess = @(
    'Classes\RequestEnums.ps1',
    'Classes\RequestConfig.ps1',
    'Classes\RequestCache.ps1',
    'Classes\RequestLogger.ps1',    # Logging interno
    'Classes\Request.ps1'
)
```

**Depois**:
```powershell
ScriptsToProcess = @(
    'Classes\RequestEnums.ps1',
    'Classes\RequestConfig.ps1',
    'Classes\RequestCache.ps1',
    'Classes\Request.ps1'
)

# Nota: Logger module (v1.0.0+) deve ser importado manualmente
# Import-Module '..\powershell-logger\Logger.psd1' -Force
```

---

## 📦 Módulo Logger Externo

### Localização
```
c:\Users\claudio.almeida\.dev\temp\
├── powershell-logger/        ← Módulo standalone
│   ├── Core/
│   │   ├── LoggerEnums.ps1
│   │   ├── LoggerConfig.ps1
│   │   └── Logger.ps1
│   ├── Logger.psd1 (v1.0.0)
│   ├── Tests/
│   ├── Build.ps1
│   └── README.md
└── request/                   ← Request module
    ├── Classes/
    ├── Request.psd1 (v3.1.0)
    └── Invoke-RequestWithLogger.ps1
```

### Funcionalidades do Logger

| Feature | RequestLogger (v3.0) | Logger Module (v3.1) |
|---------|----------------------|----------------------|
| **Níveis** | 5 (DEBUG, INFO, WARN, ERROR, SUCCESS) | 6 (+ FATAL) |
| **Formatos** | 1 (Detailed) | 3 (Simple, Detailed, Json) |
| **Saída** | Console apenas | Console + Arquivo |
| **Buffer** | ❌ | ✅ (configurável) |
| **Singleton** | ❌ | ✅ Instance() |
| **Exception Log** | Básico | Detalhado (type, inner, stacktrace) |
| **Timestamp** | Fixo | Formato customizável |
| **File Output** | ❌ | ✅ Com buffer |
| **Json Format** | ❌ | ✅ Structured logging |
| **Testes** | ❌ | ✅ 30 testes Pester |
| **Docs** | ❌ | ✅ README + CHANGELOG |

---

## 🎯 Benefícios da Modularização

### 1. Reutilização
Logger module pode ser usado em **qualquer projeto PowerShell**:
- Scripts de automação
- Outros módulos HTTP
- Ferramentas de DevOps
- Scripts de CI/CD

### 2. Redução de Código
- **Request**: ~100 linhas eliminadas (RequestLogger.ps1)
- **Logger**: 280 linhas (mas reutilizável)
- **Resultado**: Código mais limpo e focado em HTTP

### 3. Funcionalidades Avançadas
- **Singleton**: `[Logger]::Instance()` para uso global
- **File Output**: Logs persistentes com buffer
- **Json Format**: Structured logging para análise
- **FATAL Level**: Para erros críticos com flush imediato

### 4. Manutenção Independente
- Logger evolui independentemente do Request
- Versioning separado
- Testes separados (30 testes vs 24 testes)
- Bug fixes não afetam Request

### 5. Profissionalismo
- Logger tem:
  - ✅ Build automation (Build.ps1)
  - ✅ Dependency management (requirements.psd1)
  - ✅ Comprehensive tests (30 tests)
  - ✅ Documentation (README + CHANGELOG)
  - ✅ Examples (Test-Logger.ps1)
  - ✅ Package distribution (ZIP)

---

## 🚀 Como Usar

### Instalação

```powershell
# 1. Importar Logger module
cd c:\Users\claudio.almeida\.dev\temp\powershell-logger
Import-Module .\Logger.psd1 -Force

# 2. Importar Request module
cd ..\request
Import-Module .\Request.psd1 -Force
```

### Uso Básico

```powershell
# Configurar Logger
$logger = [Logger]::new()
$logger.Info('Iniciando requisições')

# Usar Request
$request = [Request]::new('https://api.exemplo.com', 'token')

try {
    $data = $request.Get('/api/data')
    $logger.Success("Recebidos $($data.Count) registros")
} catch {
    $logger.Error('Falha na requisição', $_.Exception)
}
```

### Exemplo Completo

```powershell
# Executar exemplo de integração
.\Invoke-RequestWithLogger.ps1

# Com log em arquivo
.\Invoke-RequestWithLogger.ps1 -OutputFile 'request.log'

# Log detalhado em JSON
.\Invoke-RequestWithLogger.ps1 -LogLevel DEBUG -LogFormat Json
```

---

## ✅ Validação

### Build Status
```
Request v3.1.0:
  ✓ Clean: OK
  ✓ Analyze: 0 erros críticos
  ✓ Test: 23/24 passou (1 skipped)
  ✓ Build: Manifest válido

Logger v1.0.0:
  ✓ Clean: OK
  ✓ Analyze: 0 erros críticos
  ✓ Test: 30/30 passou
  ✓ Build: Manifest válido
  ✓ Package: 11.58 KB
```

### Compatibilidade
- PowerShell 5.1+ ✅
- PowerShell 7+ ✅
- Windows ✅
- Linux/macOS ✅ (Logger)

---

## 📝 Breaking Changes

### Para Usuários do Request v3.0.0

**Antes** (automático):
```powershell
Import-Module .\Request.psd1
# RequestLogger já carregado automaticamente
```

**Depois** (manual):
```powershell
# 1. Importar Logger (dependência externa)
Import-Module '..\powershell-logger\Logger.psd1'

# 2. Importar Request
Import-Module .\Request.psd1
```

### Código de Logging (compatível)

O código de logging permanece **100% compatível** se você usar a mesma API:

```powershell
# v3.0.0 (RequestLogger)
$logger = [RequestLogger]::new()
$logger.Info('Mensagem')
$logger.Error('Erro', $exception)

# v3.1.0 (Logger module) - MESMA API
$logger = [Logger]::new()
$logger.Info('Mensagem')
$logger.Error('Erro', $exception)
```

**Novas funcionalidades disponíveis**:
```powershell
# Singleton (novo)
[Logger]::Instance().Info('Mensagem global')

# File output (novo)
$config = [LoggerConfig]::new()
$config.OutputFile = 'app.log'
$logger = [Logger]::new($config)

# Json format (novo)
$config.Format = [LogFormat]::Json
```

---

## 🎓 Lições Aprendidas

1. **Separação de Responsabilidades**: HTTP ≠ Logging
2. **Reutilização > Duplicação**: Logger agora serve múltiplos projetos
3. **Modularização**: Facilita manutenção e evolução independente
4. **Testes**: Logger tem 30 testes dedicados (antes: 0)
5. **Profissionalismo**: Build automation + docs + examples

---

**Conclusão**: Request v3.1.0 é mais **enxuto, focado e profissional**, delegando logging para módulo especializado reutilizável! 🎉
