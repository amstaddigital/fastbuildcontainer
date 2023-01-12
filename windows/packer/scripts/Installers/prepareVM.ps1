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
  # flatten -PathToDir $Destination
  Write-Host "Cleaning up!"
  Remove-Item $archivePath
  if ($AddToPath) {
    AddToPath -PathToAdd $Destination
  }
  Write-Host "Installation complete!"
}
$toolset = Get-ToolsetContent
$requiredComponents = $toolset.visualStudio.workloads | ForEach-Object { "--add $_" }
$releaseInPath = $toolset.visualStudio.edition
$subVersion = $toolset.visualStudio.subversion
$channel = $toolset.visualStudio.channel
$bootstrapperUrl = "https://aka.ms/vs/${subVersion}/${channel}/vs_${releaseInPath}.exe"
$workLoads = @(
	$requiredComponents
	"--remove Component.CPython3.x64"
)
$workLoadsArgument = [String]::Join(" ", $workLoads)
# Install VS
Install-VisualStudio -BootstrapperUrl $bootstrapperUrl -WorkLoads $workLoadsArgument

Wait-Process -Id $(Start-Process -FilePath .\prerequisite.bat -NoNewWindow -PassThru).Id
#ami-018bde64d7d1b4694

AddToPath -PathToAdd "$env:ChocolateyInstall\bin"

$fburl = "https://www.fastbuild.org/downloads/$env:FASTBUILD_VERSION/FASTBuild-Windows-x64-$env:FASTBUILD_VERSION.zip"
WebInstall -InstallUrl $fburl -Destination $env:FASTBUILD_HOME -AddToPath $true

# Install-WindowsFeature -Name NFS-Client
# New-PSDrive -Name "Z" -PSProvider "FileSystem" -Root "\\fs-0f1f61d2609906cbb.fsx.us-east-1.amazonaws.com\fsx\" -Persist