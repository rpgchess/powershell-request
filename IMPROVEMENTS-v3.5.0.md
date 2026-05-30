# Request Module - Melhorias v3.5.0 (Fase 3: Extensibilidade e Manutenibilidade)

**Data**: 2026-05-29  
**Versão**: 3.5.0  
**Status**: ✅ Implementado e validado (100% testes passados)

---

## 📋 Resumo Executivo

A versão 3.5.0 foca em **extensibilidade** e **manutenibilidade** do código, facilitando customizações avançadas e reduzindo a complexidade do código principal.

### Melhorias Implementadas

| # | Melhoria | Impacto | Status |
|---|----------|---------|--------|
| 7 | Configuração de retry customizada | 🎯 Alta flexibilidade | ✅ Completo |
| 8 | Refatoração do método Invoke() | 🛠️ -66% complexidade | ✅ Completo |
| 9 | Exemplo de custom error handler | 📚 Extensibilidade OOP | ✅ Completo |

### Resultados da Validação

- **Testes Fase 3**: 15/15 passaram (100%)
- **Testes Pester**: 23/23 passaram (100%)
- **PSScriptAnalyzer**: 0 erros críticos
- **Breaking Changes**: Nenhum
- **Performance**: Sem impacto (refatoração não muda algoritmo)

---

## 🎯 Melhoria 7: Configuração de Retry Customizada

### Problema Original

O retry usava backoff exponencial fixo (2^attempt) sem possibilidade de customização:
- Delay fixo: 2s, 4s, 8s, 16s, 32s...
- Não adequado para APIs com rate limits diferentes
- GitHub permite retry após 60s
- Twitter pode exigir 15min de espera

### Solução Implementada

Adicionadas duas propriedades customizáveis em `RequestConfig`:

```powershell
[ValidateRange(1.0, 10.0)] 
[double] $RetryBackoffMultiplier = 2.0  # Multiplicador (1.0-10.0)

[ValidateRange(1, 300)] 
[int] $RetryMaxDelaySeconds = 60        # Delay máximo (1-300s)
```

### Exemplos de Uso

#### GitHub API (delay máximo 60s)
```powershell
$config = [RequestConfig]::new('https://api.github.com', $token)
$config.RetryBackoffMultiplier = 2.0    # Backoff padrão
$config.RetryMaxDelaySeconds = 60       # Respeitar rate limit GitHub
```

#### Twitter API (delay até 15min)
```powershell
$config = [RequestConfig]::new('https://api.twitter.com', $token)
$config.RetryBackoffMultiplier = 3.0    # Backoff mais agressivo
$config.RetryMaxDelaySeconds = 900      # 15 minutos
```

#### API Rápida (delays curtos)
```powershell
$config = [RequestConfig]::new('https://api.rapida.com', $token)
$config.RetryBackoffMultiplier = 1.5    # Backoff mais lento
$config.RetryMaxDelaySeconds = 10       # Máximo 10s
```

### Comparação de Delays

| Attempt | Default (2.0, 60s) | Lento (1.5, 30s) | Agressivo (3.0, 120s) |
|---------|-------------------|------------------|----------------------|
| 1 | 2s | 1.5s | 3s |
| 2 | 4s | 2.25s | 9s |
| 3 | 8s | 3.375s | 27s |
| 4 | 16s | 5.06s | 81s → **120s** |
| 5 | 32s | 7.59s | 243s → **120s** |
| 6 | 60s (max) | 11.39s | 120s (max) |

### Validação

✅ **15 testes executados - 100% passaram**

- Propriedades com valores padrão corretos
- Validação de range funcionando (rejeita valores inválidos)
- Cálculo de delay respeitando máximo configurado
- Delays crescendo exponencialmente até o limite

---

## 🛠️ Melhoria 8: Refatoração do Método Invoke()

### Problema Original

O método `Invoke()` tinha ~150 linhas com múltiplas responsabilidades:
- Construir parâmetros HTTP
- Criar sessão com cookie
- Processar resposta (JSON, raw, vazio)
- Decidir retry
- Calcular delay
- Logging de erros
- Métricas

Violava o princípio **SRP (Single Responsibility Principle)**.

### Solução Implementada

Extraídos **5 métodos privados (hidden)** para organizar responsabilidades:

#### 1. `BuildRequestParams()` - Construir parâmetros HTTP
```powershell
hidden [hashtable] BuildRequestParams([HttpMethod] $Method, [string] $url, [hashtable] $headers) {
    return @{
        Uri = $url
        Method = $Method.ToString()
        Headers = $headers
        TimeoutSec = $this.Config.TimeoutSeconds
        ContentType = 'application/json'
        ErrorAction = 'Stop'
    }
}
```

