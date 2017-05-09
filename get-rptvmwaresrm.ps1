<#
=======================================================================================
File Name: get-rptvmwaresrm.ps1
Created on: 
Created with VSCode
Version 1.0
Last Updated: 
Last Updated by: John Shelton | c: 260-410-1200 | e: john.shelton@lucky13solutions.com

Purpose:

Notes: 

Change Log:


=======================================================================================
#>
#
# Define Parameter(s)
#
param (
  [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
  [string[]] $VCenterServers = $(throw "-VCenterServers is required.  Pass as array.")
)
#
Clear-Host
#
# Load VMWare PSSnapin
#
Add-PSSnapin VMWare.VimAutomation.Core
#
# Define Output Variables
#
$ExecutionStamp = Get-Date -Format yyyyMMdd_hh-mm-ss
$path = "c:\temp\"
$FilenamePrepend = 'rpt_'
$FullFilename = "get-rptvmwaresrm.ps1"
$FileName = $FullFilename.Substring(0, $FullFilename.LastIndexOf('.'))
$FileExt = '.xlsx'
$OutputFile = $path + $FilenamePrePend + '_' + $FileName + '_' + $ExecutionStamp + $FileExt
$PathExists = Test-Path $path
IF($PathExists -eq $False)
  {
  New-Item -Path $path -ItemType  Directory
  }
#
$Result = @()
ForEach($VCenterServer in $VCenterServers){
  $SRMCred = Get-Credential -Message "Please enter the credentials to connect to $VCenterServer SRM"
  Connect-VIServer -Server $VCenterServer -Credential $SRMCred
  $srm = Connect-SrmServer
  $srmApi = $srm.ExtensionData
  $protectionGroups = $srmApi.Protection.ListProtectionGroups()
  $protectionGroups | % {
    $protectionGroup = $_
    
    $protectionGroupInfo = $protectionGroup.GetInfo()
    
    # The following command lists the virtual machines associated with a protection group
    $protectedVms = $protectionGroup.ListProtectedVms()
    # The result of the above call is an array of references to the virtual machines at the vSphere API
    # To populate the data from the vSphere connection, call the UpdateViewData method on each virtual machine view object
    $protectedVms | % { $_.Vm.UpdateViewData() }
    # After the data is populated, use it to generate a report
    $protectedVms | %{
        $output = "" | select VCenterServer, VmName, PgName, State, NeedsConfig
        $output.VCenterServer = $VCenterServer
        $output.VmName = $_.Vm.Name
        $output.PgName = $protectionGroupInfo.Name
        $output.NeedsConfig = $_.NeedsConfiguration
        $output.State = $_.State
        $Result += $Output
      }
  } | Format-Table @{Label="VM Name"; Expression={$_.VmName} }, @{Label="Protection group name"; Expression={$_.PgName} }, @{Label="Needs Configuration"; Expression={$_.NeedsConfig} }, @{Label="State"; Expression={$_.State} }
}
Clear-Host
$Result | Sort-Object VMName | Export-Excel -Path $OutputFile -WorkSheetname "SRM Info" -TableName "$VCenterServer" -AutoSize -TableStyle Medium4

