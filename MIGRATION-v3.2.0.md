# Migration Guide: Request v3.1.0 → v3.2.0

> **Modularização de Cache** - RequestCache removido, substituído por Cache module externo

---

## 📋 Resumo das Mudanças

### 🔥 Breaking Changes
- **RequestCache.ps1 removido** do projeto Request
- **Nova dependência**: Cache module v1.0.0+ (standalone)
- **API change**: `[RequestCache]` → `[Cache]`

### ✨ Melhorias
- **Cache modularizado**: Reutilizável em outros projetos PowerShell
- **Novos métodos**: GetKeys(), GetStats(), RemoveExpired()
- **Múltiplos construtores**: Maior flexibilidade na inicialização
- **Parse robusto**: DateTimeOffset para melhor precisão

---

## 🚀 Guia de Migração

### Passo 1: Instalar Cache Module

```powershell
# Navegar para o diretório do Cache module
cd ..\powershell-cache

# Instalar dependências (Pester, PSScriptAnalyzer)
.\Install-Dependencies.ps1

# Validar build
.\Build.ps1 -Task All
```

### Passo 2: Importar Módulos na Ordem Correta

```powershell
# Importar Cache module primeiro
Import-Module '..\powershell-cache\Cache.psd1' -Force

# Importar Logger module (mantido de v3.1.0)
Import-Module '..\powershell-logger\Logger.psd1' -Force

# Importar Request module
Import-Module '.\Request.psd1' -Force
```

### Passo 3: Atualizar Código

#### Antes (v3.1.0)

```powershell
using module '.\Request.psd1'

# Criar cache com RequestCache
$cache = [RequestCache]::new('my-api.cache')

# Set/Get/Save
$cache.Set('user-data', $userData, 300)
$data = $cache.Get('user-data')
$cache.Save()

# Métodos disponíveis: Get, Set, Remove, Clear, Contains, Load, Save
```

#### Depois (v3.2.0)

```powershell
# Importar Cache module
Import-Module '..\powershell-cache\Cache.psd1'
Import-Module '.\Request.psd1'

# Criar cache com Cache (extensão .cache automática)
$cache = [Cache]::new('my-api')

# Set/Get/Save (API compatível)
$cache.Set('user-data', $userData, 300)
$data = $cache.Get('user-data')
$cache.Save()

# Novos métodos disponíveis
$keys = $cache.GetKeys()          # Lista todas as chaves válidas
$stats = $cache.GetStats()        # Estatísticas (total, válidas, expiradas)
$removed = $cache.RemoveExpired() # Remove entradas expiradas manualmente
```

---

## 🔄 Compatibilidade de API

### Métodos Mantidos (100% compatível)

| Método | v3.1.0 | v3.2.0 | Notas |
|--------|--------|--------|-------|
| `Get(key)` | ✅ | ✅ | Idêntico |
| `Set(key, data)` | ✅ | ✅ | Idêntico |
| `Set(key, data, ttl)` | ✅ | ✅ | Idêntico |
| `Remove(key)` | ✅ | ✅ | Idêntico |
| `Clear()` | ✅ | ✅ | Idêntico |
| `Contains(key)` | ✅ | ✅ | Idêntico |
| `Load()` | ✅ | ✅ | Idêntico |
| `Save()` | ✅ | ✅ | Idêntico |

### Novos Métodos (v3.2.0)

| Método | Descrição | Exemplo |
|--------|-----------|---------|
| `GetKeys()` | Lista todas as chaves válidas (não expiradas) | `$keys = $cache.GetKeys()` |
| `GetStats()` | Retorna estatísticas do cache (total, válidas, expiradas) | `$stats = $cache.GetStats()` |
| `RemoveExpired()` | Remove todas as entradas expiradas | `$removed = $cache.RemoveExpired()` |

### Construtores

```powershell
# v3.1.0 - RequestCache
$cache = [RequestCache]::new('file.cache')

# v3.2.0 - Cache (extensão .cache automática)
$cache = [Cache]::new('file')              # Cria no diretório atual
$cache = [Cache]::new('file', 'C:\Path')   # Caminho customizado
```

---

## 📦 Estrutura do Projeto

### Antes (v3.1.0)

