param(
    [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
)

$ErrorActionPreference = "Stop"

$addonName = "betterlights"
$localizationRoot = Join-Path $Root "resource\localization"
$englishPath = Join-Path $localizationRoot "en\$addonName.properties"
$luaRoot = Join-Path $Root "lua"
$errors = New-Object System.Collections.Generic.List[string]
$warnings = New-Object System.Collections.Generic.List[string]

function Add-Error {
    param([string]$Message)
    $errors.Add($Message) | Out-Null
}

function Add-Warning {
    param([string]$Message)
    $warnings.Add($Message) | Out-Null
}

function Read-Properties {
    param([string]$Path)

    $result = [ordered]@{
        Keys = [ordered]@{}
        Lines = @()
    }

    if (-not (Test-Path -LiteralPath $Path)) {
        Add-Error "Missing localization file: $Path"
        return $result
    }

    $lines = @(Get-Content -LiteralPath $Path)
    $result.Lines = $lines

    if ($lines.Count -eq 0 -or $lines[0] -ne "") {
        Add-Error "$Path must start with a blank first line."
    }

    for ($i = 0; $i -lt $lines.Count; $i++) {
        $lineNumber = $i + 1
        $line = $lines[$i]

        if ($line -eq "" -or $line.TrimStart().StartsWith("#")) {
            continue
        }

        $equalsIndex = $line.IndexOf("=")
        if ($equalsIndex -lt 1) {
            Add-Error "${Path}:$lineNumber is not a key=value line."
            continue
        }

        $key = $line.Substring(0, $equalsIndex)
        $value = $line.Substring($equalsIndex + 1)

        if ($key -match "\s") {
            Add-Error "${Path}:$lineNumber has whitespace in key '$key'."
        }

        if (-not $key.StartsWith("$addonName.")) {
            Add-Error "${Path}:$lineNumber key '$key' must start with '$addonName.'."
        }

        if ($result.Keys.Contains($key)) {
            Add-Error "${Path}:$lineNumber duplicates key '$key'."
            continue
        }

        $result.Keys[$key] = @{
            Value = $value
            Line = $lineNumber
        }
    }

    return $result
}

function Get-LuaLocalizationKeys {
    param([string]$LuaPath)

    $source = Get-Content -LiteralPath $LuaPath -Raw
    $keys = New-Object System.Collections.Generic.HashSet[string]

    foreach ($match in [regex]::Matches($source, 'phrase(?:Format)?\("([^"]+)"')) {
        $keys.Add("$addonName." + $match.Groups[1].Value) | Out-Null
    }

    foreach ($call in [regex]::Matches($source, 'phrase(?:Format)?\(([^)]*)\)')) {
        foreach ($match in [regex]::Matches($call.Groups[1].Value, '"([^"]+\.[^"]*)"')) {
            $keys.Add("$addonName." + $match.Groups[1].Value) | Out-Null
        }
    }

    $helperPatterns = @(
        'setupPage\([^,]+,\s*"([^"]+)"',
        'setupPage\([^,]+,\s*"[^"]+",\s*"([^"]+)"',
        'addSection\([^,]+,\s*"([^"]+)"',
        'addSection\([^,]+,\s*"[^"]+",\s*"([^"]+)"',
        'addColorMixerControl\([^,]+,\s*"([^"]+)"',
        'modelElightLabel\s*=\s*"([^"]+)"',
        'enableLabel\s*=\s*"([^"]+)"',
        'radiusLabel\s*=\s*"([^"]+)"',
        'brightnessLabel\s*=\s*"([^"]+)"',
        'nameKey\s*=\s*"([^"]+)"',
        'titleKey\s*=\s*"([^"]+)"',
        'subtitleKey\s*=\s*"([^"]+)"',
        'labelKey\s*=\s*"([^"]+)"'
    )

    foreach ($pattern in $helperPatterns) {
        foreach ($match in [regex]::Matches($source, $pattern)) {
            $keys.Add("$addonName." + $match.Groups[1].Value) | Out-Null
        }
    }

    return @($keys | Sort-Object)
}

function Get-FormatTokens {
    param([string]$Value)

    return @([regex]::Matches($Value, '%(?:\d+\$)?[-+#0 ]*(?:\d+|\*)?(?:\.(?:\d+|\*))?[cdiouxXeEfgGaAqs]') |
        ForEach-Object { $_.Value })
}

if (-not (Test-Path -LiteralPath $localizationRoot)) {
    Add-Error "Missing localization directory: $localizationRoot"
}

$english = Read-Properties -Path $englishPath
$englishKeys = @($english.Keys.Keys | Sort-Object)

$luaKeys = New-Object System.Collections.Generic.HashSet[string]
if (-not (Test-Path -LiteralPath $luaRoot)) {
    Add-Error "Missing Lua directory: $luaRoot"
} else {
    foreach ($luaFile in Get-ChildItem -LiteralPath $luaRoot -Recurse -Filter "*.lua") {
        foreach ($key in Get-LuaLocalizationKeys -LuaPath $luaFile.FullName) {
            $luaKeys.Add($key) | Out-Null
        }
    }
}

foreach ($key in @($luaKeys | Sort-Object)) {
    if (-not $english.Keys.Contains($key)) {
        Add-Error "Missing English localization key used by Lua: $key"
    }
}

foreach ($key in $englishKeys) {
    if (-not $luaKeys.Contains($key)) {
        Add-Warning "English localization key is not referenced by current Lua scans: $key"
    }
}

if (Test-Path -LiteralPath $localizationRoot) {
    foreach ($languageDir in Get-ChildItem -LiteralPath $localizationRoot -Directory) {
        $path = Join-Path $languageDir.FullName "$addonName.properties"
        if (-not (Test-Path -LiteralPath $path)) {
            Add-Warning "Language '$($languageDir.Name)' has no $addonName.properties file."
            continue
        }

        $localized = Read-Properties -Path $path
        if ($languageDir.Name -eq "en") {
            continue
        }

        foreach ($key in $englishKeys) {
            if (-not $localized.Keys.Contains($key)) {
                Add-Error "$path is missing English key '$key'."
                continue
            }

            $englishTokens = Get-FormatTokens -Value $english.Keys[$key].Value
            $localizedTokens = Get-FormatTokens -Value $localized.Keys[$key].Value
            if (($englishTokens -join "|") -ne ($localizedTokens -join "|")) {
                Add-Error "$path key '$key' has format placeholders '$($localizedTokens -join ", ")' but English has '$($englishTokens -join ", ")'."
            }
        }

        foreach ($key in @($localized.Keys.Keys | Sort-Object)) {
            if (-not $english.Keys.Contains($key)) {
                Add-Warning "$path has extra key '$key'."
            }
        }
    }
}

Write-Host "Localization validation"
Write-Host "Root: $Root"
Write-Host "English keys: $($englishKeys.Count)"
Write-Host "Lua keys found: $($luaKeys.Count)"

if ($warnings.Count -gt 0) {
    Write-Host ""
    Write-Host "Warnings:"
    foreach ($warning in $warnings) {
        Write-Host "  - $warning"
    }
}

if ($errors.Count -gt 0) {
    Write-Host ""
    Write-Host "Errors:"
    foreach ($errorMessage in $errors) {
        Write-Host "  - $errorMessage"
    }

    exit 1
}

Write-Host ""
Write-Host "Localization validation passed."
