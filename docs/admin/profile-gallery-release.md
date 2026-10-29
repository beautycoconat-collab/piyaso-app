# Üç profil fotoğrafı ve konum gönderimi güncellemesi

23 Ekim 2026. Kullanıcının açık talebi: gönderilerde fotoğraf/video paylaşımı kapansın, profile en fazla üç fotoğraf eklensin ve durağan araç daha seyrek konum göndersin.

- Gönderi düzenleyicisinden kamera/galeri girişleri kaldırıldı. Eski taslaktaki görsel yeni gönderiye dönüşmez. Supabase RPC ve eski D1 gönderi API’si de yeni görsel ekini reddeder. Yazı, müzik bağlantısı, anket ve mevcut ses kaydı korunur. Geçmiş gönderiler silinmedi.
- Profilde ana fotoğraf, ekleme/değiştirme/kaldırma, ana fotoğraf seçimi, ileri/geri ve dokunmatik kaydırma. İlk görsel listelerde; diğerleri yalnız görüntüleyici açıldığında alınır. Demo fotoğrafları cihazda, gerçek hesap fotoğrafları yetkili Supabase Storage’da.
- Yüklemeden önce en uzun kenar 1280 piksele, JPEG en fazla 400 KiB’a dönüştürülür. En fazla 8 MiB JPG/PNG/WebP girdi kabul edilir. Canvas dönüşümü dosyanın EXIF bilgisini yeniden taşımaz.
- `profile_photos_update` en fazla üç benzersiz, sahip olunan görseli kabul eder. Normal profil yazımıyla galeri sınırı aşılamaz. Özel/engelli/pasif hesap ve gizlenmiş fotoğraf erişimleri korunur. Ek görseller genel profil DTO’suna eklenmedi.
- Galeriden çıkan dosya, profil/araç fotoğrafı veya geçmiş gönderi tarafından kullanılmıyorsa Storage API ile temizlenir. Başarısız temizleme kullanıcıya bildirilir; Storage tablosundan elle nesne kaydı silinmez.
- Hareketli/şüpheli ölçüm: 5 saniye. En az üç güvenilir ölçüm ve 20 saniye durağanlık sonrası: 30 saniye. 25 metreden kötü doğruluk durağan kabul edilmez. Hareket başlayınca bekleme uzatılmaz.
- Watch sessizleştiğinde, paylaşım açık ve uygulama görünürse taze GPS okuması istenir; eski koordinata yeni zaman damgası üretilmez. Süresi geçmiş/tekrarlı ölçüm gönderilmez. Durma, oturum değişimi, görünmez sayfa ve geç gelen eski callback denetlendi. Sunucudaki 90 saniyelik görünürlük sınırı uzatılmadı.
- Admin plaka/araç ekranında ek profil fotoğraflarını inceleme, gizleme ve yeniden gösterme eklendi. Yeni tablo veya rol yetkisi açılmadı.

Doğrulama: ana uygulama 87 test; admin 29 test grubu. SQL testleri PGlite üzerinde izole veri kullanır. Gerçek telefon/iOS GPS sürüş testi değildir. Tarayıcı önizlemesi erişim/ortam engeline takıldığından görsel QA tamamlanmış sayılmadı. Üretimde örnek fotoğraf veya konum oluşturulmadı.

Bu sürüm genel bundle yenilemesini parçalara ayırmaz; kullanıcının bu konudaki sorusu açıklanmıştır. Tasarrufun toplam faturaya etkisi ölçülmemiştir.
