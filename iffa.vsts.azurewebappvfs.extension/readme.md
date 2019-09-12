# Azure WebApp Virtual File System Tasks

A custom Azure DevOps deployment task for deleting files and/or folders from the app service, with deployment slot support & fixes for issues found in upstream.

![Screenshot](https://raw.githubusercontent.com/iffa/VSTS-Build-AzureWebAppVFS/master/iffa.vsts.azurewebappvfs.extension/images/1.png)

## Why not simply use "Remove additional files at destination"?

Good question. It is true that Azure app service deployment has built-in functionality for removing files that don't exist in the artifact from the app service. We however noticed that this functionality is **very slow**, especially for our scenario: we're deploying NodeJS webapps and we install packages as part of deployment in the app service instead of carrying them over from the build process. As part of every deployment, with "Remove additional files at destination" enabled, we'd spend 5-10 minutes removing node_modules. NPM/Yarn can handle this itself, so we started looking for a way to delete only the files & folders we care about.

## Credits
- https://github.com/Geertvdc/VSTS-Build-AzureWebAppVFS (original version)
- https://github.com/NielsSchneider/VSTS-Build-AzureWebAppVFS (deployment slot support, base for this fork)