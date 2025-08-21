# OneStart Removal Script

# Define valid paths for OneStart files, currently needs function
$valid_paths = @(
    "C:\Users\*\AppData\Roaming\OneStart\*",
    "C:\Users\*\AppData\Local\OneStart*\*"
)

# Defines and stops process names related to OneStart
function Stop-OneStartProcesses {
    param(
        [string[]]$ProcessNames = @("DBar") # Default process, allows expansion
    )

    $totalStopped = 0

    foreach ($proc in $ProcessNames) {
        $runningProcesses = Get-Process -Name $proc -ErrorAction SilentlyContinue

        if (-not $runningProcesses) {
            Write-Output "No running processes found for: $proc."
        } else {
            foreach ($process in $runningProcesses) {
                try {
                    Stop-Process -Id $process.Id -Force -ErrorAction Stop
                    Write-Output "Process '$proc' (PID: $($process.Id)) has been stopped."
                    $totalStopped++
                } catch {
                    Write-Output "Failed to stop proces '$proc' (PID: $($process.Id)): $_"
                    
                }
            }
        }
    }

    if ($totalStopped -gt 0) {
        Write-Output "Total processes stopped: $totalStopped"
        Start-Sleep -Seconds 2 # Slight Delay for flow control
    }

    return $totalStopped
}

# Remove OneStart directories for all users
$file_paths = @(
    "\AppData\Roaming\OneStart.ai\", # Changed Path - c0pp3rdru1d
    "\AppData\Local\OneStart.ai",
    "\AppData\Local\OneStart*\*"  # New path added
)

foreach ($userFolder in Get-ChildItem C:\Users -Directory) {
    foreach ($fpath in $file_paths) {
        $fullPath = Join-Path $userFolder.FullName $fpath
        if (Test-Path $fullPath) {
            try {
                Remove-Item -Path $fullPath -Recurse -Force -ErrorAction Stop
                Write-Output "Deleted: $fullPath"
            } catch {
                Write-Output "Failed to delete: $fullPath - $_"
            }
        }
    }
}

# Remove OneStart registry keys
$reg_paths = @(
    "\HKEY_CLASSES_ROOT\OneStart.aiUpdate.Update3Webuser",
    "\HKEY_CURRENT_USER\Software\OneStart.ai",
    "\HKEY_LOCAL_MACHINE\Software\OneStart.ai"
)

foreach ($registry_hive in Get-ChildItem Registry::HKEY_USERS) {
    foreach ($regpath in $reg_paths) {
        $fullRegPath = "Registry::$($registry_hive.PSChildName)$regpath"
        if (Test-Path $fullRegPath) {
            try {
                Remove-Item -Path $fullRegPath -Recurse -Force -ErrorAction Stop
                Write-Output "Removed registry key: $fullRegPath"
            } catch {
                Write-Output "Failed to remove registry key: $fullRegPath - $_"
            }
        }
    }
}

# Remove OneStart registry properties from Run key
$reg_properties = @("OneStartBar", "OneStartBarUpdate", "OneStartUpdate")

foreach ($registry_hive in Get-ChildItem Registry::HKEY_USERS) {
    $runKeyPath = "Registry::$($registry_hive.PSChildName)\Software\Microsoft\Windows\CurrentVersion\Run"
    
    if (Test-Path $runKeyPath) {
        foreach ($property in $reg_properties) {
            try {
                Remove-ItemProperty -Path $runKeyPath -Name $property -ErrorAction Stop
                Write-Output "Removed registry value: $property from $runKeyPath"
            } catch {
                Write-Output "Failed to remove registry value: $property from $runKeyPath - $_"
            }
        }
    }
}

# Remove scheduled tasks related to OneStart
$schtasknames = @("OneStart Chromium", "OneStart Updater", "OneStartAutoLaunchTask")

$c = 0
foreach ($task in $schtasknames) {
    $clear_tasks = Get-ScheduledTask -TaskName $task -ErrorAction SilentlyContinue

    if ($clear_tasks) {
        try {
            Unregister-ScheduledTask -TaskName $task -Confirm:$true -ErrorAction Stop
            Write-Output "Removed scheduled task: '$task'."
            $c++
        } catch {
            Write-Output "Failed to remove scheduled task: '$task' - $_"
        }
    }
}

if ($c -eq 0) {
    Write-Output "No OneStart scheduled tasks were found."
}
