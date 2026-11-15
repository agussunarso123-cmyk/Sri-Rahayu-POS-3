# Sri Rahayu POS

Aplikasi kasir Android untuk usaha kuliner Sri Rahayu.

## Fitur yang sudah masuk ke kode
- Dashboard penjualan dan ringkasan transaksi.
- Kasir dengan keranjang dan validasi stok.
- Pembayaran Tunai, QRIS, Transfer bank, dan E-Wallet.
- Input uang tunai diterima dan hitung kembalian otomatis.
- Katalog menu, kategori, harga, stok, dan foto dari galeri.
- Riwayat transaksi menampilkan metode pembayaran.
- Pemilihan dan penambahan cabang.
- Penyimpanan lokal agar kasir dasar tetap bisa digunakan tanpa internet.

## Tahap pengembangan berikutnya
1. Stok terpisah untuk setiap cabang dan mutasi/transfer stok.
2. Bahan baku, resep, dan perhitungan harga pokok penjualan (HPP).
3. Pengeluaran, pembelian bahan, pemasok, dan laporan laba-rugi.
4. Meja, pesanan belum dibayar (open bill), dan cetak struk Bluetooth.
5. Login PIN karyawan, peran owner/manajer/kasir, dan tutup shift.
6. Database cloud, sinkronisasi antarperangkat, dan backup.

## Catatan penting
Versi ini belum menjadi sistem cloud multi-perangkat. Data transaksi dan stok saat ini tersimpan di perangkat Android yang digunakan. QRIS, transfer, dan e-wallet pada tahap ini adalah pencatatan metode pembayaran, bukan integrasi/payment gateway yang memverifikasi pembayaran otomatis. Sinkronisasi cloud membutuhkan konfigurasi backend dan kredensial proyek.

## Membuat APK
1. Buka tab Actions: https://github.com/agussunarso123-cmyk/Sri-Rahayu-POS-3/actions
2. Pilih workflow **Build Sri Rahayu POS APK**.
3. Tekan **Run workflow** atau tunggu build otomatis setelah commit.
4. Jika workflow berhasil, buka run tersebut dan unduh artifact **sri-rahayu-pos-release**.
5. Ekstrak ZIP lalu pasang file `app-release.apk` di Android.
