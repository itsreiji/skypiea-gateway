# sync_upstream.ps1
# Syncs the local repository with the upstream repository, resetting the main branch.
# Implements self-preservation logic to backup itself and handle gitignore.

$ErrorActionPreference = "Stop"

function Log-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Green
}

function Log-Warn {
    param([string]$Message)
    Write-Host "[WARN] $Message" -ForegroundColor Yellow
}

function Log-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

# --- Self-Preservation Start ---
$scriptName = $MyInvocation.MyCommand.Name
$shScriptName = "sync_upstream.sh"
$tempDir = [System.IO.Path]::GetTempPath()
$backupScript = Join-Path $tempDir $scriptName
$backupShScript = Join-Path $tempDir $shScriptName

Log-Info "Starting self-preservation..."

# Backup scripts
if (Test-Path $scriptName) {
    Copy-Item $scriptName $backupScript -Force
    Log-Info "Backed up $scriptName to $backupScript"
}

if (Test-Path $shScriptName) {
    Copy-Item $shScriptName $backupShScript -Force
    Log-Info "Backed up $shScriptName to $backupShScript"
}

# Ensure .gitignore includes scripts
function Ensure-Gitignore {
    param([string]$file)
    $gitignore = ".gitignore"
    if (!(Test-Path $gitignore)) {
        New-Item $gitignore -ItemType File | Out-Null
    }
    
    $content = Get-Content $gitignore -ErrorAction SilentlyContinue
    if ($content -notcontains $file) {
        Log-Info "Adding $file to .gitignore"
        Add-Content $gitignore $file
    } else {
        Log-Info "$file already in .gitignore"
    }
}

Ensure-Gitignore $scriptName
Ensure-Gitignore $shScriptName

# Unstage scripts if tracked
$gitStatus = git ls-files --error-unmatch $scriptName 2>&1
if ($LASTEXITCODE -eq 0) {
    Log-Warn "Unstaging $scriptName"
    git rm --cached $scriptName | Out-Null
}

$gitStatus = git ls-files --error-unmatch $shScriptName 2>&1
if ($LASTEXITCODE -eq 0) {
    Log-Warn "Unstaging $shScriptName"
    git rm --cached $shScriptName | Out-Null
}
# --- Self-Preservation End ---

# Fetch upstream
Log-Info "Fetching upstream..."
$upstreamUrl = git remote get-url upstream 2>&1
if ($LASTEXITCODE -ne 0) {
    Log-Error "Remote 'upstream' not found. Please add it with 'git remote add upstream <url>'."
    exit 1
}
git fetch upstream

# Determine main branch
$mainBranch = ""
if (git show-ref --verify --quiet refs/remotes/upstream/main) {
    $mainBranch = "main"
} elseif (git show-ref --verify --quiet refs/remotes/upstream/master) {
    $mainBranch = "master"
} else {
    Log-Error "Could not detect 'main' or 'master' branch on upstream."
    exit 1
}

Log-Info "Detected main branch: $mainBranch"

# Switch to main branch locally
if (git show-ref --verify --quiet refs/heads/$mainBranch) {
    Log-Info "Switching to local $mainBranch..."
    git checkout $mainBranch
} else {
    Log-Info "Creating local $mainBranch from upstream/$mainBranch..."
    git checkout -b $mainBranch upstream/$mainBranch
}

# Reset to upstream
Log-Info "Resetting $mainBranch to upstream/$mainBranch..."
git reset --hard upstream/$mainBranch

# Delete other local branches
Log-Info "Cleaning up other local branches..."
$branches = git branch | ForEach-Object { $_.Trim().TrimStart('* ') }
foreach ($branch in $branches) {
    if ($branch -ne $mainBranch -and $branch -ne "") {
        Log-Info "Deleting branch: $branch"
        git branch -D $branch
    }
}

# --- Restoration Start ---
Log-Info "Restoring scripts from backup..."
if (Test-Path $backupScript) {
    Copy-Item $backupScript $scriptName -Force
    Log-Info "Restored $scriptName"
}

if (Test-Path $backupShScript) {
    Copy-Item $backupShScript $shScriptName -Force
    Log-Info "Restored $shScriptName"
}

# Re-apply gitignore check
Ensure-Gitignore $scriptName
Ensure-Gitignore $shScriptName

# Remove temp files (optional, but good practice)
Remove-Item $backupScript -ErrorAction SilentlyContinue
Remove-Item $backupShScript -ErrorAction SilentlyContinue
# --- Restoration End ---

Log-Info "Sync complete! You are now on $mainBranch, identical to upstream/$mainBranch."