param(
    [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
)

$ErrorActionPreference = "Stop"

$changelogPath = Join-Path $Root "data_static\betterlights_changelog.txt"
$versionPath = Join-Path $Root "lua\autorun\client\betterlights_00_core.lua"
$errors = New-Object System.Collections.Generic.List[string]
$entries = New-Object System.Collections.Generic.List[object]
$versions = New-Object System.Collections.Generic.HashSet[string]

function Add-Error {
    param([string]$Message)
    $errors.Add($Message) | Out-Null
}

if (-not (Test-Path -LiteralPath $changelogPath)) {
    Add-Error "Missing changelog file: $changelogPath"
} else {
    $lines = @(Get-Content -LiteralPath $changelogPath)
    $state = "heading"
    $currentTitle = $null
    $currentVersion = $null
    $currentItems = New-Object System.Collections.Generic.List[string]

    for ($i = 0; $i -lt $lines.Count; $i++) {
        $lineNumber = $i + 1
        $line = $lines[$i].TrimStart([char]0xFEFF).Trim()
        if ($line -eq "") {
            continue
        }

        if ($state -eq "heading") {
            $headingMatch = [regex]::Match($line, '^\[b\](Better Lights (v\d+\.\d+\.\d+[A-Za-z0-9.-]*))\[/b\]$')
            if (-not $headingMatch.Success) {
                Add-Error "${changelogPath}:$lineNumber expected a '[b]Better Lights v...[/b]' heading."
                continue
            }

            $currentTitle = $headingMatch.Groups[1].Value
            $currentVersion = $headingMatch.Groups[2].Value
            $currentItems = New-Object System.Collections.Generic.List[string]
            $state = "list"
            continue
        }

        if ($state -eq "list") {
            if ($line -ne "[list]") {
                Add-Error "${changelogPath}:$lineNumber expected '[list]' after $currentVersion."
                continue
            }

            $state = "items"
            continue
        }

        if ($line -eq "[/list]") {
            if ($currentItems.Count -eq 0) {
                Add-Error "${changelogPath}:$lineNumber release $currentVersion has no items."
            }

            if (-not $versions.Add($currentVersion)) {
                Add-Error "${changelogPath}:$lineNumber duplicates release $currentVersion."
            }

            $entries.Add([pscustomobject]@{
                Title = $currentTitle
                Version = $currentVersion
                Items = @($currentItems)
            }) | Out-Null

            $currentTitle = $null
            $currentVersion = $null
            $currentItems = New-Object System.Collections.Generic.List[string]
            $state = "heading"
            continue
        }

        $itemMatch = [regex]::Match($line, '^\[\*\](.+)$')
        if (-not $itemMatch.Success) {
            Add-Error "${changelogPath}:$lineNumber expected a '[*]' item or '[/list]'."
            continue
        }

        $item = $itemMatch.Groups[1].Value.Trim()
        if ($item -match '\[[^\]]+\]') {
            Add-Error "${changelogPath}:$lineNumber uses unsupported BBCode inside a changelog item."
        }

        $currentItems.Add($item) | Out-Null
    }

    if ($state -ne "heading") {
        Add-Error "$changelogPath ends before the $currentVersion release block is complete."
    }
}

$currentAddonVersion = $null
if (-not (Test-Path -LiteralPath $versionPath)) {
    Add-Error "Missing version source: $versionPath"
} else {
    $versionSource = Get-Content -LiteralPath $versionPath -Raw
    $versionMatch = [regex]::Match($versionSource, 'BL\.VERSION\s*=\s*"(v[^"]+)"')
    if (-not $versionMatch.Success) {
        Add-Error "Could not find BL.VERSION in $versionPath."
    } else {
        $currentAddonVersion = $versionMatch.Groups[1].Value
    }
}

if ($entries.Count -eq 0) {
    Add-Error "$changelogPath contains no complete release entries."
} elseif ($currentAddonVersion -and $entries[0].Version -ne $currentAddonVersion) {
    Add-Error "The newest changelog entry is $($entries[0].Version), but BL.VERSION is $currentAddonVersion."
}

$itemCount = 0
foreach ($entry in $entries) {
    $itemCount += $entry.Items.Count
}

Write-Host "Changelog validation"
Write-Host "Root: $Root"
Write-Host "Releases: $($entries.Count)"
Write-Host "Items: $itemCount"

if ($errors.Count -gt 0) {
    Write-Host ""
    Write-Host "Errors:"
    foreach ($errorMessage in $errors) {
        Write-Host "  - $errorMessage"
    }

    exit 1
}

Write-Host ""
Write-Host "Changelog validation passed."
