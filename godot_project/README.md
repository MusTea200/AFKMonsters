# GITHUB HAFIZA PROTOKOLÜ (GITHUB MEMORY PROTOCOL)

## Sorun Tespiti (Mermi Ateşleme Hatası)
Mobil platformlarda mermi ateşleme sisteminin çalışmamasının temel sebebi `CombatComponent.gd` içerisindeki hedefleme (targeting) mekanizmasıdır. Ancak mermilerin yönünü sadece fare (mouse) konumuna göre almak veya sadece en yakındaki düşmana atmak, dokunmatik ekranlı mobil cihazlarda bir tutarsızlığa neden olur. Eğer oyuncu ekrana hiç dokunmazsa (fare konumu sıfırlanmışsa) veya düşman yoksa mermi üretimi başarısız olmaktadır. Aynı sorun gamepad veya sanal joystick kullanımında "manuel nişan" (manual aim) eksikliğiyle de belirginleşmektedir.

## Mimari Değişiklik ve Çözüm (Aim Vector)
1.  **CombatComponent.gd Güncellemesi:** Ateşleme yönü belirlenirken `get_global_mouse_position()` bağımlılığı tamamen kaldırılacak. Eğer `Global.current_input_type == Global.InputType.TOUCH` ise veya `JOYPAD` aktifse, atış yönü doğrudan VirtualJoystick (sağ joystick) veya Gamepad sağ analog vektöründen (Input.get_vector() veya get_joystick_vector()) alınacak.
2.  **Sanal Joystick Entegrasyonu:** `Arena.tscn` içine bir `VirtualJoystick` eklenmemiş veya silinmiş. `Arena.gd` içerisinde kodla veya `Arena.tscn` içine bir joystick eklenecek.

## Performans ve Gelecek Planları
*   **Optimizasyon:** Sağ ve Sol Joystick'ler sadece dokunmatik ekran algılandığında veya `TOUCH` modunda aktif olacak (`visible = true`).
*   **Esneklik:** Sanal Joystick vektörü normalize edilerek sadece yön bilgisi alındığından, farklı çözünürlüklerdeki (Aspect Ratio) bozulmaların önüne geçilecek.
