# Profil, plaka ve jant düzeni — 26 Ekim 2026

- Araçsız gerçek hesapta Garajım / Gönderiler / Rozetler sekmelerini gizleyen koşul kaldırıldı. İlk plaka kartı Garajım içinde; ilk başarılı kayıttan sonra mevcut yönetim özeti kullanılıyor.
- Boş kart daha kısa, daha küçük araç çizimi ve 44 px eylem alanıyla düzenlendi.
- Dekoratif plakaların 430×78 alana zorlanması ve metnin yatay esnetilmesi kaldırıldı. Mevcut çerçeve varlıkları ve klasik plaka korundu.
- Garaj araç çizimi, plaka stilini ve isimlerini kendi araç kaydından alıyor.
- Ek otomobil modellerinde jantlar, büyütülmüş kaplama maske elipsleri yerine ölçülmüş jant yüzlerine yerleşiyor. İlk yedi modelin mevcut kalibrasyonu korunuyor.

Doğrulama: 206/206 Node testi geçti; JavaScript sözdizimi geçti. İlk denemede model wheels listesindeki üçüncü geometrinin jant olarak kullanılması testte yakalandı; düzeltildi ve tüm testler yeniden geçti. Canlı kullanıcı verisi ve fiyatlar değiştirilmedi; migration yok.

Görsel sınır: Yerel önizleme terminal.local:4173 tarayıcıda ERR_CONNECTION_REFUSED verdi. Gerçek girişli mobil cihazda jantların son görünümü bu ortamda doğrulanamadı. Kod/ölçüm testleri fiziksel cihaz testi değildir.

## Ek tarayıcı kontrolü
Canlı v146 üzerinde üç profil sekmesi arasında geçiş doğrulandı. Jant önizlemesinde 234 px iç alana 353 px SVG yerleştiği ve eski sticky `top` değerinin relative kutuyu 48 px aşağı ittiği ölçüldü. SVG iç sarmalayıcısı mevcut alanın yüksekliğine sınırlandı, relative kutunun top/bottom değerleri sıfırlandı. Bu kontrol girişsiz masaüstü tarayıcıda yapıldı; girişli fiziksel cihaz kontrolünün yerine geçmez.
