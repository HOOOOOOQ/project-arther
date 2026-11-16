# PROJECT AETHER — validasi fase 02

Status: **BELUM SELESAI / BLOCKED ON ROBLOX STUDIO**. Tidak ada Roblox Studio atau engine di lingkungan ini. Tidak ada pengujian gameplay Roblox, visual, fisika, service DataStore Roblox, multiplayer nyata, atau perangkat yang telah dijalankan. Jangan melanjutkan fase berikutnya atau merilis berdasarkan hasil CLI ini.

## Passed tests — yang benar-benar dijalankan

- Rojo 7.6.1 `build default.project.json`: berhasil membuat `.rbxlx`. Hasil dibuka sebagai XML dan diperiksa dengan `tests/verify_build.py`, **bukan dibuka di Studio**. Terdapat 13 script pada path/class yang diharapkan, isi source sama, `Workspace.StreamingEnabled=true`; pemeriksaan pola require statis dan pemisahan client/server lulus. `PlayerGui.AetherUI` dibuat oleh LocalScript saat runtime, bukan objek statis `StarterGui` di file build.
- Luau 0.747: kompilasi 13 source dan 3 tes Luau; progression, validasi schema, migrasi v1, operasi lease dan aturan tonic lulus.
- `tests/player_data_mock.py`: menjalankan source `PlayerDataService` dengan DataStore, waktu, HTTP, task dan Player tiruan. Kasus retry, migrasi, lock pemilik lain, batal saat load, kegagalan save, lease hilang, profil invalid dan waiter release bersamaan lulus. **Ini bukan DataStore Roblox dan tidak menguji scheduler Roblox.**
- `tests/server_flow_mock.py`: menjalankan `WorldService`, `PlayerService`, `InventoryService` dengan fake objek/event: reward papan, jarak, karakter mati, cooldown, level, HP/mana, tonic dan isolasi data dua pemain tiruan lulus. **Tidak mensimulasikan replikasi, physics, terrain atau dua client Roblox.**
- `tests/ui_flow_mock.py`: menjalankan `UIController` dengan fake instance/event/tween: pembuatan UI di fake PlayerGui, loading, menu, panel, transisi play, pembaruan HUD, permintaan tonic dan reduced-motion lulus. **Tidak merender UI atau mensimulasikan perilaku engine/perangkat.**
- `git diff --check`: lulus untuk diff yang dilacak.

Perintah ulang: `./tests/run.sh` (Python 3, Luau dan luau-compile pada PATH) dan `./tests/verify-rojo.sh` (Rojo dan Python 3). Build manual: `rojo build default.project.json -o Aether.rbxlx`.

## Failed tests dan bug yang diperbaiki

- Regresi load saat `PlayerRemoving` terjadi sebelum `Player.Parent` dilepas awalnya **gagal pada fake**: sesi dapat muncul setelah release dan memperpanjang lease. Kini bootstrap mencatat lifecycle/removal, load yang dibatalkan melepaskan lease, dan shutdown menunggu load in-flight hingga deadline. Tes tiruan lulus setelah perbaikan. Deadline tetap terbatas; bila platform tidak merespons, pelepasan tidak dijamin.
- Regresi dua release bersamaan awalnya **gagal pada fake**: waiter dapat mengembalikan sukses walau final save sebelumnya gagal. Kini waiter menerima status final save, termasuk kegagalan tak terkonfirmasi. Tes tiruan lulus setelah perbaikan.
- Audit UI menemukan keyboard C/I dapat membuka panel sebelum profil siap; I juga dapat membuka tas sebelum Play. Input dan aktivasi tombol menu kini menunggu loading selesai, dan I hanya aktif saat gameplay. Reduced motion membatalkan tween kamera menu; HUD sekarang menghormati inset Roblox. Pemeriksaan fake lulus, tetapi tampilan aktual belum diverifikasi.
- Tidak ada tes otomatis akhir yang gagal. Kesalahan parsing Unicode pada pembangkit tes tiruan ditemukan dan diperbaiki selama penulisan tes; ini bukan error kode game.

File yang diubah: `ServerBootstrap.server.luau`, `PlayerDataService.luau`, `UIController.luau`, `tests/run.sh`, dan `README.md`. File baru: tiga `tests/*_mock.py` dan laporan ini. Tidak ada fitur gameplay baru.

## Runtime observations dan remaining bugs

