function Connect-Mist {
    <#
    .SYNOPSIS
        Connects to the Juniper Mist Cloud API and captures Session/CSRF tokens.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [PSCredential]$Credential,

        [Parameter(Mandatory = $false)]
        [string]$TOTP,

        [Parameter(Mandatory = $false)]
        [switch]$NoWelcome
    )

    process {
        $BaseUrl = "https://api.mist.com"
        $LoginUri = "$BaseUrl/api/v1/login"
        
        $Email = $Credential.UserName
        $Password = $Credential.GetNetworkCredential().Password

        $Body = @{
            email = $Email
            password = $Password
        }
        if (-not [string]::IsNullOrWhiteSpace($TOTP)) {
            $Body['two_factor'] = $TOTP
        }
        $BodyJson = $Body | ConvertTo-Json -Compress

        if ($PSCmdlet.SessionState.PSVariable.GetValue('VerbosePreference') -ne 'SilentlyContinue') {
            Write-Verbose "--- [STEP 1: LOGIN] ---"
            Write-Verbose "POST $LoginUri"
        }

        try {
            $WebResponse = Invoke-WebRequest -Uri $LoginUri `
                -Method POST `
                -Headers @{ 
                    "User-Agent" = "PSMist"
                    "Accept"     = "application/json"
                    "Content-Type" = "application/json"
                } `
                -Body $BodyJson `
                -SkipHttpErrorCheck
        }
        catch {
            throw "Network Connection Failed: $($_.Exception.Message)"
        }

        # --- PARSE COOKIES AND CSRF ---
        function Parse-Cookies {
            param($Resp)
            $CookieString = ""
            $CsrfToken = $null
            
            if ($Resp.Headers['Set-Cookie']) {
                $CookieArray = $Resp.Headers['Set-Cookie']
                if ($CookieArray -is [string]) { $CookieArray = @($CookieArray) }
                
                $CookieString = ($CookieArray -join '; ')
                foreach ($Cookie in $CookieArray) {
                    if ($Cookie -match 'csrftoken=([^;]+)') {
                        $CsrfToken = $matches[1]
                    }
                }
            }
            return @{ CookieString = $CookieString; CsrfToken = $CsrfToken }
        }

        $Parsed = Parse-Cookies -Resp $WebResponse

        $Global:MistSession = @{
            Cookies   = $Parsed.CookieString
            CsrfToken = $Parsed.CsrfToken
        }

        # --- ERROR HANDLING & MFA CHECK ---
        if ($WebResponse.StatusCode -ge 400 -and $WebResponse.StatusCode -ne 401) {
            throw "Login failed (Status $($WebResponse.StatusCode)): $($WebResponse.Content)"
        }

        # Check if 2FA is required. Mist may return 200 OK with a body indicating 2FA, or 401 Unauthorized etc.
        # Alternatively, if we get back a 2FA response, we must perform the two_factor POST.
        $ContentObj = $WebResponse.Content | ConvertFrom-Json
        $RequiresTwoFactor = ($ContentObj -and $ContentObj.two_factor_required -eq $true) -or ($WebResponse.Content -match "two_factor") -or ($WebResponse.StatusCode -eq 401 -and $WebResponse.Content -match "two_factor")

        if ($RequiresTwoFactor) {
            if ([string]::IsNullOrWhiteSpace($TOTP)) {
                throw "Login Failed: Two-Factor Authentication is required. Please run Connect-Mist with -TOTP."
            }

            Write-Verbose "--- [STEP 2: 2FA] ---"
            $TwoFactorUri = "$BaseUrl/api/v1/login/two_factor"
            $TwoFactorBody = @{
                two_factor = $TOTP
            } | ConvertTo-Json -Compress

            $ReqHeaders = @{ 
                "User-Agent" = "PSMist"
                "Accept"     = "application/json"
                "Content-Type" = "application/json"
            }
            if ($Global:MistSession.Cookies) { $ReqHeaders['Cookie'] = $Global:MistSession.Cookies }
            if ($Global:MistSession.CsrfToken) { $ReqHeaders['X-CSRFToken'] = $Global:MistSession.CsrfToken }

            try {
                $TfResponse = Invoke-WebRequest -Uri $TwoFactorUri `
                    -Method POST `
                    -Headers $ReqHeaders `
                    -Body $TwoFactorBody `
                    -SkipHttpErrorCheck

                if ($TfResponse.StatusCode -ge 400) {
                    throw "2FA Login failed (Status $($TfResponse.StatusCode)): $($TfResponse.Content)"
                }

                # Update cookies with the newly authenticated session
                $ParsedTf = Parse-Cookies -Resp $TfResponse
                if ($ParsedTf.CookieString) { $Global:MistSession.Cookies = $ParsedTf.CookieString }
                if ($ParsedTf.CsrfToken) { $Global:MistSession.CsrfToken = $ParsedTf.CsrfToken }

            } catch {
                throw "2FA Connection Failed: $($_.Exception.Message)"
            }
        }

        if (-not $NoWelcome) {
            Write-Host "Connected to Juniper Mist Cloud API!" -ForegroundColor Green
        }
    }
}
