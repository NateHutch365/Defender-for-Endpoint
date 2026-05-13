# MDE Performance Troubleshooting Guide


```powershell
# Close as many apps that are not needed for the reproduction
# Do not collect with the Process Monitor (Procmon) simultaneously, in order to prevent overhead from the Procmon data collection showing up in the results.
 
# Use MDE performance analyser for 3-5 minutes: Performance analyzer for Microsoft Defender Antivirus - Microsoft Defender for Endpoint | Microsoft Learn - Get a decent data set/sample
 
# To collect traces during high CPU utilisation run the following command:
 
New-MpPerformanceRecording -RecordTo "C:\TS-Temp\recording.etl"
 
# To analyse the MDAV Perf data
# Example 1:
 
Get-MpPerformanceReport -Path "C:\TS-Temp\recording.etl" -TopProcesses 3
 
Get-MpPerformanceReport -Path "C:\TS-Temp\recording.etl" -TopScans 3
Get-MpPerformanceReport -Path "C:\TS-Temp\recording.etl" -TopScans 5
 
Get-MpPerformanceReport -Path "C:\TS-Temp\recording.etl" -TopPaths 3
 
Get-MpPerformanceReport -Path "C:\TS-Temp\recording.etl" -TopFiles 5 -TopExtensions 5 -TopProcesses 5 -TopScans 5
 
Get-MpPerformanceReport -Path "C:\TS-Temp\recording.etl" -TopScans 20 -TopPaths 20 -TopExtensions 20 -TopProcesses 20
 
# To dive deeper into a specific value
 
Get-MpPerformanceReport -Path "C:\TS-Temp\recording.etl" -TopExtensions 20 -TopScansPerExtension 5 -TopPathsPerExtension 5 -TopScansPerPathPerExtension 5 -TopProcessesPerExtension 5 -TopScansPerProcessPerExtension 5 -TopScansPerFilePerExtension 5 -TopFilesPerExtension 5
 
Get-MpPerformanceReport -Path "C:\TS-Temp\recording.etl" -Overview
 
# Common reason for high CPU utilisation: https://learn.microsoft.com/en-us/defender-endpoint/troubleshoot-performance-issues
 
(Get-MpPerformanceReport -Path: C:\TS-Temp\recording.etl -Topscans:1000). TopScans | Export-CSV -Path: C:\TS-Temp\Install-Scans.csv -Encoding:UTF8 -NoTypeInformation
 
# Collect performance recording remotely
 
$s = New-PSSession -ComputerName Server02 -Credential Domain01\User01
New-MpPerformanceRecording -RecordTo C:\LocalPathOnServer02\trace.etl -Session $s
 
# Collect a performance recording in non-interactive mode (timer)
 
New-MpPerformanceRecording -RecordTo:.\Defender-scans.etl -Seconds 60
 
# Can also run via Live Response: https://kostaskoutrou.github.io/2026/01/17/performance-troubleshooting-mde.html#common-reasons-for-higher-cpu-by-mdav
```