Tidak ada observasi Roblox runtime. Fake menunjukkan alur kode yang disebut di atas, tidak membuktikan Instance property, tween, camera, UI safe area, DataStore timing, replikasi, physics, streaming atau input benar di engine. Tidak ada bug runtime yang dapat dinyatakan selesai/tersisa tanpa menjalankan checklist; semua item di bawah masih **NOT RUN**. Secara desain, timeout shutdown bisa menyisakan lease hingga kedaluwarsa dan final save yang gagal bisa kehilangan progres sejak save sebelumnya. Kualitas aset, performa dan seluruh attack surface belum diverifikasi.

## Prosedur manual Roblox Studio

Catat versi Studio, tanggal, jenis device/viewport, langkah, hasil aktual, log server/client dan status PASS/FAIL untuk setiap item. Gunakan test experience terpisah, akun uji dan data yang boleh dibuang. Jangan gunakan experience/data produksi. Simpan salinan `.rbxlx` dan log yang sesuai dengan source yang diuji.

### A. Setup dan lokasi UI

1. Install Rojo 7, jalankan `rojo build default.project.json -o Aether.rbxlx`, buka hasil di Studio sebagai **place kosong**. Jangan sync ke place yang memiliki terrain penting: world generator menulis terrain di origin. Publish ke experience uji dan aktifkan Game Settings → Security → Enable Studio Access to API Services.
2. Buka View → Output dan Explorer; jalankan Play. Pada sisi client, periksa `Players > <pemain> > PlayerGui > AetherUI > Root`, dengan `LoadingScreen`, `MainMenu`, `HUD`, dan panel modal yang dibuat saat runtime. Di server periksa `ReplicatedStorage > AetherRemotes` (`State`, `RequestState`, `UseItem`) serta `Workspace > AetherWorld > EldoriaVillage`. Periksa tidak ada error script, missing module, infinite yield atau warning berulang. UI tidak perlu ada di StarterGui saat edit mode.
3. Coba instance world yang sudah ada **hanya pada place uji**: bootstrap seharusnya menolak menggantinya dan menghasilkan error yang jelas. Pulihkan place kosong untuk sisa tes.

### B. Loading, menu, HUD dan panel

1. Saat masuk, catat status loading yang nyata dan spinner; tidak boleh ada angka persentase palsu. Setelah data tersedia, menu muncul dan kamera menampilkan desa. Jika akses API tidak aktif, pemain harus ditolak, bukan diberi profil kosong yang kemudian disimpan.
2. Sebelum Play, coba C, I, tombol Karakter dan Pengaturan. I tidak boleh membuka tas; Karakter dan setting harus dapat dibuka/ditutup setelah profil siap. Tekan **Mulai Petualangan**: menu hilang, HUD muncul, kamera kembali ke kontrol Roblox. Ulangi dengan reduced motion dan pastikan gerak kamera menu berhenti ketika opsi diaktifkan.
3. Untuk profil level 1 baru, cek HP 100/100, mana 100/100, XP 0/100 dan gold 0. Panel Karakter harus sesuai. Mana saat ini tidak dipakai skill dan reset ketika spawn/level-up; settings hanya lokal sesi ini. Uji respawn dan cek HP/mana diperbarui.
4. Dengan **server command line** di Developer Console/Studio saat Play dan akun uji, setelah spawn protection hilang, jalankan:

   ```lua
   local p = game:GetService("Players"):GetPlayers()[1]
   local h = p and p.Character and p.Character:FindFirstChildOfClass("Humanoid")
   if h then h:TakeDamage(40) end
   ```

   Amati HP turun. Buka tas dengan I/tombol touch, gunakan tonic: HP bertambah maksimal 40 tanpa melampaui max dan stok turun satu; saat HP penuh atau mati stok tidak berubah. Tunggu minimal 0,5 detik antarpermintaan. Gunakan kedua tonic dan pastikan stok habis. Jangan tandai lulus jika tidak bisa menjalankan perintah pada **server**.

### C. Training dan penyimpanan

