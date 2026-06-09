[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$HtmlFile,

    [Parameter(Mandatory = $true, Position = 1)]
    [string]$PublishFolder
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

function Stop-WithMessage {
    param([string]$Message)
    [Console]::Error.WriteLine($Message)
    exit 1
}

$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

try {
    $sourceFile = (Resolve-Path -LiteralPath $HtmlFile).Path
}
catch {
    Stop-WithMessage "HTML file not found: $HtmlFile"
}

if ([System.IO.Path]::GetExtension($sourceFile) -ine ".html") {
    Stop-WithMessage "The input file must have an .html extension: $sourceFile"
}

if ($PublishFolder -cnotmatch "^[a-z0-9]+(?:-[a-z0-9]+)*$") {
    Stop-WithMessage "The publish folder may contain only lowercase letters, numbers, and hyphens. Example: weekly-dashboard-20260601-0607"
}

$targetFolder = Join-Path $repositoryRoot $PublishFolder
$targetIndex = Join-Path $targetFolder "index.html"

if (Test-Path -LiteralPath $targetFolder) {
    Write-Warning "Publish folder already exists: $targetFolder"
    $confirmation = Read-Host "Type YES to overwrite its index.html"
    if ($confirmation -cne "YES") {
        Write-Host "Publishing cancelled. Existing files were not changed."
        exit 0
    }
}
else {
    New-Item -ItemType Directory -Path $targetFolder | Out-Null
}

Push-Location $repositoryRoot
try {
    $gitRoot = (& git rev-parse --show-toplevel 2>$null).Trim()
    if (-not $gitRoot) {
        Stop-WithMessage "Not a Git repository: $repositoryRoot"
    }

    if ([System.IO.Path]::GetFullPath($gitRoot) -ne [System.IO.Path]::GetFullPath($repositoryRoot)) {
        Stop-WithMessage "The script is not located directly inside the community-dashboard repository."
    }

    Copy-Item -LiteralPath $sourceFile -Destination $targetIndex -Force

    & git add -- $PublishFolder
    if ($LASTEXITCODE -ne 0) {
        Stop-WithMessage "git add failed."
    }

    & git diff --cached --quiet -- $PublishFolder
    if ($LASTEXITCODE -eq 0) {
        Write-Host "No content changes were found. Nothing was committed."
        exit 0
    }
    if ($LASTEXITCODE -ne 1) {
        Stop-WithMessage "Unable to inspect the staged changes."
    }

    $commitDate = Get-Date -Format "yyyyMMdd"
    $commitPrefix = -join ([char[]](0x66F4, 0x65B0, 0x5468, 0x62A5))
    $commitMessage = "$commitPrefix-$commitDate"

    & git commit -m $commitMessage -- $PublishFolder
    if ($LASTEXITCODE -ne 0) {
        Stop-WithMessage "git commit failed."
    }

    & git push
    if ($LASTEXITCODE -ne 0) {
        Stop-WithMessage "git push failed. The commit remains local; check the network and GitHub authentication, then run git push."
    }

    $pagesUrl = "https://jackluliqiang-del.github.io/community-dashboard/$PublishFolder/"
    Write-Host ""
    Write-Host "Published: $pagesUrl" -ForegroundColor Green
}
finally {
    Pop-Location
}
