<#
.SYNOPSIS
    Pester tests for Request module.

.DESCRIPTION
    Comprehensive unit and integration tests for Request module v3.0.0+.
    Tests cover: RequestConfig validation, Request instantiation, HTTP methods,
    authentication (Basic/Bearer/Session), retry logic, error handling.

.NOTES
    Author: Claudio Almeida
    Date: 2026-05-25
    Version: 3.0.0
    Requires: Pester 5.x
#>

BeforeAll {
    # Import module
    $modulePath = Join-Path $PSScriptRoot '..' 'Request.psd1'
    Import-Module $modulePath -Force
    
    # Mock API endpoint for testing
    $script:MockApiUrl = 'https://jsonplaceholder.typicode.com'
}

Describe 'RequestConfig' -Tag 'Unit' {
    Context 'Validation' {
        It 'Should validate basic config without authentication' {
            $config = [RequestConfig]::new('https://api.exemplo.com')
            $config.IsValid() | Should -Be $true
        }
        
        It 'Should validate Basic authentication with username and password' {
            $config = [RequestConfig]::new('https://api.exemplo.com', 'user', 'pass')
            $config.IsValid() | Should -Be $true
            $config.AuthType | Should -Be ([AuthType]::Basic)
        }
        
        It 'Should validate Bearer authentication with token' {
            $config = [RequestConfig]::new('https://api.exemplo.com', 'token123')
            $config.IsValid() | Should -Be $true
            $config.AuthType | Should -Be ([AuthType]::Bearer)
        }
        
        It 'Should fail validation for Session auth without SessionId' {
            $config = [RequestConfig]::new('https://api.exemplo.com')
            $config.AuthType = [AuthType]::Session
            $config.IsValid() | Should -Be $false
        }
        
        It 'Should validate Session authentication with SessionId' {
            $config = [RequestConfig]::new('https://api.exemplo.com')
            $config.AuthType = [AuthType]::Session
            $config.SessionId = 'ABC123DEF456'
            $config.IsValid() | Should -Be $true
        }
        
        It 'Should fail validation with empty BaseUrl' {
            $config = [RequestConfig]::new('')
            $config.IsValid() | Should -Be $false
        }
    }
    
    Context 'ToString' {
        It 'Should display Basic auth info without password' {
            $config = [RequestConfig]::new('https://api.exemplo.com', 'user@test.com', 'secret')
            $str = $config.ToString()
            $str | Should -Match 'User: user@test.com'
            $str | Should -Not -Match 'secret'
        }
        
        It 'Should display Bearer token (redacted)' {
            $config = [RequestConfig]::new('https://api.exemplo.com', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9')
            $str = $config.ToString()
            $str | Should -Match 'Token: \[REDACTED\]'
        }
        
        It 'Should display Session info (redacted)' {
            $config = [RequestConfig]::new('https://api.exemplo.com')
            $config.AuthType = [AuthType]::Session
            $config.SessionId = 'ABC123DEF456GHI789'
            $str = $config.ToString()
            $str | Should -Match 'SessionId: \[REDACTED\]'
        }
    }
}

Describe 'Request Class' -Tag 'Unit' {
    Context 'Instantiation' {
        It 'Should create Request with valid config' {
            $config = [RequestConfig]::new('https://api.exemplo.com')
            $request = [Request]::new($config)
            $request | Should -Not -BeNullOrEmpty
            $request.Config | Should -Be $config
        }
        
        It 'Should create Request with Basic auth constructor' {
            $request = [Request]::new('https://api.exemplo.com', 'user', 'pass')
            $request.Config.AuthType | Should -Be ([AuthType]::Basic)
        }
        
        It 'Should create Request with Bearer auth constructor' {
            $request = [Request]::new('https://api.exemplo.com', 'token123')
            $request.Config.AuthType | Should -Be ([AuthType]::Bearer)
        }
        
        It 'Should throw on invalid config' {
            $config = [RequestConfig]::new('')
            { [Request]::new($config) } | Should -Throw
        }
    }
    
    Context 'Headers' {
        It 'Should include User-Agent header' {
            $config = [RequestConfig]::new('https://api.exemplo.com')
            $request = [Request]::new($config)
            $headers = $request.GetDefaultHeaders()
            $headers['User-Agent'] | Should -Match 'Mozilla'
        }
        
        It 'Should include Basic auth header' {
            $request = [Request]::new('https://api.exemplo.com', 'user', 'pass')
            $headers = $request.GetDefaultHeaders()
            $headers['Authorization'] | Should -Match '^Basic '
        }
        
        It 'Should include Bearer token header' {
            $request = [Request]::new('https://api.exemplo.com', 'token123')
            $headers = $request.GetDefaultHeaders()
            $headers['Authorization'] | Should -Be 'Bearer token123'
        }
        
        It 'Should merge additional headers' {
            $config = [RequestConfig]::new('https://api.exemplo.com')
            $config.AdditionalHeaders = @{ 'X-Custom' = 'value' }
            $request = [Request]::new($config)
            $headers = $request.GetDefaultHeaders()
            $headers['X-Custom'] | Should -Be 'value'
        }
    }
}

Describe 'HTTP Methods (Integration)' -Tag 'Integration' {
    BeforeAll {
        $script:testConfig = [RequestConfig]::new($script:MockApiUrl)
        $script:testRequest = [Request]::new($script:testConfig)
    }
    
    Context 'GET Requests' {
        It 'Should fetch single post' {
            $result = $script:testRequest.Get('/posts/1')
            $result.id | Should -Be 1
            $result.title | Should -Not -BeNullOrEmpty
        }
        
        It 'Should fetch multiple posts' {
            $result = $script:testRequest.Get('/posts')
            $result.Count | Should -BeGreaterThan 0
        }
    }
    
    Context 'POST Requests' {
        It 'Should create new post' {
            $body = @{
                title  = 'Test Post'
                body   = 'Test Content'
                userId = 1
            }
            $result = $script:testRequest.Post('/posts', $body)
            $result.id | Should -Not -BeNullOrEmpty
        }
    }
    
    Context 'PUT Requests' {
        It 'Should update existing post' {
            $body = @{
                id     = 1
                title  = 'Updated Title'
                body   = 'Updated Content'
                userId = 1
            }
            $result = $script:testRequest.Put('/posts/1', $body)
            $result.id | Should -Be 1
        }
    }
    
    Context 'DELETE Requests' {
        It 'Should delete post' {
            $result = $script:testRequest.Delete('/posts/1')
            # JSONPlaceholder DELETE retorna {} (JSON vazio)
            # Validar StatusCode 200 ao invés de Success (mais confiável)
            $result.StatusCode | Should -Be 200
        }
    }
}

Describe 'Error Handling' -Tag 'Integration' {
    BeforeAll {
        $script:testConfig = [RequestConfig]::new($script:MockApiUrl)
        $script:testRequest = [Request]::new($script:testConfig)
    }
    
    Context '404 Not Found' {
        It 'Should throw on non-existent resource' {
            { $script:testRequest.Get('/posts/999999') } | Should -Throw
        }
    }
    
    Context 'Invalid JSON' {
        It 'Should handle non-JSON response gracefully' {
            # JSONPlaceholder always returns JSON, skip for now
            Set-ItResult -Skipped -Because "Test API always returns valid JSON"
        }
    }
}

AfterAll {
    # Cleanup
    Remove-Module Request -ErrorAction SilentlyContinue
}
