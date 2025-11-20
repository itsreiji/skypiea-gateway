# Script Otomatis Sync Upstream (Versi Gratis/Lokal)
# Jalanin script ini kapan aja kamu mau update repo kamu.

Write-Host "🚀 Memulai proses Sync Upstream..." -ForegroundColor Cyan

# 1. Cek Remote Upstream
$upstream = git remote get-url upstream 2>$null
if (-not $upstream) {
    Write-Host "🔗 Menambahkan remote upstream..." -ForegroundColor Yellow
    git remote add upstream https://github.com/BerriAI/litellm.git
} else {
    Write-Host "✅ Remote upstream sudah ada." -ForegroundColor Green
}

# 2. Ambil update terbaru dari internet
Write-Host "⬇️  Mengambil data terbaru dari upstream..." -ForegroundColor Yellow
git fetch upstream

# 3. Update Branch MAIN
Write-Host "🔄 Mengupdate branch MAIN..." -ForegroundColor Yellow
git checkout main
if ($LASTEXITCODE -ne 0) { Write-Error "Gagal pindah ke main. Pastikan tidak ada perubahan yang belum di-commit."; exit }

Write-Host "📋 Mengecek perubahan yang akan di-merge dari upstream/main..." -ForegroundColor Cyan
git log --oneline --graph upstream/main..HEAD 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "ℹ️  Tidak ada perubahan baru dari upstream." -ForegroundColor Blue
} else {
    Write-Host "📊 File yang akan terpengaruh:" -ForegroundColor Magenta
    git diff --stat upstream/main..HEAD
    Write-Host ""
}

git merge upstream/main
if ($LASTEXITCODE -eq 0) {
    Write-Host "📝 Commit yang berhasil di-merge:" -ForegroundColor Green
    git log --oneline -5 HEAD~1..HEAD
    Write-Host ""
}

git push origin main

# 4. Update Branch SKYPIEA-DEV
Write-Host "🛠️  Mengupdate branch SKYPIEA-DEV..." -ForegroundColor Yellow
git checkout skypiea-dev
if ($LASTEXITCODE -ne 0) { Write-Error "Gagal pindah ke skypiea-dev."; exit }

Write-Host "📋 Mengecek perubahan yang akan di-merge dari main..." -ForegroundColor Cyan
git log --oneline --graph main..HEAD 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "ℹ️  Branch skypiea-dev sudah up-to-date dengan main." -ForegroundColor Blue
} else {
    Write-Host "📊 File yang akan terpengaruh:" -ForegroundColor Magenta
    git diff --stat main..HEAD
    Write-Host ""
}

git merge main
if ($LASTEXITCODE -ne 0) {
    Write-Error "⚠️  ADA CONFLICT! Script berhenti."
    Write-Host "Silakan selesaikan conflict secara manual, lalu commit dan push." -ForegroundColor Red
    exit
} else {
    Write-Host "📝 Commit yang berhasil di-merge:" -ForegroundColor Green
    git log --oneline -5 HEAD~1..HEAD
    Write-Host ""
}

git push origin skypiea-dev

Write-Host "✅ Selesai! Semua branch sudah update." -ForegroundColor Green
