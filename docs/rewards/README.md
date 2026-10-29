# Kıyı — Rozet, günlük giriş ve jeton ödülleri

26 Ekim 2026. Gerçek geliştirme, Supabase migration ve test teslimatı.

## Tamamlananlar

- Türkiye (`Europe/Istanbul`) gününe göre, yalnız **Ödülü Al** ile günlük jeton. Aynı kimlik/gün için tek işlem; kesintide seri sıfırlanır, bakiye silinmez. 30. günün ardından döngü 1'e döner. İstekte gelen sahip, jeton ve saat bilgileri kullanılmaz.
- 30 günlük takvim, bugünün ödülü, seri/ilerleme, alınan günler ve sonraki büyük ödül.
- Profilde **Günlük ödüller ve görevler** düğmesi. Garajı olmayan hesaplar da erişir. Mevcut Rozetler sekmesi üç bölüme genişletildi. Mevcut davet ekranı gerçek kod/bağlantıya bağlandı.
- Kişisel rastgele davet kodu/bağlantısı, paylaşma/kopyalama, bekleyen/tamamlanan davetler, toplam jeton. Yeni ve e-postası doğrulanmış hesap, davetini kayıt sonrası 7 günde ve ilk aktif kullanımından önce bağlar. URL'deki kod doğrulama sonrası bağlanır.
- Aktif gün: günlük ödül alma veya kabul edilmiş profil/garaj/sosyal işlem. Sadece uygulama açılışı/bundle sorgusu gün saymaz. Üç ayrı Türkiye gününden sonra 75 jeton; aylık en fazla 5. Kota dolan davetler sonraki ay bekler. Kullanıcı paneli açınca veya beş dakikalık sunucu sırası ile işlenir; saatlik yoğunlukta sıra gecikebilir.
- Kendini davet, aynı doğrulanmış e-posta/alias kimliğiyle tekrar kayıt/davet ve tekrar istek kontrolleri. Davet bağı bir kez kurulur. Davet eden hesap daha önce oluşturulmuş olmalı; böylece karşılıklı döngü kurulmaz.
- İlk Anahtar 15, Çifte Garaj 20, Üçlü Garaj 30; ilk otomobil/motosiklet yalnız rozet. 5/10 araç görevi yok. Araç kimliği ve görülen plaka takibi hem silip eklemeyi hem tek aracın plakasını değiştirerek ödül toplamayı engeller.
- Profil 10, ilk gönderi 10, ilk video 10, 10 gönderi 15, 25 gönderi 25, 10 takipçi 10, 100 takipçi 25, ilk özelleştirme 5. Kullanıcı/başarı için tek kalıcı ödeme kaydı.
- Mevcut mor hesap doğrulama işareti ve eski rozetler korunur. Yeni başarılar diğer profillerdeki mevcut Rozetler görünümünde de gösterilir.

## Takvim

| Gün | Jeton |
| --- | ---: |
| 1 | 5 |
| 2 | 5 |
| 3 | 10 |
| 4 | 5 |
| 5 | 5 |
| 6 | 10 |
| 7 | 30 |
| 8 | 5 |
| 9 | 5 |
| 10 | 20 |
| 11 | 5 |
| 12 | 5 |
| 13 | 5 |
| 14 | 30 |
| 15 | 5 |
| 16 | 10 |
| 17 | 5 |
| 18 | 5 |
| 19 | 10 |
| 20 | 20 |
| 21 | 30 |
| 22 | 5 |
| 23 | 5 |
| 24 | 5 |
| 25 | 5 |
| 26 | 10 |
| 27 | 5 |
| 28 | 5 |
| 29 | 10 |
| 30 | 40 |

1–10: **100**, 11–20: **100**, 21–30: **120**; toplam **320**.

## İçerik ve kötüye kullanım kuralları

Gönderi ödülü: en az 24 saat önce yayımlanmış, gizlenmemiş, tekrar metin/medya anahtarı olmayan, en az 12 karakter veya hazır medya içeren ve bekleyen incelemesi bulunmayan içerik. Mevcut medya inceleme kuyruğu sonuçlanmadan video ödülü verilmez. Takipçi ödülü: e-postası doğrulanmış, en az 7 günlük hesap, 24 saattir mevcut takip, üç aktif gün, aktif/engelsiz ilişki. Bunlar otomatik risk azaltma kurallarıdır; farklı gerçek e-postalarla açılan tüm sahte hesapları veya anlamsal spamı kesin olarak tespit etme garantisi değildir. Yeni ücretli kimlik/cihaz doğrulama servisi eklenmedi.

## Geçiş kuralı

