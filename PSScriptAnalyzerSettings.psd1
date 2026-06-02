@{
    IncludeRules = @(
        'PSAvoidUsingCmdletAliases',
        'PSAvoidUsingEmptyCatchBlock',
        'PSUseDeclaredVarsMoreThanAssignments',
        'PSAvoidUsingPositionalParameters',
        'PSUseSingularNouns',
        'PSAvoidUsingPlainTextForPassword',
        'PSUseApprovedVerbs'
    )
    Rules = @{
        PSAvoidUsingCmdletAliases = @{ Enable = $true }
        PSAvoidUsingWriteHost = @{ Enable = $false }
        PSAvoidUsingPositionalParameters = @{ Enable = $true }
        PSUseDeclaredVarsMoreThanAssignments = @{ Enable = $true }
    }
}
