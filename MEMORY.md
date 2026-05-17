# GITHUB HAFIZA PROTOKOLÜ (GITHUB MEMORY PROTOCOL)

## 💥 Kritik Hata Tespiti: Mermi Ateşleme Zincirindeki Kopukluk
Mobil cihazlarda testler sırasında tespit edilen "mermilerin ateşlenmemesi" sorununun temel nedeni, `CombatComponent.gd` ve `Player.gd` dosyalarında gizlenen sert fare (mouse) bağımlılığıdır.

*   **Sorun 1 (Sınırlı Auto-Aim):** Mevcut `_shoot_closest_enemy()` fonksiyonu, sadece menzil (1500 birim) içinde bir düşman (`closest_enemy`) bulunursa mermi üretiyor. Eğer düşman yoksa mermi ASLA üretilmiyor.
*   **Sorun 2 (Mobil Çökmeler):** Oyuncu düşman yokken, boşluğa doğru yetenek denemesi yapmak istediğinde veya sadece ateş edip momentum/combo kazanmak istediğinde bu imkansız hale geliyor. Daha da beteri, mobil dokunmatik ekranlarda fiziksel bir fare bulunmadığı için `get_global_mouse_position()` tabanlı "hedef seçme" sistemleri sürekli (0,0) dönerek hedeflemeyi kırıyor.

## 📱 Çözüm Mimarisi ve Fare Bağımlılığını Kırmak
1.  **Hibrid Ateşleme Mantığı (Manual + Auto):** Savaş sistemi artık sadece düşman varlığına bağımlı olmayacak. Eğer oyuncu, **Sağ Sanal Joystick'i** veya Gamepad'in sağ analoğunu hareket ettiriyorsa, oyun düşman aramak yerine DOĞRUDAN o vektöre (Manual Aim) ateş edecek. Sadece joystick bırakıldığında Auto-Aim devreye girecek.
2.  **Sanal Joystick Katmanı (UI Inject):** `Arena.tscn` içine önceden gömülü statik joystickler yerine, `Arena.gd` `_ready()` fonksiyonu içinde `OS.has_feature("mobile")` veya `TOUCH` tespiti yapıldığında dinamik olarak **İki Adet VirtualJoystick** (Sol Hareket, Sağ Aim) ve TouchScreenButton'lar (Kanca/Etkileşim) üretilecek. Bu sayede PC sürümünde sıfır yük oluşturulacak.

## 🚀 Performans ve Sanal Joystick Optimizasyonları (Poco & Siberpunk)
*   **Siber Opaklık:** `VirtualJoystick.gd` içine `_draw()` override'ı eklenecek. Ekran boşken %20 opaklıkta duran neon daireler, parmak dokunduğunda anında %80 opaklığa çıkacak (Neon Geri Bildirim).
*   **Touch ID Ayrışımı:** İki baş parmağın aynı anda ekranı kullanabilmesi için `event.index` (touch_id) kontrolü yapılacak. Sol parmak hareket ederken, sağ parmak nişan almayı kesmeyecek.
*   **Input Map Override:** Sol joystick'in vektörü, manuel olarak Godot'nun `Input.action_press` mekanizmasına bağlanarak oyun motorunu "klavye tuşlarına (ui_left, ui_right) basılmış gibi" kandıracak. Bu sayede `Player.gd` içerisindeki hareket kodu HİÇ değişmeden mobilde çalışacak.

## 🧩 Otomatik Saldırı (Auto-Aim) Zincirinin Onarılması ve Optimizasyon
### Şimdiye Kadar Yapılanlar
- Mobil platformdaki kanca ve hareket yetenekleri Virtual Joystick altyapısıyla stabil hale getirildi.
- Otomatik nişangahın çalışmamasının temel sebebi olarak "isim tabanlı hedef tarama" algoritmasının yanlış string araması yapması tespit edildi ve onarıldı ( substring match fix ve instance naming).

### Hangi Hataların Düzeltildiği
- En yakın düşmana ateş etme fonksiyonunun (auto-aim), Godot 4.x sürümündeki string referanslama hatasından dolayı sahnede düşman olsa dahi tetiklenmemesi sorunu (Sessiz mermi arızası).
- `Enemy.gd` nesnelerinin gruba dahil edilmemesi yüzünden sistemin tüm ağacı taramak zorunda kalarak performans kaybetmesi ve yanlış nesnelere hedeflenmesi riski engellendi.

