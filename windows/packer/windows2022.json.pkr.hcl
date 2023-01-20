packer {
  required_plugins {
    amazon = {
      version = ">= 0.0.1"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "agent_tools_directory" {
  type    = string
  default = "C:\\hostedtoolcache\\windows"
}

variable "allowed_inbound_ip_addresses" {
  type    = string
  default = "${env("AGENT_IP")}"
}

variable "build_resource_group_name" {
  type    = string
  default = "${env("BUILD_RESOURCE_GROUP_NAME")}"
}

variable "capture_name_prefix" {
  type    = string
  default = "packer"
}

variable "client_cert_path" {
  type    = string
  default = "${env("ARM_CLIENT_CERT_PATH")}"
}

variable "client_id" {
  type    = string
  default = "${env("ARM_CLIENT_ID")}"
}

variable "client_secret" {
  type      = string
  default   = "${env("ARM_CLIENT_SECRET")}"
  sensitive = true
}

variable "helper_script_folder" {
  type    = string
  default = "C:\\Program Files\\WindowsPowerShell\\Modules\\"
}

variable "image_folder" {
  type    = string
  default = "C:\\image"
}

variable "image_os" {
  type    = string
  default = "win22"
}

variable "image_version" {
  type    = string
  default = "dev"
}

variable "imagedata_file" {
  type    = string
  default = "C:\\imagedata.json"
}

variable "install_password" {
  type      = string
  sensitive = true
  default   = "SuperS3cr3t!!!!"
}

variable "install_user" {
  type    = string
  default = "Administrator"
}

variable "location" {
  type    = string
  default = "${env("ARM_RESOURCE_LOCATION")}"
}

variable "object_id" {
  type    = string
  default = "${env("ARM_OBJECT_ID")}"
}

variable "private_virtual_network_with_public_ip" {
  type    = string
  default = "${env("PRIVATE_VIRTUAL_NETWORK_WITH_PUBLIC_IP")}"
}

variable "resource_group" {
  type    = string
  default = "${env("ARM_RESOURCE_GROUP")}"
}

variable "storage_account" {
  type    = string
  default = "${env("ARM_STORAGE_ACCOUNT")}"
}

variable "subscription_id" {
  type    = string
  default = "${env("ARM_SUBSCRIPTION_ID")}"
}

variable "temp_resource_group_name" {
  type    = string
  default = "${env("TEMP_RESOURCE_GROUP_NAME")}"
}

variable "tenant_id" {
  type    = string
  default = "${env("ARM_TENANT_ID")}"
}

variable "virtual_network_name" {
  type    = string
  default = "${env("VNET_NAME")}"
}

variable "virtual_network_resource_group_name" {
  type    = string
  default = "${env("VNET_RESOURCE_GROUP")}"
}

variable "virtual_network_subnet_name" {
  type    = string
  default = "${env("VNET_SUBNET")}"
}

variable "vm_size" {
  type    = string
  default = "Standard_D8s_v4"
}

source "amazon-ebs" "ami" {
  ami_name      = "dragon-builder-${local.timestamp}"
  communicator  = "winrm"
  instance_type = "m4.xlarge"
  region        = "${var.region}"
  source_ami_filter {
    filters = {
      name                = "Windows_Server-2022-English-Full-Base-2022.12.14"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["amazon"]
  }
  winrm_password = "${var.install_password}"
  winrm_username = "${var.install_user}"
  user_data_file = "./bootstrap_win.txt"
  launch_block_device_mappings {
    device_name = "/dev/sda1"
    volume_size = 400
  }
  aws_polling {
    delay_seconds = 40
    max_attempts  = 10
  }
}
locals { timestamp = regex_replace(timestamp(), "[- TZ:]", "") }
# a build block invokes sources and runs provisioning steps on them. The
# documentation for build blocks can be found here:
# https://www.packer.io/docs/templates/hcl_templates/blocks/build
build {
  name    = "uebuilder"
  sources = ["source.amazon-ebs.ami"]
  provisioner "powershell" {
    inline = ["New-Item -Path ${var.image_folder} -ItemType Directory -Force"]
  }

  provisioner "file" {
    destination = "${var.helper_script_folder}"
    source      = "${path.root}/scripts/ImageHelpers"
  }

  provisioner "file" {
    destination = "${var.image_folder}\\toolset.json"
    source      = "${path.root}/toolsets/toolset-2022.json"
  }

  provisioner "powershell" {
    inline = ["if (-not ((net localgroup Administrators) -contains '${var.install_user}')) { exit 1 }"]
  }

  provisioner "powershell" {
    elevated_password = "${var.install_password}"
    elevated_user     = "${var.install_user}"
    inline            = ["bcdedit.exe /set TESTSIGNING ON"]
  }

  provisioner "powershell" {
    environment_vars = ["IMAGE_VERSION=${var.image_version}", "IMAGE_OS=${var.image_os}", "AGENT_TOOLSDIRECTORY=${var.agent_tools_directory}", "IMAGEDATA_FILE=${var.imagedata_file}"]
    execution_policy = "unrestricted"
    scripts          = ["${path.root}/scripts/Installers/Configure-Antivirus.ps1", "${path.root}/scripts/Installers/Install-PowerShellModules.ps1", "${path.root}/scripts/Installers/Install-WindowsFeatures.ps1", "${path.root}/scripts/Installers/Install-Choco.ps1", "${path.root}/scripts/Installers/Initialize-VM.ps1", "${path.root}/scripts/Installers/Update-ImageData.ps1", "${path.root}/scripts/Installers/Update-DotnetTLS.ps1"]
  }

  provisioner "windows-restart" {
    check_registry        = true
    restart_check_command = "powershell -command \"& {while ( (Get-WindowsOptionalFeature -Online -FeatureName Containers -ErrorAction SilentlyContinue).State -ne 'Enabled' ) { Start-Sleep 30; Write-Output 'InProgress' }}\""
    restart_timeout       = "10m"
  }

  provisioner "powershell" {
    scripts = ["${path.root}/scripts/Installers/Install-Docker.ps1", "${path.root}/scripts/Installers/Install-PowershellCore.ps1", "${path.root}/scripts/Installers/Install-WebPlatformInstaller.ps1"]
  }

  provisioner "windows-restart" {
    restart_timeout = "30m"
  }

  provisioner "powershell" {
    elevated_password = "${var.install_password}"
    elevated_user     = "${var.install_user}"
    scripts           = ["${path.root}/scripts/Installers/Install-VS.ps1", "${path.root}/scripts/Installers/Install-KubernetesTools.ps1"]
    valid_exit_codes  = [0, 3010]
  }

  provisioner "windows-restart" {
    check_registry  = true
    restart_timeout = "10m"
  }

  provisioner "powershell" {
    pause_before = "2m0s"
    scripts = ["${path.root}/scripts/Installers/Install-Wix.ps1", "${path.root}/scripts/Installers/Install-WDK.ps1",
      //  "${path.root}/scripts/Installers/Install-Vsix.ps1", 
      //  "${path.root}/scripts/Installers/Install-AzureCli.ps1", "${path.root}/scripts/Installers/Install-AzureDevOpsCli.ps1",
    "${path.root}/scripts/Installers/Install-CommonUtils.ps1", "${path.root}/scripts/Installers/Install-JavaTools.ps1", "${path.root}/scripts/Installers/Install-Kotlin.ps1"]
  }

  provisioner "windows-restart" {
    restart_timeout = "10m"
  }

  provisioner "windows-shell" {
    inline = ["wmic product where \"name like '%%microsoft azure powershell%%'\" call uninstall /nointeractive"]
  }

  provisioner "powershell" {
    scripts = ["${path.root}/scripts/Installers/Install-Toolset.ps1", "${path.root}/scripts/Installers/Configure-Toolset.ps1", "${path.root}/scripts/Installers/Install-NodeLts.ps1", "${path.root}/scripts/Installers/Install-AndroidSDK.ps1",
      //"${path.root}/scripts/Installers/Install-AzureModules.ps1",
      "${path.root}/scripts/Installers/Install-Pipx.ps1", "${path.root}/scripts/Installers/Install-PipxPackages.ps1", "${path.root}/scripts/Installers/Install-Git.ps1",
      // "${path.root}/scripts/Installers/Install-GitHub-CLI.ps1",
      //"${path.root}/scripts/Installers/Install-PHP.ps1", 
      //"${path.root}/scripts/Installers/Install-Rust.ps1",
      // "${path.root}/scripts/Installers/Install-Sbt.ps1", "${path.root}/scripts/Installers/Install-Chrome.ps1", "${path.root}/scripts/Installers/Install-Edge.ps1", "${path.root}/scripts/Installers/Install-Firefox.ps1", "${path.root}/scripts/Installers/Install-Selenium.ps1", "${path.root}/scripts/Installers/Install-IEWebDriver.ps1",
      // "${path.root}/scripts/Installers/Install-Apache.ps1", "${path.root}/scripts/Installers/Install-Nginx.ps1", "${path.root}/scripts/Installers/Install-Msys2.ps1", 
      "${path.root}/scripts/Installers/Install-WinAppDriver.ps1",
      //"${path.root}/scripts/Installers/Install-R.ps1",
      "${path.root}/scripts/Installers/Install-AWS.ps1",
      //"${path.root}/scripts/Installers/Install-DACFx.ps1", "${path.root}/scripts/Installers/Install-MysqlCli.ps1", 
      //"${path.root}/scripts/Installers/Install-SQLPowerShellTools.ps1", "${path.root}/scripts/Installers/Install-SQLOLEDBDriver.ps1", 
      "${path.root}/scripts/Installers/Install-DotnetSDK.ps1", //"${path.root}/scripts/Installers/Install-Mingw64.ps1", "${path.root}/scripts/Installers/Install-Haskell.ps1", 
      //"${path.root}/scripts/Installers/Install-Stack.ps1", "${path.root}/scripts/Installers/Install-Miniconda.ps1", "${path.root}/scripts/Installers/Install-AzureCosmosDbEmulator.ps1", "${path.root}/scripts/Installers/Install-Mercurial.ps1", "${path.root}/scripts/Installers/Install-Zstd.ps1", "${path.root}/scripts/Installers/Install-NSIS.ps1", 
      "${path.root}/scripts/Installers/Install-Vcpkg.ps1",
      //"${path.root}/scripts/Installers/Install-PostgreSQL.ps1", 
      "${path.root}/scripts/Installers/Install-Bazel.ps1", //"${path.root}/scripts/Installers/Install-AliyunCli.ps1", 
      "${path.root}/scripts/Installers/Install-RootCA.ps1",
      // "${path.root}/scripts/Installers/Install-MongoDB.ps1", "${path.root}/scripts/Installers/Install-CodeQLBundle.ps1", 
    "${path.root}/scripts/Installers/Disable-JITDebugger.ps1"]
  }

  provisioner "powershell" {
    elevated_password = "${var.install_password}"
    elevated_user     = "${var.install_user}"
    scripts           = ["${path.root}/scripts/Installers/Install-WindowsUpdates.ps1", "${path.root}/scripts/Installers/Configure-DynamicPort.ps1", "${path.root}/scripts/Installers/Configure-GDIProcessHandleQuota.ps1", "${path.root}/scripts/Installers/Configure-Shell.ps1", "${path.root}/scripts/Installers/Enable-DeveloperMode.ps1", "${path.root}/scripts/Installers/Install-LLVM.ps1"]
  }

  provisioner "windows-restart" {
    check_registry        = true
    restart_check_command = "powershell -command \"& {if ((-not (Get-Process TiWorker.exe -ErrorAction SilentlyContinue)) -and (-not [System.Environment]::HasShutdownStarted) ) { Write-Output 'Restart complete' }}\""
    restart_timeout       = "30m"
  }

  provisioner "powershell" {
    pause_before = "2m0s"
    scripts = ["${path.root}/scripts/Installers/Wait-WindowsUpdatesForInstall.ps1"
    ]
  }

  provisioner "powershell" {
    environment_vars = ["INSTALL_USER=${var.install_user}"]
    scripts          = ["${path.root}/scripts/Installers/Run-NGen.ps1", "${path.root}/scripts/Installers/Finalize-VM.ps1"]
    skip_clean       = true
  }

  provisioner "windows-restart" {
    restart_timeout = "10m"
  }

}
