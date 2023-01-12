@rem @"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command "[System.Net.ServicePointManager]::SecurityProtocol = 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))" && SET "PATH=%PATH%;%ChocolateyInstall%\bin"

@rem pdbcopy.exe from Windows SDK is needed for creating an Installed Build of the Engine
choco install -y choco-cleaner || goto :error
choco install -y python || goto :error
choco install -y vcredist-all || goto :error
choco install -y windows-sdk-10-version-1809-windbg || goto :error
@rem Gather the required DirectX runtime files, since Windows Server Core does not include them
curl --progress-bar -L "https://download.microsoft.com/download/8/4/A/84A35BF1-DAFE-4AE8-82AF-AD2AE20B6B14/directx_Jun2010_redist.exe" --output %TEMP%\directx_redist.exe && ^
start /wait %TEMP%\directx_redist.exe /Q /T:%TEMP% && ^
expand %TEMP%\APR2007_xinput_x64.cab -F:xinput1_3.dll C:\Windows\System32\ && ^
expand %TEMP%\Jun2010_D3DCompiler_43_x64.cab -F:D3DCompiler_43.dll C:\Windows\System32\ && ^
expand %TEMP%\Feb2010_X3DAudio_x64.cab -F:X3DAudio1_7.dll C:\Windows\System32\ && ^
expand %TEMP%\Jun2010_XAudio_x64.cab -F:XAPOFX1_5.dll C:\Windows\System32\ && ^
expand %TEMP%\Jun2010_XAudio_x64.cab -F:XAudio2_7.dll C:\Windows\System32\ || goto :error

@rem Retrieve the DirectX shader compiler files needed for DirectX Raytracing (DXR)
curl --progress-bar -L "https://github.com/microsoft/DirectXShaderCompiler/releases/download/v1.6.2104/dxc_2021_04-20.zip" --output %TEMP%\dxc.zip && ^
powershell -Command "Expand-Archive -Path \"$env:TEMP\dxc.zip\" -DestinationPath $env:TEMP" && ^
xcopy /y %TEMP%\bin\x64\dxcompiler.dll C:\Windows\System32\ && ^
xcopy /y %TEMP%\bin\x64\dxil.dll C:\Windows\System32\ || goto :error

@rem Gather the Vulkan runtime library
curl --progress-bar -L "https://sdk.lunarg.com/sdk/download/latest/windows/vulkan-runtime-components.zip?u=" --output %TEMP%\vulkan-runtime-components.zip && ^
powershell -Command "Expand-Archive -Path \"$env:TEMP\vulkan-runtime-components.zip\" -DestinationPath $env:TEMP" && ^
powershell -Command "Copy-Item -Path \"*\x64\vulkan-1.dll\" -Destination C:\Windows\System32" || goto :error
	
@rem Something that gets installed in ue4-build-prerequisites creates a bogus NuGet config file
@rem Just remove it, so a proper one will be generated on next NuGet run
@rem See https://github.com/adamrehn/ue4-docker/issues/171#issuecomment-852136034
if exist %APPDATA%\NuGet rmdir /s /q %APPDATA%\NuGet

@rem Display a human-readable completion message
@echo off
@echo Finished installing build prerequisites and cleaning up temporary files.
goto :EOF

@rem If any of our essential commands fail, propagate the error code
:error
echo "an error has occured"
@echo off
exit /b %ERRORLEVEL%

aws ec2 create-image --instance-id i-00e53958a56b2892c --name "dovabuilder" --description "Builder base for dragonrealm"