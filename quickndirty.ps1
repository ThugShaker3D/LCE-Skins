#!/usr/bin/env pwsh

$basePath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$skinPacksPath = Join-Path $basePath "assets\bedrockskins\skin_packs"

if (-not (Test-Path $skinPacksPath)) {
    Write-Error "Skin packs directory not found: $skinPacksPath"
    exit 1
}

Write-Host "skin pack rename go brrr: $skinPacksPath" -ForegroundColor Green

$skinPackDirs = Get-ChildItem -Path $skinPacksPath -Directory | Sort-Object Name

foreach ($dir in $skinPackDirs) {
    $folderName = $dir.Name
    Write-Host "`nProcessing: $folderName" -ForegroundColor Yellow
    
    $skinsJsonPath = Join-Path $dir.FullName "skins.json"
    if (-not (Test-Path $skinsJsonPath)) {
        Write-Warning "  skins.json not found, skipping"
        continue
    }
    
    try {
        $skinsData = Get-Content $skinsJsonPath -Raw | ConvertFrom-Json
        $oldName = $skinsData.serialize_name
        
        if ($oldName -eq $folderName) {
            Write-Host "  already done, skipping" -ForegroundColor Green
            continue
        }
        
        Write-Host "  old name: $oldName"
        Write-Host "  new name: $folderName"
        
        # Get all files in the folder (recursive)
        $allFiles = Get-ChildItem -Path $dir.FullName -File -Recurse
        
        $filesUpdated = 0
        $replacementsMade = 0
        
        foreach ($file in $allFiles) {
            try {
                $content = Get-Content $file.FullName -Raw
                $originalContent = $content
                
                # Replace all occurrences of the old name with the new folder name
                $content = $content -replace [regex]::Escape($oldName), $folderName
                
                # Only write if content changed
                if ($content -ne $originalContent) {
                    $content | Set-Content $file.FullName -NoNewline
                    $filesUpdated++
                    $replacementsMade += ([regex]::Matches($originalContent, [regex]::Escape($oldName))).Count
                    Write-Host "    Updated: $($file.Name)"
                }
            }
            catch {
                Write-Warning "    Failed to process $($file.Name): $($_.Exception.Message)"
            }
        }
        
        Write-Host "  updated $filesUpdated files with $replacementsMade replacements" -ForegroundColor Green
    }
    catch {
        Write-Warning "  shits broken yo: $($_.Exception.Message)"
    }
}

Write-Host "`nScript completed!" -ForegroundColor Green