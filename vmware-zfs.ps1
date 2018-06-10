param(
    [String]$BackupTag="backup",
    [parameter(Mandatory=$true)]
    [String]$DataSet,
    [parameter(Mandatory=$true)]
    [String]$VCenter,
    [parameter(Mandatory=$true)]
    [String]$User,
    [parameter(Mandatory=$true)]
    [String]$Password,
    [int]$RetentionAmount
)
$ErrorActionPreference="Stop"

try{
    Import-Module -Name VMware.VimAutomation.Core
}
catch{
    Write-Error -Message "You are mising Vmware.PowerCLI"
}

Connect-ViServer -Server $VCenter -User $User -Password $Password | Out-Null

function Create-Backup{
    $snapshot_jobs = [System.Collections.ArrayList]@()
    foreach ($vm in (Get-VM -Tag $BackupTag)){
        @snapshot_jobs.Add(New-Snapshot -VM $vm -Name "backup_snapshot" -Quiesce)
    }
}