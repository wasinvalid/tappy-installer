# --- Functions ---
function WaitUntilContinued {
    Write-Host -NoNewLine 'Press any key to continue...'
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
}

function FetchModpackNames {
    $repoUrl = "https://api.github.com/repos/wasinvalid/tappy-installer/contents/resources"
    $headers = @{
        "User-Agent" = "PowerShellScript"
    }

    try {
        $response = Invoke-RestMethod -Uri $repoUrl -Headers $headers

        # Always return an array
        return @(
            $response |
            Where-Object { $_.type -eq 'file' -and $_.name -like "*.zip" } |
            Select-Object -ExpandProperty name
        )
    }
    catch {
        Write-Host "Failed to fetch data from the repository."
        WaitUntilContinued
        Exit
    }
}

function FormatModpackNames {
    param($fileNames)

    $fileNames = @($fileNames) # force array

    return @(
        foreach ($file in $fileNames) {
            $baseName = [System.IO.Path]::GetFileNameWithoutExtension($file)

            (
                $baseName -split '-' |
                ForEach-Object {
                    $_.Substring(0,1).ToUpper() + $_.Substring(1).ToLower()
                }
            ) -join ' '
        }
    )
}


function ShowMenu {
    param($choices, $selectedIndex)

    Clear-Host
    for ($i = 0; $i -lt $choices.Count; $i++) {
        if ($i -eq $selectedIndex) {
            Write-Host $choices[$i] -ForegroundColor White -BackgroundColor Blue
        }
        else {
            Write-Host $choices[$i]
        }
    }
}

function SelectModpack {
    param($choices)

    $choices = @($choices) # safety
    $selectedIndex = 0

    while ($true) {
        ShowMenu -choices $choices -selectedIndex $selectedIndex
        $key = [System.Console]::ReadKey($true)

        switch ($key.Key) {
            'UpArrow'   { $selectedIndex = ($selectedIndex - 1 + $choices.Count) % $choices.Count }
            'DownArrow' { $selectedIndex = ($selectedIndex + 1) % $choices.Count }
            'Enter' {
                Write-Host "`nYou selected: $($choices[$selectedIndex])"
                return $choices[$selectedIndex]
            }
        }
    }
}

function InstallModpack {
    param($displayName)

    # Convert display name back to filename format
    $modpackName = ($displayName -replace ' ', '-').ToLower()
    $modpackUrl  = "https://github.com/wasinvalid/tappy-installer/raw/refs/heads/main/resources/$modpackName.zip"

    $tempDir     = "$env:TEMP\ReadyOrNotModPack"
    $zipPath     = "$tempDir\$modpackName.zip"
    $defaultPath = "C:\Program Files (x86)\Steam\steamapps\common\Ready Or Not\ReadyOrNot\Content\Paks"
    $steamPattern = "\SteamLibrary\steamapps\common\Ready Or Not\ReadyOrNot\Content\Paks"

    # Prepare temp
    Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue | Out-Null
    New-Item -ItemType Directory -Path $tempDir | Out-Null

    # Find mod folder
    $modFolder = $null
    if (Test-Path $defaultPath) {
        $modFolder = $defaultPath
    } else {
        foreach ($drive in Get-PSDrive -PSProvider FileSystem) {
            $path = "$($drive.Root)$steamPattern"
            if (Test-Path $path) {
                $modFolder = $path
                break
            }
        }
    }

    if (-not $modFolder) {
        Write-Host "Mod folder not found."
        WaitUntilContinued
        Exit
    }

    Write-Host "Downloading modpack..."
    Invoke-WebRequest -Uri $modpackUrl -OutFile $zipPath -ErrorAction SilentlyContinue | Out-Null

    if (-not (Test-Path $zipPath)) {
        Write-Host "Download failed."
        WaitUntilContinued
        Exit
    }

    Write-Host "Extracting modpack..."
    Expand-Archive -Path $zipPath -DestinationPath $modFolder -Force | Out-Null

    Write-Host "Modpack installed successfully!"
    WaitUntilContinued
}

# --- Main ---
Write-Host "Loading modpacks..."
$fileNames      = FetchModpackNames
$formattedNames = FormatModpackNames $fileNames

if ($formattedNames.Count -eq 0) {
    Write-Host "No modpacks found."
    WaitUntilContinued
    Exit
}

Write-Host "`nSelect a modpack:"
$selectedModpack = SelectModpack $formattedNames
InstallModpack $selectedModpack
