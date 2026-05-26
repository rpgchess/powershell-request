<#
.SYNOPSIS
    Classe base para requisições HTTP com suporte a múltiplos tipos de autenticação.

.DESCRIPTION
    Encapsula Invoke-WebRequest com tratamento de erros, retry logic, logging e autenticação automática.
    
    Suporta 3 tipos de autenticação via construtores:
    - Basic: Username/Password em Base64 (Authorization: Basic)
    - Bearer: Token OAuth2/JWT (Authorization: Bearer)
    - Session: Cookie JSESSIONID (via RequestConfig)
    
    Headers padrão: Content-Type e Accept = application/json (se não fornecidos customizados).

.EXAMPLE
    # Basic Authentication
    $request = [Request]::new('https://api.exemplo.com', 'user', 'password')
    $users = $request.Get('/api/users')
    
.EXAMPLE
    # Bearer Token
    $request = [Request]::new('https://api.exemplo.com', 'eyJhbGciOiJIUzI1NiIs...')
    $data = $request.Get('/api/data')
    
.EXAMPLE
    # Session Cookie
    $config = [RequestConfig]::new('https://api.exemplo.com')
    $config.SessionId = 'ABC123DEF456'
    $request = [Request]::new($config)
    $response = $request.Get('/api/info')

.NOTES
    Author: Claudio Almeida
    Date: 2026-05-22
    Version: 2.0.0
    Changelog:
    - 2.0.0: Adicionados 3 construtores para autenticação (Basic, Bearer, Session)
    - 1.1.0: Adicionado parâmetro $CustomHeaders com padrão JSON
    - 1.0.0: Release inicial
#>

class Request {
    [RequestConfig] $Config
    [string] $Request
    [string] $Response

    # Construtor 1: Config completo (máximo controle)
    Request([RequestConfig] $Config) {
        if (-not $Config.IsValid()) {
            throw "Configuração inválida: $($Config.ToString())"
        }
        $this.Config = $Config
    }
    
    # Construtor 2: Basic Authentication (Username + Password)
    Request([string] $BaseUrl, [string] $Username, [string] $Password) {
        $this.Config = [RequestConfig]::new($BaseUrl, $Username, $Password)
    }
    
    # Construtor 3: Bearer Token Authentication
    Request([string] $BaseUrl, [string] $Token) {
        $this.Config = [RequestConfig]::new($BaseUrl, $Token)
    }

    # Método para obter headers padrão (incluindo autenticação)
    [hashtable] GetDefaultHeaders() {
        $headers = @{
            'User-Agent' = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
            'Accept-Language' = 'pt-BR,pt;q=0.9,en-US;q=0.8,en;q=0.7'
        }
        
        # Adicionar headers de autenticação baseado no tipo
        switch ($this.Config.AuthType) {
            'Basic' {
                if ($this.Config.Username -and $this.Config.Password) {
                    $credentials = "$($this.Config.Username):$($this.Config.Password)"
                    $bytes = [Text.Encoding]::ASCII.GetBytes($credentials)
                    $base64 = [Convert]::ToBase64String($bytes)
                    $headers['Authorization'] = "Basic $base64"
                }
            }
            'Bearer' {
                if ($this.Config.Token) {
                    $headers['Authorization'] = "Bearer $($this.Config.Token)"
                }
            }
            'Session' {
                # Session Cookie é adicionado via WebRequestSession no método Invoke
                # Não adicionar aqui como header simples (não funciona corretamente)
            }
        }
        
        # Adicionar headers adicionais
        foreach ($key in $this.Config.AdditionalHeaders.Keys) {
            $headers[$key] = $this.Config.AdditionalHeaders[$key]
        }
        
        return $headers
    }