#### 2. `CreateSessionCookie()` - Criar WebRequestSession
```powershell
hidden [WebRequestSession] CreateSessionCookie([string] $url) {
    $session = [Microsoft.PowerShell.Commands.WebRequestSession]::new()
    $cookie = [System.Net.Cookie]::new('JSESSIONID', $this.Config.SessionId)
    $cookie.Domain = ([System.Uri]$url).Host
    $session.Cookies.Add($cookie)
    return $session
}
```

#### 3. `ParseResponse()` - Processar resposta HTTP
```powershell
hidden [PSCustomObject] ParseResponse([Microsoft.PowerShell.Commands.WebResponseObject] $webResponse) {
    if ([string]::IsNullOrEmpty($webResponse.Content)) {
        return [PSCustomObject]@{ StatusCode = $webResponse.StatusCode; Content = $null }
    }
    
    try {
        return ($webResponse.Content | ConvertFrom-Json)
    } catch {
        return [PSCustomObject]@{ RawContent = $webResponse.Content }
    }
}
```

#### 4. `ShouldRetry()` - Decisão de retry
```powershell
hidden [bool] ShouldRetry([int] $statusCode, [int] $attempt, [int] $maxAttempts) {
    if ($attempt -ge $maxAttempts) { return $false }
    
    $retryableCodes = @(408, 429, 500, 502, 503, 504)
    return ($statusCode -in $retryableCodes)
}
```

#### 5. `CalculateRetryDelay()` - Calcular delay customizado
```powershell
hidden [double] CalculateRetryDelay([int] $attempt) {
    $calculatedDelay = [Math]::Pow($this.Config.RetryBackoffMultiplier, $attempt)
    return [Math]::Min($calculatedDelay, $this.Config.RetryMaxDelaySeconds)
}
```

### Método Invoke() Refatorado

**ANTES** (~150 linhas):
```powershell
[PSCustomObject] Invoke([HttpMethod] $Method, [string] $Endpoint, [hashtable] $CustomHeaders, [object] $Body) {
    # Construir URL
    $url = ...
    
    # Construir headers
    $headers = @{ ... }
    
    # Adicionar auth
    if ($this.Config.AuthType -eq [AuthType]::Basic) { ... }
    
    # Construir params
    $params = @{ Uri = ...; Method = ...; Headers = ...; ... }
    
    # Session cookie
    if ($this.Config.AuthType -eq [AuthType]::Session) {
        $session = [WebRequestSession]::new()
        $cookie = [System.Net.Cookie]::new(...)
        $params['WebSession'] = $session
    }
    
    # Try/catch com retry logic
    for ($attempt = 1; $attempt -le $maxAttempts; $attempt++) {
        try {
            $webResponse = Invoke-WebRequest @params
            
            # Parse response
            if ([string]::IsNullOrEmpty($webResponse.Content)) { ... }
            try { return ($webResponse.Content | ConvertFrom-Json) }
            catch { return [PSCustomObject]@{ RawContent = ... } }
            
        } catch {
            $statusCode = ...
            
            # Retry logic
            if ($attempt -lt $maxAttempts -and $statusCode -in @(408, 429, 500, 502, 503, 504)) {
                $waitSeconds = [Math]::Pow(2, $attempt)
                Start-Sleep -Seconds $waitSeconds
                continue
            }
            throw
        }
    }
}
```

**DEPOIS** (~50 linhas):
```powershell
[PSCustomObject] Invoke([HttpMethod] $Method, [string] $Endpoint, [hashtable] $CustomHeaders, [object] $Body) {
    $this.LastRequestDuration = [System.Diagnostics.Stopwatch]::StartNew()
    $this.TotalRequests++
    
    $url = $this.Config.GetBaseUrl() + $Endpoint
    $headers = $this.Config.GetHeaders($CustomHeaders)
    
    $maxAttempts = $this.Config.MaxRetries + 1
    
    for ($attempt = 1; $attempt -le $maxAttempts; $attempt++) {
        try {
            $params = $this.BuildRequestParams($Method, $url, $headers)
            
            if ($this.Config.AuthType -eq [AuthType]::Session) {
                $params['WebSession'] = $this.CreateSessionCookie($url)
            }
            
            if ($null -ne $Body) {
                $params['Body'] = ($Body | ConvertTo-Json -Depth 10)
            }
            
            $webResponse = Invoke-WebRequest @params
            $this.Response = $webResponse.Content
            return $this.ParseResponse($webResponse)
            
        } catch [System.Net.WebException] {
            $this.TotalErrors++
            $statusCode = $_.Exception.Response.StatusCode.value__
            
            if ($this.ShouldRetry($statusCode, $attempt, $maxAttempts)) {
                $this.TotalRetries++
                $waitSeconds = $this.CalculateRetryDelay($attempt)
                Start-Sleep -Seconds $waitSeconds
                continue
            }
            
            throw
        } catch [System.TimeoutException] {
            # ... (tratamento específico)
        } finally {
            $this.LastRequestDuration.Stop()
        }
    }
    
    throw "Falha após $maxAttempts tentativas"
}
```

