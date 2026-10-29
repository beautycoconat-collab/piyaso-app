# Kıyı Aşama 2 — altyapı teslimi

24 Ekim 2026. Çoklu garaj ve güvenli medya altyapısı uygulandı. Aşama 3 başlatılmadı.

## Uygulanan migration'lar
- Önceki `stage2_vehicle_catalog` korundu: 21 otomobil, 18 hazır olmayan motosiklet.
- `stage2_multi_garage`: araçlar, araca bağlı görünüm, model/parça uyumluluk kataloğu, mevcut araçların eklemeli aktarımı, yetkili komutlar.
- `stage2_secure_media`: özel medya kayıtları, sunucudan yükleme, kota rezervasyonu, referans koruması ve saatlik Storage API temizliği.
- `stage2_media_scheduler_dependency`: eksik pg_net eklentisi kuruldu; net şeması ve fonksiyonları anon/authenticated erişimine kapatıldı.
- `kiyi-media` Edge Function yayınlandı. Yüklemede kullanıcı token'ı Auth sunucusundan doğrulanır. Temizlemede özel anahtar DB tarafından doğrulanır. Platform JWT kapısı bu iki ayrı kimlik kontrolü nedeniyle kapalıdır; kimliksiz yükleme açık değildir.

## Garaj ve veri korunması
`kiyi_vehicles` her araca ayrı UUID verir; aynı hesapta otomobil ve motosiklet saklanır. İlk araç eski profilin plakasını, modelini, renk ve plaka tasarımını korur. Model seçmemiş eski hesaplar da desteklenir. Plakalar normalize edilir ve profil/garaj arasında çakışma engellenir.

`kiyi_vehicle_customizations` renk, plaka tasarımı ve isimleri, kaplama, jant, far, araç altı ışığı ve cam/tavan aksesuarlarını araç UUID'siyle saklar. Sürüm kontrolü eski ekranın yeni kaydı ezmesini engeller. Mevcut satın alınmış renk/plaka hakları ve finansal kayıtlar korunur; mevcut fiyat, envanter ve atomik kredi işleminden yararlanılır. Satın alma hakkı hesap envanterinde kalır, seçilen görünüm araç bazındadır. Profil çerçevesi profil özelliği olarak kalır.

Garaj ekranına “Garajım · Tüm araçlar” girişi eklendi. Araç ekleme ve araç seçerek görünüm kaydetme çalışır. Birincil araç profilin mevcut aracıdır; bu aşamada birincil değiştirme/silme arayüzü eklenmedi. Bunlar veri korumak için gerekli olmayan ek işlevlerdir.

Motosikletler garaja kaydedilebilir; hazır olmayan model açıkça belirtilir. Görsel veya özelleştirme önizlemesi gösterilmez; sunucu da özelleştirmeyi reddeder. 18 model ve 11 parça alanının hazırlık durumu korunur.

## Medya
Fotoğraf JPEG/PNG/WebP, video MP4/WebM ve mevcut ses MP4/WebM desteklenir. Dosya başlığı sunucuda kontrol edilir; SVG ve türü uyuşmayan içerik reddedilir. Bu kontrol tam video codec/transcode veya antivirüs taraması değildir.

Sınırlar: fotoğraf/ses 5 MiB, video 20 MiB, hesap 50 MiB, ortak proje için 500 MiB uygulama bütçesi; hesap başına saatte 30 rezervasyon. Proje kontrolü diğer bucket'ların kullanımını da sayar. Rezervasyonlar kilit altında atomiktir; aynı anda yükleme kotayı aşamaz. Bunlar uygulama sınırlarıdır; plan kotasını büyütmez ve bant genişliği için sınırsız kullanım garantisi vermez.

Bucket özel kalır. Yeni dosyalar yalnızca sunucudan yüklenir; tarayıcıdaki eski doğrudan yükleme yolu RLS ile engellenir. Kullanıcı, MIME, gerçek byte sayısı, boyut ve Storage metadata doğrulanır. İmzalı okuma linkleri mevcut 60 saniyelik erişim akışını kullanır; takipçi görünürlüğü, engelleme ve moderasyon kontrolleri korunur.

Silinen gönderinin medyası kuyruğa girer. Referansı bulunan dosya silinmez. Yarım yükleme 1 saatten, kullanılmayan tamamlanmış yükleme 24 saatten sonra temizliğe adaydır. Saatlik görev Storage API ile dosyayı siler; hata olursa kayıt tutulup sonraki çalışmada tekrar denenir. Temizlik için storage.objects satırları doğrudan silinmez.

## Sosyal sistem
Mevcut takip, favori, engelleme, beğeni, yorum, anket, hediye ve bildirim komutları korunur. Yeni geniş doğrudan tablo erişimi açılmadı. Garaj ve özelleştirme tablolarında RLS açık ve anon/authenticated doğrudan tablo grant'ı yok; sahiplik private dispatcher içinde denetlenir. Okunabilir model ve parça kataloglarında yalnız SELECT politikası bulunur. Durum düzenleyicisine fotoğraf/video seçimi, video gösterimi ve nesne biçimindeki yorum profilini gösterme düzeltmesi eklendi.

