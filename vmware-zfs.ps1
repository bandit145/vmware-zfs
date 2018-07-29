#!/usr/bin/env pwsh
param(
    [String]$BackupTag=$null,
    [parameter(Mandatory=$true)]
    [String]$DataSet,
    [parameter(Mandatory=$true)]
    [String]$VCenter,
    [parameter(Mandatory=$true)]
    [String]$User,
    [parameter(Mandatory=$true)]
    [String]$Password,
    [int]$RetentionLimit
)
$ErrorActionPreference="Stop"
if($env:USER -ne "root"){
    Write-Error -Message "This script must be run as root!"
}

try{
    Import-Module -Name VMware.VimAutomation.Core
}
catch{
    Write-Error -Message "You are mising Vmware.PowerCLI"
}

Connect-ViServer -Server $VCenter -User $User -Password $Password | Out-Null


$snapshot_jobs = [System.Collections.ArrayList]@()
foreach ($vm in (Get-VM -Tag $BackupTag)){
    snapshot_jobs.Add(New-Snapshot -VM $vm -Name "backup_snapshot" -Quiesce -RunAsync)
}
while ("Running" -in $snapshot_jobs.state){
}
foreach ($task in $snapshot_jobs){
    if ($task.state -ne "Success"){
        Write-Output "VM Failed to snapshot!"
    }
}
#clean up snapshots
Create-ZFSSnapshot
foreach ($vm in (Get-VM -Tag $BackupTag)){
    Get-Snapshot -VM $vm -Name "backup_snapshot" | Remove-Snapshot -Confirm:$false -RunAsync
}

function Create-ZFSSnapshot{
    $snapshots = (zfs list -t snapshot | awk 'NR>1{print $1}').split()
    if($snapshots.Length+1 -eq $RetentionLimit){
        zfs destroy $snapshots[$snapshots.Length-1]
        Write-Output -join($snapshots[$snapshots.Length-1]," destroyed!")
    }
    zfs snapshot -join($DataSet@"vmware-auto-snap",(Get-Date -UFormat "%Y-%m-%d-%T"))
}