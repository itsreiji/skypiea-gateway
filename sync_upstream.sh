#!/bin/bash

# Script Otomatis Sync Upstream (Versi Mac/Linux)
# Jalanin script ini kapan aja kamu mau update repo kamu.
# Cara pakai: 
# 1. chmod +x sync_upstream.sh
# 2. ./sync_upstream.sh

echo -e "\033[0;36m🚀 Memulai proses Sync Upstream...\033[0m"

# 1. Cek Remote Upstream
if ! git remote | grep -q "upstream"; then
    echo -e "\033[0;33m🔗 Menambahkan remote upstream...\033[0m"
    git remote add upstream https://github.com/BerriAI/litellm.git
else
    echo -e "\033[0;32m✅ Remote upstream sudah ada.\033[0m"
fi

# 2. Ambil update terbaru dari internet
echo -e "\033[0;33m⬇️  Mengambil data terbaru dari upstream...\033[0m"
git fetch upstream

# 3. Update Branch MAIN
echo -e "\033[0;33m🔄 Mengupdate branch MAIN...\033[0m"
git checkout main
if [ $? -ne 0 ]; then
    echo -e "\033[0;31mGagal pindah ke main. Pastikan tidak ada perubahan yang belum di-commit.\033[0m"
    exit 1
fi

git merge upstream/main
git push origin main

# 4. Update Branch SKYPIEA-DEV
echo -e "\033[0;33m🛠️  Mengupdate branch SKYPIEA-DEV...\033[0m"
git checkout skypiea-dev
if [ $? -ne 0 ]; then
    echo -e "\033[0;31mGagal pindah ke skypiea-dev.\033[0m"
    exit 1
fi

git merge main
if [ $? -ne 0 ]; then
    echo -e "\033[0;31m⚠️  ADA CONFLICT! Script berhenti.\033[0m"
    echo -e "\033[0;31mSilakan selesaikan conflict secara manual, lalu commit dan push.\033[0m"
    exit 1
fi

git push origin skypiea-dev

echo -e "\033[0;32m✅ Selesai! Semua branch sudah update.\033[0m"
