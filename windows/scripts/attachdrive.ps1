#Declare params Must be the first statement
param(
  [string]$StorageUrl,
  [string]$Username,
  [securestring]$Password,
  [string]$StorageName,
  [string]$DriveLetter,
  [bool]$Persist
  
) 

$connectTestResult = Test-NetConnection -ComputerName adbuild.file.core.windows.net -Port 445
if ($connectTestResult.TcpTestSucceeded) {
  # Save the password so the drive will persist on reboot
  cmd.exe /C "cmdkey /add:`"$StorageUrl`" /user:`"$Username`" /pass:`"$Password`""
  # Mount the drive
  New-PSDrive -Name $DriveLetter -PSProvider FileSystem -Root "\\$StorageUrl\$StorageName" -Persist $Persist
  $env:FASTBUILD_CACHE_PATH = "$DriveLetter`:\cache"
  $env:FASTBUILD_CACHE_MODE = "rw"
  $env:FASTBUILD_BROKERAGE_PATH = "$DriveLetter`:\broker"
}
else {
  Write-Host -Message "Unable to reach the Azure storage account via port 445. Check to make sure your organization or ISP is not blocking port 445, or use Azure P2S VPN, Azure S2S VPN, or Express Route to tunnel SMB traffic over a different port."
}