```
request/
├── Core/
│   ├── RequestEnums.ps1
│   ├── RequestConfig.ps1
│   ├── RequestCache.ps1    ← Arquivo interno
│   └── Request.ps1
├── Request.psd1
└── Request.psm1
```

### Depois (v3.2.0)

```
request/
├── Core/
│   ├── RequestEnums.ps1
│   ├── RequestConfig.ps1
│   └── Request.ps1         ← RequestCache removido
├── Request.psd1            ← ScriptsToProcess atualizado
└── Request.psm1

powershell-cache/           ← Módulo externo
├── Core/
│   └── Cache.ps1
├── Cache.psd1
├── Cache.psm1
└── Tests/
    └── Cache.Tests.ps1     ← 37 unit tests
```

---

## 🧪 Validação

### Testar Cache Module

```powershell
cd ..\powershell-cache
.\Build.ps1 -Task All

# Esperado:
# - PSScriptAnalyzer: 0 erros
# - Pester: 37/37 testes passando (100%)
```

### Testar Request Module

```powershell
cd ..\request

# Limpar build anterior
Remove-Item Package -Recurse -Force -ErrorAction SilentlyContinue

# Build completo
.\Build.ps1 -Task All

# Esperado:
# - PSScriptAnalyzer: 0 erros
# - Pester: 23/24 testes (1 skip intencional - integração Jira)
```

### Exemplo Completo

```powershell
# Importar módulos
Import-Module '..\powershell-cache\Cache.psd1'
Import-Module '..\powershell-logger\Logger.psd1'
Import-Module '.\Request.psd1'

# Criar cache
$cache = [Cache]::new('github-api')

# Criar request com cache
$request = [Request]::new('https://api.github.com', $env:GITHUB_TOKEN)

# Buscar dados (com cache)
$cacheKey = 'user-octocat'
$user = $cache.Get($cacheKey)

if ($null -eq $user) {
    Write-Host "Cache miss - buscando da API..." -ForegroundColor Yellow
    $user = $request.Get('/users/octocat')
    $cache.Set($cacheKey, $user, 300)  # 5 minutos
    $cache.Save()
} else {
    Write-Host "Cache hit!" -ForegroundColor Green
}

# Verificar estatísticas
$stats = $cache.GetStats()
Write-Host "Cache stats: $($stats.ValidEntries) válidas, $($stats.ExpiredEntries) expiradas"
```

---

## ❌ Erros Comuns

### Erro 1: Cache module não encontrado

```
The term '[Cache]' is not recognized...
```

**Solução**: Importar Cache module antes do Request

```powershell
Import-Module '..\powershell-cache\Cache.psd1' -Force
```

### Erro 2: RequestCache não existe

```
Unable to find type [RequestCache]
```

**Solução**: Substituir `[RequestCache]` por `[Cache]` no código

```powershell
# Antes
$cache = [RequestCache]::new('file.cache')

# Depois
$cache = [Cache]::new('file')
```

### Erro 3: ScriptsToProcess error

```
The specified module 'Request' was not loaded because no valid module file was found...
```

**Solução**: Atualizar Request.psd1 removendo RequestCache.ps1 dos ScriptsToProcess

```powershell
ScriptsToProcess = @(
    'Core\RequestEnums.ps1',
    'Core\RequestConfig.ps1',
    # 'Core\RequestCache.ps1',  ← Remover
    'Core\Request.ps1'
)
```

---

## 📚 Recursos Adicionais

- **Cache Module README**: `..\powershell-cache\README.md`
- **Cache Module Tests**: `..\powershell-cache\Tests\Cache.Tests.ps1`
- **Request CHANGELOG**: `.\CHANGELOG.md`
- **Logger Migration**: `.\MIGRATION-v3.1.0.md`

---

## 🆘 Suporte

Se encontrar problemas durante a migração:

1. Verificar se Cache module está instalado: `Get-Module -ListAvailable Cache`
2. Validar build do Cache: `cd ..\powershell-cache; .\Build.ps1 -Task Test`
3. Verificar ordem de import: Cache → Logger → Request
4. Consultar exemplos: `..\powershell-cache\Test-Cache.ps1`

---

**Versão**: v3.2.0  
**Data**: 2026-05-26  
**Breaking Changes**: Sim (RequestCache → Cache)  
**Retrocompatibilidade**: API mantida (métodos Get/Set/Save/Load idênticos)
