Invoke-WebRequest "https://www.fastbuild.org/downloads/$env:FASTBUILD_VERSION/FASTBuild-Windows-x64-$env:FASTBUILD_VERSION.zip" -o C:\fastbuild\fb.zip 
Expand-Archive -Path $env:FASTBUILD_HOME\fb.zip -DestinationPath $env:FASTBUILD_HOME
Remove-Item $env:FASTBUILD_HOME\fb.zip

Write-Host "Selft destructing"

Remove-Item -Path $env:FASTBUILD_HOME\fbinstall.ps1 -Verbose