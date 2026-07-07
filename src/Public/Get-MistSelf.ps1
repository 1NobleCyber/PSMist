function Get-MistSelf {
    <#
    .SYNOPSIS
        Gets the current user's Mist account details.
    #>
    [CmdletBinding()]
    param()

    Invoke-MistRequest -Uri "/api/v1/self" -Method GET
}
