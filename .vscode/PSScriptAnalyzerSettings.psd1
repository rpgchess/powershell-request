@{
    # PSScriptAnalyzer settings for Request module
    
    # Severity levels: Error, Warning, Information
    Severity = @('Error', 'Warning')
    
    # Include default rules
    IncludeDefaultRules = $true
    
    # Exclude specific rules
    ExcludeRules = @(
        'PSAvoidUsingWriteHost',  # Permitir Write-Host em scripts de exemplo/teste
        'PSUseShouldProcessForStateChangingFunctions',  # Não aplicável para classes HTTP
        'PSAvoidUsingUsernameAndPasswordParams',  # Construtores HTTP Basic Auth (não credenciais sistema)
        'PSAvoidUsingPlainTextForPassword',  # HTTP Basic Auth requer plaintext (encripta depois)
        'PSUseBOMForUnicodeEncodedFile',  # BOM não obrigatório
        'PSAlignAssignmentStatement'  # Alinhamento estético (opcional)
    )
    
    # Rules to enforce
    Rules = @{
        PSUseApprovedVerbs = @{
            Enable = $true
        }
        PSAvoidUsingCmdletAliases = @{
            Enable = $true
        }
        PSAvoidUsingPlainTextForPassword = @{
            Enable = $true
        }
        PSUseDeclaredVarsMoreThanAssignments = @{
            Enable = $true
        }
        PSProvideCommentHelp = @{
            Enable = $true
            ExportedOnly = $true
            BlockComment = $true
            VSCodeSnippetCorrection = $true
            Placement = 'before'
        }
        PSUseConsistentIndentation = @{
            Enable = $true
            IndentationSize = 4
            PipelineIndentation = 'IncreaseIndentationForFirstPipeline'
            Kind = 'space'
        }
        PSUseConsistentWhitespace = @{
            Enable = $true
            CheckInnerBrace = $true
            CheckOpenBrace = $true
            CheckOpenParen = $true
            CheckOperator = $true
            CheckPipe = $true
            CheckPipeForRedundantWhitespace = $true
            CheckSeparator = $true
            CheckParameter = $false
        }
        PSAlignAssignmentStatement = @{
            Enable = $true
            CheckHashtable = $true
        }
        PSUseCorrectCasing = @{
            Enable = $true
        }
    }
}
