New-Module -name get_autopilotinfo_existing -scriptblock {
  # To execute this script as a one liner on a windows host with powershell 3.0+, run this command replacing server URI with your hosted web API <mandatory>. Please see our autopilot-enrollment-existing-devices project for more information.

  # [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12; (new-object Net.WebClient).DownloadString("https://raw.githubusercontent.com/jknyght9/autopilot-enrollment-existing-devices/master/Host%20Scripts/get-apinfoexisting.ps1") | iex; getautopilotinfoexisting https://<server URI>:8000/register

  # Example:
  # [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12; (new-object Net.WebClient).DownloadString("https://raw.githubusercontent.com/jknyght9/autopilot-enrollment-existing-devices/master/Host%20Scripts/get-apinfoexisting.ps1") | iex; getautopilotinfoexisting https://myserver:8000/register

  # Self-Signed Certificate Example:
  # [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12; [System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true};(new-object Net.WebClient).DownloadString("https://raw.githubusercontent.com/jknyght9/autopilot-enrollment-existing-devices/master/Host%20Scripts/get-apinfoexisting.ps1") | iex; getautopilotinfoexisting https://myserver:8000/register

  Function Get-AutopilotInfoExisting() {
    param(
      [Parameter(Position = 0)]
      [String]$WebAPI
    )

    If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
      Write-Error "You do not have Administrator rights to run this script.`nPlease re-run this script as an Administrator."
      return
    }

    If (-NOT $WebAPI) {
      Write-Error "Please provide the web API URI to register this device."
      return
    }
    
    $Name = @($env:ComputerName)
    foreach ($comp in $Name) {
      $bad = $false
      Write-Host "Obtaining system information..."
      $externalip = (Invoke-WebRequest -Uri http://icanhazip.com -Method GET -UseBasicParsing).Content
      $serial = (Get-WmiObject -ComputerName $comp -Credential $Credential -Class Win32_BIOS).SerialNumber
      $osname = (Get-WmiObject -ComputerName $comp -Credential $Credential -Class Win32_OperatingSystem).Caption
      $osver = (Get-WmiObject -ComputerName $comp -Credential $Credential -Class Win32_OperatingSystem).Version
  
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
        "Hostname"             = $comp
        "OS"                   = $osname + " " + $osver
        "ExternalIP"           = $externalip
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
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
    Invoke-WebRequest -Uri $WebAPI -Method POST -Body ($apinfo | ConvertTo-Json) -ContentType "application/json" -UseBasicParsing
  }
  Set-Alias getautopilotinfoexisting -Value Get-AutopilotInfoExisting | Out-Null
  Export-ModuleMember -Alias 'getautopilotinfoexisting' -Function 'Get-AutopilotInfoExisting' | Out-Null
}
