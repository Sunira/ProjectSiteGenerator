function new-M365Site {
    
    #Retrieve the top level site from the user.
    $tenantURL = Read-Host "Please Provide the Tenant/Admin Site URL"

    #Retrieve the site url the user wants to provision
    $url = Read-Host "Please enter the SPO URL for the site being created"

     #Retrieve the site title from User
    $title = Read-Host "Please enter the title of the new site"

    $owner = Read-Host "Please enter the site owner e-mail for this new site"

    # Connect to M365
    try {
        Connect-SPOService -Url $tenantURL
        write-host "Connected succesfully to M365!" -foregroundcolor green
    }
    catch {
        write-host "Failed to connect to M365." -foregroundcolor red
        Break new-M365Site
    }
    
    #Does the site already exist in SPO?
    $siteExists = get-SPOSite | Where-Object { $_.url -eq $url }
    
    #Or does the site exist in the Trash? 
    $isSiteInRBin = get-SPODeletedSite | Where-Object { $_.url -eq $url }
    
    #If it doesn't already exist in those two places, create the site. 

    write-host "Attempting to create site: $($title)" -foregroundcolor green
    if (($null -eq $siteExists) -and ( $null -eq $isSiteInRBin)) {
        New-SPOSite -Url $url -Owner $owner -StorageQuota 1000 -Title $title
        write-host "$($teamSiteUrl) created!" -foregroundcolor green
    }
    elseif ($siteExists -eq $true) {
        write-host "info: $($url) already exists" -foregroundcolor red
    }
    else {
        write-host "info: $($url) still exists in the Recycling Bin" -foregroundcolor red
    }
}

new-M365Site