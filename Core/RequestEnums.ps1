<#
.SYNOPSIS
    Enumeradores para o módulo Request.

.DESCRIPTION
    Define os enumeradores utilizados no módulo Request.
#>

enum HttpMethod {
    GET
    POST
    PUT
    DELETE
    PATCH
}

enum AuthType {
    None      # Sem autenticação
    Basic     # Basic Authentication (username:password em base64)
    Bearer    # Bearer Token (OAuth2, JWT)
    Session   # Session Cookie (JSESSIONID)
}
