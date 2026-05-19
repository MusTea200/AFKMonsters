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

## 🐛 Siber Hata Avı ve Güvenlik Yamaları (Gacha UI & Vending Machine)

### Şimdiye kadar yapılanlar
- `GachaUI.gd` içerisindeki arayüzü dinamik olarak dolduracak, eksik bırakılan `_populate_tab` fonksiyonu tamamen kodlandı. İlgili fonksiyon, GridContainer'ı temizleyip PanelContainer'ları sıfırdan oluşturarak `category`, `item_index` ve `level` meta verilerini panellere kusursuzca yerleştiriyor.
- `Arena.gd` dosyasına hile motoru (Cheat Engine) entegre edildi. Savaş alanındayken klavyeden "1" tuşuna basıldığında oyuncuya anında 1000 Altın, 1000 Döngü Parçacığı ekleniyor ve içinde bulunulan aktif Redzone siber yeşile döndürülüp %100 ele geçirilmiş sayılarak Otomat anında etkileşime açılıyor.
- Arayüzlerde ve sahnelerde unutulmuş olan tüm sinyaller ve güvenlik bariyerleri aktif hale getirildi.

### Hangi hataların düzeltildiği
- **Eksik Fonksiyon Halüsinasyonu:** GachaUI scriptinde daha önce `_populate_tab` çağrılmış ama fonksiyonun içi/kendisi yazılmamıştı. Bu da oyunun market sekmesine geçildiğinde fatal error verip çökmesine sebep oluyordu. Bu kritik eksiklik onarıldı.
- **Emniyet Zafiyeti (is_captured Kontrolü):** `VendingMachine.gd` içindeki `_on_body_entered` fonksiyonunda Otomat'ın bölgesi henüz tam ele geçirilmemişken (kırmızı alarm halindeyken) bile oyuncu temas ettiğinde marketin bodoslama açılması gibi büyük bir zafiyet vardı. Artık fonksiyon başında katı bir `if not is_captured: return` bariyeri var. Oyuncu ele geçirilmemiş otomata sürtünse bile menü açılmıyor.
- **Duraklatılmış Oyunda UI Sinyal Kilitlenmesi:** Market menüsündeki "X" kapatma butonuna basıldığında arayüz kaybolsa bile `get_tree().paused` state'i `false` yapılmadığı için oyun Matrix'te asılı kalıyordu (zaman donuyordu). Kapatma sinyaline `get_tree().paused = false` ve `queue_free()` protokolleri gömülerek sonsuz donma engellendi.

### Bir daha aynı hatalara nasıl bulaşılmayacağı
- Bir fonksiyon başka bir yerde çağrılıyorsa (özellikle UI tarafında dinamik liste oluşturan fonksiyonlar), içi henüz tam kodlanmamış olsa bile en azından `pass` geçilerek declare edilmeli. Halüsinasyon veya eksik bırakma hatalarının önüne böyle geçilebilir.
- Fiziksel etkileşimle (Area2D / body_entered) tetiklenen arayüz pop-up'larında (Otomat, Sandık vb.), durumu kontrol eden boolean güvenlik bariyerleri (örn. `is_captured`, `is_unlocked`) methodun hemen en başında `return` ile denetlenmeli.
- Pause modunu (`get_tree().paused = true`) değiştiren herhangi bir UI elemanının kapatma/iptal tuşuna mutlaka `get_tree().paused = false` sinyali yedeklenmeli. Aksi takdirde oyun motoru sonsuz bekleme moduna geçer.

### Projenin gidişatı ve gelecek planları
- Otomat, Gacha çarkı ve Redzone savunma fazı arasındaki entegrasyon başarılı şekilde kapatıldı. Oyunun Risk/Reward döngüsü planlandığı gibi dopamin zerk eden bir yapıya oturtuldu.
- Gelecek planları arasında global stat yükseltmelerinin (Döngü Parçacığı marketinin) kapasitesinin ve etkisinin genişletilmesi, yeni Tier ve nadirlik sınıflarının Gacha çarkına entegrasyonu yer alıyor.

### Kendisinin ekleyeceği ve yararlı olduğunu düşündüğü özellikler
- "1" hilesi gibi, geliştirme süreçlerini çok hızlandıran bir Debug Console (veya komut satırı) yapısı fena olmazdı. Şimdilik tuş ataması ile bypass ediliyor ama ileride "God Mode", "Kill All Enemies" veya "Spawn Boss" gibi makrolar eklenebilir.
- Gacha menüsünde "Skip Animation" (Animasyonu Geç) seçeneği eklenerek çarkın yavaşlama süresine sabredemeyen oyuncular için hızlı açılış özelliği eklenebilir.

### Güvenlik ve performans adına yaptıkları
- Eşya yaratımı (`PanelContainer`) sırasında GridContainer öncelikle `queue_free()` kullanılarak tamamen temizleniyor. Böylece menü her açıldığında yüzlerce gereksiz düğümün üst üste binip Memory Leak (bellek sızıntısı) yaratması engelleniyor.
- `_process` gibi her kare çalışan fonksiyonlarda değil, sinyal (event) tabanlı tetiklenmelerle ilerlenerek işlemci döngüleri korundu.
- Efsanevi (Tier 5) düşme şansı 0.01'den 0.05'e yükseltilerek hem dopamin döngüsü tetiklendi hem de imkansız bir RNG senaryosundan daha makul bir oyun içi piyasaya geçiş yapıldı.

