function new-M365Site {
    
    #Retrieve the top level site from the user.
    $tenantURL = Read-Host "Please Provide the Tenant/Admin Site URL:"

    #Retrieve the site title from User
    $title = Read-Host "Please enter the title of the new site"

    #Retrieve the site title from User
    $desc = Read-Host "Please enter the site description of the new site"

    #Retrieve the site alias ( site.sharepoint.com/sites/*alias* ) from User
    $alias = Read-Host "Please enter the site alias of the new site. example: ...com/sites/your-alias"

    #Connect to M365
    try {
        Connect-PnPOnline $tenantURL
        #Connect-SPOService -Url $tenantURL -Credential $credentials
        write-host "Connected succesfully to M365!" -foregroundcolor green
    }
    catch {
        write-host "Failed to connect to M365." -foregroundcolor red
        Break new-M365Site
    }

    #Try to create new TeamSite(with O365 Group)
    try {        
        write-host "Attempting to create site: $($title)" -foregroundcolor green
        $teamSiteUrl = New-PnPSite -Type TeamSite -Title $title -Description $desc -Alias $alias
        write-host "Successfully Created: $($teamSiteUrl)! " -foregroundcolor green
    }
    catch {
        write-host "Failed to create new site: $($Title)." -foregroundcolor red
        Break new-M365Site
    }   
}

new-M365Site