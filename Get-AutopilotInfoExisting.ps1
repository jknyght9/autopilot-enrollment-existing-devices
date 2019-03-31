<#PSScriptInfo

.VERSION 1.0

.GUID cf302e6f-9e8f-426b-82c7-1f43111e02d3

.AUTHOR Jacob Stauffer

.COMPANYNAME Coherent CYBER

.COPYRIGHT 

.TAGS Windows AutoPilot

.LICENSEURI 

.PROJECTURI 

.ICONURI 

.EXTERNALMODULEDEPENDENCIES 

.REQUIREDSCRIPTS 

.EXTERNALSCRIPTDEPENDENCIES 

.RELEASENOTES
Version 1.0:  Original published version.

#>

<#
.SYNOPSIS
Retrieves the Windows AutoPilot deployment details from a target system and send the information to a web API
.DESCRIPTION
This script uses WMI to retrieve properties needed by the Microsoft Store for Business to support Windows AutoPilot deployment.
.EXAMPLE
.\Get-AutopilotInfoExisting.ps1
#>

[CmdletBinding()]
param(
  [Parameter(Mandatory = $False, ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True, Position = 0)][alias("DNSHostName", "ComputerName", "Computer")] [String[]] $Name = @($env:ComputerName),
  [Parameter(Mandatory = $False)] [String] $WebAPI = "http://10.10.1.17:8000/register"
)

Begin {
  $isAdmin = $false
}

Process {
  If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "You do not have Administrator rights to run this script.`nPlease re-run this script as an Administrator."
    return
  }
  else {
    $isAdmin = $true
  }

  foreach ($comp in $Name) {
    $bad = $false
    Write-Verbose "Obtaining system information..."
    $serial = (Get-WmiObject -ComputerName $comp -Credential $Credential -Class Win32_BIOS).SerialNumber

    # Get the hash (if available)
    $devDetail = (Get-WMIObject -ComputerName $comp -Credential $Credential -Namespace root/cimv2/mdm/dmmap -Class MDM_DevDetail_Ext01 -Filter "InstanceID='Ext' AND ParentID='./DevDetail'")
    if ($devDetail -and (-not $Force)) {
      $hash = $devDetail.DeviceHardwareData
    }
    else {
      $bad = $true
      $hash = ""
    }

    # If the hash isn't available, get the make and model
    if ($bad -or $Force) {
      $cs = Get-WmiObject -ComputerName $comp -Credential $Credential -Class Win32_ComputerSystem
      $make = $cs.Manufacturer.Trim()
      $model = $cs.Model.Trim()
      if ($Partner) {
        $bad = $false
      }
    }
    else {
      $make = ""
      $model = ""
    }

    # Getting the PKID is generally problematic for anyone other than OEMs, so let's skip it here
    $product = ""

    $apinfo = New-Object psobject -Property @{
      "Hostname"             = $Name
      "Device Serial Number" = $serial
      "Windows Product ID"   = $product
      "Hardware Hash"        = $hash
      "Manufacturer name"    = $make
      "Device model"         = $model
    }

    # Write the object to the pipeline or array
    if ($bad) {
      # Report an error when the hash isn't available
      Write-Error -Message "Unable to retrieve device hardware data (hash) from computer $comp" -Category DeviceError
    }
  }
}

End {
  if ($isAdmin) {
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $WebAPI -Method POST -Body ($apinfo | ConvertTo-Json) -ContentType "application/json"
  }
}
