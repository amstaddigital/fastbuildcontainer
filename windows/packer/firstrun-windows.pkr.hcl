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

variable "script_path" {
  type    = string
  default = "Z:\\installer"
}
variable "helper_script_folder" {
  type    = string
  default = "C:\\Program Files\\WindowsPowerShell\\Modules\\"
}

locals { timestamp = regex_replace(timestamp(), "[- TZ:]", "") }

# source blocks are generated from your builders; a source can be referenced in
# build blocks. A build block runs provisioner and post-processors on a
# source.
source "amazon-ebs" "ami" {
  ami_name      = "packer-windows-demo-${local.timestamp}"
  communicator  = "winrm"
  instance_type = "t2.micro"
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
  subnet_id                   = "subnet-0950377f170583952"
  vpc_id                      = "vpc-09f33041f099b6310"
  associate_public_ip_address = true
  force_deregister            = true
  user_data_file              = "./bootstrap_win.txt"
  winrm_insecure              = true
  winrm_username              = "Administrator"
  winrm_use_ssl               = true
  skip_create_ami             = true
  security_group_ids          = ["sg-0e0ef23ea923dd806"]

}

# a build block invokes sources and runs provisioning steps on them.
build {
  name    = "dovabuilder"
  sources = ["source.amazon-ebs.ami"]

  provisioner "file" {
    destination = "${var.helper_script_folder}"
    source      = "${path.root}/scripts/ImageHelpers"
  }

  provisioner "file" {
    destination = "${var.helper_script_folder}\\toolset.json"
    source      = "${path.root}/toolsets/toolset-2022.json"
  }

  provisioner "powershell" {
    inline = ["if (-not ((net localgroup Administrators) -contains 'Administrator')) { exit 1 }"]
  }

  provisioner "powershell" {
    inline = ["bcdedit.exe /set TESTSIGNING ON"]
  }

  provisioner "powershell" {
    execution_policy = "unrestricted"
    scripts          = ["${path.root}/scripts/Installers/Configure-Antivirus.ps1", "${path.root}/scripts/Installers/Install-Choco.ps1", "${path.root}/scripts/Installers/Install-Git.ps1",]
  }

  provisioner "windows-restart" {
    restart_timeout = "30m"
  }

  #  provisioner "powershell" {
  #    inline = [ #Sysprep the instance with ECLaunch v2. Reset enables runonce scripts again.
  #      "Set-Location $env:programfiles/amazon/ec2launch",
  #      "./ec2launch.exe reset -c -b",
  #    "./ec2launch.exe sysprep -c -b"]
  #  }
}