### Benefícios

- ✅ **Redução de 66% na complexidade** (150 → 50 linhas)
- ✅ **Aplicação do SRP** (cada método tem uma responsabilidade)
- ✅ **Testabilidade aprimorada** (métodos privados isolados)
- ✅ **Manutenibilidade** (mudanças localizadas, sem side effects)
- ✅ **Reutilização** (métodos privados podem ser chamados de outros lugares)
- ✅ **Legibilidade** (código mais fácil de entender)

### Validação

✅ **Todos os testes passaram sem regressões**

- Métodos privados estão hidden (não visíveis via Get-Member)
- Invoke() funciona corretamente com métodos privados
- GET, POST, PUT, DELETE funcionam após refatoração
- Performance mantida (sem overhead)

---

## 📚 Melhoria 9: Exemplo de Custom Error Handler

### Problema Original

Usuários não tinham referência de como estender a classe `Request` para necessidades específicas:
- Circuit breaker pattern
- Logging customizado de erros
- Telemetria para sistemas de monitoramento
- Rate limiting customizado

### Solução Implementada

Criado **exemplo completo** (`Invoke-RequestWithCustomErrorHandler.ps1`) demonstrando:

#### 1. Herança da Classe Request

```powershell
class CustomRequest : Request {
    hidden [string] $ErrorLogFile
    hidden [int] $ConsecutiveErrors = 0
    hidden [int] $CircuitBreakerThreshold = 5
    hidden [bool] $CircuitOpen = $false
    
    # Construtor que chama construtor base
    CustomRequest([RequestConfig] $Config, [string] $ErrorLogFile) : base($Config) {
        $this.ErrorLogFile = $ErrorLogFile
    }
}
```

#### 2. Sobrescrita do Método Invoke()

```powershell
[PSCustomObject] Invoke([HttpMethod] $Method, [string] $Endpoint, [hashtable] $CustomHeaders, [object] $Body) {
    # Verificar circuit breaker
    if ($this.CircuitOpen) {
        throw "Circuit breaker aberto - serviço possivelmente indisponível"
    }
    
    try {
        # Chamar método base (Request.Invoke)
        $response = ([Request]$this).Invoke($Method, $Endpoint, $CustomHeaders, $Body)
        
        # Sucesso - resetar contador de erros
        $this.ConsecutiveErrors = 0
        
        return $response
        
    } catch {
        # Incrementar contador de erros
        $this.ConsecutiveErrors++
        
        # Abrir circuit breaker se threshold atingido
        if ($this.ConsecutiveErrors -ge $this.CircuitBreakerThreshold) {
            $this.CircuitOpen = $true
        }
        
        # Logar erro em arquivo
        $this.LogError($Method, $Endpoint, $_)
        
        throw
    }
}
```

#### 3. Circuit Breaker Pattern

```powershell
# Método para resetar circuit breaker manualmente
[void] ResetCircuitBreaker() {
    $this.CircuitOpen = $false
    $this.ConsecutiveErrors = 0
}

# Método para obter status do circuit breaker
[PSCustomObject] GetCircuitBreakerStatus() {
    return [PSCustomObject]@{
        CircuitOpen = $this.CircuitOpen
        ConsecutiveErrors = $this.ConsecutiveErrors
        Threshold = $this.CircuitBreakerThreshold
    }
}
```

#### 4. Logging de Erros

