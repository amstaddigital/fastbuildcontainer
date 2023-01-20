function flatten {
  param (
    [string]$PathToDir
  )
  $children = Get-ChildItem $PathToDir -Attributes Directory
  $children | Get-ChildItem | Move-Item -Destination $PathToDir
  $children | Remove-Item
}
function AddToPath {
  param (
    [string]$PathToAdd
  )
  if ($env:PATH.Contains($PathToAdd)) {
    Write-Host "$PathToAdd already present on env PATH"
  }
  else {
    $env:PATH += ";$PathToAdd"
    [Environment]::SetEnvironmentVariable('PATH', $env:PATH, 'Machine')
  }
}
function WebInstall {
  param (
    [string]$InstallUrl,
    [string]$Destination,
    [bool]$AddToPath 
  )
  mkdir $Destination -ErrorAction SilentlyContinue

  $filename = ([uri] $InstallUrl).Segments[-1]
  $archivePath = "$env:TEMP\$filename"
  Write-Host "Installing from web: $InstallUrl at directory $Destination"
  Invoke-WebRequest $InstallUrl -o $archivePath
  Expand-Archive -Path $archivePath -DestinationPath $Destination

  # check if zip isnt flat i.e. all files are nested inside a folder
  Write-Host "Cleaning up!"
  Remove-Item $archivePath
  if ($AddToPath) {
    AddToPath -PathToAdd $Destination
  }
  Write-Host "Installation complete!"
}

AddToPath -PathToAdd "$env:ChocolateyInstall\bin"

# # Install cygwin
# $PACKAGES = "mintty,wget,ctags,diffutils,git,git-completion,libnfs8,libnfs-utils"
# choco install -y cygwin 
# C:\tools\cygwin\cygwinsetup.exe -P $PACKAGES -q
# AddToPath -PathToAdd "C:\tools\cygwin\bin"

# choco install -y winfsp --pre
$winfspPath = (Get-Item $(Get-ItemPropertyValue -Path hklm:\SOFTWARE\WOW6432Node\WinFsp\Services\memfs64 -Name Executable)).Directory.FullName
AddToPath -PathToAdd $winfspPath
https://downloads.rclone.org/rclone-current-windows-amd64.zip
$fburl = "https://www.fastbuild.org/downloads/$env:FASTBUILD_VERSION/FASTBuild-Windows-x64-$env:FASTBUILD_VERSION.zip"
WebInstall -InstallUrl $fburl -Destination $env:FASTBUILD_HOME -AddToPath $true

WebInstall -InstallUrl "https://downloads.rclone.org/rclone-current-windows-amd64.zip" -Destination C:\tools\rclone -AddToPath $true
mkdir "$env:USERPROFILE\AppData\Roaming\rclone" -ErrorAction SilentlyContinue
$rcloneConfig = "$env:USERPROFILE\AppData\Roaming\rclone\rclone.conf"
$rcloneCfg = "
[remote]
type = s3
env_auth = true
provider = AWS
region = us-east-1
acl = public-read-write
storage_class = 
"
Add-Content -Path $rcloneConfig -Value $rcloneCfg