    # Método principal de requisição HTTP
    [PSCustomObject] Invoke([HttpMethod] $Method, [string] $Endpoint, [hashtable] $CustomHeaders = $null, [object] $Body = $null) {
        $url = "$($this.Config.GetBaseUrl())$Endpoint"

        if ($Method -in [HttpMethod]::GET, [HttpMethod]::DELETE) {
            $this.Request = $url.Contains('?') ? $url.Split('?')[1] : $Body
        } else {
            $this.Request = $Body
        }
        
        # Obter headers base da configuração (incluindo autenticação)
        $headers = $this.GetDefaultHeaders()
        
        # Se headers customizados não fornecidos, usar padrão JSON
        if ($null -eq $CustomHeaders) {
            $CustomHeaders = @{
                'Content-Type' = 'application/json'
                'Accept' = 'application/json'
            }
        }
        
        # Mesclar headers customizados com headers base (customizados têm prioridade)
        foreach ($key in $CustomHeaders.Keys) {
            $headers[$key] = $CustomHeaders[$key]
        }
        
        $attempt = 0
        $maxAttempts = $this.Config.MaxRetries

        while ($attempt -lt $maxAttempts) {
            try {
                $attempt++
                
                Write-Verbose "[$Method] $url (Tentativa $attempt/$maxAttempts)"
                
                $params = @{
                    Uri = $url
                    Method = $Method.ToString()
                    Headers = $headers
                    TimeoutSec = $this.Config.TimeoutSeconds
                    ErrorAction = 'Stop'
                }
                
                # Se autenticação Session, criar WebRequestSession com cookie JSESSIONID
                if ($this.Config.AuthType -eq [AuthType]::Session) {
                    if ([string]::IsNullOrWhiteSpace($this.Config.SessionId)) {
                        throw "SessionId não configurado para autenticação Session"
                    }
                    
                    # Extrair domínio da URL se CookieDomain não foi especificado
                    $cookieDomain = $this.Config.CookieDomain
                    if ([string]::IsNullOrWhiteSpace($cookieDomain)) {
                        $uri = [System.Uri]$url
                        $cookieDomain = $uri.Host
                        Write-Verbose "CookieDomain não configurado, usando host da URL: $cookieDomain"
                    }
                    
                    # Criar WebRequestSession
                    $session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
                    
                    # Criar cookie JSESSIONID com propriedades corretas
                    $cookie = New-Object System.Net.Cookie
                    $cookie.Name = "JSESSIONID"
                    $cookie.Value = $this.Config.SessionId
                    $cookie.Domain = $cookieDomain
                    $cookie.Path = "/"
                    $cookie.Secure = $true
                    $cookie.HttpOnly = $true
                    
                    # Adicionar cookie à sessão
                    $session.Cookies.Add($cookie)
                    
                    # Usar WebSession no request
                    $params['WebSession'] = $session
                    
                    Write-Verbose "Session Cookie configurado: JSESSIONID=$($this.Config.SessionId.Substring(0, [Math]::Min(10, $this.Config.SessionId.Length)))... (Domain: $cookieDomain)"
                }

                if ($null -ne $Body) {
                    if ($Body -is [string]) {
                        $params['Body'] = $Body
                    } else {
                        $params['Body'] = ($Body | ConvertTo-Json -Depth 10 -Compress)
                    }
                }

                $webResponse = Invoke-WebRequest @params
                
                # Parse response
                if ($webResponse.Content) {
                    $this.Response = $webResponse.Content
                    try {
                        $jsonResult = $webResponse.Content | ConvertFrom-Json
                        
                        # Se JSON válido e não é vazio, retornar
                        if ($null -ne $jsonResult -and $jsonResult.PSObject.Properties.Count -gt 0) {
                            return $jsonResult
                        } else {
                            # JSON vazio ({}, []) - retornar objeto com Success
                            return [PSCustomObject]@{
                                StatusCode = $webResponse.StatusCode
                                Success    = $true
                                Content    = $webResponse.Content
                            }
                        }
                    } catch {
                        # Não é JSON - retornar conteúdo raw
                        return [PSCustomObject]@{
                            StatusCode  = $webResponse.StatusCode
                            Content     = $webResponse.Content
                            RawResponse = $webResponse
                        }
                    }
                }

                return [PSCustomObject]@{
                    StatusCode = $webResponse.StatusCode
                    Success    = $true
                }

            } catch [System.Net.WebException] {
                $statusCode = $_.Exception.Response.StatusCode.value__
                
                # Retry em erros temporários (408, 429, 5xx)
                if ($statusCode -in @(408, 429, 500, 502, 503, 504) -and $attempt -lt $maxAttempts) {
                    $waitSeconds = [Math]::Pow(2, $attempt)
                    Write-Warning "Erro HTTP $statusCode. Aguardando $waitSeconds segundos antes de retentar..."
                    Start-Sleep -Seconds $waitSeconds
                    continue
                }

                # Tratar erros específicos
                $errorMessage = switch ($statusCode) {
                    400 { 'Bad Request - Parâmetros inválidos' }
                    401 { 'Unauthorized - Token inválido ou expirado' }
                    403 { 'Forbidden - Sem permissão para acessar este recurso' }
                    404 { 'Not Found - Recurso não encontrado' }
                    429 { 'Too Many Requests - Rate limit excedido' }
                    500 { 'Internal Server Error - Erro no servidor' }
                    502 { 'Bad Gateway - Servidor indisponível' }
                    503 { 'Service Unavailable - Serviço temporariamente indisponível' }
                    504 { 'Gateway Timeout - Timeout no servidor' }
                    default { "Erro HTTP $statusCode" }
                }

                Write-Error "$errorMessage - $($_.Exception.Message)"
                throw

            } catch {
                Write-Error "Erro inesperado: $($_.Exception.Message)"
                throw
            }
        }

        throw "Falha após $maxAttempts tentativas"
    }

