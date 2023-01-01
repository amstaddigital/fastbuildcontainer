
powershell.exe -file attachdrive.ps1 -StorageUrl %STORAGE_URL% -Username %STORAGE_USER% -Password %STORAGE_PASSWORD% -StorageName %STORAGE_NAME% -DriveLetter %DRIVE_LETTER% -Persist %PERSIST%
C:\fastbuild\FBuildWorker.exe -console -cpus=100% -mode=dedicated -nosubprocess