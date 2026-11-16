# PROJECT AETHER — prototipe Eldoria

Vertical slice Roblox Adventure RPG berbasis Luau dan Rojo. **Belum siap rilis:** kode dan build dapat diverifikasi di luar Roblox, tetapi runtime, UI, DataStore, dan multiplayer belum diuji di Roblox Studio. Tidak ada akses langsung ke place Roblox pengguna dari lingkungan ini.

## Menjalankan di Studio

1. Pasang [Rojo 7](https://rojo.space/) CLI dan plugin Studio. Dari root repository jalankan `rojo build default.project.json -o Aether.rbxlx`, lalu buka hasilnya di Studio. Alternatif: `rojo serve default.project.json` dan sambungkan plugin ke **place kosong**.
2. Gunakan place kosong tanpa baseplate, spawn, terrain atau folder `Workspace.AetherWorld`. Generator mengubah terrain di sekitar origin dan menolak mengganti folder dunia yang sudah ada. Backup place apa pun sebelum mencoba; dunia hanya dihasilkan saat server berjalan.
3. Untuk tes penyimpanan, publish **experience uji terpisah**, lalu aktifkan Game Settings → Security → **Enable Studio Access to API Services**. Studio dapat mengakses DataStore experience yang sama; jangan bereksperimen dengan data produksi.
4. Play → **Mulai Petualangan**. Papan di utara plaza memberi 35 EXP dan 12 gold, dengan cooldown 20 detik per pemain. Di PC tahan E untuk prompt, tekan C untuk karakter dan I untuk tas. Pada mobile gunakan joystick, jump, prompt bawaan Roblox, serta tombol UI yang disediakan. Kedua tonic awal dapat digunakan dari tas ketika health belum penuh; item dikonsumsi dan healing diputuskan server.
5. Untuk mencoba di Studio tanpa DataStore, ubah `STUDIO_EPHEMERAL` di `PlayerDataService` menjadi `true`. Ini **tidak menyimpan data**, hanya aktif di Studio, dan harus dikembalikan ke `false` sebelum uji penyimpanan. Default-nya kegagalan load menolak pemain, bukan menimpa profil dengan data baru.

Data hanya dianggap tersimpan saat `UpdateAsync` berhasil. Bila final save gagal, progres sejak save terakhir bisa hilang; lease yang tidak berhasil dilepas akan kedaluwarsa. Setelah server terputus mendadak, login ulang mungkin perlu menunggu hingga sekitar 180 detik. Periksa Output server jika load/save gagal.

## Struktur instance

```
default.project.json                           Rojo / Workspace.StreamingEnabled
src/ReplicatedStorage/Shared/                  Config, Progression, ItemConfig
src/ServerScriptService/ServerBootstrap.server.luau
src/ServerScriptService/Services/              data, schema, lease, player, inventory, world
src/StarterPlayer/StarterPlayerScripts/ClientBootstrap.client.luau
src/StarterPlayer/StarterPlayerScripts/Controllers/UIController.luau
```

Semua file `.luau` selain bootstrap adalah ModuleScript; `.server.luau` menjadi Script dan `.client.luau` LocalScript. Server membuat `ReplicatedStorage.AetherRemotes` (`State`, `RequestState`, `UseItem`), `Workspace.AetherWorld` dan objek lingkungan. Client membuat `PlayerGui.AetherUI`. State, penggunaan item, training, EXP dan gold dikendalikan server; client hanya meminta snapshot profilnya atau meminta penggunaan item yang dikenali.

Schema profil v2 menyimpan level, EXP, gold, kelas, tonic dan jumlah latihan; profil v1 yang valid dimigrasikan ke v2 saat load. Profil/record dengan field atau versi yang tidak dikenal ditolak agar tidak diam-diam terhapus. Mana adalah atribut sesi yang diisi saat spawn/level naik; **belum ada skill yang memakainya**. Tracker menunjukkan aktivitas latihan, bukan sistem quest penuh. Pengaturan reduced motion lokal dan tidak tersimpan. Dua tonic adalah persediaan awal sekali saja, belum ada sistem restock.

Eldoria adalah **greybox** procedural, bukan peta realistis final: rumah, pasar, papan lokasi calon NPC, area latihan, jalan, dua jembatan, sungai dan pintu hutan. Belum ada NPC interaktif atau toko. Tidak ada ID audio/animasi/aset eksternal palsu. Combat, skill, equipment, quest lengkap, dungeon, boss, party, cuaca, map dan audio belum diimplementasikan.

## Pengujian lokal

- `./tests/run.sh` membutuhkan `luau`, `luau-compile` dan Python 3 pada PATH; menjalankan tes murni, simulasi dengan fake, dan kompilasi.
- `./tests/verify-rojo.sh` membutuhkan `rojo` dan Python 3; membangun place sementara dan memeriksa hirarki, source, pola dependency statis, dan pemisahan client/server secara terbatas.
- Hasil dan prosedur validasi terbaru: [docs/PHASE_02_RUNTIME_VALIDATION.md](docs/PHASE_02_RUNTIME_VALIDATION.md); laporan sebelumnya: [docs/PHASE_02.md](docs/PHASE_02.md). Tes CLI dan fake tidak menggantikan Studio.
