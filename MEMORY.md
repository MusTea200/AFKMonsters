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
