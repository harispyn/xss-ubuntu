Cara Penggunaan
Siapkan Server:
Miliki server VPS dengan Ubuntu 22.04.
Arahkan nama domain (misal xss.yourdomain.com) ke IP address server Anda.
Download Script:
Login ke server Anda via SSH.
Download script menggunakan wget atau curl.
bash

Line Wrapping

Collapse
Copy
1
2
3
wget https://raw.githubusercontent.com/your-repo/.../install_xsshunter.sh 
# atau salin-tempel langsung ke editor seperti nano
nano install_xsshunter.sh
Jalankan Script:
Berikan izin eksekusi pada script.
bash

Line Wrapping

Collapse
Copy
1
chmod +x install_xsshunter.sh
Jalankan script dengan sudo.
bash

Line Wrapping

Collapse
Copy
1
sudo bash install_xsshunter.sh
Ikuti Instruksi:
Script akan meminta Anda untuk memasukkan nama domain, email, dan password admin.
Tunggu hingga proses instalasi selesai. Prosesnya akan memakan waktu beberapa menit tergantung kecepatan server.
Selesai:
Jika tidak ada error, Anda akan melihat pesan sukses di akhir proses.
Buka browser dan kunjungi domain Anda (misal https://xss.yourdomain.com).
Login dengan email dan password yang Anda buat saat instalasi.
Penjelasan Singkat Script
Bagian Awal: Mendefinisikan warna untuk output agar lebih mudah dibaca dan memeriksa apakah script dijalankan sebagai root.
Input User: Meminta data penting (domain, email, password) yang akan digunakan dalam konfigurasi.
Update & Dependencies: Memperbarui sistem dan menginstall paket-paket dasar yang diperlukan seperti git dan curl.
Node.js: Menambahkan repository resmi NodeSource untuk mendapatkan versi Node.js LTS terbaru (18.x) dan menginstallnya.
MongoDB: Menambahkan repository resmi MongoDB dan menginstall mongodb-org. Layanan MongoDB kemudian diaktifkan dan dijalankan.
Nginx & PM2: Menginstall Nginx untuk web server dan PM2 untuk manajemen proses Node.js.
Setup Aplikasi: Meng-klon kode sumber XSSHunter Express dari GitHub, menginstall dependencies-nya (npm install), dan membuat file .env yang berisi semua variabel konfigurasi penting (koneksi database, domain, secret key, dll).
Konfigurasi PM2: Membuat file ecosystem.config.js untuk menjalankan aplikasi secara stabil di background dan memastikannya otomatis restart jika crash.
Konfigurasi Nginx: Membuat file konfigurasi Nginx yang bertindak sebagai reverse proxy. Nginx akan menerima lalu lintas dari internet (port 80/443) dan meneruskannya ke aplikasi Node.js yang berjalan di localhost:3000.
SSL (Certbot): Menginstall Certbot dan secara otomatis meminta serta memasang sertifikat SSL/TLS gratis dari Let's Encrypt untuk domain Anda. Ini juga akan mengatur redirect otomatis dari HTTP ke HTTPS.
Penyelesaian: Menampilkan pesan sukses dan informasi login kepada pengguna.


