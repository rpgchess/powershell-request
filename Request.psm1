<#
.SYNOPSIS
    Módulo Request - Cliente HTTP genérico com retry logic.

.DESCRIPTION
    Fornece classe base Request para implementação de clientes HTTP robustos.
    
    Recursos:
    - Retry automático para erros temporários (5xx, 429)
    - Backoff exponencial
    - Tratamento de erros HTTP específico
    - Suporte a JSON serialization/deserialization
    - Métodos convenientes (Get, Post, Put, Delete, Patch)
    
    A classe Request pode ser usada standalone ou como classe base para herança.

.EXAMPLE
    # Uso direto
    using module '.\Request.psd1'
    
    $config = [PSCustomObject]@{
        BaseUrl = 'https://api.exemplo.com'
        TimeoutSeconds = 30
        MaxRetries = 3
    }
    $config | Add-Member -MemberType ScriptMethod -Name GetBaseUrl -Value { return $this.BaseUrl }
    $config | Add-Member -MemberType ScriptMethod -Name GetDefaultHeaders -Value { 
        return @{ 'Authorization' = 'Bearer token' }
    }
    
    $request = [Request]::new($config)
    $users = $request.Get('/users')

.EXAMPLE
    # Herança em classe de serviço
    class MyApiService : Request {
        MyApiService([object] $Config) : base($Config) { }
        
        [PSCustomObject] GetUsers() {
            return $this.Get('/api/users')
        }
        
        [PSCustomObject] CreateUser([hashtable] $UserData) {
            return $this.Post('/api/users', $UserData)
        }
    }

.NOTES
    Author: Claudio Almeida
    Date: 2026-05-22
    Version: 1.0.0
    
    Dependências:
    - Nenhuma (módulo standalone)
    - Opcional: Enum HttpMethod para tipagem forte
#>

# Classe Request carregada via ScriptsToProcess no manifesto .psd1

# Exportar tudo
Export-ModuleMember -Function * -Variable * -Alias * -Cmdlet *
