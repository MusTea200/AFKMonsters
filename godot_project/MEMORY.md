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

## Core Loop Onarımı ve UI Optimizasyonları (v1.3.1)
* **Kritik Hata Tamiri:** Daha önceki güncellemelerde mermi atma fonksiyonu (`_shoot_closest_enemy`) içindeki instantiate kodlarının comment out yapılması veya syntax hatalarıyla bloğun kopması mermi ateşlemesini durdurmuştu. Ayrıca Enemy ve Economy bağlantıları sarsıldığı için ölümde altın/exp transformasyonları sekteye uğramıştı. Bu kırılmaların temel sebebi, regex (re.sub) tabanlı file modifikasyonlarında girinti (indentation) hatalarının yaşanmasıdır. Tüm kritik _shoot ve ölüm köprüleri (finalize_run) restore edildi.
* **Juice & Performans:** UI üzerindeki `MomentumLabel` hız arttıkça dinamik olarak büyüyüp titremesi planlandı. Ancak her karede (frame) Tween oluşturmak (Tween spam) ciddi bir performans kaçağı yaratır ve animasyonların birbiriyle çakışmasına sebep olur. Bu nedenle, animasyon (scale ve renk değişimi), sadece hız limiti belirli eşikleri aştığında veya hedef değer mevcut değerden farklı olduğunda bir `lerp` veya kontrollü bir Tween mekanizması ile tetiklenecek şekilde optimize edilmelidir.
* **Gidişat ve Planlar:** Çarkıfelek (Roulette Universe) ve Sürü (Horde Raid) sistemlerinin alt yapıları kuruldu. Gelecek adımlarda, bu evrenlere özgü düşman shader'ları ve dalga (wave) tabanlı özel boss saldırıları genişletilebilir.

## Omni-Input Sistem ve Kontrolcü Çeşitliliği (v1.4.0)
* **Otomatik Kontrolcü Tespiti (Omni-Input):** `Global.gd` üzerinde `current_input_type` isimli bir enum (KEYBOARD, JOYPAD, TOUCH) eklenecek. `_unhandled_input` içindeki eventlerin tipine göre (`InputEventKey/Mouse`, `InputEventJoypadMotion/Button`, `InputEventScreenTouch`) oyun motoru anlık olarak mevcut cihazı algılayacak. Bu bilgiye göre ekrandaki "E", "Space" gibi UI uyarıları anında güncellenecek.
* **Sağ Analog Nişan Matematiği (Right Stick Aim):** Fare imlecinin konumu yerine, Gamepad kullanıldığında sağ analogun eksen verileri (`JOY_AXIS_RIGHT_X`, `JOY_AXIS_RIGHT_Y`) okunarak normalize edilmiş bir `aim_direction` vektörü çıkarılacak. `CombatComponent.gd` ve `Player.gd` hedefleme algoritmaları bu yeni vektörel yöne adapte edilecek.
* **Mobil Dokunmatik Entegrasyon Planı:** Touch girdileri yakalandığında CanvasLayer üzerine dinamik olarak 2 adet sanal joystick (Sol hareket, Sağ ateş/grapple) belirmesi ve Player'ın direkt `touch_aim` ve `touch_move` verilerini globalden okuması hedefleniyor.

## P2P Mimari ve Sonsuz Harita (v1.5.0)
* **Hibrit UI & Kontrolcü Eşleme:** Ekrandaki etkileşim yazıları artık klavye/mouse için "[E]", aynı anda hem PlayStation hem Xbox kolunu destekleyecek şekilde gamepad için ise "[Y / ▲]" olarak güncelleniyor. Ayrıca mobil için Sanal Joystick taslağı hazırlandı.
* **ESC Menüsü Geliştirmesi:** Çok oyunculu ortam göz önünde bulundurularak ESC menüsüne "Ayarlar" (Hassasiyet, Çözünürlük, Ses, Lobi), "Ana Menü" ve "Kapat" eklenecek. Çok oyunculu duraklatmalarda tüm oyuncularda 5 saniyelik bir bekleme (resume countdown) senkronizasyonu çalışacak.
* **RAM Tabanlı Host Migration (Sunucu Göçü):** Eşler (Peers) bağlandığında `OS.get_static_memory_peak_usage()` (veya OS meta veri simülasyonu) üzerinden RAM kapasitelerini paylaşır. En yüksek kapasiteye sahip cihaz Host (Server) olur. Host ayrıldığında oyun donmaz; kalan en yüksek RAM'e sahip peer yeni Host olur ve state sync ile oyunu pürüzsüz devralır.
* **Seed Tabanlı Procedural Chunk Harita:** Sabit arena sınırları yerine seed tabanlı sonsuz harita jenerasyonuna geçildi. Culling nedeniyle objelerin (altın, rulet adam vs.) kaybolmasını önlemek için aktif olmayan chunk'lardaki obje verileri bir `Dictionary` (Sözlük) içinde saklanıp oyuncu yaklaştığında tekrar instantiate edilecek (Chunk Persistence).
* **Mermi Atma (Shooting) Hatası Çözümü:** `Player.gd` ve `CombatComponent.gd` içindeki boş kalan `bullet_scene` referansı, doğrudan `preload("res://Bullet.tscn")` ile doldurularak mermi atamama sorunu kalıcı olarak çözüldü.