## Testler ve sonuçlar
- Node: 117 test geçti; 0 başarısız, 0 atlandı.
- Üretim derlemesi geçti; Site 113. sürüm olarak yayınlandı. Canlı Edge endpoint oturumsuz isteğe HTTP 401 verdi.
- Gerçek Supabase üzerinde `tests/stage2-catalog.sql`, `tests/domain-integration.sql`, `tests/stage2-garage-media.sql` transaction içinde çalıştırıldı; test verileri geri alındı.
- İki ayrı auth kullanıcı kimliğiyle garaj ayrımı, yetkisiz renk kaydı, plaka çalma engeli, hazır olmayan motosiklet, eski sürümle kayıt, farklı araca renk kaydı ve parçaların kalıcılığı doğrulandı.
- Gerçek DB: takipçi durumları, oy, beğeni, yorum, silme yetkisi, engelleme, hediye atomikliği ve cüzdan izolasyonu geçti.
- Medya: geçersiz tür, aşırı boyut, yetkisiz worker erişimi, referanslı dosyanın korunması, gönderi silme kuyruğu ve Storage dosyası silinmeden ack reddi geçti. Edge birim testleri başlık doğrulaması, kimliksiz erişim, sınırlar ve reserve→upload→confirm sırasını doğruladı.
- Geri alma SQL'i gerçek DB'de transaction içinde çalıştırılıp ROLLBACK ile test edildi; aktif sistem kapatılmadı.
- Canlı veri kontrolü: 39 model, 1 profil, 1 cüzdan, 1 aktarılmış araç, 0 hediye. Eski plaka/renk/plaka stili ile yeni birincil araç arasında 0 fark; garaj tablolarında 0 güvensiz grant. Test kullanıcıları kalıcı bırakılmadı.

## Bulunan ve giderilen test hataları
1. Model seçmemiş eski hesapta plaka satın alma engelleniyordu; eski araç uyumluluğu düzeltildi.
2. Garaj liste sorgusunda PL/pgSQL değişkeni ile tablo alias'ı çakışıyordu; alias'lar düzeltildi.
3. Medya boyut koşulunda CASE ifadesinin parantezi eksikti; SQL düzeltildi.
4. Temizlik testinin sentetik Storage metadata satırını doğrudan silme denemesi Supabase tarafından reddedildi. Koruma aşılmadı; test Storage API silinmeden ack reddini ve ayrı dosyasız rezervasyonda ack işlemini doğrulayacak şekilde düzeltildi. Uygulama temizlik işçisi zaten Storage API kullanır.

5. Gerçek temizleme çağrısında pg_net eklentisinin kurulu olmadığı bulundu. Ayrı migration ile kuruldu; normal kullanıcıların network fonksiyonlarına erişimi kapatıldı ve çağrı tekrarlandı.

6. Geçici test hesabının temizliğinde mevcut ops_activity/ops_presence foreign key’leri silmeyi engelledi. Yalnız bu geçici hesaba ait test aktivitesi ve presence satırları temizlenerek test hesabı kaldırıldı; mevcut hesaplara dokunulmadı.

## Doğrulama sınırları ve kalanlar
İki kullanıcı veri ayrımı testi SQL rol/JWT bağlamında yapıldı. Ayrıca geçici test hesabıyla gerçek Auth girişi, gerçek PNG dosyasının Edge üzerinden Storage’a yüklenmesi, imzalı özel erişim, medyalı gönderi oluşturma ve gönderiyi silme başarıyla doğrulandı. Tarayıcı önizlemesi başka bir vinext sunucusunun çalışması nedeniyle açılamadı; iki fiziksel cihaz testi yapılmadı. Saatlik cron etkinliği doğrulandı; zamanlanmış saati bekleme yerine aynı temizleme HTTP çağrısı ayrıca tetiklendi: HTTP 200, deleted=1, pending=0. Gerçek dosya Storage’dan ve kayıt tablosundan kaldırıldı. Test hesabı ve oturumu temizlendi.

Keşfet tasarımı, rozetler, motosiklet görselleri, codec dönüştürme, antivirüs, eski D1/R2 kimlik eşleştirme/importu bu aşamada yapılmadı. Mevcut D1/R2 verileri korunur. Motosiklet özelleştirmesinin açılması görsel/katman doğrulaması gerektirir.

## Geri alma
`supabase/rollback/stage2-disable.sql` önceki frontend'e dönüşle birlikte yeni komutları devre dışı bırakır; araç, özelleştirme, medya ve satın alma kayıtlarını silmez. Sunucu yükleme güvenlik kapısı açık tutulur; eski güvensiz upload'a geri dönülmez. Fonksiyonların önceki tanımları private yedek tablolarda tutulur. Yeniden etkinleştirme için yeni fonksiyon tanımları ve worker grant'ı geri yüklenir, cron yeniden kurulur. Yeni garaj tabloları katalogla bağlıyken eski katalog DROP rollback'i çalıştırılmamalıdır. Finansal kayıtları veya mevcut kullanıcı tablolarını silen migration yoktur.

## Değişen dosyalar
- public/vehicle-garage.js
- public/supabase-account.js
- public/status-system.js
- public/kiyi.html
- supabase/migrations/20261024133403_stage2_multi_garage.sql
- supabase/migrations/20261024133534_stage2_secure_media.sql
- supabase/migrations/20261024134753_stage2_media_scheduler_dependency.sql
- supabase/functions/kiyi-media/index.ts
- supabase/rollback/stage2-disable.sql
- tests/stage2-garage-media.sql
- tests/stage2-media-edge.test.mjs
- docs/admin/stage2-progress.md

## Değişen tablolar
Yeni: public.kiyi_vehicles, public.kiyi_vehicle_customizations, public.kiyi_vehicle_parts; kiyi_private.stage2_garage_backup, stage2_media_backup, media_registry, media_cleanup, media_worker_secret.
Mevcut: storage.buckets sınırları; storage.objects yeni restrictive INSERT politikası; kiyi_posts ve kiyi_profiles referans koruma trigger'ları; cron.job temizlik görevi. Katalog, envanter, kredi, hediye ve sosyal kayıtlar korunur.