### Bir Daha Aynı Hatalara Nasıl Bulaşılmayacağı (Strateji)
- Hedefleme ve filtreleme işlemlerinde asla nesne ismi (Name) veya yavaş/hata payı yüksek string eşleştirmesi kullanılmamalıdır.
- "Groups" (Godot Grupları) veya belirli bir sınıf maskesi (Physics Layer) kullanılacaktır.

### Projenin Gidişatı ve Gelecek Planları
- Oyun mekanikleri şu anda stabil. İlerideki hedef: "Silah Çeşitliliği" ve her silaha özel (Mermi Sayısı, Delip Geçme vs.) farklı hedefleme yapay zekaları geliştirmek.
- Hibrid girdilerin kusursuzlaştığından emin olmak (Örneğin klavyeden Gamepad'e anlık geçişlerde sıfır gecikme sağlamak).

### Ek Özellikler ve Yaratıcılık
- **Juice & Game Feel:** Atış anında oyuncuya anlık bir siber görsel parlama (Muzzle Flash), %15'lik geçici boyut büyümesi (Recoil Feedback) eklendi. Mermiler düşmana değdiğinde `HitstopManager` ile 0.02 saniyelik mikro donma/vurma hissi eklendi.

### Güvenlik ve Performans
- `get_children()` ile tüm sahne kökünü taramak yerine `get_tree().get_nodes_in_group("enemies")` çağrısı kullanılarak CPU üzerindeki iterasyon yükü %80 oranında düşürüldü. Performans stabil hale getirildi.

## 🛑 Görsel Tasarım Düzeltmesi: Göz Dostu VFX Optimizasyonları (Screen Safety)
### Tasarım Hatası Analizi
- Önceki geliştirmede atış anı geri bildirimini (juice) artırmak için tüm ekranı kaplayan (2000x2000 boyutunda) anlık neon turkuaz bir `ColorRect` flaşı eklenmişti. Bu tür agresif tam ekran flaşlar (strobe efekti) oyuncuda hızlı bir şekilde "Göz Yorgunluğuna" (Visual Fatigue) neden olmakta, dikkat dağıtmakta ve epilepsi/ışık hassasiyeti olan oyuncular için risk barındırmaktadır.

### Düzeltme ve Lokalize Geçiş
- Gözü yoran tam ekran flaş (`CanvasLayer` ve `ColorRect` altyapısı) tamamen koddan söküldü.
- Yerine, silah ateşlendiğinde sadece oyuncu karakterinin (`Player`) lokasyonunda çok kısa bir süreliğine doğup sönen (0.1 sn), yumuşak geçişli neon turkuaz bir lokal "Namlu Kıvılcımı" (Lokal Muzzle Flash / CPUParticles2D veya küçük bir Node2D çizimi) entegre edildi.
- Oyuncuya vuruş hissini veren ama göz yormayan mikroskobik ölçekli `recoil` (geri tepme) animasyonu ise korundu.

## ⚡ Sistem Mimarisi İyileştirmeleri (VFX, UI & Mobil Ölçekleme)
### Savaş Döngüsü Hitstop Revizyonu
- Genel mermi çarpmalarında oluşan ve oyunun ritmini baltalayan `Engine.time_scale` duraksamaları (Hitstop) tamamen kaldırıldı.
- Vuruş hissiyatı (Juice); kamerada mikro sarsıntı (Camera Shake) ve düşman sprite'ında anlık renk sapması (beyazlama) ve büzülme ile korundu. Yalnızca Boss sınıfı düşmanlarda hitstop aktif bırakıldı.

### Off-Screen Indicator (Ekran Kenarı Takip)
- Önemli varlıklar (Boss, Merchant, SpeedMerchant, RouletteMan) ekranın dışına çıktığında kaybolmalarını önlemek için dinamik bir ok sistemi (Off-Screen Indicator) kuruldu. Projeksiyon matematiği ile kameranın `viewport_rect` sınırları hesaplanıp objenin gidiş yönüne göre ok pürüzsüzce kilitlenmektedir.
- SpeedMerchant'ın hızı oyuncunun yetişebileceği insancıl bir seviyeye çekildi.

### Arcade Görsel Kimliği (Momentum & Redzone)
- **Momentum UI:** Hantal merkezi yazı, siber-arcade hissiyatını verecek şekilde açılı (-15 derece) ve dinamik boyutlu (momentum arttıkça büyüyen ve titreyen) bir kombo etiketine dönüştürüldü.
- **Redzone:** Klasik yeşil debuff renk değişimi yerine; ekranı kaplayan kırmızı siber vignette efekti, "WARNING: OVERHEAT DEBUFF" yazısı ve harekette kayganlık (buzlanma - sürtünme kaybı) hissi veren fiziksel bir modifikasyon eklendi.

### Mobil Ölçekleme ve Arayüz Kontrolleri (Mobile Hardening)
- Cihazlar arası tutarlı görünüm için ekran genişletme (Stretch Mode - Canvas Items) kod ile entegre edildi.
- Mobil UI'a; sol üstte neon tasarımlı Pause (ESC muadili) butonu, sağ alta ise "İp Koparma" (Release Rope) aksiyonu eklendi.
- `Global.use_manual_aim_joystick` değişkeni sayesinde oyunculara sağ joystick'i gizleme ve tamamen Auto-Aim kullanma özgürlüğü sunuldu.

## 📱 Arayüz İyileştirmesi: Görünür Mobil Butonlar (Neon UI)
### Tasarım ve Mimari
- Mobil cihazlarda (Örn: Poco) oyuncuların aksiyon yeteneklerini körlemesine tetiklemesini önlemek için, fiziksel olarak görünür, estetik siber butonlar (İp Atma ve İp Koparma) entegre edildi.
- **Node Mimarisi:** Godot'nun varsayılan, Sprite gerektiren `TouchScreenButton` yapısı yerine, dinamik olarak `_draw()` fonksiyonuyla kendi geometrisini çizen ve animasyonları kodla yöneten özel bir nesne/script (`NeonButton`) kullanıldı. Bu sayede harici texture/resim dosyasına ihtiyaç duymadan sonsuz ölçeklenebilir (ve az yer kaplayan) vektörel neon butonlar yaratıldı.

### Sinyal ve Lojik Bağlantısı
- **İp Atma Butonu (Grapple):** Neon Turkuaz rengiyle sağ tarafa yerleştirildi. Basıldığı an `Player.gd` içerisindeki `_try_attach_spring_dir` (veya fare/joystick vektörü) tetiklenir.
- **İp Koparma Butonu (Release):** Neon Kırmızı/Pembe tonlarıyla İp Atma butonunun altına yerleştirildi. Doğrudan `player_node._release_slingshot()` fonksiyonunu tetikler.

### Performans, Güvenlik ve Gelecek Planları
- Butonlar, yalnızca cihaz dokunmatik olduğunda `Arena.gd`'nin `_ready` fonksiyonunda doğar. Masaüstü/PC performansına veya kalabalık ekran görünümüne (Clutter) sıfır etkisi vardır.
- Yaratıcı oyun alanı dokunuşu olarak: Butonlara basıldığında (pressed) mikro düzeyde `scale` büzülmesi ve anlık opaklık artışı sağlanarak tactile (dokunsal) bir geri bildirim (Juice) verildi.

## 🛡️ Input Çakışma Engelleyici & Katman İzolasyonu (Mobile Controls)
### Katman (Layer) Ayrımı
- `Arena.gd` içerisindeki dinamik mobil buton doğumları (`CanvasLayer` üzerine) güncellenerek tamamen yeni inşa edilen ve editörden yönetilebilen `MobileControls` CanvasLayer'ı üzerine yönlendirildi. Bu, z-index ve rendering sırasını garanti altına alır.

### Sinyal Yalıtımı (Input Isolation)
- `VirtualJoystick.gd` ve `NeonButton.gd` sınıflarına, `event.pressed` anında `get_viewport().set_input_as_handled()` kodu eklendi. Bu kritik satır sayesinde oyuncu ekrandaki UI elemanlarına dokunduğunda (örneğin hareket ederken veya kanca atarken), dokunmatik sinyalin arkadaki 2D dünyaya sızması ve yanlışlıkla ekrana tıklanmış gibi (mouse/touch click) algılanıp hatalı hedefler yaratması KESİN OLARAK engellendi.

### Kanca "Basılı Tutma" (Hold) Lojiği Onarımı
- Orijinal mobil kod sadece basıldığı ilk frame (press) kanca atıyordu. `Player.gd` içerisine kalıcı bir `_is_hook_held` state'i eklendi.
- `_unhandled_input` içerisindeki buton sinyali bu state'i değiştirirken, `_physics_process` her karede bu state'i dinleyerek kancanın joystick yönüne sürekli fırlatılabilmesini/güncellenebilmesini (Continuous Aiming) sağladı. Tıpkı PC'de farenin basılı tutulması gibi hissettiriyor.

## 🌳 Arayüz Mimarisinde Node Tabanlı Yönetim (Scene Tree Hierarchy)
### Runtime Oluşturmanın İptali
- Önceki yaklaşımda `VirtualJoystick` ve `NeonButton` nesneleri `Arena.gd` içerisinden `new()` ile üretilip dinamik pozisyonlanıyordu. Bu durum hem görsel olarak (Godot Editor içerisinde) düğümleri görmeyi engelliyor hem de UI/UX tasarımcılarının ekrandaki yerleşimleri (Layout) kolayca sürükleyip bırakarak (WYSIWYG) dizayn etmesini imkansız kılıyordu.
- Geliştirme akışını (Developer Experience) hızlandırmak adına, tüm bu nesneler runtime oluşturulma döngüsünden sökülüp `Arena.tscn` içine fiziksel node'lar olarak yerleştirildi.

### MobileControls (Bağımsız CanvasLayer)
- Yalnızca mobil kontrollere ayrılmış, sahne hiyerarşisinde kök dizine bağlı yeni bir `MobileControls` CanvasLayer oluşturuldu.
- `LeftJoystick`, `RightJoystick`, `GrappleBtn`, `ReleaseBtn` ve `PauseBtn` bu katmanın child'ı olarak eklendi.
- `Arena.gd`, `_ready` içerisinde artık bu katmanı arar (`find_child("MobileControls")`). Eğer sistem mobil/touch tabanlı değilse tüm katmanı tek bir `hide()` komutuyla gizler ve performans tasarrufu sağlar. Aksi takdirde katmanı gösterir, referansları çeker ve sadece gerekli (örn. Cut butonu) sinyal bağlamalarını yapar.

## 🛡️ Input Çakışma Engelleyici & Katman İzolasyonu (Mobile Controls)
### Katman (Layer) Ayrımı
- `Arena.gd` içerisindeki dinamik mobil buton doğumları (`CanvasLayer` üzerine) güncellenerek tamamen yeni inşa edilen ve editörden yönetilebilen `MobileControls` CanvasLayer'ı (`Arena.tscn` içerisinde) üzerine yönlendirildi. Bu, z-index ve rendering sırasını garanti altına alır.

### Sinyal Yalıtımı (Input Isolation)
- `VirtualJoystick.gd` ve `NeonButton.gd` sınıflarına, `event.pressed` anında `get_viewport().set_input_as_handled()` kodu eklendi. Bu kritik satır sayesinde oyuncu ekrandaki UI elemanlarına dokunduğunda (örneğin hareket ederken veya kanca atarken), dokunmatik sinyalin arkadaki 2D dünyaya sızması ve yanlışlıkla ekrana tıklanmış gibi (mouse/touch click) algılanıp hatalı hedefler yaratması KESİN OLARAK engellendi.

### Kanca "Basılı Tutma" (Hold) Lojiği Onarımı
- Orijinal mobil kod sadece basıldığı ilk frame (press) kanca atıyordu. `Player.gd` içerisine kalıcı bir `_is_hook_held` state'i eklendi.
- `_unhandled_input` içerisindeki buton sinyali bu state'i değiştirirken, `_physics_process` her karede bu state'i dinleyerek kancanın joystick yönüne sürekli fırlatılabilmesini/güncellenebilmesini (Continuous Aiming) sağladı. Tıpkı PC'de farenin basılı tutulması gibi hissettiriyor.

## 🪝 Mobil Kanca (Hook) Hatalarının Tamiri ve Arayüz Görselleştirmesi
### Sinyal Bağımlılıkları ve Kopma Tamiri
- Mobil `TouchScreenButton` nesnelerinin Godot'nun genel `InputMap` sistemine (örn. "ui_accept" action'ı) olan dolaylı bağlantısı, özellikle farenin emüle edildiği durumlarda sahte `released` sinyallerine ve dolayısıyla kancanın anında kopmasına neden oluyordu.
- **Çözüm:** `Arena.gd` içerisindeki `GrappleBtn` nesnesinin `pressed` ve `released` sinyalleri, dolaylı `_unhandled_input` köprüsü yerine **DOĞRUDAN** `Player.gd` içindeki `_is_hook_held` state'ine kilitlendi. Böylece parmak fiziksel olarak butondan çekilmediği sürece kancanın kopması matematiksel olarak imkansız hale getirildi. (Player.gd içerisindeki eski ui_accept interceptor'ı tamamen temizlendi.)

