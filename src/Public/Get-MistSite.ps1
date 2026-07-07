function Get-MistSite {
    <#
    .SYNOPSIS
        Gets the sites within a specified Mist organization.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$OrgId
    )

    Invoke-MistRequest -Uri "/api/v1/orgs/$OrgId/sites" -Method GET
}
