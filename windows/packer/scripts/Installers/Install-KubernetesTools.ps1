################################################################################
##  File:  Install-KubernetesTools.ps1
##  Desc:  Install tools for K8s.
################################################################################


Write-Host "Install Kubectl"
Choco-Install -PackageName kubernetes-cli

Write-Host "Install Helm"
Choco-Install -PackageName kubernetes-helm

# Write-Host "Install Minikube"
# Choco-Install -PackageName minikube

# 