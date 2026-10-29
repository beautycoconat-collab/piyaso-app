# Rozet sayfası — kompakt tasarım revizyonu

Yalnız `public/badge-levels.js`, `public/badge-levels.css` ve HTML varlık sürümleri değişti. Veritabanı/migration/ekonomi dosyaları değişmedi.

Yerleşim yeniden kuruldu: küçük ikonlu özet, tek satır ikonlu kategori filtreleri, 7 günlük sayfalanmış ödül takvimi, takvim noktaları ve 7. güne hediye çizimi. Davet aşamaları çizgilerle bağlı yatay sırada; ödül mevcut sunucu verisinden gelir. Garaj ve Keşfet satırlarında beş kart; Topluluk ve Özel satırlarında kısa yatay kartlar var. Büyük Kıyı yazılı eksik görsel alanları küçük nötr kilit görünümüyle değiştirildi. Görseller contain ve multiply ile oranı bozulmadan gösteriliyor. Önceki hazır görseller değiştirilmedi.

Dört seviyeli Gönderi grubu arayüzde “Gönderi Serisi” olarak ayrılıyor. Bağımsız İlk Gönderi, 10 Gönderi ve 25 Gönderi eski kazanımlarının kayıtları ve ödül hakları korunuyor. Varsa mevcut tek görev ödülü sunucunun achievements.amount değerinden yalnızca gösteriliyor; rozet seviyelerine ödül eklenmedi.

211/211 Node testi geçti. Browser JavaScript sözdizimi kontrolü geçti. Mobil görünüm için 390px iframe kontrolü denendi ancak tarayıcı güvenlik politikası data URL gezinmesini engelledi. Bu engel aşılmadı; fiziksel iPhone veya mobil ekran görüntüsü doğrulanmış değildir. Normal canlı tarayıcı kontrolü ayrıca yapılır.

GitHub teslimi önceki engelle aynı: bağlı hesapta Kıyı deposu/yazma erişimi tespit edilemiyor. Sites kaynak deposuna kayıt GitHub gönderimi olarak sunulmaz.