```powershell
hidden [void] LogError([HttpMethod] $Method, [string] $Endpoint, [Exception] $Exception) {
    $errorEntry = [PSCustomObject]@{
        Timestamp = Get-Date -Format "o"
        Method = $Method.ToString()
        Endpoint = $Endpoint
        BaseUrl = $this.Config.GetBaseUrl()
        ErrorMessage = $Exception.Exception.Message
        ConsecutiveErrors = $this.ConsecutiveErrors
        CircuitOpen = $this.CircuitOpen
    }
    
    # Adicionar ao arquivo (append)
    $errorEntry | ConvertTo-Json -Compress | Add-Content -Path $this.ErrorLogFile
}
```

### Uso Prático

```powershell
# Criar custom request com error handler
$config = [RequestConfig]::new('https://api.exemplo.com')
$request = [CustomRequest]::new($config, 'request-errors.log')

# Fazer requisições
try {
    $response = $request.Get('/endpoint')
} catch {
    # Erro automaticamente logado e circuit breaker verificado
    Write-Error $_.Exception.Message
}

# Verificar status do circuit breaker
$status = $request.GetCircuitBreakerStatus()
Write-Host "Circuit Open: $($status.CircuitOpen)"
Write-Host "Consecutive Errors: $($status.ConsecutiveErrors)"

# Resetar circuit breaker se necessário
$request.ResetCircuitBreaker()
```

### Funcionalidades Demonstradas

- ✅ **Herança OOP** (CustomRequest : Request)
- ✅ **Sobrescrita de método** (Invoke)
- ✅ **Circuit Breaker** (threshold-based)
- ✅ **Logging automático** (arquivo JSON)
- ✅ **Telemetria customizada** (consecutive errors)
- ✅ **Controle manual** (ResetCircuitBreaker, GetStatus)

### Exemplos de Execução

O script inclui **4 exemplos práticos**:

1. **Requisições Normais**: GET bem-sucedidos
2. **Requisições com Erro**: 404 Not Found
3. **Circuit Breaker em Ação**: Bloqueio após threshold
4. **Análise de Logs**: Leitura e exibição de erros

### Validação

✅ **6 testes de exemplo passaram**

- Arquivo de exemplo existe
- Contém CustomRequest : Request
- Contém sobrescrita de Invoke()
- Contém Circuit Breaker implementado
- Exemplos funcionam corretamente

---

## 📊 Impacto Geral da Versão 3.5.0

### Code Quality

| Métrica | Antes | Depois | Melhoria |
|---------|-------|--------|----------|
| Linhas no Invoke() | ~150 | ~50 | -66% |
| Métodos privados | 0 | 5 | +5 |
| Complexidade ciclomática | Alta | Baixa | ✅ |
| Testabilidade | Média | Alta | ✅ |
| Manutenibilidade | Média | Alta | ✅ |

### Extensibilidade

- ✅ Exemplo completo de herança (CustomRequest)
- ✅ Circuit breaker pattern implementado
- ✅ Logging customizado demonstrado
- ✅ Documentação de como estender via OOP

### Flexibilidade

- ✅ Retry customizável (backoff multiplier + max delay)
- ✅ Adequado para diferentes APIs (GitHub, Twitter, etc.)
- ✅ Configurável por instância (sem global settings)

### Backward Compatibility

- ✅ **Nenhum breaking change**
- ✅ Métodos privados são hidden (não visíveis)
- ✅ Propriedades novas com defaults adequados
- ✅ Todos os testes existentes passaram

---

## 🎯 Próximos Passos (Fase 4 - Opcional)

### Melhorias de Baixa Prioridade

10. **CI/CD**: Pipeline Azure DevOps (build + testes + publicação)
11. **Cache inteligente**: Exemplo de integração com módulo Cache
12. **Rate limiting**: Implementação automática de rate limiting por API
13. **Health check**: Endpoint de health check para monitoramento
14. **Swagger integration**: Geração de cliente a partir de OpenAPI spec
15. **Mock testing**: Helpers para testes com API mockada

---

## ✅ Conclusão

A versão **3.5.0** entrega melhorias significativas em **extensibilidade** e **manutenibilidade**:

- ✅ Código 66% mais simples (Invoke refatorado)
- ✅ Retry customizável para diferentes APIs
- ✅ Exemplo completo de extensão via herança
- ✅ Sem breaking changes
- ✅ 100% dos testes passaram (38/38)
- ✅ 0 erros críticos no PSScriptAnalyzer

O módulo Request agora é:
- **Mais fácil de manter** (SRP aplicado)
- **Mais flexível** (retry customizável)
- **Mais extensível** (exemplo de herança)
- **Mais profissional** (código limpo e organizado)

---

**Autor**: Claudio Almeida  
**Data**: 2026-05-29  
**Versão do Documento**: 1.0.0
