function new-M365Site {
    
    #Retrieve the top level site from the user.
    $tenantURL = Read-Host "Please Provide the Tenant/Admin Site URL:"

    #Get Admin Email to Run Script
    $username = Read-Host "User E-mail to run script with:"
    
    #Store Credentials for Use
    $cred = Get-Credential -UserName $username -Message "You will now be asked for Password."

    # Connect to M365
    try {
        Connect-PnPOnline $tenantURL -Credentials $cred 
        write-host "Connected succesfully to M365!" -foregroundcolor green
    }
    catch {
        write-host "Failed to connect to M365." -foregroundcolor red
        Break new-M365Site
    }

    #Retrieve the site title from User
    $title = Read-Host "Please enter the title of the new site"

    #Retrieve the site title from User
    $desc = Read-Host "Please enter the site description of the new site"

    #Retrieve the site alias ( site.sharepoint.com/sites/*alias* ) from User
    $alias = Read-Host "Please enter the site alias of the new site. example: ...com/sites/your-alias"

    #Try to Create New Project Site!
    try {        
        write-host "Attempting to create site: $($title)" -foregroundcolor green
        $teamSiteUrl = New-PnPSite -Type TeamSite -Title $title -Description $desc -Alias $alias -ErrorAction Stop
        write-host "Successfully Created: $($teamSiteUrl) ! " -foregroundcolor green
    }
    catch {
        write-host "Failed to create new site: $($Title)." -foregroundcolor red
        $errorMessage = $_.ErrorDetails.Message
        write-host "Error: $($errorMessage)" -foregroundcolor red
        Break new-M365Site
    }
    
    # Since we are connecting now to SP side, credentials will be asked
    try {        
        Connect-PnPOnline $teamSiteUrl -Credentials $cred 
    } catch {
        write-host "Failed to connect to new site: $($Title)." -foregroundcolor red
        Break new-M365Site
    }

    #Check for Risk Content Type
    $riskCT = Get-PnPContentType -Identity "Risk"
    
    #If Content Type Doesn't Exist, Create it
    if ( $null -eq $riskCT ) {
        try {
            Write-Host "Didn't detect Risk content type. Attempting to create..."
            Add-PnPContentType -Name "Risk" -Description "Used for tracking risk in Project Sites" -Group "Custom Content Types"
            Write-Host "Created new Risk Content Type." -foregroundcolor green
        }
        catch {
            Write-Host "Unable to provision Risk Content Type to add to Sites."
            Break new-M365Site
        }

        $riskCT = Get-PnPContentType -Identity "Risk"

        #Risk Content Type - Add Columns Condition, Consequence, Mitigation
        if ( $null -ne $riskCT ) {

            Write-Host "Risk Content Type Exists Now!" -foregroundcolor yellow

            try {
                Write-Host "Trying to add fields." -foregroundcolor yellow
                
                
                # Check for Condition Field, Create if it doesn't exist
                try { 
                    $conditionField = Get-PnPField -Identity "Condition" -ErrorAction SilientlyContinue
                } catch {
                    Write-Host "No Condition field found." -foregroundcolor yellow
                }

                if ( $null -eq $conditionField ) {
                    Write-Host "Attempting to create condition field." -foregroundcolor yellow
                    Add-PnPField -Type Text -InternalName "Condition" -DisplayName "Condition" -AddToDefaultView ; 
                    Write-Host "Condition Field created" -foregroundcolor green
                } else {
                    Write-Host "Condition Field already exists." -foregroundcolor yellow
                }


                 # Check for Consequence Field, Create if it doesn't exist
                try { 
                    $consequenceField = Get-PnPField -Identity "Consequence" -ErrorAction SilientlyContinue
                } catch {
                    Write-Host "No Consequence field found." -foregroundcolor yellow
                }
            
                if ( $null -eq $consequenceField ) {
                    Write-Host "No Consequence field found, attempting to create." -foregroundcolor yellow
                    Add-PnPField -Type Text -InternalName "Consequence" -DisplayName "Consequence" -AddToDefaultView;
                    Write-Host "Consequence Field created" -foregroundcolor green
                }
                else {
                    Write-Host "Consequence Field already exists." -foregroundcolor yellow
                }


                # Check for Mitigation Field, Create if it doesn't exist
                try { 
                    $mitigationField = Get-PnPField -Identity "Mitigation" -ErrorAction SilientlyContinue
                } catch {
                    Write-Host "No Mitigation field found." -foregroundcolor yellow
                }
            
                if ( $null -eq $mitigationField ) {
                    Write-Host "No Mitigation field found, attempting to create." -foregroundcolor yellow
                    Add-PnPField -Type Text -InternalName "Mitigation" -DisplayName "Mitigation" -AddToDefaultView;
                    Write-Host "Mitigation Field created" -foregroundcolor green
                } else {
                    Write-Host "Mitigation Field already exists." -foregroundcolor yellow
                }
            }

            catch {
                Write-Host "Unable to create Condition, Consequence, or Mitigation fields. Check errors." -foregroundcolor yellow
            }

            # Risk Content Type Management
            try {
                Write-Host "Attempting to add fields to Risk Content Type." -foregroundcolor yellow
                Add-PnPFieldToContentType -Field "Condition" -ContentType "Risk" 
                Add-PnPFieldToContentType -Field "Consequence" -ContentType "Risk" 
                Add-PnPFieldToContentType -Field "Mitigation" -ContentType "Risk" 
            }
            catch {
                Write-Host "Unable to add new fields to content type." -foregroundcolor yellow
            }
        }

        # Risk List Management
        try {
            Write-Host "Checking for Risk List..." -foregroundcolor yellow
            $riskList = Get-PnPList -Identity "Risk"
            if ( $null -eq $riskList) {
                Write-Host "No Risk list detected. Attempting to create Risk List." -foregroundcolor yellow
                $riskList = New-PnPList -Title "Risk" -Url "lists/Risk" -Template GenericList
                Write-Host "Risk List Created!" -foregroundcolor green
                
                Write-Host "Enabling Content Type Management on Risk List..." -foregroundcolor yellow
                Set-PnPList -Identity "Risk" -EnableContentTypes $true
                Write-Host "Content type management enabled!" -foregroundcolor green

            }
            else {
                Write-Host "Risk List already exists, no need to create." -foregroundcolor yellow
            }
        }
        catch {
            Write-Host "Unable to add Risk List to Site." -foregroundcolor yellow
        }

        #Apply Risk Content Type to newly created Risk List
        try {
            Write-Host "Applying Risk Content type to Risk List..." -foregroundcolor yellow
            Add-PnPContentTypeToList -List "Risk" -ContentType "Risk" -DefaultContentType
            Write-Host "Risk Content Type Applied!" -foregroundcolor green
        }
        catch {
            Write-Host "Unable to apply content type Risk to Project Risk." -foregroundcolor yellow
        }

        #Make Risk Content Type Fields Visible on Default List View
        try {
            Write-Host "Making Risk List Columns Visible" -foregroundcolor yellow
            $view = Set-PnPView -List "Risk" -Identity "All Items" -Fields "ID", "Title", "Condition", "Consequence", "Mitigation"
            Write-Host "Column Visibility Applied!" -foregroundcolor green
        }
        catch {
            Write-Host "Unable to show columns on default view." -foregroundcolor yellow
        }
    
    }

    Write-Host "SUCCESS! Site creation script complete for $($teamSiteUrl)" -foregroundcolor green

}

new-M365Site