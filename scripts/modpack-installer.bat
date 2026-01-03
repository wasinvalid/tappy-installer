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
        return $response | Where-Object { $_.type -eq 'file' } | Select-Object -ExpandProperty name
    }
    catch {
        Write-Host "Failed to fetch data from the repository."
        WaitUntilContinued
        Exit
    }
}

function FormatModpackNames {
    param($fileNames)
    return $fileNames | ForEach-Object {
        # Remove .zip extension
        $nameWithoutExtension = $_.Substring(0, $_.LastIndexOf('.'))

        # Split by dash and capitalize each word
        $words = $nameWithoutExtension.Split('-') | ForEach-Object { 
            $_.Substring(0,1).ToUpper() + $_.Substring(1).ToLower()
        }
        
        # Join the words with spaces
        $words -join ' '
    }
}

function ShowMenu {
    param($choices, $selectedIndex)
    Clear-Host  # Clear the screen before displaying the menu
    for ($i = 0; $i -lt $choices.Length; $i++) {
        if ($i -eq $selectedIndex) {
            Write-Host "$($choices[$i])" -ForegroundColor White -BackgroundColor Blue
        }
        else {
            Write-Host "$($choices[$i])"
        }
    }
}

function SelectModpack {
    param($choices)
    $selectedIndex = 0
    while ($true) {
        ShowMenu -choices $choices -selectedIndex $selectedIndex
        $key = [System.Console]::ReadKey($true)

        if ($key.Key -eq "UpArrow") {
            $selectedIndex = ($selectedIndex - 1 + $choices.Length) % $choices.Length
        }
        elseif ($key.Key -eq "DownArrow") {
            $selectedIndex = ($selectedIndex + 1) % $choices.Length
        }
        elseif ($key.Key -eq "Enter") {
            Write-Host "`nYou selected: $($choices[$selectedIndex])"
            return $choices[$selectedIndex]
        }
    }
}

function InstallModpack {
    param($modpackName)
    $modpackUrl = "https://github.com/wasinvalid/tappy-installer/raw/refs/heads/main/resources/$($modpackName)-modpack.zip"
    $tempDir = "$env:TEMP\ReadyOrNotModPack"
    $modpackPath = "$tempDir\$($modpackName)-modpack.zip"
    $defaultFolder = "C:\Program Files (x86)\Steam\steamapps\common\Ready Or Not\ReadyOrNot\Content\Paks"
    $steamLibraryPattern = "\SteamLibrary\steamapps\common\Ready Or Not\ReadyOrNot\Content\Paks"
    $modFolder = ""

    # Clean temporary directory (suppressing output)
    if (Test-Path $tempDir) { Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue | Out-Null }
    New-Item -ItemType Directory -Path $tempDir -ErrorAction SilentlyContinue | Out-Null

    # Check if default folder exists
    if (Test-Path $defaultFolder) {
        $modFolder = $defaultFolder
        Write-Host "Found mod folder: $defaultFolder"
    } else {
        Write-Host "Default mod folder not found: $defaultFolder"
        # Search for the mod folder in all drives
        foreach ($drive in Get-PSDrive -PSProvider FileSystem) {
            $currentPath = "$($drive.Root)$steamLibraryPattern"
            if (Test-Path $currentPath) {
                $modFolder = $currentPath
                Write-Host "Found mod folder: $modFolder"
                break
            }
        }
    }

    if (-not $modFolder) {
        Write-Host "Error: Mod folder not found."
        WaitUntilContinued
        Exit
    }

    # Check if mod is already installed
    if (Test-Path "$modFolder\mods") {
        Write-Host "Mod already installed."
        WaitUntilContinued
        Exit
    }

    # Download the modpack (suppressing unnecessary output)
    Write-Host "Downloading modpack..."
    Invoke-WebRequest -Uri $modpackUrl -OutFile $modpackPath -ErrorAction SilentlyContinue | Out-Null

    if (-not (Test-Path $modpackPath)) {
        Write-Host "Error: Download failed."
        WaitUntilContinued
        Exit
    }

    Write-Host "Download completed. Moving modpack..."
    Move-Item -Force $modpackPath -Destination $modFolder -ErrorAction SilentlyContinue | Out-Null

    Write-Host "Extracting modpack..."
    Expand-Archive -Path "$modFolder\$($modpackName)-modpack.zip" -DestinationPath $modFolder -Force -ErrorAction SilentlyContinue | Out-Null

    if ($?) {
        Write-Host "Modpack installed successfully."
    } else {
        Write-Host "Error: Failed to extract modpack."
    }

    # Clean up (suppressing output)
    Remove-Item -Path "$modFolder\$($modpackName)-modpack.zip" -Force -ErrorAction SilentlyContinue | Out-Null
    WaitUntilContinued
}

# --- Main Flow ---
Write-Host "Loading options..."
$fileNames = FetchModpackNames
$formattedNames = FormatModpackNames -fileNames $fileNames

Write-Host "`nSelect a modpack:"
$selectedModpack = SelectModpack -choices $formattedNames

InstallModpack -modpackName $selectedModpack
