<# 
.SYNOPSIS 
    PowerCLI script that generates a HTML report from your vCenter
    to display the VM disk configuration
.NOTES  
    Author: jlg-io
    Version: 1.0
.EXAMPLE
    PS> .\Get-VMHardDiskReport.ps1
.LINK
    plop.bzh
#>

$reportFile = "VMDiskReport_{0:yyyyMMdd}.html" -f (Get-Date)
$vm = Get-VM | Where-Object PowerState -eq "PoweredOn"
$tvm = @()

$head=@"
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"  "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<title>VM Disk Report</title>
<style>
body{color:#565656;font-family:Calibri,Verdana,sans-serif;font-size:14px;line-height:1.25}
H1{color:white;font-size:32px;margin-bottom:50px;margin-top:0px;margin-left:0px;margin-right:0px;text-align:center;background-color:#0072A3;}
H2{color:#313131;font-size:28px;margin-left:14px;text-lign:left;}
H3{color:#000000;font-size:22px;margin-left:16px;}
H4{color:#8C8C8C;font-size:18px;position:absolute;top:24px;left:180px;width:100%; }
table {border-collapse: collapse;margin-left:10px;border-radius:7px 7px 0px 0px;}
th, td {padding: 8px;text-align: left;border-bottom: 1px solid #ddd;}
th {background-color: #00567A;color: white;}
td:first-child{font-weight:bold;}
tr:nth-child(even){background-color: #E8E8E8}
</style>

</head>
"@

Function Write-LogInfo {
    Param ([string]$logstring)
    Write-host -ForegroundColor Cyan "$(Get-Date -Format 's') : [ INFO  ] : $logstring"
}

Write-LogInfo "Start"

$head | Out-File $reportFile

FOREACH ($v in $vm) {
    Write-LogInfo ("{0}" -f $v.Name) 
    $tvm += "" | Select-Object @{
        Name="VM Name"
        Expression={$v.Name}
    },@{
        Name="Disks"
        Expression={$v | Get-HardDisk | ForEach-Object{($_.FileName) + " xxxx"}}
    },@{
        Name="Format"
        Expression={$v | Get-HardDisk | ForEach-Object{($_.StorageFormat).ToString() + " xxxx"}}
    },@{
        Name="SCSI Controller"
        Expression={
            $v | Get-HardDisk | ForEach-Object{
                $ctrl = ($_ | Get-ScsiController).ExtensionData.DeviceInfo.Summary
                $bus = (($_ | Get-ScsiController).ExtensionData.BusNumber).ToString()
                $unitNumber = ($_.ExtensionData.UnitNumber).ToString()
                '{0} ({1}:{2}) xxxx' -f $ctrl, $bus, $unitNumber
            }
        }
    },@{
        Name="Size"
        Expression={$v | Get-HardDisk | ForEach-Object{[math]::round(($_.CapacityGB),2).ToString()+" Go xxxx"}}
    }
}

$tvm | ConvertTo-Html -Fragment -PreContent "<H1>VM Disk Report</H1>" | Out-File -Append $reportFile

(Get-content $reportFile) | Foreach-Object {($_).Replace("xxxx","</br>")} | Out-file $reportFile

Write-LogInfo "End"