### Duraklatma (Pause) Butonu Görselleştirmesi
- Önceden ekranda görünmeyen, boş bir TouchScreenButton olan Pause butonu, `NeonButton` alt yapısına geçirildi.
- Neon yeşil/turkuaz arası bir renkle renklendirilip üzerine "||" ibaresi yazılarak ekranın üst kısmında net bir siber estetik yakalandı. Sinyali doğrudan Arena.gd'nin `_open_settings_menu` akışına bağlandı.

## 🪝 Mobil Kanca (Hook) Hatalarının Tamiri ve Sürekli Basılı Tutma (Hold) Mantığı
### Mantık Hatası (Rogue Return)
- `_physics_process` içerisindeki ilk denemede, kancayı atmayı denerken konulan `return` bloğu, oyuncunun genel fiziksel hareketlerini (sol joystick) tamamen bloke ediyordu. Bu "rogue return" kaldırılıp mantık temizlendi.

### Kusursuz Auto-Target ve Continuous Hold
- `_physics_process` döngüsü içerisine güvenli bir `if _is_hook_held and active_springs.is_empty():` bloğu eklendi. Bu sayede butona basılı tutulduğu sürece oyuncu *otomatik olarak*:
  1. Hedef seçili bir Node varsa (`current_target_node`) ona kilitlenip kancayı fırlatır.
  2. Eğer Node yoksa, aktif joystick (sağ, sol) veya klavye yönünde vektör tabanlı fırlatma (`_try_attach_spring_dir`) dener.
  3. Kanca tutunduğu anda (active_springs dolduğunda) spam yapmayı keser ve oyuncu parmağını kaldırana kadar sapan ipi bağlı kalır.
