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

## Zaman ve Zorluk Matrisi (v1.3.0)
* **Bug Fix (Mesafe Culling):** Haritadaki önemli objelerin (RouletteMan, DeathLine vb.) oyuncudan uzaklaştığında silinmesini (culling) önlemek için `Arena.gd` içerisindeki `_cull_distant_objects` fonksiyonuna istisnalar (continue) eklendi.
* **Geri Sayım ve Overtime Katlanma Algoritması:** 10 dakikalık (varsayılan) geriye akan bir timer kuruldu. Süre 0'ın altına indiğinde oyun bitmez, Overtime'a (hiper-enflasyon) geçer. Kazanılan altın miktarı şu üstel denkleme göre her saniye katlanır:
$S_0 = 30 \times 3^{\frac{T_{base} - 10}{5}}$
$\text{Reward} = S_0 \times 2^{t_{overtime}}$
Bu ödül `EconomyComponent.gd` üzerinden `Global.dongu_parcaciklari` bakiyesine doğrudan eklenir.
* **Dinamik Düşman Zorluğu:** `Arena.gd` içinde süre 1 dakikanın üstündeyken her dakika; son 1 dakikada ise her 20 saniyede bir düşmanların hız, can ve hasar potansiyeli %15 katlanarak ($x \times 1.15$) artırılır.
* **UI Optimizasyonu:** Sürekli ekranda uçuşan momentum yazıları iptal edilerek CanvasLayer'a sabitlenen dinamik bir Momentum UI eklendi. Arka plana anime tarzı `SpeedLines.gdshader` entegre edildi, çizgi yoğunluğu oyuncu ivmesine (velocity/max_speed) bağlandı.
