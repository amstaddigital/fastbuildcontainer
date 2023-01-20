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

variable "helper_script_folder" {
  type    = string
  default = "C:\\Program Files\\WindowsPowerShell\\Modules\\"
}

variable "agent_tools_directory" {
  type    = string
  default = "C:\\hostedtoolcache\\windows"
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

locals { timestamp = regex_replace(timestamp(), "[- TZ:]", "") }

# source blocks are generated from your builders; a source can be referenced in
# build blocks. A build block runs provisioner and post-processors on a
# source.
source "amazon-ebs" "ami" {
  ami_name      = "dovabuilderdroid-${local.timestamp}"
  communicator  = "winrm"
  instance_type = "c6a.8xlarge"
  region        = "${var.region}"
  source_ami    = "ami-0dccae98bea902470"
  subnet_id                   = "subnet-0950377f170583952"
  vpc_id                      = "vpc-09f33041f099b6310"
  associate_public_ip_address = true
  force_deregister            = true
  user_data_file              = "./bootstrap_win.txt"
  winrm_insecure              = true
  winrm_username              = "Administrator"
  winrm_use_ssl               = true
  # skip_create_ami             = true
  security_group_ids    = ["sg-0e0ef23ea923dd806"]
  disable_stop_instance = true
  launch_block_device_mappings {
    device_name = "/dev/sda1"
    volume_size = 400
  }
}

# a build block invokes sources and runs provisioning steps on them.
build {
  name    = "dovabuilder"
  sources = ["source.amazon-ebs.ami"]




  provisioner "powershell" {
    environment_vars = ["IMAGE_VERSION=${var.image_version}", "IMAGE_OS=${var.image_os}", "AGENT_TOOLSDIRECTORY=${var.agent_tools_directory}", "IMAGEDATA_FILE=${var.imagedata_file}"]
    execution_policy = "unrestricted"
    scripts = [
       "${path.root}/scripts/Installers/Install-Toolset.ps1", "${path.root}/scripts/Installers/Configure-Toolset.ps1", "${path.root}/scripts/Installers/Install-NodeLts.ps1",
       "${path.root}/scripts/Installers/Install-WindowsFeatures.ps1", "${path.root}/scripts/Installers/Install-Docker.ps1",
       "${path.root}/scripts/Installers/Install-AndroidSDK.ps1"
    ]
  }

  provisioner "windows-restart" {
    restart_timeout = "10m"
  }

  provisioner "powershell" {
    execution_policy = "unrestricted"
    scripts          = ["${path.root}/scripts/Installers/Finalize-VM.ps1"]
  }

  provisioner "powershell" {
    inline = [
      #Sysprep the instance with ECLaunch v2. Reset enables runonce scripts again.
      "Set-Location $env:programfiles/amazon/ec2launch",
      "./ec2launch.exe reset -c -b",
      "./ec2launch.exe sysprep -s -b"
    ]

    valid_exit_codes = [0, 3010]
  }

}

