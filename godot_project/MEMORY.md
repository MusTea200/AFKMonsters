# OYUN MİMARİSİ HAFIZA DOSYASI

## Çözülen Hatalar
* **Ekran Sarsıntı Enflasyonu (Infinite Trauma):** Aynı anda çok sayıda düşmanın ölmesiyle biriken sarsıntı şiddetine üst sınır getirildi. `CameraShake.gd` içindeki trauma değeri clamp fonksiyonu ile maksimum 0.6'da tutuldu. Böylece oyun hissiyatı korunurken baş dönmesi engellendi.

## Matematik Notu
* **Yalancı Mıknatıs (Mimic) Çembersel Spawn Lojiği:** Mimic patladığında düşmanların üst üste binmemesi için çembersel vektör matematiği kullanıldı. Yeni formül: $r$ yarıçap olmak üzere, her düşman $360^\circ / 10 = 36^\circ$ ($2\pi/10$ radyan) açıyla konumlandırıldı: `Vector2(cos(angle), sin(angle)) * r`.

## Gelecek Planı
* **Seyyar Market UI (SpeedMerchant):** "E" tuşuyla açılan, zamanı hafif yavaşlatan ve 3'lü kart sunan sistemin kart (Glassmorphism + Neon Border) sayısının dinamik hale getirilmesi ve farklı RPG havuzlarından stat çekmesi eklenecek.
