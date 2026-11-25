
$vault = "D:\ЗООПАРК\ЗООПАРК\ЗООПАРК ДОЛБОЕБОВ\Public"
$site = "D:\quartz-site"
$target = "$site\content\Public"

$ErrorActionPreference = "Stop"

try {
    if (-not (Test-Path -LiteralPath $vault)) {
        throw "Vault not found: $vault"
    }

    if (-not (Test-Path -LiteralPath $site)) {
        throw "Quartz site not found: $site"
    }

    Set-Location $site

    Write-Host "=== FULL OBSIDIAN SYNC ===" -ForegroundColor Cyan

    if (Test-Path -LiteralPath $target) {
        Remove-Item -LiteralPath $target -Recurse -Force
    }

    New-Item -ItemType Directory -Path $target -Force | Out-Null

    robocopy $vault $target /E /XD .obsidian .trash /R:2 /W:2

    if ($LASTEXITCODE -ge 8) {
        throw "Robocopy failed: $LASTEXITCODE"
    }

    Write-Host "=== CREATING FOLDER PAGES ===" -ForegroundColor Cyan

    $folders = @(Get-ChildItem -LiteralPath $target -Directory -Recurse)

    foreach ($folder in $folders) {
        $index = Join-Path $folder.FullName "index.md"

        if (-not (Test-Path -LiteralPath $index)) {
            $relative = $folder.FullName.Substring($target.Length).TrimStart('\')
            $depth = ($relative -split '\\').Count
            $links = @()

            Get-ChildItem -LiteralPath $folder.FullName -Directory |
                Sort-Object Name |
                ForEach-Object {
                    $links += "- [[Public/$relative/$($_.Name)/index|$($_.Name)]]"
                }

            $content = @(
                "# $($folder.Name)"
                ""
                "## Вложенные папки"
                ""
                $links
            )

            Set-Content -LiteralPath $index -Value $content -Encoding UTF8
        }
    }

    Write-Host "=== CLEANING OLD BUILD ===" -ForegroundColor Cyan

    if (Test-Path "$site\public") {
        Remove-Item "$site\public" -Recurse -Force
    }

    Write-Host "=== BUILDING QUARTZ ===" -ForegroundColor Cyan

    npx quartz build

    if ($LASTEXITCODE -ne 0) {
        throw "Quartz build failed"
    }

    Write-Host "=== GIT UPDATE ===" -ForegroundColor Cyan

    git add -A

    if ($LASTEXITCODE -ne 0) {
        throw "Git add failed"
    }

    git diff --cached --quiet

    if ($LASTEXITCODE -eq 0) {
        Write-Host "No changes detected." -ForegroundColor Green
        exit 0
    }

    git commit -m ("Full site update " + (Get-Date -Format "yyyy-MM-dd HH:mm"))

    if ($LASTEXITCODE -ne 0) {
        throw "Git commit failed"
    }

    git push

    if ($LASTEXITCODE -ne 0) {
        throw "Git push failed"
    }

    Write-Host ""
    Write-Host "FULL UPDATE COMPLETED!" -ForegroundColor Green
}
catch {
    Write-Host ""
    Write-Host "ERROR: $_" -ForegroundColor Red
    exit 1
}
