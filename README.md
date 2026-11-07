# 📱 VPN-Droid-Server

> **Ubah HP Android (Termux) apa pun menjadi Server VPN Pribadi (Trojan-WS + Cloudflare Tunnel) berkecepatan tinggi, tanpa root, tanpa port forwarding, dan tanpa IP Publik Statis!**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/Platform-Android%20Termux-brightgreen.svg)](https://termux.dev)
[![Architecture](https://img.shields.io/badge/Arch-ARM64%20%7C%20ARM32%20%7C%20x86__64-blue.svg)](https://github.com/XTLS/Xray-core)

---

## 🌟 Fitur Utama

- ⚡ **100% Native & Ringan:** Berjalan langsung di Termux Android (tanpa PRoot, tanpa Chroot, tanpa butuh akses Root). Hanya memakan RAM ~50 MB.
- 🛡️ **Bypass CGNAT & Tanpa Port Forwarding:** Menggunakan **Cloudflare Zero Trust Tunnel (QUIC)**. Server bisa diakses dari belahan dunia mana pun tanpa IP publik statis.
- 🔒 **Akses Dua Arah (Internet + LAN Lokal):**
  - Berselancar ke internet publik dengan IP koneksi HP Android server.
  - Mengakses perangkat lokal LAN di rumah (Router `192.168.x.1`, PC, NAS, Smart Home, dll.) dari luar rumah.
- 📋 **TUI Menu Interaktif (`vpnmenu`):** Antarmuka terminal modern dengan visual status *real-time*, ganti token/domain dinamis, reset password otomatis, dan live logs.
- 📷 **Auto QR Code & Link Nekobox:** Menghasilkan link `trojan://...` dan mencetak QR Code ASCII langsung di terminal Termux.
- 🔋 **Manajemen Daya Otomatis:** Terintegrasi dengan `termux-wake-lock` agar CPU HP tidak tidur saat layar dimatikan.

---

## 🚀 Cara Instalasi Cepat (One-Line Installer)

Buka aplikasi **Termux** di HP Android, lalu salin dan jalankan perintah satu baris ini:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/afcorpzone/vpn-droid-server/main/install.sh)"
```

### Yang Diminta Saat Instalasi:
1. **Token Cloudflare Tunnel:** String panjang dari Cloudflare Zero Trust Dashboard.
2. **Domain / Hostname:** Subdomain yang kamu gunakan (misal: `vpn.domainkamu.com`).

Skrip akan otomatis mendeteksi arsitektur CPU HP kamu, memasang Xray-core resmi, menyiapkan seluruh konfigurasi, mengunci CPU wake lock, dan menampilkan link serta QR Code akun Nekobox.

---

## 🛠️ Konfigurasi Cloudflare Zero Trust (Satu Kali Saja)

Agar domain kamu terhubung ke server di HP Android:

1. Buka [Cloudflare Zero Trust Dashboard](https://one.dash.cloudflare.com/) ➔ Masuk ke **Networks** ➔ **Tunnels**.
2. Buat Tunnel baru (atau pilih tunnel yang sudah ada) ➔ Klik **Configure**.
3. Masuk ke tab **Public Hostnames** ➔ Klik **Add a public hostname**.
4. Isi parameter berikut:
   - **Subdomain:** Subdomain kamu (misal: `vpn`)
   - **Domain:** Domain kamu (misal: `domainkamu.com`)
   - **Type:** `HTTP`
   - **URL:** `127.0.0.1:8080` *(atau `localhost:8080`)*
5. Klik **Save hostname**.

---

## 📱 Cara Menghubungkan di Klien (Nekobox)

1. Jalankan `vpn account` atau buka `vpnmenu` di Termux.
2. **Copy** link `trojan://...` atau **Scan QR Code** langsung dari aplikasi **Nekobox** di HP lain / PC.
3. Sambungkan VPN!

> [!TIP]
> **Akses Perangkat Lokal (LAN):**
> Di pengaturan aplikasi Nekobox, pastikan opsi **Bypass LAN** dimatikan agar kamu bisa membuka IP lokal rumah kamu (seperti `192.168.25.1` atau `192.168.25.99`) saat sedang berada di jaringan luar.

---

## 🖥️ Menu Kontrol Terminal (`vpnmenu`)

Ketik perintah berikut dari direktori mana saja di Termux:

```bash
vpnmenu
```
*(atau cukup ketik `vpn`)*

```text
╔══════════════════════════════════════════════════════╗
║          TERMUX ANDROID VPN SERVER MANAGER           ║
║         Trojan-WS + Cloudflare Zero Trust            ║
╠══════════════════════════════════════════════════════╣
║  Xray Core   : ● RUNNING (PID: 17055)
║  CF Tunnel   : ● RUNNING (PID: 17056)
║  Domain      : in.domainku.com
║  Port Lokal  : 127.0.0.1:8080
╠══════════════════════════════════════════════════════╣
║  [1] Nyalakan VPN (Start)                             ║
║  [2] Matikan VPN (Stop)                               ║
║  [3] Restart VPN Service                              ║
║  [4] Tampilkan Akun Trojan & QR Code                  ║
║  [5] Pantau Log Koneksi (Logs)                        ║
╟──────────────────────────────────────────────────────╢
║  [6] Ganti Token Cloudflare Tunnel                    ║
║  [7] Ganti Domain / Hostname                          ║
║  [8] Reset Password Trojan (Generate Otomatis)        ║
╟──────────────────────────────────────────────────────╢
║  [0] Keluar (Exit)                                    ║
╚══════════════════════════════════════════════════════╝
```

### Perintah CLI Cepat:
- `vpn status` : Cek status proses Xray & Cloudflared
- `vpn start`  : Menyalakan service VPN + Wake Lock
- `vpn stop`   : Mematikan service VPN + Release Wake Lock
- `vpn restart`: Me-restart seluruh service
- `vpn account`: Menampilkan info akun & QR Code
- `vpn log`    : Melihat 15 baris log aktivitas terbaru

---

## 🗑️ Cara Uninstall

Jika ingin menghapus instalasi ini secara bersih:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/afcorpzone/vpn-droid-server/main/uninstall.sh)
```

---

## 📄 Lisensi

Proyek ini dilisensikan di bawah [MIT License](LICENSE).
Dikembangkan untuk komunitas *self-hosted* & pengguna Android.