Migration anındaki tamamlanmış görevlerin ve mevcut rozetlerin anlık durumu `reward_legacy` ile saklanır. Daha sonra e-postasını doğrulayan eski hesap da kapsanır. Bu görevler **0 jetonluk tüketilmiş ödül** olarak işaretlenir; mevcut bakiye değişmez. Gelecekteki yeni eşik/görev normal ödül verir. Geçmişte silinmiş ve mevcut rozet/veri kaydı bulunmayan eylemler yeniden üretilemez; mevcut kalıcı rozetler bu durumda da korunur. Geçmiş ödüller için toplu geriye dönük jeton dağıtılmadı.

## Veritabanı ve güvenlik

Uygulanan migration'lar, canlı migration geçmişiyle aynı adlarla:

- `20261026161439_loyalty_rewards.sql`
- `20261026162251_loyalty_invite_settlement.sql`
- `20261026163037_loyalty_vehicle_identity.sql`
- `20261026163729_loyalty_config_validation.sql`

Mevcut `kiyi_wallets`, `kiyi_ledger`, `kiyi_badges`, `kiyi_vehicles`, `kiyi_profiles` ve mevcut komut RPC'si kullanılır. Cüzdan/hediye/satın alma fonksiyonları yeniden oluşturulmadı. `kiyi_badges` kod kısıtı genişletildi. Komut yönlendirmesi yedeklenerek sarıldı; araç kimliği ve hesap silme tetikleyicileri eklendi.

Yeni, istemci erişimi kapalı `kiyi_private` tabloları: `reward_backup`, `reward_settings`, `reward_rules`, `reward_identity`, `reward_awards`, `reward_legacy`, `reward_days`, `reward_daily`, `reward_vehicles`, `reward_codes`, `reward_invites`, `reward_config_audit`, `reward_vehicle_ids`, `reward_vehicle_plates`. Tümünde RLS açık ve anon/authenticated doğrudan okuma/yazma yetkisi yok. Yalnız mevcut oturum ve hesap doğrulamasını geçen RPC ilgili kullanıcının verisini döndürür. İç yardımcı fonksiyonlar istemciye kapalıdır.

Ödeme, mevcut kullanıcı cüzdan kilidi + benzersiz ödül anahtarı + tek transaction içindeki cüzdan ve defter yazımıyla yapılır. Başarısız defter yazımında ödül ve bakiye birlikte geri alınır. Ödül tutarları yalnız sunucudaki yapılandırmadan alınır. `reward_admin` mevcut yönetici/MFA yetkilendirmesini kullanır ve değişiklik nedenini/eski-yeni değerleri kaydeder. Yeni yönetici paneli formu bu görevde eklenmedi; yapılandırma altyapısı ve korumalı API hazır.

Doğrulanmış e-posta sunucu anahtarlı HMAC ile eşleştirilir, ham e-posta ödül tablolarına kopyalanmaz. Bu özet gerçek kişi doğrulaması değildir. Hesap silme tetikleyicisi günlük ilerlemeyi, davet bağlarını ve kişisel araç geçmişini temizler. Mali kayıt ve mükerrer ödül önleme özeti korunabilir; işletmeci kesin saklama sürelerini/hukuki dayanağı onaylamalı. Gizlilik açıklaması güncellendi.

## Veri ve fiyat koruması

Önce/sonra kontrol toplamları aynı:

| Kontrol | MD5 |
| --- | --- |
| Mevcut cüzdanlar | `47df1633108d57bd3da99562cbffb81a` |
| Hediye/ürün kataloğu | `f83daf2b33e76bfc737b6276abc3b216` |
| Jeton paketleri | `211f79b52fab865c49b3a9f327bf4be7` |
| Araç parça fiyatları | `c412e11a5cffc06e61874e72d3033c4c` |

Önceden var olan tek gerçek profil korunmuştur. İki geçici gerçek Auth hesabı tamamen temizlendi; bu hesapların bakiyeleri/deneme kayıtları dışında hiçbir kullanıcı bakiyesi test için değiştirilmedi. Gerçek kullanıcılara test bildirimi/e-posta/hediye gönderilmedi.

## Testler

