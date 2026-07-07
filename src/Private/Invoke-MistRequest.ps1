function Invoke-MistRequest {
    <#
    .SYNOPSIS
        Internal helper to execute Mist API calls.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Uri,

        [ValidateSet('GET', 'POST', 'PUT', 'DELETE', 'PATCH')]
        [string]$Method = 'GET',

        [object]$Body,
        [hashtable]$Headers = @{}
    )

    $BaseUrl = "https://api.mist.com"
    $CleanUri = $Uri.TrimStart('/')
    $FullUri = "$BaseUrl/$CleanUri"

    # Build Headers
    $ReqHeaders = @{
        "User-Agent"   = "PSMist"
        "Content-Type" = "application/json"
    }

    # Inject Cookies if available
    if ($Global:MistSession.Cookies) {
        $ReqHeaders['Cookie'] = $Global:MistSession.Cookies
    }
    
    # Inject CSRF Token if available
    if ($Global:MistSession.CsrfToken) {
        $ReqHeaders['X-CSRFToken'] = $Global:MistSession.CsrfToken
    }

    # Inject Authorization header if using API Token instead of session
    if ($Global:MistSession.ApiToken) {
        $ReqHeaders['Authorization'] = "Token $($Global:MistSession.ApiToken)"
    }

    # Add any extra headers passed (overwriting defaults if necessary)
    foreach ($Key in $Headers.Keys) {
        $ReqHeaders[$Key] = $Headers[$Key]
    }

    if ($PSCmdlet.SessionState.PSVariable.GetValue('VerbosePreference') -ne 'SilentlyContinue') {
        Write-Verbose "--- [REQUEST] $Method $FullUri ---"
        Write-Verbose "Headers: $($ReqHeaders | ConvertTo-Json -Compress)"
        if ($Body) { 
            Write-Verbose "Body: $( $Body | ConvertTo-Json -Depth 5 -Compress )" 
        }
    }

    $Params = @{
        Uri         = $FullUri
        Method      = $Method
        Headers     = $ReqHeaders
        ContentType = "application/json"
    }

    if ($Body) {
        $Params.Body = ($Body | ConvertTo-Json -Depth 10 -Compress)
    }

    try {
        $Response = Invoke-RestMethod @Params
        
        if ($PSCmdlet.SessionState.PSVariable.GetValue('VerbosePreference') -ne 'SilentlyContinue') {
            Write-Verbose "--- [RESPONSE] ---"
            Write-Verbose ($Response | ConvertTo-Json -Depth 5)
        }

        return $Response
    }
    catch {
        Write-Error "API Call Failed: $_"
        if ($PSCmdlet.SessionState.PSVariable.GetValue('VerbosePreference') -ne 'SilentlyContinue') {
            try {
                if ($_.Exception.Response -and $_.Exception.Response.Content) {
                    $Reader = [System.IO.StreamReader]::new($_.Exception.Response.GetResponseStream())
                    Write-Verbose "--- [ERROR BODY] ---"
                    Write-Verbose $Reader.ReadToEnd()
                }
            } catch {}
        }
        throw $_
    }
}
