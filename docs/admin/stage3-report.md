# Kıyı — Aşama 3 teslim raporu

24 Ekim 2026. Aşama 2 tabloları yeniden oluşturulmadan Garajım ve motosiklet özelleştirme akışları geliştirildi. Aşama 4 başlatılmadı.

## Kullanıcıya açılanlar
- Profilde Garajım sekmesi ve araç sayısı. Kompakt görsel kartlar; tür, marka/model, plaka, detay ve özelleştirme bağlantıları. Tümü/Otomobil/Motosiklet filtreleri. Boş durumda İlk Aracını Ekle.
- Tür→marka→model→plaka→mevcut renk sırasıyla gerçek hesapta araç ekleme. Otomobil kataloğu 21, motosiklet kataloğu 18 model. Aynı normalize plaka ikinci kez eklenmez; profil plakalarıyla da çakışamaz.
- Plaka ve görünürlük düzenleme, profil/harita aracını seçme, geri alınabilir kayıt durumuyla garajdan kaldırma. Silme fiziksel DELETE değildir; eski plaka ve görünüm kayıtları korunur. Doğrulanmış birincil plakanın değiştirilmesi/silinmesi mevcut talep kuralına bağlı kalır.
- Her motosikletin kendi appearance kaydı, ücretsiz canlı önizleme, maliyet özeti ve mevcut Kıyı kredisiyle satın alıp kaydetme. Bir araca uygulanan görünüm diğerine otomatik uygulanmaz.
- Profil iznine açık araçları diğer kullanıcıların görebilmesi; özel araçların gizlenmesi, blok, hayalet ve Premium kontrolleri.
- Haritada mevcut otomobil ikonuna dokunmadan motosiklet ikonu ve tür filtresi. Antalya/İzmir bölge kayıtları, geometriler, konum hassasiyeti ve mevcut paylaşım akışı değiştirilmedi.

## Görseller ve katman kapsamı
18 ayrı şeffaf yan görünüm eklendi. Bunlar logo içermeyen özgün üretilmiş model illüstrasyonlarıdır; resmi üretici fotoğrafı/CAD değildir. İki ilk taslak (NS200 ve Drift L) yeterince ayırt edici bulunmadığından yeniden üretildi. Mobil WebP dosyalarının toplamı yaklaşık 2,4 MiB; yüksek çözünürlüklü kaynaklar ayrı tutuldu. Ön ve arka görünümler bu teslimde eklenmedi.

Tam model listesi, dosya boyutları, SHA-256 ve destek matrisi: `docs/motorcycle-assets.md`.

Bütün 18 modelde gövde rengi, kaplama, jant rengi, jant şeritleri, far, motor altı aydınlatma ve sele katmanları bulunur. Egzoz/ayna alternatifleri PCX 125, R25 ve MT-25'te açıldı. Ön cam yalnız ön cam katmanı bulunan modellerde açılır. Diğer modellerde ilgili kategori desteklenmediği açıklamasıyla kapalıdır; backend de uyumsuz seçimleri reddeder. Dolayısıyla **18 modelin her birinde on kategorinin tamamının açık olduğu iddia edilmez.**

2D sistem kaynak görseli, gövde/sele maskelerini, tekerlek koordinatlarını, karbon desenini ve konumlanmış aksesuar katmanlarını kullanır. Renk değişimi yalnız butonda kalmaz. Görseli/uygun katmanı doğrulanmamış modelin preview ve kayıt yolu kapalı tutulur.

## Kredi ve envanter
Yeni para birimi veya cüzdan tablosu oluşturulmadı. Önceki ekrandaki mavi elmas sunumu ana uygulama akışında mevcut Kıyı kredi cüzdanına yönlendirildi. Otomobilin eski düzenleme kodu korunur; yeni motosiklet düzenleyicisi ayrı parça kataloğunu kullanır.

Satın alma hakkı `kiyi_inventory` içinde hesap bazındadır; seçimin uygulanması `kiyi_vehicle_customizations.vehicle_id` ile araca bağlıdır. Uyumlu, önceden sahip olunan hakkın uygulanması tekrar ücretlendirilmez. Renk SKU'ları mevcut `color:#...` haklarını kullanır. Kredi, envanter, görünüm ve ledger aynı transaction içinde güncellenir; sahiplik, sürüm, bakiye ve request_id denetlenir. Aynı isteğin tekrarı yeniden kredi düşürmez.

