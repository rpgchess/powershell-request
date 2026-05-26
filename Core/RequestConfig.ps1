<#
.SYNOPSIS
    Classe de configuração para requisições HTTP.

.DESCRIPTION
    Encapsula configurações de conexão, autenticação e comportamento de retry.
    Suporta 4 tipos de autenticação:
    - None: Sem autenticação
    - Basic: Username/Password (Basic Authentication)
    - Bearer: Token (Bearer Authentication)
    - Session: JSESSIONID (Cookie Authentication)

.EXAMPLE
    # Basic Authentication
    $config = [RequestConfig]::new('https://api.exemplo.com', 'user', 'pass')
    
.EXAMPLE
    # Bearer Token
    $config = [RequestConfig]::new('https://api.exemplo.com', 'eyJhbGci...')
    
.EXAMPLE
    # Session Cookie
    $config = [RequestConfig]::new('https://api.exemplo.com')
    $config.SessionId = 'ABC123DEF456'

.NOTES
    Author: Claudio Almeida
    Date: 2026-05-22
    Version: 2.0.0
#>

class RequestConfig {
    # Configuração básica
    [string] $BaseUrl
    [int] $TimeoutSeconds = 30
    [int] $MaxRetries = 3
    
    # Autenticação
    [AuthType] $AuthType = [AuthType]::None
    [string] $Username
    hidden [string] $Password
    hidden [string] $Token
    hidden [string] $SessionId
    [string] $CookieDomain  # Domínio do cookie (ex: jira.linx.com.br)
    
    # Headers adicionais (não relacionados a autenticação)
    [hashtable] $AdditionalHeaders = @{}
    
    # Construtor 1: Configuração básica (sem autenticação)
    RequestConfig([string] $BaseUrl) {
        $this.BaseUrl = $BaseUrl
        $this.AuthType = [AuthType]::None
    }
    
    # Construtor 2: Basic Authentication
    RequestConfig([string] $BaseUrl, [string] $Username, [string] $Password) {
        $this.BaseUrl = $BaseUrl
        $this.Username = $Username
        $this.Password = $Password
        $this.AuthType = [AuthType]::Basic
    }
    
    # Construtor 3: Bearer Token
    RequestConfig([string] $BaseUrl, [string] $Token) {
        $this.BaseUrl = $BaseUrl
        $this.Token = $Token
        $this.AuthType = [AuthType]::Bearer
    }
    
    # Método para obter URL base
    [string] GetBaseUrl() {
        return $this.BaseUrl
    }
    
    # Método para validar configuração
    [bool] IsValid() {
        if ([string]::IsNullOrWhiteSpace($this.BaseUrl)) {
            return $false
        }
        
        switch ($this.AuthType) {
            'Basic' {
                return (-not [string]::IsNullOrWhiteSpace($this.Username)) -and 
                       (-not [string]::IsNullOrWhiteSpace($this.Password))
            }
            'Bearer' {
                return -not [string]::IsNullOrWhiteSpace($this.Token)
            }
            'Session' {
                return -not [string]::IsNullOrWhiteSpace($this.SessionId)
            }
            'None' {
                return $true
            }
        }
        
        return $false
    }
    
    # Método para obter descrição da configuração (para debug)
    [string] ToString() {
        $authInfo = switch ($this.AuthType) {
            'Basic' { "User: $($this.Username)" }
            'Bearer' { "Token: $($this.Token.Substring(0, [Math]::Min(10, $this.Token.Length)))..." }
            'Session' { "Session: $($this.SessionId.Substring(0, [Math]::Min(10, $this.SessionId.Length)))..." }
            'None' { "No Auth" }
        }
        
        return "RequestConfig { BaseUrl: $($this.BaseUrl), AuthType: $($this.AuthType), $authInfo }"
    }
}
