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

git merge upstream/main
git push origin main

# 4. Update Branch SKYPIEA-DEV
Write-Host "🛠️  Mengupdate branch SKYPIEA-DEV..." -ForegroundColor Yellow
git checkout skypiea-dev
if ($LASTEXITCODE -ne 0) { Write-Error "Gagal pindah ke skypiea-dev."; exit }

git merge main
if ($LASTEXITCODE -ne 0) { 
    Write-Error "⚠️  ADA CONFLICT! Script berhenti."
    Write-Host "Silakan selesaikan conflict secara manual, lalu commit dan push." -ForegroundColor Red
    exit 
}

git push origin skypiea-dev

Write-Host "✅ Selesai! Semua branch sudah update." -ForegroundColor Green
