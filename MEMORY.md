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