Yeni motosiklet parça fiyatları (mevcut krediyle): ücretli gövde rengi 500; kaplama 200; jant rengi 100; jant şeridi 50; far ve alt ışık 75; egzoz 150; ayna 60; ön cam 80; sele 60. Orijinal seçenekler ve beyaz/siyah temel renkler ücretsizdir. İlk kayıtta girilen mevcut/fabrika rengi korunur ve geri seçilebilir. Eski otomobil, hediye ve paket fiyatları değiştirilmedi.

## Veritabanı ve migration sonuçları
Uygulandı:
1. `stage3_garage_management`: mevcut araç tablosuna deleted_at/visibility ekleme, yetkili lifecycle komutları, public garage, ikincil plaka arama, profil sayısı, harita tür bilgisi ve atomik motosiklet satın alma.
2. `stage3_part_catalog_permissions`: varsayılan geniş grant'ları kaldırıp yalnız authenticated SELECT bırakma.
3. `stage3_existing_catalog_grants`: mevcut model/parça kataloglarında aynı daraltma; anon okuma ve TRUNCATE kapalı.
4. `stage3_reviewed_motorcycle_assets`: mevcut 18 modelin ready/parts alanlarını güncelleme ve 489 model/parça seçeneğini tanımlama.

Yeni tablolar: `public.kiyi_vehicle_part_products`, `kiyi_private.stage3_backup`.
Değişen mevcut yapılar: `kiyi_vehicles` (ek sütunlar); `kiyi_vehicle_models` (motosiklet hazır/uyumluluk bilgileri); `kiyi_private.command`, `person`, `viewport_map`; katalog grant'ları. Eski araç, kredi, envanter ve hediye tabloları yeniden yaratılmadı.

Güvenlik: kullanıcı tablo yazma yetkisi açılmadı. Yeni ürün tablosunda RLS açık ve yalnız katalog SELECT politikası var. Araç işlemleri kimlik/hesap durumu/sahiplik denetleyen private komuttan geçer. Üç katalogda anon SELECT ve authenticated TRUNCATE yetkisi olmadığı sorguyla doğrulandı.

Veri koruma: profil, appearance, cüzdan, envanter ve hediye satırlarının sıralı JSON özet hash'leri değişiklik öncesi/sonrası birebir eşleşti. 21 otomobil ve 18 motosiklet katalog kaydı korundu. Test kayıtları transaction sonunda geri alındı.

Geri alma: `supabase/rollback/stage3-disable.sql`. Fonksiyonların eski tanımları ve model metadata'sı private yedekte tutulur. Araçlar, satın almalar ve ledger silinmez. Yeni birincil motosiklet veya soft-delete durumu oluşmuşsa eski uygulamaya körlemesine dönmek yerine rollback durur; uyumlu kurtarma sürümü gerekir. Güvensiz geniş katalog grant'ları geri açılmaz.

## Test sonuçları
- Mevcut 117 Node testi değişmeden geçti. 6 yeni testle toplam **123 geçti; 0 başarısız; 0 atlandı**.
- Yeni görsel test: 18 dosyanın farklılığı, alpha kanalı ve mobil boyutu; desteklenen her katmanın raster piksellerinde görünür değişim; hazır olmayan modele sahte SVG döndürülmemesi.
- Yeni istemci testleri: karma garaj filtresi, boş durum, tek mevcut kredi cüzdanı ve otomobil ikonunun korunup motosiklet ikonunun ayrılması.
- Gerçek Supabase bağlantısında `tests/stage3-garage.sql` geçti. İki ayrı auth kimliğiyle iki otomobil + iki motosiklet, ortak liste, mükerrer plaka, düzenleme, silme, araç bazlı görünüm, otomatik yayılmama, doğru profil sayısı, birincil motosiklet, idempotent kredi düşümü, yetersiz kredi rollback'i ve çapraz kullanıcı erişim reddi doğrulandı.
- Aynı gerçek DB testinde public/özel garaj, ikincil plaka araması, harita tür filtresi, motorcycle alanı ve hayalet kimliğinin korunması kontrol edildi.
- Önceki finansal/sosyal domain ve 21 model kayıt regresyonları geçti. Bu sistemlere yeni özellik eklenmedi.
- Geri alma SQL'i canlı DB üzerinde transaction içinde uygulanıp ROLLBACK ile doğrulandı; sistem geri alınmadı.
- Üretim derlemesi geçti; sürüm yayını başarılı.
- Bulut Chrome'da yeni filtrelerin DOM'a geldiği ve uygulama kaynaklı JavaScript hatası olmadığı kontrol edildi. WebGL bu ortamda açılamadığı için harita zemininin görsel doğrulaması sınırlı kaldı. Gerçek iOS/Android cihazda oturum açılmış tam kullanıcı arayüzü testi yapılmadı; bu doğrulanmış gibi sunulmaz. Görsel katmanlar 320 px genişlikte raster olarak ayrıca kontrol edildi.

