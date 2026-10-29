# Kıyı — Dört seviyeli rozetler

Profil → Rozetler: genel sayaç ve ilerleme, Tümü/Garaj/Keşfet/Topluluk/Özel filtreleri, yatay günlük takvim, mevcut davet ekranına bağlantı, kategori listeleri, Tümünü gör ve dört seviye detayları.

42 kaynak ikon 320 px WebP biçiminde, oranı korunarak içe aktarıldı. Renk değiştirilmedi, kırpılmadı. 16 tanımın kazanılmış görseli eksik; `missing-art.md` listeler. Gri Gümüş kaynakları kilitli görünümde kullanılır. Mor profil doğrulama işareti değişmedi.

Sunucu: 28 seviye (7×4) ve 18 tek görev; eşikler katalogdan gelir. Yeni rozetler jeton vermez. Önceki 14 rozet kodu ve jeton ödülleri korunur. Günlük döngü 320, başarılı davet 75; hediye, paket ve özelleştirme fiyatları değişmez.

Sayım: 24 saatlik, benzersiz, kaldırılmamış ve bekleyen şikâyeti olmayan gönderi/yorumlar; medyada hazır dosya ve moderasyon şartı. Diğer doğrulanmış, en az 24 saatlik hesapların beğenileri. Hediye/şarkıda eşleşen eksi ledger kaydı gerekir; iade veya yönetici geçersizliği hariçtir. Davette mevcut doğrulama ve üç aktif gün gerekir; aylık ödeme kotası dolsa da uygun davet rozet ilerlemesinde sayılır.

Harita: mevcut doğrulanmış konum yazımından bölge, kullanıcı ve Türkiye günü kaydedilir. Aynı bölge/gün tekildir. Paylaşım kapalıyken ve hayalet modda ilerleme yazılmaz. Ultra üç bölgenin her birinde en az bir kayıt ve toplam 30 bölge-gün ister. Eski konum geçmişi saklanmadığından geçmiş harita ziyaretleri uydurulmaz. Silinen içerikler yeni seviyeleri geri çekebilir; önceki tek rozetler korunur. Kazanım satırı tekildir ve ilk kazanım tarihi korunur.

Migration: `20261026195043_badge_levels.sql`, `20261026195741_badge_visibility.sql` Supabase’e uygulandı. Altı yeni özel tablo RLS açık, doğrudan istemci izinleri kapalıdır. Yeni işlem mevcut oturum/hesap/hız denetiminden geçer. Başka profil yalnızca önceki görünürlük denetimi izin verirse okunur. Yönetici geçersiz kılma ops.write, MFA ve etkin yönetici oturumu gerektirir. Hesap silme ilerleme ve bölge-gün kayıtlarını temizler.

Geri alma: `supabase/rollback/badge-levels.sql` eski dispatcher’ı geri getirir, kazanım/cüzdan verisini silmez. Canlıya uygulanmadı; transaction içinde test edilip geri alındı.

Doğrulama: bağlı veritabanında bütün eşikler, beğeni/yorum tekrarı, hediye/şarkı/iade, doğrulanmış davetler, harita günlük tekillik/hayalet/Ultra ve jeton korunması geçti. Ek testte medyanın inceleme şartı, engellenen profil, iptal edilmiş Onaylı/Premium rozetlerinin görünmemesi ve hesap silme geçti. İki geçici gerçek Supabase Auth hesabı, iki cihaz ve dört eşzamanlı okuma testinde sahiplik sahteciliği, doğrudan tablo/RPC yazımı ve yönetici girişimi reddedildi; oturum iptali sonrası token reddedildi. Hesaplar ve test kayıtları temizlendi. Gerçek kullanıcılara test bildirimi gönderilmedi.

Koruma kontrol değerleri önce/sonra aynı: wallets `47df1633108d57bd3da99562cbffb81a`, ürün fiyatları `7d54cdb0db7747a14696783d85408190`.

Başarısız ilk denemeler: test kullanıcı adının uzunluğu, entitlements fixture satırının eksikliği, kiyi_blocks fixture sütun sayısı düzeltildi. Bir RLS toplu sorgusu yanlışlıkla indeksleri de kapsayıp false döndürdü; yalnız tablolarla yinelenince altısında da true doğrulandı. Yerel tarayıcı önizlemesi terminal.local:4173 üzerinde ERR_CONNECTION_REFUSED verdi. Fiziksel telefon ve girişli mobil görsel kontrolü yapılmadı. Otomatik sahte hesap tespiti kesin kimlik doğrulaması değildir. Mevcut sızdırılmış parola koruması uyarısı bu görevden önce vardı, Auth ayarı değiştirilmedi.

Teslim sınırı: erişilebilir GitHub depoları yalnız ai-betting-lab ve sportsbetting; Kıyı deposu ve yazma yetkisi tespit edilemedi. Başka projeye kod gönderilmedi. Sites kaynak deposu GitHub teslimatı olarak gösterilmez.
