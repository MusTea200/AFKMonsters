# OYUN MİMARİSİ HAFIZA DOSYASI

## Çözülen Hatalar
* **Ekran Sarsıntı Enflasyonu (Infinite Trauma):** Aynı anda çok sayıda düşmanın ölmesiyle biriken sarsıntı şiddetine üst sınır getirildi. `CameraShake.gd` içindeki trauma değeri clamp fonksiyonu ile maksimum 0.6'da tutuldu. Böylece oyun hissiyatı korunurken baş dönmesi engellendi.

## Matematik Notu
* **Yalancı Mıknatıs (Mimic) Çembersel Spawn Lojiği:** Mimic patladığında düşmanların üst üste binmemesi için çembersel vektör matematiği kullanıldı. Yeni formül: $r$ yarıçap olmak üzere, her düşman $360^\circ / 10 = 36^\circ$ ($2\pi/10$ radyan) açıyla konumlandırıldı: `Vector2(cos(angle), sin(angle)) * r`.

## Gelecek Planı
* **Seyyar Market UI (SpeedMerchant):** "E" tuşuyla açılan, zamanı hafif yavaşlatan ve 3'lü kart sunan sistemin kart (Glassmorphism + Neon Border) sayısının dinamik hale getirilmesi ve farklı RPG havuzlarından stat çekmesi eklenecek.

## Momentum ve Geometrik Savaş Sistemi (v1.2.0)
* **Bug Fix (RouletteMan Vortex):** UI/Control node komutları (set_anchors_and_offsets_preset) Sprite2D üzerinde çağrılamadığı için oyun çöküyordu. Bu sorun, Sprite2D'nin pozisyonu doğrudan `get_viewport_rect().size / 2.0` kullanılarak viewport'un tam ortasına (`global_position`) sabitlenmesiyle çözüldü.
* **Bug Fix (Redzone Stacking):** Redzone opaklığı `min(0.5, ...)` şeklinde sabitlendi, böylece çoklu alanlar üst üste binse bile ekran tamamen karararak (blinding) oyun deneyimini baltalamıyor.
* **Faz Kalkanı Lojiği:** `Player.shield_charges` üzerinden kontrol edilir. Eğer oyuncunun kalkanı varsa `take_damage` içinde can azalmak yerine kalkan şarjı bir birim düşer ve alınan hasar nullify edilir (absorbe edilir). "PHASE SHIELD!" bildirimi fırlatılır.
* **Geometrik Orbitaller (N-Gen):** `2 * PI / orbital_count` formülüyle orbitaller kusursuz bir çember formunda açısal olarak eşit yerleştirilir (örn: 3 orbital varsa bir eşkenar üçgen çizerler). Orbitallerin `Time.get_ticks_msec()` ile rotasyon hızı, oyuncunun anlık ivmesiyle orantılı olarak `rot_speed = 2.0 + (velocity/max_speed) * 8.0` şeklinde artırıldı; bu sayede oyuncu ne kadar hızlıysa orbitaller o kadar ölümcül bir matkaba dönüşüyor.
