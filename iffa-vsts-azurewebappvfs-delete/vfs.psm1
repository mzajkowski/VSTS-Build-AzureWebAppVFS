
function Get-AzureRmWebAppPublishingCredentials($resourceGroupName, $webAppName, $slotName = $null){
	if ([string]::IsNullOrWhiteSpace($slotName)){
		$resourceType = "Microsoft.Web/sites/config"
		$resourceName = "$webAppName/publishingcredentials"
	}
	else{
		$resourceType = "Microsoft.Web/sites/slots/config"
		$resourceName = "$webAppName/$slotName/publishingcredentials"
	}
	$publishingCredentials = Invoke-AzureRmResourceAction -ResourceGroupName $resourceGroupName -ResourceType $resourceType -ResourceName $resourceName -Action list -ApiVersion 2015-08-01 -Force
    	return $publishingCredentials
}

function Get-KuduApiAuthorisationToken($username, [SecureString] $password){
    return ("Basic {0}" -f [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $username,$password))))
}

function Get-FileListFromWebApp($webAppName, $slotName = "", $username, [SecureString] $password, $filePath, $allowUnsafe = $false, $alternativeUrl, $continueIfFileNotExist){

    $kuduApiAuthorisationToken = Get-KuduApiAuthorisationToken $username $password
    if ($slotName -eq ""){				
        $kuduApiUrl = "https://$webAppName.scm.azurewebsites.net/api/vfs/site/wwwroot/$filePath"
    }
    else{
        $kuduApiUrl = "https://$webAppName`-$slotName.scm.azurewebsites.net/api/vfs/site/wwwroot/$filePath"
    }

	if($alternativeUrl -ne ""){
		$kuduApiUrl = $kuduApiUrl.Replace("scm.azurewebsites.net","$alternativeUrl")
	}

	try {
    	$dirList = Invoke-RestMethod -Uri $kuduApiUrl `
									 -Headers @{"Authorization"=$kuduApiAuthorisationToken;"If-Match"="*"} `
									 -Method GET `
									 -ContentType "multipart/form-data"		
		return $dirList
	}
	catch {
		if($_.Exception.Response.StatusCode.value__ -eq "404" -and $continueIfFileNotExist -eq $true){
			# Dont write to output as it is returned from the function
			# Write-Output "File not found (but ignored because of setting)"

			# Return empty array so as not to iterate for 404
			$arr = @()
			return ,$arr		  
		}
		else {
			throw $_.Exception
		}
	}
}

function Remove-FileFromWebApp($webAppName, $slotName = "", $username, [SecureString] $password, $filePath, $allowUnsafe = $false, $alternativeUrl, $continueIfFileNotExist, $deleteRecursive){
	Write-Host "Remove-FileFromWebApp path: $filePath"

	if($deleteRecursive -eq $true -and $filePath.EndsWith("/")){
		
		Write-Host "Recursive delete so Get-FileListFromWebApp to see which files to delete: $filePath"
		$dirs = Get-FileListFromWebApp -webAppName "$webAppName" -slotName "$slotName" -username $username -password $password -filePath "$filePath" -allowUnsafe $allowUnsafe -alternativeUrl $alternativeUrl -continueIfFileNotExist $continueIfFileNotExist
		foreach($file in $dirs){
			$href = $file.href
			$filename = $href.Substring($file.href.IndexOf("/vfs/site/wwwroot/")+18)

			Remove-FileFromWebApp -webAppName "$webAppName" -slotName "$slotName" -username $username -password $password -filePath "$filename" -allowUnsafe $allowUnsafe -alternativeUrl $alternativeUrl -continueIfFileNotExist $continueIfFileNotExist -deleteRecursive $deleteRecursive
		}

		Remove-FileFromWebApp -webAppName "$webAppName" -slotName "$slotName" -username $username -password $password -filePath "$filePath" -allowUnsafe $allowUnsafe -alternativeUrl $alternativeUrl -continueIfFileNotExist $continueIfFileNotExist -deleteRecursive $false

		return
	}

	if($deleteRecursive -eq $true -and $filePath.StartsWith("**/*.")){

		Write-Host "[CUSTOM] Recursive delete so Get-FileListFromWebApp to see which files to delete: $filePath"

		$dirs = Get-FileListFromWebApp -webAppName "$webAppName" -slotName "$slotName" -username $username -password $password -filePath "" -allowUnsafe $allowUnsafe -alternativeUrl $alternativeUrl -continueIfFileNotExist $continueIfFileNotExist
		foreach($file in $dirs){
			if($file.EndsWith($expresion)){
				$href = $file.href
				$filename = $href.Substring($file.href.IndexOf("/vfs/site/wwwroot/")+18)

				Remove-FileFromWebApp -webAppName "$webAppName" -username $username -password $password -filePath "$filename" -allowUnsafe $allowUnsafe -alternativeUrl $alternativeUrl -continueIfFileNotExist $continueIfFileNotExist -deleteRecursive $deleteRecursive
			}
		}

	}

    $kuduApiAuthorisationToken = Get-KuduApiAuthorisationToken $username $password
    if ($slotName -eq ""){				
        $kuduApiUrl = "https://$webAppName.scm.azurewebsites.net/api/vfs/site/wwwroot/$filePath"
    }
    else{
        $kuduApiUrl = "https://$webAppName`-$slotName.scm.azurewebsites.net/api/vfs/site/wwwroot/$filePath"
    }

	if($alternativeUrl -ne ""){
			$kuduApiUrl = $kuduApiUrl.Replace("scm.azurewebsites.net","$alternativeUrl")
	}

	try {
		Invoke-RestMethod -Uri $kuduApiUrl `
						  -Headers @{"Authorization"=$kuduApiAuthorisationToken;"If-Match"="*"} `
						  -Method DELETE `
						  -ContentType "multipart/form-data"			
	}
	catch {
		if($_.Exception.Response.StatusCode.value__ -eq "404" -and $continueIfFileNotExist -eq $true){
			Write-Host "File not found (but ignored because of setting)"
		}
		else {
			throw $_.Exception
		}		
	}
}