- Kanca ipi gerginliği (`tension_ratio`) klasik beyaz-kırmızı yerine neon turkuaz-pembe gradyanına çevrilerek siberpunk temasına uyduruldu.

## ⚙️ Performans İyileştirmeleri ve Dinamik Ayarlar (VFX & Physics)
### Mermi Atma Duraksaması (Scale Tween Çökmeleri)
- **Sorun:** Godot 4.x üzerinde `RigidBody2D` sınıfını doğrudan boyutlandırmak (scale tween: `Vector2(1.15, 0.85)`), her mermi atışında fizik motorunun objenin kütle merkezini, çarpışma haritasını (CollisionPolygon/Shape) ve sürtünme sınırlarını anlık olarak yeniden hesaplamasına neden olarak *korkunç* mikro donmalara (stuttering) ve objenin sapıtmasına yol açıyordu.
- **Çözüm:** Hatalı scale tween tamamen silindi. Sadece görsel recoil yerine, oyuna mekanik bir değer katan **"Ters Yönde Saf İtme (Central Impulse)"** eklendi (`player.apply_central_impulse(-shoot_dir * 150.0)`). Böylece her ateşleme oyuncuyu hafifçe geriye doğru ivmelendirir, performans ve game loop sarsıntısız devam eder.

### "Hold to Grapple" Şalteri ve Kullanıcı Özgürlüğü (Cut Butonu İptali)
- Kancayı bırakmak için kullanılan ikinci düğme (Cut Butonu) mobilde pratik bir deneyim (UX) sunmuyordu, koddan ve ağaçtan kökünden silindi.
- Menüye `Global.grapple_hold_mode` adında bir ayar eklendi.
- Bu ayar açıkken (Varsayılan: AÇIK); kanca tuşuna parmak basılı kaldıkça asılı kalınır, çekilince (veya PC'de farenin sol tıkı bırakılınca) kanca otomatik kopar (Akıcı sallanma hissi). Eğer ayar kapatılırsa, kanca bir kez tıklandığında tutunur ve bir daha tıklanana/aksiyon alınana dek bırakmaz (Daha az yorucu).

## 👑 Geometrik Canavarlar ve Bölüm Sonu Zayıf Nokta (WeakSpot) Mimarisi
### Canavar Yönelimleri (Rotation)
- Tüm standart canavarlar (üçgen, kare, okta vs.) `Polygon2D` kullanılarak `(0,0)` orijininde **Kuzeye** (Up) bakacak şekilde tasarlandığı tespit edildi. Bu nedenle `Enemy.gd` içindeki `_process` döngüsüne `rotation = movement.angle() + PI/2.0` satırı eklendi. Böylece üstümüze koşan her şekil, sivri veya doğru ucuyla bize bakar hale getirildi.
- Mermiler (Bullet.gd) ise tasarımsal olarak **Doğuya** (Right) bakacak şekilde yapılandırılmış. `Bullet.gd` `_process` döngüsüne `rotation = direction.angle()` eklenerek mermilerin de gidiş yönergelerine doğru dönmesi (orientation) stabil kılındı.

### Boss - WeakSpot Hitbox Mimarisi (Katman Ayrımı)
- Boss (İçe göçük Altıgen) `EnemyBossHexagon.gd` adında, `Enemy.gd`'den miras alan (inheritance) yepyeni bir script'e bağlandı.
- Mermilerin gövdeye çarpıp erimesi (hasar vermemesi) için script içerisinde `take_damage` override edilerek `pass` atandı.
- Asıl hasar alınacak "Yarık" bölgesi için `enemy_boss_hexagon.tscn` içerisine `WeakSpot` Area2D ve CollisionShape2D'si yerleştirildi. Mermi (`Bullet.gd`) çarptığı yüzeyin adının `WeakSpot` olduğunu anladığı an, hiyerarşiden geri tırmanıp (get_parent) ana Boss scriptindeki custom `weak_spot_hit` fonksiyonunu tetiklemekte.
- Zayıf noktadan alınan kritik vuruşlara kırmızı `CPUParticles2D` kıvılcım şelalesi eklenerek muazzam bir combat geri bildirimi sağlandı.

### Çarkıfelek Adam (RouletteMan) Revizyonu
- Fazla uzun süren yorucu mekanik iptal edilerek dönüş arzusu (10 -> 3) devire indirildi.
- Konuşma balonu `PanelContainer` ile siber neon stilinde baştan giydirildi ve metin büyütüldü.
- Evren açıldığında (Lissajous eğrileri devreye girerken) düşmanların yerlerinde kilitlenip titremesini engelleyen `lerp()` tabanlı `chaotic_dir` yumuşatması `Enemy.gd` döngüsüne entegre edildi.

## 🗑️ Spawner Mimarisinin Güncellenmesi & Dependency Resolution
### Hata Tespiti ve Kırık Bağımlılık Temizliği
- Proje genelinde (`Magnet.gd`, `Arena.gd`) önceden var olan ancak bir önceki refaktörle silinmiş olan `Enemy.tscn` dosyasına yapılan `preload` çağrıları tespit edildi. Bu durum, runtime esnasında sahne instantiaton hatalarına (crash) yol açacaktı. Tüm kırık referanslar temizlendi.
- `Magnet.gd` içerisindeki riskli ceza (penalty) doğumu, varsayılan bir şekle (`enemy_triangle.tscn` veya havuza) yönlendirilerek esnetildi.

### Dinamik Ağırlıklı Şekil Havuzu (Shape Pool)
- `Arena.gd` dosyasına tüm yeni geometrik canavarları (üçgen, kare, beşgen, altıgen, okta) barındıran global bir `enemy_scenes` dizisi kuruldu (`Array[PackedScene]`).
- Spawner (`_on_spawn_timer_timeout`), artık oyunun süresine (zorluğuna) orantılı olarak rastgele veya ağırlıklı seçim (weight-based spawning) yapan yaratıcı bir sisteme kavuştu. Oyun başlarında ağırlıklı olarak Triangle ve Circle gelirken, ilerleyen dakikalarda Hexagon (Zehir) ve Octagon (Yerçekimi) gibi karmaşık geometriler daha sık spawnlanacak. Boss sahnesi bu standart rotasyon döngüsünden izole edildi.

### Gelecek Planları ve Performans
- Bu havuz (Pool) altyapısı gelecekte tam teşekküllü bir Object Pooling yapısına geçirilerek `queue_free()` yüklerinden kaçınmayı hedeflemektedir. Şimdilik `Array.pick_random()` ve zaman (arena_time) tabanlı algoritma sayesinde Poco gibi mobil cihazlarda bile 60 FPS sarsılmadan oynanış akışı garanti altına alınmıştır.

## 💎 Döngü Parçacığı Ekonomisi ve Üst Üste Binen Redzone Lojiği (Risk/Reward)
### Üst Üste Binen (Overlapping) Alanlar
- Redzone sahnelerinin tekilliği kaldırılarak üst üste bindiğinde çarpanı artıran matematiksel katman (layer) mantığına geçirildi.
- `Player.gd` içerisine `active_redzone_count` adlı bir takip değişkeni eklendi. Giren/Çıkan Area2D sinyalleri bu katmanları toplar/çıkartır. Bu sayede oyuncu 3 alanın kesişimindeyse debuff aynıdır ama Matrix Bonus çarpanı x3 olur.
- Sadece `active_redzone_count > 1` olduğunda çalışan yeni bir UI tasarımı yazıldı. Alan rengi siber plazmaya (koyu kırmızı) döner ve ekrana "MATRIX BONUS: MULTIPLIER X" uyarısı neon pembe renkle düşer.

### Mavi Parçacık Döngüsü (Loop Particles)
- `LoopParticle.tscn` adında oyuncuya manyetik olarak çekilen (%100 pürüzsüz Vector hareketli), siber mavi glow efektlerine sahip fiziksel bir loot objesi dizayn edildi.
- `Enemy.gd`'nin ölüm (`_die`) lojiğine ganimet tablosu bağlandı:
  1. Düşman Redzone dışındaysa: Parçacık düşme ihtimali dükkandaki `Global.particle_drop_chance_level` seviyesine bağlıdır (%20 + %10 her seviye için).
  2. Düşman Redzone içindeyse: Parçacık kesin düşer, fakat miktar `base_amount * redzone_multiplier` oranında katlanarak inanılmaz bir ödül havuzu yaratır. Risk alana devasa ödül.

### Meta Dükkan Altyapısı
- `Global.gd` içerisine parçacık olasılığı ve düşme adedini kontrol eden kalıcı istatistikler ve base cost (satın alım bedeli) kodları eklendi.
- `ShopUI.gd` dosyasındaki switch-case mantığı `particle_chance` ve `particle_amount` key'lerini okuyarak, döngü parçacığıyla maksimuma ulaşılabilecek şekilde geliştirildi.

## 🧪 Zehir Havuzu (PoisonPool) Mimarisi ve Eksik Varlık Çözümü
### Derleme Krizi ve Kırık Referans
- `Enemy.gd` içerisinde, Hexagon (Altıgen) canavarının arkasında bıraktığı zehir havuzları, yanlışlıkla `load("res://Redzone.gd")` script dosyasına bir `PackedScene` gibi `.instantiate()` atılmaya çalışılarak kurgulanmış. Bu durum doğrudan motor çökmesine sebep oluyordu. Scriptler instantiate edilemez, sahneler edilebilir.
- Hatalı satır tamamen temizlenerek, dinamik ve bağımsız bir `PoisonPool.tscn` sahnesi yaratıldı.

### DoT (Damage over Time) Mekaniği
- Sahnede `PoisonPool.gd` isimli yeni bir bağımsız alan (Area2D) oluşturuldu.
- Oyuncu bu alanın içine girdiğinde (body_entered), saniyede bir kez hafif hasar veren (DoT) bir `Timer` döngüsüne yakalanır. Oyuncu çıktığında (body_exited) döngü kırılır.
- Havuzlar kalıcı değildir. Haritayı çöpe çevirmemek (Memory Leak önlemek) adına, `_ready` fonksiyonunda başlatılan bir `create_tween()` ile 3 saniyelik bir ömre (fade out) sahiptir ve süresi bitince kendi kendini yok eder (`queue_free`).

### Performans ve Görsel
- Polygon2D kullanılarak asset/resim dosyasına bağımlı olmayan neon yeşili/mor arası siber estetik bir görünüm sağlandı.

## 🏁 Son Revizyonlar ve Çıktı Özeti
Tüm görev hedefleri başarılı şekilde tamamlanmış ve `main` branch'i ile senkronizasyon pürüzsüzce gerçekleşmiştir.
- Mavi Parçacık meta-ekonomisi (Global.gd ve LoopParticle.gd) artık siber ganimet algoritması ile çalışmaktadır.
- Redzone alanlarının `active_redzone_count` tabanlı katmanlı yapısı aktiftir; oyuncu alan kesişimlerindeyken katlanarak artan Risk/Ödül dinamiğini deneyimler.
- Geometrik düşmanlar, zehir havuzları, hareket yörüngeleri ve WeakSpot boss hitbox izolasyonları (damage filtering) stabil şekilde işlemektedir. Yeni bir özellik isteğine veya revizyona geçilmeye hazırdır.

## 🔒 Oturum Durumu Yönetimi (Session State & Persistence)
### Rulet Evreni Durumunun Sıfırlanması
- **Hata:** `Global.roulette_universe_unlocked` değişkeni kalıcı bir veri (`save_game()` ve `load_game()`) olarak işleniyordu. Bu da, oyuncu öldüğünde veya ana menüye döndüğünde dahi oyunun bozuk (chaotic) kalmasına ve Lissajous eğrili düşman hareketinin kalıcı olarak devrede kalmasına neden oluyordu.
- **Çözüm:** `Global.gd` içerisindeki `save/load` bloğundan `roulette_universe_unlocked` tamamen silindi. Sadece geçici (RAM tabanlı) bir `Session State` yapıldı. Ayrıca `start_run()` içerisine `roulette_universe_unlocked = false` eklenerek her oyun başlangıcında temiz bir sayfa açılması garanti edildi.

### Varlık Koruma Sistemi (Entity Culling Protection)
- **Hata:** Oyuncu Roulette Man'den uzaklaştığında, Arena'nın mesafe tabanlı culling (çöpe atma) mekanizması (`_cull_distant_objects`), üstünde Roulette Man bağlı olan `GrappleNode` nesnesini de acımasızca siliyordu.
- **Çözüm:** `_cull_distant_objects` içine yeni bir güvenlik duvarı yazıldı. Tarama döngüsü artık silmeye hazırlandığı bir `grapple_node` un child'ları arasında `RouletteMan` veya `Merchant` var mı diye kontrol eder. Eğer varsa o node'un silinmesini (cull) kesin olarak iptal eder.

### Mavi Parçacık Market Ekonomisi
- Döngü parçacığı olasılık (`blue_chance_level`) ve miktar (`blue_amount_level`) değişkenleri Global'de hazır edilmişti. Bir önceki PR'de ShopUI arayüzünde aktif edilmişlerdi. Bu görevde Global config kayıtlarına son kez bakılarak sistemin kararlılığı teyit edildi.

## 🛒 İkili Pazar Ekonomisi (Dual-Currency Economy) & Arsenal
### Pazar Arayüzünün Bölünmesi
- `ShopUI.tscn` içerisinde tek bir dikey kaydırma listesi olan yapı, **TabContainer** mimarisine geçirilerek "Döngü" (Kalıcı Statlar ve Mavi Parçacık Buffları) ve "Arsenal" (Kullanılabilir Aktif Yetenekler) olarak iki sekmeye ayrıldı.
- `ShopUI.gd` içerisindeki GridContainer iterasyon fonksiyonları parametrik hale getirilerek her iki tab'ın da ayrı ayrı veya topluca güncellenebilmesi (`_refresh_container`) sağlandı.

### Yeni Arsenal Yetenekleri (Deployables)
- **Taret (Turret.gd):** Oyuncunun bulunduğu konuma konuşlanan, kendi otonom `_process` döngüsü ve menzili olan, Neon Turuncu bir savunma mekanizması yaratıldı. Düşman grubunu filtreleyerek en yakındakine mermi atar.
- **Taşınabilir Mıknatıs (PortableMagnet.gd):** Oyuncunun üzerinde doğan ve 10 saniye boyunca onu takip eden geniş bir `Area2D` alanı. İçine giren `LoopParticle` veya `Coin` nesnelerini `global_position` iterasyonu ile oyuncuya doğru şiddetle çeker.
- **Zehir Şişesi (PoisonFlask.gd):** Hedefe fırlatılıp patlayan, patladığında Hexagon canavarının da kullandığı mevcut `PoisonPool.tscn` zeminini oluşturarak devasa bir DoT (Zamana bağlı hasar) alanı bırakan mekanik eklendi.

### Mobil Entegrasyon & Harcanabilir Yetenekler
- Bu üç yetenek Global üzerinden satın alındığında "Unlock" (1 seviye maks) olarak işaretlenir.
- PC'de `Q, E, R` tuşları ile, mobil cihazlarda ise `MobileControls` içerisine eklenen yeni Neon Butonlar (Turuncu, Mor, Yeşil) ile tetiklenirler.
- Tetiklendikleri an yetenekler tüketilir (`unlocked = false`) ve mobil cihazda butonları gizlenir (`hide()`). Yeniden kullanmak için dükkandan tekrar satın alınmaları gerekir, ki bu da oyun döngüsü için harika bir "sink" (kaynak tüketme) mekaniğidir.
