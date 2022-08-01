param($sourceFileUrl="", $destinationFolder="", $labName="Ignored",$installOptions="Chrome")
Start-Transcript "C:\scriptlog.txt"
$ErrorActionPreference = 'SilentlyContinue'

if([string]::IsNullOrEmpty($sourceFileUrl) -eq $false -and [string]::IsNullOrEmpty($destinationFolder) -eq $false)
{
    if((Test-Path $destinationFolder) -eq $false)
    {
        Write-Output "Creating destination folder $destinationFolder"
        New-Item -Path $destinationFolder -ItemType directory
    }
    $splitpath = $sourceFileUrl.Split("/")
    $fileName = $splitpath[$splitpath.Length-1]
    $destinationPath = Join-Path $destinationFolder $fileName

    Write-Output "Starting download: $sourceFileUrl to $destinationPath"
    (New-Object Net.WebClient).DownloadFile($sourceFileUrl,$destinationPath);

    Write-Output "Unzipping $destinationPath to $destinationFolder"
    (new-object -com shell.application).namespace($destinationFolder).CopyHere((new-object -com shell.application).namespace($destinationPath).Items(),16)
}
#install WSL latest version
start-process wsl --install

# Install Chrome
$Path = $env:TEMP; 
$Installer = "chrome_installer.exe"
Write-Output "Downloading Chrome installer"
#Invoke-WebRequest "http://dl.google.com/chrome/install/375.126/chrome_installer.exe" -OutFile $Path\$Installer
Invoke-WebRequest "https://chromeenterprise.google/browser/download/thank-you/?platform=WIN64_BUNDLE&channel=stable&usagestats=0#" -OutFile $Path\$Installer
Write-Output "Installing Chrome from $Path\$Installer..."
Start-Process -FilePath $Path\$Installer -Args "/silent /install" -Verb RunAs -Wait
Remove-Item $Path\$Installer

# Install Docker for Windows 
$Path = $env:TEMP; 
$Installer = "Docker Desktop Installer.exe"
Write-Output "Downloading Docker installer"
#Invoke-WebRequest "https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe" -OutFile $Path\$Installer
Invoke-WebRequest "https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe" -OutFile $Path\$Installer 
Write-Output "Installing Docker for Desktop from $Path\$Installer..."
Start-Process -FilePath $Path\$Installer -Args "install --quite" -Wait -NoNewWindow
Remove-Item $Path\$Installer

if([string]::IsNullOrEmpty($installOptions) -eq $false) 
{

    if($installOptions.Contains("VSCode")) 
    {
        # Install VS Code
        $Path = $env:TEMP; 
        $Installer = "vscode.exe"
        Write-Output "Downloading VSCode installer"
        Invoke-WebRequest "https://go.microsoft.com/fwlink/?Linkid=852157" -OutFile $Path\$Installer
        Write-Output "Installing VSCode from $Path\$Installer..."
        Start-Process -FilePath $Path\$Installer -Args "/verysilent /MERGETASKS=!runcode" -Verb RunAs -Wait
        Remove-Item $Path\$Installer
    }

    if($installOptions.Contains("CLI")) 
    {
        # Install Azure CLI 2
        $Path = $env:TEMP; 
        $Installer = "cli_installer.msi"
        Write-Output "Downloading Azure CLI installer"
        Invoke-WebRequest "https://aka.ms/InstallAzureCliWindows" -OutFile $Path\$Installer
        Write-Output "Installing Azure CLI from $Path\$Installer..."
        Start-Process -FilePath msiexec -Args "/i $Path\$Installer /quiet /qn /norestart" -Verb RunAs -Wait
        Remove-Item $Path\$Installer
    }

}

$Path = $env:TEMP; 
$Installer = "Git-2.21.0-64-bit.exe"
Write-Output "Downloading Git Client"
Invoke-WebRequest "https://github.com/git-for-windows/git/releases/download/v2.21.0.windows.1/Git-2.21.0-64-bit.exe" -OutFile $Path\$Installer
Write-Host "Installing Git Client from $Path\$Installer..." -ForegroundColor Green
Start-Process -FilePath msiexec -Args "/i $Path\$Installer /quiet /qn /norestart" -Verb RunAs -Wait
Remove-Item $Path\$Installer


# Install Azure PowerShell
Write-Output "Installing NuGet package provider"
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force

Write-Output "Installing Az PowerShell module"
Install-Module -Name Az -AllowClobber -Scope AllUsers -Force -Confirm:$false

# Uninstall AzureRM PowerShell
# This image has AzureRM PS installed from MSI, so this is how we uninstall
Write-Output "Check for AzureRm PowerShell"
$app = Get-WmiObject -Class Win32_Product | Where-Object { $_.Name -like "*Azure PowerShell*" }
if ($null -ne $app) {
    Write-Output "Uninstalling AzureRm PowerShell via MSI"
    $app.Uninstall()
}
else {
    Write-Output "Could not find AzureRM PowerShell MSI"
}


Stop-Transcript
