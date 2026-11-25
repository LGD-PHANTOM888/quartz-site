$vault = "D:\ЗООПАРК\ЗООПАРК\ЗООПАРК ДОЛБОЕБОВ\Public"
$site  = "D:\quartz-site"

if (-not (Test-Path -LiteralPath $vault)) {
    Write-Host "ERROR: vault folder not found: $vault" -ForegroundColor Red
    exit 1
}

Set-Location $site

Write-Host "=== Copying Public from Obsidian ==="
robocopy $vault "$site\content\Public" /MIR /XD .obsidian .trash /NFL /NDL /NJH /NP
if ($LASTEXITCODE -ge 8) {
    Write-Host "ERROR: copy failed" -ForegroundColor Red
    exit 1
}

git add -A
git diff --cached --quiet
if ($LASTEXITCODE -eq 0) {
    Write-Host "No changes, site is up to date."
    exit 0
}

Write-Host "=== Pushing to GitHub ==="
git commit -m ("update " + (Get-Date -Format "yyyy-MM-dd HH:mm"))
git push
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: push failed" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Done. The site will update in 1-3 minutes." -ForegroundColor Green