## 🚀 Kademeli Ele Geçirme Lojiği ve Siber Renk Matrisleri

### Şimdiye kadar yapılanlar
- `Redzone.gd` alanına dinamik ve siber tasarımlı bir ProgressBar eklendi. Oyuncu alanın içine girdiğinde bu bar görünür hale geliyor ve 10 saniyelik bir süre içerisinde %0'dan %100'e doğru doluyor.
- Ele geçirme barı her %10 arttığında, `_spawn_redzone_wave` ile orantılı olarak güçlenmiş (`max_health`, `damage_amount` ve `move_speed`) düşman dalgaları yaratıldı. Dalga doğumu anında kırmızı bir Polygon2D şok dalgasıyla (Tween animasyonu) desteklendi.
- Bar %100'e ulaştığında merkezde beliren ve rengi 10 saniye boyunca kırmızıdan (#ff0000) yeşile (#00ff00) pürüzsüzce interpolasyon yapan (Color Lerp) 10 saniyelik bir geri sayım Label eklendi.
- Sayaç 0'a ulaştığında alanın rengi anında `#00ff004d`ye, içerisindeki otomatın rengi ise `#00ff33`ye dönüştürülerek kilitler açıldı. Gacha menüsünden çıkıldıktan sonra otomat etkileşime sonsuza dek kapatılarak rengi sinsi bir gri tonu olan `#7c7c7c`ye ayarlandı.

### Hangi hataların düzeltildiği
- Oyuncunun girdiği anda hemen ele geçirilebilen veya belirsiz ilerleme mekaniğine sahip statik siber bölgeler ortadan kaldırıldı ve yerine aşamalı bir UX (Kullanıcı Deneyimi) geri bildirimi eklendi.
- Geri sayım sırasında statik tekdüze renk kullanımından ötürü oluşan zaman algısı körlüğü çözüldü.

### Bir daha aynı hatalara nasıl bulaşılmayacağı
- UI geri bildirimleri (örneğin süreç barları, zamanlayıcılar), kod içinden ziyade Tween ve zaman aralıklı hesaplamalar (math lerp) ile kontrol edilerek oyunun frame dalgalanmalarından bağımsız tutulmalıdır.
- Sinyal tabanlı durum kapanışlarında (`tree_exited`), nesne tekrar kullanılamayacak ise boolean kilidi yanında (örn. `is_captured = false`) mutlaka kalıcı, etkisizleştiğini belirten bir görsel duruma (gri renk vs.) büründürülmelidir.

### Projenin gidişatı ve gelecek planları
- Alan savunma mekaniği tam donanımlı bir dalga hayatta kalma mini oyununa dönüştürüldü.
- Daha sonraki sürümlerde oyuncuya bu tarz meydan okumaları tamamlama sürelerine ve kaçırdığı hasarlara göre bonus statüler sağlayan başarı puanı sistemi getirilebilir.

### Kendisinin ekleyeceği ve yararlı olduğunu düşündüğü özellikler
- Her düşman dalgası doğduğunda kısa ve ani bir kamera sarsıntısı (`CameraShake` singleton ile) eklenebilir, bu arcade hissiyatını ve ağırlığı artırır.
- Otomat rengi yeşil olduğu an siber bir onaylama sesi (`AudioStreamPlayer2D`) çalınabilir.

### Güvenlik ve performans adına yaptıkları
- `_process` üzerinde yorucu olan düğüm yaratma işlemleri ve döngüler, yalnızca yüzde kontrolü her %10'luk eşiği geçtiğinde bir defaya mahsus çalışacak şekilde sınırlanarak performans korundu.
- Yaratılan şok dalgası `Polygon2D` düğümü, Tween bitiminde belleği işgal etmemesi adına doğrudan `queue_free()` fonksiyonuna (`tween_callback` aracılığıyla) bağlandı.

### Mimari Değişim: Editör Odaklı (UI) Kodlama (@onready)
- Daha öncesinde `Redzone.gd` dosyasının içerisinde `.new()` ile oluşturulan `Polygon2D`, `ProgressBar`, `Label` ve `VendingMachine` nesneleri tamamen kod içerisinden temizlenerek silinmiştir.
- Bunun yerine bu düğümlerin oyuncunun sahnede (`Redzone.tscn`) editör üzerinden yerleştirileceği varsayılarak tüm nesneler `@onready` ile bağlanmıştır.
- **Neden Yapıldı?:** Kod ile arayüz oluşturmak, arayüzün (UI) sahne görünümünde görünmez olmasına, görsel hizalama sorunlarına ve her seferinde kod içindeki koordinatların körlemesine denenmesine sebep oluyordu. Düğümleri editöre taşıyıp sadece lojiği koda bağlamak (örneğin `$ProgressBar` referansı) tasarım özgürlüğünü ve görsel geri bildirimi (UX tweaking) büyük oranda artırmıştır.
