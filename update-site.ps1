
$vault = "D:\ЗООПАРК\ЗООПАРК\ЗООПАРК ДОЛБОЕБОВ\Public"
$site  = "D:\quartz-site"

$ErrorActionPreference = "Stop"

try {
    if (-not (Test-Path -LiteralPath $vault)) {
        throw "Vault folder not found: $vault"
    }

    if (-not (Test-Path -LiteralPath $site)) {
        throw "Quartz folder not found: $site"
    }

    Set-Location $site

    Write-Host "=== Syncing Obsidian files ===" -ForegroundColor Cyan

    robocopy $vault "$site\content\Public" /MIR /XD .obsidian .trash /R:2 /W:2

    if ($LASTEXITCODE -ge 8) {
        throw "Robocopy failed with code $LASTEXITCODE"
    }

    Write-Host "=== Cleaning old Quartz build ===" -ForegroundColor Cyan

    if (Test-Path "$site\public") {
        Remove-Item "$site\public" -Recurse -Force
    }

    Write-Host "=== Building Quartz ===" -ForegroundColor Cyan

    npx quartz build

    if ($LASTEXITCODE -ne 0) {
        throw "Quartz build failed"
    }

    Write-Host "=== Checking Git ===" -ForegroundColor Cyan

    git add -A

    if ($LASTEXITCODE -ne 0) {
        throw "Git add failed"
    }

    git diff --cached --quiet

    if ($LASTEXITCODE -eq 0) {
        Write-Host "No changes to push." -ForegroundColor Green
        exit 0
    }

    Write-Host "=== Committing changes ===" -ForegroundColor Cyan

    git commit -m ("Full site update " + (Get-Date -Format "yyyy-MM-dd HH:mm"))

    if ($LASTEXITCODE -ne 0) {
        throw "Git commit failed"
    }

    Write-Host "=== Pushing to GitHub ===" -ForegroundColor Cyan

    git push

    if ($LASTEXITCODE -ne 0) {
        throw "Git push failed"
    }

    Write-Host ""
    Write-Host "SUCCESS! Quartz site fully updated." -ForegroundColor Green
}
catch {
    Write-Host ""
    Write-Host "ERROR: $_" -ForegroundColor Red
    exit 1
}
