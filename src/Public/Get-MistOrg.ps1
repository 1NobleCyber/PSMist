function Get-MistOrg {
    <#
    .SYNOPSIS
        Gets the organizations that the current Mist user has access to.
    #>
    [CmdletBinding()]
    param()

    Invoke-MistRequest -Uri "/api/v1/self/orgs" -Method GET
}
