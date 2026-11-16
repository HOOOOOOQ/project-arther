# Audit & laporan fase 01

## Audit awal

- Branch awal hanya berisi `README.md` (judul) dan `.git`; tidak ada place, script, instance, dependensi, atau tes untuk diaudit. Tidak ada akses Studio/MCP pada lingkungan ini; tidak mungkin memeriksa instance dalam place pengguna yang tidak disediakan.
- Struktur dibuat sebagai proyek Rojo yang memisahkan shared, server services dan client controller. Ini struktur awal yang dapat diperluas, bukan seluruh struktur akhir dari master prompt. Folder/layanan untuk fitur mendatang sengaja tidak dibuat kosong.

## Diimplementasikan

- Skema profil v1 (level, XP, gold, Warrior), pemeriksaan nilai, XP multi-level, cap level dan atribut turunan. Health Humanoid disesuaikan saat spawn dan naik level.
- DataStore `UpdateAsync` dengan retry, lease 180 detik, autosave 60 detik, save ketika keluar dan BindToClose, serta penolakan profil rusak/versi tidak dikenal. Jika load gagal tidak ada profil default yang digunakan untuk menimpa data. Write memverifikasi token dan lease; kegagalan yang terdeteksi dilog dan tidak dianggap sukses. Mode Studio nonpersisten tersedia sebagai opt-in eksplisit.
- Server membuat dan memvalidasi permintaan snapshot yang dibatasi frekuensinya; client tidak bisa mengirim jumlah EXP atau gold. Papan latihan memeriksa karakter hidup, jarak dan cooldown di server.
- UI awal: status loading tanpa persentase, menu, kamera menu statis, HUD health/XP/gold, panel atribut, setting motion lokal, notifikasi sederhana, ukuran responsif; kontrol karakter standar Roblox. Tidak ada klaim bahwa kelas/atribut yang belum dipakai telah menjadi gameplay.
- Greybox Eldoria yang dihasilkan server: terrain, sungai, jembatan, plaza, rumah terbuka, pohon, spawn, lighting dan papan latihan. StreamingEnabled di konfigurasi place.

## Hasil tes di lingkungan ini

- Luau 0.747: semua 9 file source dan 1 tes berhasil dikompilasi dengan `luau-compile`.
- `tests/progression.test.luau`: lulus untuk threshold, rollover, beberapa level, cap, penolakan data invalid dan copy profil.
- `default.project.json`: sintaks JSON valid. Belum divalidasi dengan Rojo atau Roblox Studio.
- Kesalahan yang ditemukan: ekspektasi tes multi-level awal menggunakan 500 XP untuk tiga kenaikan, padahal membutuhkan 600 XP dari level 2; diperbaiki menjadi 650 XP dengan sisa 50. Review kode juga memperbaiki sesi yang bisa tetap diperpanjang setelah final save gagal dan tinggi air yang menutupi jembatan. Kedua perbaikan terakhir belum diuji di engine.
- Pengunduhan binary release Luau terhalang host release-assets, sehingga Luau dibangun dari source untuk tes lokal; ini bukan masalah kode game.

## Wajib diuji di Studio sebelum fase berikutnya

1. Build/sync Rojo ke place kosong, buka Output dan periksa error, warning, instance dan generator terrain; cek kamera, respawn serta viewport PC, tablet, ponsel landscape dan portrait.
2. Dengan experience uji terbit dan akses API aktif: masuk, gunakan papan, periksa cooldown, naik level, keluar, masuk ulang dan verifikasi level/XP/gold. Uji dua client dan cross-server untuk memastikan sesi ganda ditolak; uji rejoin setelah lease kedaluwarsa.
3. Uji kegagalan load/save, gangguan DataStore, PlayerRemoving saat load, autosave bersamaan dengan shutdown, dan recovery. Jangan menggunakan data produksi saat pengujian. DataStore di jaringan nyata, perilaku throttling dan race belum diuji.
4. Coba request remote berulang/argumen tidak valid, prompt dari jarak jauh dan karakter mati. Periksa profiling dan kebersihan koneksi, lalu lakukan playtest mobile/PC sesungguhnya.

## Batasan dan langkah berikutnya

Fase 01 baru implementasi awal, belum lulus QA Studio dan belum siap produksi. Belum ada sistem penanganan migrasi schema lama, backup/recovery, aksesibilitas penuh atau observability produksi. Session lease dan save belum terbukti terhadap semua kegagalan platform. Selanjutnya: selesaikan QA di atas, perbaiki masalah yang ditemukan, lalu bangun sistem inventory/equipment dan quest yang tersimpan sebelum memperluas combat/AI dan dunia. Gunakan aset dan animation/audio ID yang sah hanya setelah tersedia.
