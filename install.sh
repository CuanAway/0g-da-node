#!/bin/bash

# ========================================
#   Penginstal 0G Labs DA-Node oleh CuanAway
#   GitHub: https://github.com/CuanAway/0g-da-node
#   Discord: testway
#   Twitter: https://x.com/testwayyyy
# ========================================

# Fungsi untuk menampilkan teks dengan warna
tampilkan_teks_warna() {
    local warna=$1
    local teks=$2
    echo -e "${warna}${teks}\e[0m"
}

# Warna untuk teks
CYAN="\e[1;36m"
GREEN="\e[1;32m"
RED="\e[1;31m"

# Memuat logo dari file logo.sh
if [ -f "/root/0g-da-node/logo.sh" ]; then
    source /root/0g-da-node/logo.sh
else
    tampilkan_teks_warna "$RED" "❌ File logo.sh tidak ditemukan."
    exit 1
fi

# Menampilkan logo
tampilkan_logo

# Periksa apakah script dijalankan sebagai root
if [ "$(id -u)" != "0" ]; then
    tampilkan_teks_warna "$RED" "❌ Script ini harus dijalankan sebagai root atau menggunakan sudo."
    exit 1
fi

# Instal dependensi dasar
tampilkan_teks_warna "$CYAN" "🔧 Menginstal dependensi..."
apt-get update -y
apt-get install -y curl git docker.io golang netcat lz4 aria2 pv

# Instal RISC Zero
tampilkan_teks_warna "$CYAN" "🔧 Menginstal RISC Zero..."
curl -sSL https://risc0.github.io/ezkl/install.sh | bash
export PATH=$HOME/.risc0/bin:$PATH
rzup install

# Pastikan Docker berjalan
tampilkan_teks_warna "$CYAN" "🔧 Memeriksa Docker..."
systemctl start docker
systemctl enable docker
if ! systemctl is-active --quiet docker; then
    tampilkan_teks_warna "$RED" "❌ Docker gagal berjalan."
    exit 1
fi

# Pilih opsi instalasi
tampilkan_teks_warna "$CYAN" "ℹ️ Pilih komponen 0G untuk diinstal:"
tampilkan_teks_warna "$CYAN" "1. DA Node"
tampilkan_teks_warna "$CYAN" "2. DA Client"
tampilkan_teks_warna "$CYAN" "3. Storage Node"
read -p "Masukkan pilihan (1-3): " choice

case $choice in
    1)
        # Instalasi DA Node
        tampilkan_teks_warna "$CYAN" "🔧 Menginstal 0G DA Node..."
        bash <(curl -s https://file.winsnip.xyz/file/uploads/DA-NODE.sh)

        # Cek status dan ganti RPC jika error
        tampilkan_teks_warna "$CYAN" "🔧 Memeriksa status DA Node..."
        if ! systemctl is-active --quiet 0gda; then
            tampilkan_teks_warna "$CYAN" "ℹ️ Mengganti RPC ke https://0g-evm-rpc.murphynode.net..."
            sed -i 's|^eth_rpc_endpoint *= *".*"|eth_rpc_endpoint = "https://0g-evm-rpc.murphynode.net"|' $HOME/0g-da-node/config.toml
            grep '^eth_rpc_endpoint' $HOME/0g-da-node/config.toml
            systemctl restart 0gda
        fi

        # Ambil kunci publik
        tampilkan_teks_warna "$CYAN" "🔧 Menghasilkan kunci publik..."
        for i in {1..10}; do
            PUBLIC_KEY=$(grep -oP "Compressed Public Key: \K.*" $HOME/0g-da-node/da-node.log | head -n 1)
            if [ -n "$PUBLIC_KEY" ]; then
                break
            fi
            sleep 1
        done
        if [ -z "$PUBLIC_KEY" ]; then
            tampilkan_teks_warna "$RED" "❌ Gagal mendapatkan kunci publik."
            cat $HOME/0g-da-node/da-node.log
            exit 1
        fi
        ;;
    2)
        # Instalasi DA Client
        tampilkan_teks_warna "$CYAN" "🔧 Menginstal 0G DA Client..."
        bash <(curl -s https://file.winsnip.xyz/file/uploads/OG_DA_CLIENT.sh)
        PUBLIC_KEY="DA Client tidak memerlukan kunci publik terpisah."
        ;;
    3)
        # Instalasi Storage Node
        tampilkan_teks_warna "$CYAN" "🔧 Menginstal 0G Storage Node..."
        bash <(curl -s https://file.winsnip.xyz/file/uploads/STORAGE-NODE.sh)

        # Snapshot untuk Storage Node
        tampilkan_teks_warna "$CYAN" "🔧 Mengunduh snapshot Storage Node..."
        systemctl stop zgs
        cd $HOME
        rm -f storage_0gchain_snapshot.lz4
        aria2c -x 16 -s 16 -k 1M https://josephtran.co/storage_0gchain_snapshot.lz4
        rm -rf $HOME/0g-storage-node/run/db
        lz4 -c -d storage_0gchain_snapshot.lz4 | pv | tar -x -C $HOME/0g-storage-node/run
        systemctl restart zgs
        PUBLIC_KEY="Storage Node tidak memerlukan kunci publik terpisah."
        ;;
    *)
        tampilkan_teks_warna "$RED" "❌ Pilihan tidak valid."
        exit 1
        ;;
esac

# Tampilkan hasil
tampilkan_teks_warna "$GREEN" "✅ Instalasi selesai!"
tampilkan_teks_warna "$CYAN" "🔑 Kunci Publik CLI Node Anda: $PUBLIC_KEY"
tampilkan_teks_warna "$CYAN" "📜 Log real-time:"
case $choice in
    1) echo "tail -f $HOME/0g-da-node/da-node.log";;
    2) echo "docker logs -f 0g-da-client";;
    3) echo "tail -f ~/0g-storage-node/run/log/zgs.log.$(TZ=UTC date +%Y-%m-%d)";;
esac
tampilkan_teks_warna "$CYAN" "⚠️ Pastikan Anda telah stake minimal 30 token ke salah satu validator:"
tampilkan_teks_warna "$CYAN" "  - Winnode: https://testnet.itrocket.net/og/staking/0gvaloper1fnem6r4c3nxqcp5tcrpxgg4k2f5enj2scu90tr"
tampilkan_teks_warna "$CYAN" "  - MDP: https://testnet.itrocket.net/og/staking/0gvaloper1xvgs0cs8gz4hyg8qw63w5dddwylz55jg77metn"
tampilkan_teks_warna "$CYAN" "  - Catsmile: https://testnet.itrocket.net/og/staking/0gvaloper1xvgs0cs8gz4hyg8qw63w5dddwylz55jg77metn"
tampilkan_teks_warna "$CYAN" "  - OneNov: https://0g.exploreme.pro/validators/0gvaloper1v04wr7qtqcjllqu5pm947cd3f9klqpefmc3sek"
