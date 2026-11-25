
$vault = "D:\ЗООПАРК\ЗООПАРК\ЗООПАРК ДОЛБОЕБОВ\Public"
$site = "D:\quartz-site"
$target = Join-Path $site "content\Public"

$ErrorActionPreference = "Stop"

try {
    Write-Host "==================================" -ForegroundColor Cyan
    Write-Host "       QUARTZ FULL UPDATER"
    Write-Host "==================================" -ForegroundColor Cyan

    # Проверка путей
    if (-not (Test-Path -LiteralPath $vault -PathType Container)) {
        throw "Obsidian folder not found: $vault"
    }

    if (-not (Test-Path -LiteralPath $site -PathType Container)) {
        throw "Quartz folder not found: $site"
    }

    Set-Location $site

    # Полное удаление старого содержимого
    Write-Host "`n[1/6] Removing old content..." -ForegroundColor Yellow

    if (Test-Path -LiteralPath $target) {
        Remove-Item -LiteralPath $target -Recurse -Force
    }

    New-Item -ItemType Directory -Path $target -Force | Out-Null

    # Полное копирование из Obsidian
    Write-Host "`n[2/6] Copying fresh Obsidian content..." -ForegroundColor Cyan

    Get-ChildItem -LiteralPath $vault -Force |
        Where-Object {
            $_.Name -notin @(".obsidian", ".trash")
        } |
        ForEach-Object {
            Copy-Item -LiteralPath $_.FullName `
                -Destination $target `
                -Recurse -Force
        }

    # Проверка структуры
    Write-Host "`n[3/6] Checking folders..." -ForegroundColor Cyan

    $folders = @(
        Get-ChildItem -LiteralPath $target -Directory -Recurse
    )

    foreach ($folder in $folders) {
        $index = Join-Path $folder.FullName "index.md"

        if (-not (Test-Path -LiteralPath $index)) {
            $title = $folder.Name

            $content = @"
---
title: "$title"
---

# $title
"@

            Set-Content -LiteralPath $index `
                -Value $content `
                -Encoding UTF8
        }
    }

    Write-Host "Folders found: $($folders.Count)" -ForegroundColor Green

    # Удаление старой сборки
    Write-Host "`n[4/6] Cleaning old Quartz build..." -ForegroundColor Cyan

    if (Test-Path "$site\public") {
        Remove-Item "$site\public" -Recurse -Force
    }

    # Сборка
    Write-Host "`nBuilding Quartz..." -ForegroundColor Cyan

    npx quartz build

    if ($LASTEXITCODE -ne 0) {
        throw "Quartz build failed with exit code $LASTEXITCODE"
    }

    # Git
    Write-Host "`n[5/6] Preparing Git..." -ForegroundColor Cyan

    git add -A

    if ($LASTEXITCODE -ne 0) {
        throw "Git add failed"
    }

    git diff --cached --quiet

    if ($LASTEXITCODE -eq 0) {
        Write-Host "No changes detected." -ForegroundColor Green
        exit 0
    }

    git commit -m ("Full Quartz update " + (Get-Date -Format "yyyy-MM-dd HH:mm"))

    if ($LASTEXITCODE -ne 0) {
        throw "Git commit failed"
    }

    # Отправка
    Write-Host "`n[6/6] Pushing to GitHub..." -ForegroundColor Cyan

    git push

    if ($LASTEXITCODE -ne 0) {
        throw "Git push failed"
    }

    Write-Host "`n==================================" -ForegroundColor Green
    Write-Host "       UPDATE COMPLETED!"
    Write-Host "==================================" -ForegroundColor Green

    Write-Host "Your Quartz site will update after GitHub Actions finishes."

}
catch {
    Write-Host "`nERROR: $_" -ForegroundColor Red
    exit 1
}
