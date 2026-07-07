function New-MistSite {
    <#
    .SYNOPSIS
        Creates a new site within a specified Mist organization.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$OrgId,

        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $false)]
        [string]$Timezone = "UTC",
        
        [Parameter(Mandatory = $false)]
        [string]$CountryCode
    )

    $Body = @{
        name = $Name
        timezone = $Timezone
    }
    
    if ($CountryCode) {
        $Body['country_code'] = $CountryCode
    }

    Invoke-MistRequest -Uri "/api/v1/orgs/$OrgId/sites" -Method POST -Body $Body
}
