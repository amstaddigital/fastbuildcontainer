################################################################################
##  File:  Install-Git.ps1
##  Desc:  Install Git for Windows
################################################################################

# Install the latest version of Git for Windows
$download = "https://github.com/git-for-windows/git/releases/download/v2.38.1.windows.1/MinGit-2.38.1-64-bit.zip"
$target = "$env:TEMP\git.zip"
if(!(Microsoft.PowerShell.Management\Test-Path -Path "Z:\apps\git\cmd")){
  Invoke-WebRequest -Uri $download -OutFile  $target
  Expand-Archive -LiteralPath $target -DestinationPath "Z:\apps\git"
  Remove-Item $target
}

# Disable GCM machine-wide
[Environment]::SetEnvironmentVariable("GCM_INTERACTIVE", "Never", [System.EnvironmentVariableTarget]::Machine)

# Add to PATH
Add-MachinePathItem "Z:\apps\git\cmd"


