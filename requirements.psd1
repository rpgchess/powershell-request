@{
    # PSResourceGet requirements file for Request module
    # Install dependencies: Install-PSResource -RequiredResourceFile requirements.psd1
    
    # IMPORTANTE: Request module requer Logger module (não disponível no PSGallery)
    # Instalar manualmente: Import-Module '..\powershell-logger\Logger.psd1'
    
    # Core dependencies for development and testing
    PSDependencies = @{
        # Testing framework
        'Pester' = @{
            Version = '[5.0.0,6.0.0)'
            Repository = 'PSGallery'
            Target = 'CurrentUser'
        }
        
        # Code quality and analysis
        'PSScriptAnalyzer' = @{
            Version = '[1.21.0,2.0.0)'
            Repository = 'PSGallery'
            Target = 'CurrentUser'
        }
        
        # Optional: PowerShell YAML support (for config files)
        'powershell-yaml' = @{
            Version = '[0.4.0,1.0.0)'
            Repository = 'PSGallery'
            Target = 'CurrentUser'
            Optional = $true
        }
        
        # Optional: Plaster for template scaffolding
        'Plaster' = @{
            Version = '[1.1.3,2.0.0)'
            Repository = 'PSGallery'
            Target = 'CurrentUser'
            Optional = $true
        }
    }
}
