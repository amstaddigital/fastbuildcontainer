
powershell.exe -file attachdrive.ps1 -FileSystemId %FS_ID% -MountPoint %MOUNT_POINT% -AwsRegion %AWS_REGION%
C:\fastbuild\FBuildWorker.exe -console -cpus=100% -mode=dedicated -nosubprocess