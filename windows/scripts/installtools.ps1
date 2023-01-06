$path = "$env:PATH;$ChocolateyInstall\bin"
[Environment]::SetEnvironmentVariable('PATH', $path, 'Machine')

$PACKAGES = "mintty,wget,ctags,diffutils,git,git-completion,libnfs8,cyg-get"

choco install -y cygwin
C:\tools\cygwin\cygwinsetup.exe -P $PACKAGES -q

$path = "$env:PATH;C:\tools\cygwin\bin"
[Environment]::SetEnvironmentVariable('PATH', $path, 'Machine')

Invoke-WebRequest "https://www.fastbuild.org/downloads/$env:FASTBUILD_VERSION/FASTBuild-Windows-x64-$env:FASTBUILD_VERSION.zip" -o C:\fastbuild\fb.zip 
Expand-Archive -Path $env:FASTBUILD_HOME\fb.zip -DestinationPath $env:FASTBUILD_HOME
Remove-Item $env:FASTBUILD_HOME\fb.zip
