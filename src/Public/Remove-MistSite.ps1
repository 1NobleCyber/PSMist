function Remove-MistSite {
    <#
    .SYNOPSIS
        Deletes a site from Mist.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$SiteId
    )

    Invoke-MistRequest -Uri "/api/v1/sites/$SiteId" -Method DELETE
}