## Çalışma sırasında bulunan hatalar ve düzeltmeleri
- Yeni harita event listener'ı eski testin izole edilen kod parçasında window referansı oluşturdu; listener sınırı düzenlendi, iki eski viewport testi tekrar geçti.
- İlk görsel katman incelemesinde kaynak görsellerin SVG rasterizer'a gömülmesi için PNG/xlink uyumu gerekti; test işleyicisi düzeltildi. WebP dağıtımı korunur.
- Şeffaf çevre pikselleri katmanlarda taşma/lekelenme oluşturuyordu; alpha maskeleri ve mekanik kesitler düzeltildi.
- PCX ayna koordinatı, bazı yuvarlak farlı scooter'ların far konumu ve Drift alt ışık katmanı piksel testinde değişim oluşturmuyordu; konum/maskeler düzeltilerek testler geçirildi. Test eşikleri düşürülmedi.
- Birleştirilmiş SQL testlerinde eski request.jwt.claim.sub bağlamı yeni claim JSON'unu gölgeliyordu; testler arasında bağlam sıfırlanarak tekrar doğrulandı. Ürün verisi değiştirilmedi.
- Varsayılan Supabase katalog grant'ları genişti; ayrı migration'larla daraltıldı.
- Sharp için offline paket metadata'sı yoktu; sabit 0.35.4 geliştirme bağımlılığı normal paket akışıyla eklendi. Başka bağımlılıklar yükseltilmedi.
- İlk kaynak push'u servis HTTP 503 nedeniyle başarısız oldu; yerel commit korundu, erişim yenilenip aynı kaynak başarıyla gönderildi.

## Kalan sınırlar
Ön/arka görünümler ve destek matrisi dışındaki model/parça alternatifleri eklenmedi. Gerçek mobil cihaz ve iki fiziksel cihazda tam UI testi yapılmadı. Aynı modelin farklı üretim yılları için birebir CAD/üretici fotoğraf doğruluğu iddia edilmez. Bu sınırlar dışında garaj, kayıt, mevcut krediyle satın alma, araç bazlı uygulama, profil/harita ve veri ayrımı akışları uygulandı ve yukarıdaki testlerle doğrulandı. Aşama 4'e geçilmedi.

## Değişen dosyalar
- public/garage-system.js, public/garage-system.css
- public/motorcycle-assets.js, public/motorcycle-customizer.js
- public/assets/motorcycles/*-side-v1.webp (18 dosya)
- docs/artwork-source/motorcycles/*-side-v1.png (18 kaynak)
- public/cloud-domain.js, public/supabase-account.js, public/kiyi.html
- supabase/migrations/20261024135652_stage3_garage_management.sql
- supabase/migrations/20261024141631_stage3_reviewed_motorcycle_assets.sql
- supabase/migrations/20261024143225_stage3_part_catalog_permissions.sql
- supabase/migrations/20261024143312_stage3_existing_catalog_grants.sql
- supabase/rollback/stage3-disable.sql
- tests/stage3-garage.sql, tests/garage-system.test.mjs, tests/motorcycle-customizer.test.mjs
- package.json, pnpm-lock.yaml (Sharp 0.35.4 test bağımlılığı)
- docs/motorcycle-assets.md, docs/admin/stage3-report.md