- **204/204** Node testi (mevcut 199 + 5 yeni), sıfır başarısız/atlanan.
- Geçersiz NULL/negatif/500 üstü ödül takvimi değişiklikleri reddedildi; takvim korunuyor.
- Üretim derlemesi, tarayıcı JS sözdizimi ve istemci gizli anahtar taraması.
- `loyalty-rewards.sql`: günlük ilk alım, aynı gün tekrar/sahte miktar, 7/10/14/21/30/31 günleri, Türkiye gün sınırı, seri sıfırlama, davet tekrar/kendi daveti/üç gün/aylık beş sınırı, araç tekrar, içerik uygunluğu, RLS/admin erişimi, defter hatasında atomik geri alma. Geçici transaction verileri ROLLBACK edildi.
- `loyalty-eligibility.sql`: motosiklet, gerçek özelleştirme kaydı, hazır fabrika renginin tek başına yetmemesi, 10 uygun takipçi, incelenmemiş video için ödül verilmemesi, inceleme sonrası ödeme, doğrulanmamış hesabın reddi.
- `loyalty-thresholds.sql`: 100 uygun takipçiyle 10/100 eşiklerinin birer kez ödenmesi, profil tamamlama.
- `loyalty-vehicle-identity.sql`: aynı araçta plaka değişimi, değiştirilmiş plakayı yeni araç kimliğiyle ekleme, hesap silmede özel ilerlemenin temizlenmesi.
- `loyalty-settlement.sql`: sunucu sırası ile uygun davet ve aylık kota.
- `loyalty-legacy.sql`: migration öncesine eklenen doğrulanmamış eski profil, korunmuş rozet ve sonradan doğrulama; geriye dönük jeton yok. Bu dosya migration öncesi/sonrası birleştirilerek geri alınan testte çalıştırılır; hazır sisteme doğrudan uygulanmaz.
- Mevcut `domain-integration.sql` ve `stage3-garage.sql`: hediye, cüzdan/finans yetkileri, envanter, sosyal özellikler, karma garaj ve atomik araç parça alımı regresyonları geçti.
- Gerçek Auth/API testi: iki hesap, iki cihaz oturumu, sekiz eşzamanlı günlük talep → **tek 5 jeton ve tek defter kaydı**. Diğer hesabın bakiyesi değişmedi. Davet kodları ve tekrar bağlama çalıştı; tek aktif gün 75 jeton kazandırmadı. Yetkisiz admin/bakiye yazımı ve iptal edilen oturumla talep reddedildi.
- Geri alma dosyası transaction içinde denendi; eski dispatcher geri geldi ve cron durdu. Test sonunda ROLLBACK ile yeni sistem korundu.
- İzole SQL CI listesine yeni temel/uygunluk/eşik/araç/davet testleri eklendi. GitHub Actions'ın uzak çalışması bu teslimatta tetiklenmedi; gerekli izole DB Secrets yoksa ilgili iş çalıştırılamaz.

## Başarısız/sonuç alınamayan ilk denemeler

İlk SQL denemesinde `d.owner` isim çakışması düzeltildi. Bir uzun birleşik test MCP `requestState`/zaman aşımı nedeniyle doğrulanamadı; küçük gruplar ve son tam test başarılı çalıştı. Test fixture'ında döngü `i` isim çakışması, eksik gönderi `visibility` değeri ve mevcut benzersiz plaka kuralına uymayan silme senaryosu düzeltildi. İlk gerçek Auth fixture temizliği mevcut `ops_activity` FK'si yüzünden transaction olarak geri alındı; yalnız test hesaplarının `ops_activity`/`ops_presence` satırları temizlenerek ikinci deneme başarılı oldu. Hiçbiri başarılı test gibi sayılmadı.

## Güvenlik danışmanı ve sınırlar

Yeni özel tablolar için RLS açık/politika yok INFO kaydı beklenen kapalı modeldir; doğrudan istemci yetkileri yoktur. Önceden bulunan **sızdırılmış parola koruması kapalı** uyarısı devam ediyor: https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection . Bu görevde Auth planı/hesabı değiştirilmedi. Yönetici API'sinin normal hesap reddi test edildi; gerçek yönetici MFA oturumuyla tutar değiştirme uçtan uca denenmedi.

Gerçek cihaz, fiziksel klavye, 30 gerçek takvim günü bekleme veya e-posta teslimatı testi yapılmadı. Auth test hesapları sunucu sahibi tarafından e-postası doğrulanmış olarak hazırlanmıştır; milestone/seri testleri kontrollü SQL fixture'larıdır. Yeni ekranların girişli mobil görsel kontrolü ayrıca sınırlıdır; sahte testleri gerçek cihaz testi olarak raporlamıyoruz.

## Geri alma

Önce önceki Site sürümüne dönülür; ardından `supabase/rollback/loyalty-rewards.sql` kontrollü olarak uygulanır. Dosya sunucu ödül sırasını durdurur ve önceki dispatcher'ı yedekten geri getirir. Kazanılmış jeton, defter, rozet ve özel denetim tabloları **silinmez**, bakiyeler geri çekilmez. Canlı sisteme geri alma uygulanmadı; yalnız geri alınan transaction içinde doğrulandı.

## Değişen dosyalar

`public/loyalty-rewards.js`, `public/loyalty-rewards.css`, `public/kiyi.html`, `public/privacy.html`; yukarıdaki dört migration; `supabase/rollback/loyalty-rewards.sql`; altı SQL test dosyası, Node test dosyası ve gerçek Auth test sürücüsü; `scripts/test-isolated-db.py`; bu rapor ve test kanıtları.