1. Gunakan profil baru; dari spawn pergi ke papan di utara plaza. Tahan E / prompt touch. Harapan: 35 XP, 12 gold, dan jumlah latihan 1. Aktivasi ulang sebelum 20 detik tidak memberi reward lagi. Setelah menunggu minimal 20 detik untuk masing-masing dua latihan berikutnya, harapan total level 2, XP 5/150, gold 36, latihan 3; max HP 110 dan max mana 105. Pastikan server dan HUD sesuai. Untuk profil lama bandingkan dengan nilai awal, bukan angka profil baru.
2. Uji prompt di luar jarak yang diizinkan dan saat Humanoid mati, serta request remote dengan argumen tidak valid pada lingkungan uji. Tidak boleh ada reward/tonic tambahan. Periksa Output; client tidak boleh dapat memasok nilai XP, gold atau damage.
3. Dengan mode ephemeral **false** dan API aktif, keluar secara normal, masuk kembali ke experience uji, dan periksa level/XP/gold, jumlah tonic serta latihan tetap sama. Tunggu setidaknya satu interval autosave 60 detik dan ulangi. Catat setiap error DataStore dan jangan tandai penyimpanan lulus jika hanya mode ephemeral yang digunakan.
4. Uji migrasi v1 dan lease menggunakan **key unik dalam DataStore uji yang berbeda**, bukan key profil pemain atau experience produksi. Pada server command line, dengan API aktif, jalankan:

   ```lua
   local ds = game:GetService("DataStoreService"):GetDataStore("Aether_Phase02_QA_Only")
   local lease = require(game.ServerScriptService.Services.ProfileLease)
   local key = "qa_" .. game:GetService("HttpService"):GenerateGUID(false)
   local now = os.time()
   ds:SetAsync(key, {data = {schemaVersion=1, level=4, xp=12, gold=345, class="Warrior"}})
   local why
   local a = ds:UpdateAsync(key, function(old)
       local nextRecord
       nextRecord, why = lease.acquire(old, "qa-owner-a", now, 180)
       return nextRecord
   end)
   assert(a and a.data.schemaVersion == 2 and a.data.gold == 345 and a.data.inventory.tonic == 2)
   ds:UpdateAsync(key, function(old)
       local nextRecord
       nextRecord, why = lease.acquire(old, "qa-owner-b", now, 180)
       return nextRecord
   end)
   assert(why == "profile is active on another server")
   local released = ds:UpdateAsync(key, function(old)
       local nextRecord
       nextRecord, why = lease.write(old, "qa-owner-a", now, 180, a.data, true)
       return nextRecord
   end)
   assert(released and released.session == nil)
   ds:RemoveAsync(key) -- hanya key QA unik yang dibuat oleh snippet ini
   print("QA migration / sequential lease passed")
   ```

   Ini menguji migrasi/lease melalui DataStore nyata secara **sekuensial**, bukan concurrency lintas server atau seluruh `PlayerDataService.load`. Jika akses gagal, catat BLOCKED, bukan PASS. Uji migrasi jalur PlayerDataService sebenarnya hanya dengan menyemai profil v1 milik akun uji yang sudah logout, di experience uji, setelah backup; jangan menimpa sesi yang aktif.
5. Untuk uji cross-server, buka dua server terpisah pada **universe uji yang sama**, gunakan key QA unik yang sama dalam `Aether_Phase02_QA_Only` dengan token berbeda, dan jalankan acquire hampir bersamaan. Tepat satu pemilik boleh berhasil, pemilik lain ditolak; uji kembali setelah release/expiry. Hapus hanya key QA setelah kedua server selesai. Jalankan juga uji leave saat load dan shutdown saat save dengan fault injection yang terkontrol di test environment; simulator CLI tidak membuktikan race platform. Catat jika belum dapat dilakukan.

### D. Multiplayer, mobile dan navigasi

1. Test → Start dengan satu server dan dua client; periksa setiap client punya UI sendiri dan data terpisah. Dekatkan keduanya ke papan: cooldown dan EXP/gold harus independen; gunakan tonic di satu client dan pastikan yang lain tidak berubah. Untuk UI-only tanpa API, `STUDIO_EPHEMERAL=true` dapat dipakai sementara; mode itu **bukan tes persistensi**, dan harus dikembalikan ke `false`.
2. Uji PC serta emulator tablet dan smartphone, portrait dan landscape. Cek topbar/safe area, keterbacaan, overlap HUD/panel dengan joystick, tombol jump dan prompt, perubahan viewport, mouse/keyboard, touch serta kamera. Lanjutkan pada perangkat fisik untuk menyimpulkan kompatibilitas/performa.
3. Jelajahi spawn → plaza → papan → kedua sisi masing-masing jembatan → hutan, pasar, rumah dan area latihan; cek tabrakan, ramp, air, respawn, streaming, arah, bagian yang membuat karakter terjebak atau jatuh. Cek CPU/memori/instance count di profiler pada server dua client dan mobile fisik.
4. Setelah pengujian pulihkan konfigurasi, hapus hanya data QA yang memang dibuat untuk tes dan lampirkan log/screenshot. Kegagalan nyata harus direproduksi, diperbaiki dan diuji ulang sebelum status dinyatakan lulus.

## Release readiness

**Tidak siap rilis dan validasi belum selesai.** Studio, visualisasi hasil build, DataStore platform, concurrency/multiplayer, navigasi/fisika, input mobile/PC dan performa masih belum diuji. Jangan memulai fase baru sampai temuan runtime di atas diselesaikan dan hasil manual didokumentasikan.
