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
