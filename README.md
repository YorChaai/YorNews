# YorNews

Direktori situs berita lintas kategori untuk Flutter Android dan web.

## Menjalankan

```powershell
flutter pub get
flutter run -d chrome
flutter run -d android
```

Daftar situs berada di `lib/main.dart`. Setiap entri menyimpan nama, URL, negara asal media, kategori, dan deskripsi singkat. Filter Nasional/Internasional mengikuti negara asal media; filter Bola, F1, MotoGP, dan esports mengikuti kategori situs.

Proyek ini tidak memakai backend karena kontennya berupa daftar tautan statis. Tekan kartu untuk membuka situs sumber di browser. Logo situs dimuat sebagai favicon; huruf inisial menjadi pengganti jika favicon gagal dimuat.
