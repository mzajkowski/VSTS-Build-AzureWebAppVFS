Trace-VstsEnteringInvocation $MyInvocation

$ConnectedServiceName = Get-VstsInput -Name ConnectedServiceName -Require
$WebAppName = Get-VstsInput -Name WebAppName -Require
$ResourceGroupName = Get-VstsInput -Name ResourceGroupName
$SlotName = Get-VstsInput -Name SlotName
$filePaths = Get-VstsInput -Name filePath -Require
$deleteRecursive = Get-VstsInput -Name deleteRecursive 
$allowUnsafe = Get-VstsInput -Name allowUnsafe
$alternativeKuduUrl = Get-VstsInput -Name alternativeKuduUrl 
$continueIfFileNotExist = Get-VstsInput -Name continueIfFileNotExist 


# Initialize Azure.
Import-Module $PSScriptRoot\ps_modules\VstsAzureHelpers_
Initialize-Azure
Write-Host "Azure Initialized"

Import-Module $PSScriptRoot\vfs
Write-Host "VFS scripts Initialized"

if ([string]::IsNullOrWhiteSpace($ResourceGroupName)) {
	$webapp = Get-AzureRmWebApp -name "$WebAppName"
	$ResourceGroupName = $webapp.ResourceGroup
}


Write-Host "Retrieved web app: $webapp in Resource group: $resourceGroup"
Write-Host "Retrieving publishing profile"
if ([string]::IsNullOrWhiteSpace($SlotName)) {
	$login = Get-AzureRmWebAppPublishingCredentials "$ResourceGroupName" "$WebAppName" 
}
else {
	$login = Get-AzureRmWebAppPublishingCredentials "$ResourceGroupName" "$WebAppName" "$SlotName"
}
Write-Host "Publishing profile retrieved"

$username = $login.Properties.PublishingUserName
$pw = $login.Properties.PublishingPassword

if($allowUnsafe -eq $true){
	 		add-type @"
	   		using System.Net;
	   		using System.Security.Cryptography.X509Certificates;
		 		public class TrustAllCertsPolicy : ICertificatePolicy {
		   		public bool CheckValidationResult(
			 		ServicePoint srvPoint, X509Certificate certificate,
			 		WebRequest request, int certificateProblem) {
			   		return true;
			 		}
		 		}
"@
		[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
}

$filePathsArray = $filePaths.Split([Environment]::NewLine)

foreach ($filePath in $filePathsArray) {
	Remove-FileFromWebApp -webAppName "$WebAppName" -slotName "$SlotName" -username "$username" -password "$pw" -filePath "$filePath" -allowUnsafe $allowUnsafe -alternativeUrl $alternativeKuduUrl -continueIfFileNotExist $continueIfFileNotExist -deleteRecursive $deleteRecursive
}