    # Atalhos para métodos HTTP comuns
    
    # GET - sem body
    [PSCustomObject] Get([string] $Endpoint) {
        return $this.Invoke([HttpMethod]::GET, $Endpoint, $null, $null)
    }
    
    [PSCustomObject] Get([string] $Endpoint, [hashtable] $CustomHeaders) {
        return $this.Invoke([HttpMethod]::GET, $Endpoint, $CustomHeaders, $null)
    }

    # POST - com body
    [PSCustomObject] Post([string] $Endpoint, [object] $Body) {
        return $this.Invoke([HttpMethod]::POST, $Endpoint, $null, $Body)
    }
    
    [PSCustomObject] Post([string] $Endpoint, [object] $Body, [hashtable] $CustomHeaders) {
        return $this.Invoke([HttpMethod]::POST, $Endpoint, $CustomHeaders, $Body)
    }

    # PUT - com body
    [PSCustomObject] Put([string] $Endpoint, [object] $Body) {
        return $this.Invoke([HttpMethod]::PUT, $Endpoint, $null, $Body)
    }
    
    [PSCustomObject] Put([string] $Endpoint, [object] $Body, [hashtable] $CustomHeaders) {
        return $this.Invoke([HttpMethod]::PUT, $Endpoint, $CustomHeaders, $Body)
    }

    # DELETE - sem body
    [PSCustomObject] Delete([string] $Endpoint) {
        return $this.Invoke([HttpMethod]::DELETE, $Endpoint, $null, $null)
    }
    
    [PSCustomObject] Delete([string] $Endpoint, [hashtable] $CustomHeaders) {
        return $this.Invoke([HttpMethod]::DELETE, $Endpoint, $CustomHeaders, $null)
    }

    # PATCH - com body
    [PSCustomObject] Patch([string] $Endpoint, [object] $Body) {
        return $this.Invoke([HttpMethod]::PATCH, $Endpoint, $null, $Body)
    }
    
    [PSCustomObject] Patch([string] $Endpoint, [object] $Body, [hashtable] $CustomHeaders) {
        return $this.Invoke([HttpMethod]::PATCH, $Endpoint, $CustomHeaders, $Body)
    }
}
