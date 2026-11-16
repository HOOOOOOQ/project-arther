# Laporan verifikasi fase 01 & pengembangan fase 02/03

## Audit dan keputusan

Audit meliputi README, laporan fase 01, mapping Rojo dan semua source/test. Struktur asli dipertahankan: konfigurasi/progression di ReplicatedStorage, services otoritatif di server, bootstrap dan controller UI di client, world runtime di Workspace. Rojo 7.6.1 membangun place dan pemeriksaan XML mengonfirmasi 13 script berkelas dan berlokasi sesuai source, termasuk StreamingEnabled. Dependency yang memakai pola require statis pada source saat ini diperiksa terhadap hierarchy hasil build. Ini bukan validasi setiap API engine atau dependency dinamis.

Alur data: DataStore `AetherProfiles_v1` tetap dipakai; v1 yang valid dimigrasikan ke schema v2 dalam transaksi acquire. v2 berisi inventory tonic dan trainingSessions. Data tidak dikenal atau rusak ditolak, bukan dihapus. Lease 180 detik, autosave 60 detik, retry, validasi kepemilikan sebelum write, PlayerRemoving dan BindToClose tetap ada. Session lease dan penyimpanan nyata masih memerlukan pengujian Roblox. Tonic hanya diproses server, memeriksa item yang dikenal, rate limit, health, jumlah, dan karakter hidup.

## File baru

- `src/ReplicatedStorage/Shared/ItemConfig.luau`
- `src/ServerScriptService/Services/InventoryRules.luau`, `InventoryService.luau`, `ProfileLease.luau`
- `tests/inventory.test.luau`, `tests/profile_lease.test.luau`, `tests/verify_build.py`, `tests/verify-rojo.sh`
- `docs/PHASE_02.md`

## File diubah

- `README.md`, `src/ReplicatedStorage/Shared/Config.luau`
- `src/ServerScriptService/ServerBootstrap.server.luau`, `Services/PlayerDataService.luau`, `PlayerService.luau`, `ProfileSchema.luau`, `WorldService.luau`
- `src/StarterPlayer/StarterPlayerScripts/Controllers/UIController.luau`, `tests/run.sh`

Mapping `default.project.json`, progression, client bootstrap dan laporan fase 01 dipertahankan.

## Perbaikan dan implementasi

- Penambahan inventory sebelumnya akan terbuang oleh `ProfileSchema.copy`; kini migrasi v1 → v2 diuji dan snapshot mencakup field baru. Field/lease tak dikenal ditolak agar data tidak ditimpa secara diam-diam.
- Validasi gagal saat final save sebelumnya dapat meninggalkan sesi di memori. Sesi ditutup tanpa mengklaim save sukses; pada autosave pemain dikeluarkan. Validasi dilakukan sebelum copy agar field inventory rusak tidak membuat copy gagal terlebih dahulu.
- Pengiriman state memeriksa apakah pemain masih terhubung setelah operasi yang bisa yield. UI memantau pergantian CurrentCamera, membatalkan spinner pada error, dan memudarkan seluruh menu, bukan hanya latar. Tween bar, tombol, kamera dan notifikasi dikelola/dibatalkan saat diperbarui.
- Ditambahkan HUD HP/mana/EXP, portrait, gold, jumlah latihan, panel karakter/tas/settings, animasi loading tanpa persen palsu, notifikasi, kamera menu dan tombol untuk touch. Mana adalah nilai sesi server, belum ada skill; tas baru berisi tonic. Quest tracker adalah tracker aktivitas latihan sementara.
- Dunia diperluas dengan pasar, rumah atap miring, lokasi calon NPC, area latihan, rute ke hutan, dua jembatan dengan ramp, lampu, terrain, atmosfer, sumur dan tanda. Seluruhnya masih greybox buatan server, bukan NPC atau aset realistis final.

## Hasil pengujian otomatis

- **Lulus:** Luau 0.747 kompilasi 13 source dan 3 file test.
- **Lulus:** progression/schema, migrasi v1, lease acquire/renew/release/expiry/owner, dan konsumsi tonic (termasuk health penuh/mati dan jumlah habis).
- **Lulus:** `rojo build` dengan Rojo 7.6.1; XML diperiksa untuk path/class/source 13 script, StreamingEnabled, pola `require` statis, dan tidak adanya referensi langsung DataStore/server service dari client/shared.
- **Gagal saat hasil akhir:** tidak ada pada tes otomatis yang dijalankan. Tidak ada klaim bahwa kode Roblox telah berjalan di engine.

## Checklist wajib Roblox Studio

- [ ] Build dan buka place kosong; jalankan Play, periksa Output server/client dan tidak ada missing module, infinite yield, error API, atau warning.
- [ ] Cek loading menunggu game dan profil, animasi, kamera menu → gameplay, respawn, health/mana/EXP, portrait, notifikasi, panel/setting dan tooltip/prompt; jangan menganggap spinner sebagai persentase loading.
- [ ] Uji PC, tablet dan smartphone termasuk landscape/portrait, perubahan viewport dan CurrentCamera; cek keterbacaan, overlap HUD, joystick, jump, kamera dan ProximityPrompt.
- [ ] Uji papan dari dekat/jauh, saat mati, cooldown, reward aktual, level-up, tampilan tracker dan jumlah tersimpan. Pastikan pemain lain tidak bisa mengubah EXP/gold melalui remote.
- [ ] Uji tonic saat terluka, full HP, mati dan habis; spam/argumen salah melalui remote; periksa nilai health dan jumlah item di server, termasuk dua client.
- [ ] Pada **experience uji terpisah** dengan API aktif, verifikasi load/save/rejoin, v1 migration dan item/count setelah restart. Siapkan data v1 hanya di test store; backup sebelum eksperimen. Pastikan mode ephemeral mati saat tes persistensi.
- [ ] Uji gangguan DataStore, retry, lock asing/expired, rejoin lintas server, PlayerRemoving saat load, autosave serentak shutdown, validasi gagal, dan lease yang hilang. Jangan mengasumsikan semua data terselamatkan pada outage; simpan hanya dianggap sukses setelah konfirmasi platform.
- [ ] Jelajahi sungai dan kedua ramp jembatan, interior rumah, pasar, hutan dan area latihan; cek tabrakan, spawn, terrain, pencahayaan, StreamingEnabled, performa dan memori pada perangkat nyata.

## Tersisa

Belum ada pengujian runtime Studio atau public playtest; belum production-ready. Inventory masih satu consumable tanpa restock/sort/equipment; belum ada sistem quest sesungguhnya, combat, skill, NPC, shop, sisa zona, audio, animasi aset, party, minimap dan penyimpanan settings. Mana belum digunakan gameplay. Visual adalah prototipe, bukan environment realistis final; kualitas dan performa mobile belum terverifikasi. Lakukan checklist dahulu, lalu prioritaskan perbaikan temuan, sistem quest dan gameplay secara bertahap.
