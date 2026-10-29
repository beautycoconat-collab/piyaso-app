# Kıyı — Aşama 7 sonuç raporu

25 Ekim 2026, Türkiye saati. Kaynak başlangıcı: `2acce2151749b5fd392b426771dce00c93cf53d4` (Aşama 6).

**Mağaza yayın durumu: YAYINA HAZIR DEĞİL.** Web uygulaması kontrollü kullanıcı testi için **koşullu hazır**. Kod, canlı veritabanı, Edge Function ve web düzeltmeleri uygulandı. Eksik mağaza ödeme entegrasyonu, imzalama, gerçek cihaz ve e-posta testleri tamamlanmış sayılmadı. Mağaza gönderimi veya yayını yapılmadı.

## 1. Tamamlanan çalışma ve özellik doğrulaması

Önceki altı aşamanın tabloları ve uygulamaları yeniden oluşturulmadı. 21 otomobil ve 18 motosiklet modeli korundu. İki ayrı geçici hesap için gerçek Supabase Auth parola girişi ve imzalı JWT oturumları kullanıldı; yalnızca SQL ile kullanıcı taklidi yapılması gerçek hesap testi sayılmadı.

| Alan | Doğrulanan | Sınır / kalan iş |
|---|---|---|
| Hesap / profil | Gerçek Auth girişi, profil yazımı, özel alanlara doğrudan REST erişiminin reddi, çıkış sonrası eski JWT reddi | Gerçek posta kutusuyla kayıt onayı ve parola kurtarma teslimi test edilmedi |
| Plaka / Garajım | Aynı hesapta iki otomobil ve iki motosiklet; liste/sayı, düzenleme/silme, sahiplik, tekrar plaka reddi; eski model seçilmemiş araç araması | Fiziksel cihazdan tam form kullanımı doğrulanmadı |
| Özelleştirme / kredi | Ayrı araçlarda bağımsız görünüm, gerçek RPC ile ücretli parça, atomik/idempotent kredi düşme, yetersiz bakiye ve yabancı araç reddi | Gerçek para veya mağaza sandbox ödemesi yapılmadı |
| Premium / hayalet | Yalnızca sunucu yetkisi, normal hesabın hak/bakiye yükseltememesi, Premium'un engeli aşamaması, hayalet fotoğraf ve bildirim görünürlüğü | StoreKit/Play Billing doğrulama ve geri yükleme eksik |
| Harita / bölgeler | SQL ile Antalya sınırı, izinli görünürlük, hayalet kimliği, paylaşım kapatma, araç türü filtresi, hız sınırı; tarayıcıda gerçek harita karoları | Fiziksel GPS, izin diyaloğu ve arka plan geçişi test edilmedi; bölgeler değiştirilmedi |
| Keşfet / medya | SQL ile altı filtre, sayfalama, profil akışı, etiket/düzenleme/silme; HTTP ile gerçek PNG ve MP4 paylaşımı, yanlış dosya imzası reddi | İşletim sistemi fotoğraf seçicisi, uzun video ve zayıf ağ cihaz testi yok |
| Sosyal / rozet / kutu | Beğeni, yorum/yetkiler, takip, engel, izinli plaka etiketi; rozet tekilliği/eşikler, bildirim tercihleri/okundu/gizlilik | Telefon push servisi bağlı değil |
| Moderasyon | Gerçek TOTP ile AAL2, yönetici oturum izni, şikâyet durumları, gönderi/yorum gizleme, kısıtlama ve denetim kaydı; normal kullanıcı reddi | Otomatik içerik sınıflandırması ve işletmecinin müdahale süresi eksik |
| Hesap silme | Uygulamada silme talebi; kısıtlı hesap için talep erişimi; gerçek MFA yönetici işlemi, kişisel araç alanlarının temizliği, Storage API dosya silme, tamamlandı durumu | Anında otomatik silme değildir. İşletmeci süreyi, finansal saklamayı ve ortak Auth kapsamını açıklamalı |

## 2. Düzeltilen hatalar

1. **Oturum iptali:** JWT süresi dolmadan çıkış yapılmış token ile komut/media erişimi sürebiliyordu. Hassas RPC ve medya yükleme/sign akışı artık canlı `auth.sessions` kaydını doğrular. İstemci iptal edilmiş oturumda özel belleği/medya önbelleğini temizler, konum izleyicisini durdurur ve yeniden giriş ister.
2. **Hayalet profil fotoğrafı:** Eski fotoğraf yolu veya `profile_photos` listelemesiyle görünürlük atlanabiliyordu. Aynı hayalet/Premium/engel ve aktif hesap denetimleri uygulandı.
3. **Kısıtlı hesapta destek/silme:** Ağır bundle ön kontrolü, gerekli destek ve silme talebi yollarını da engelliyordu. Bu yollar mevcut kendi yetkilendirmesine canlı oturum kontrolünden sonra gider; normal araç/gönderi işlemleri kısıtlı kalır.
4. **Silinen hesapta araç verisi:** Yönetici silme akışına plaka/model ve özelleştirme temizliği eklendi. Finansal defter korunur. Yalnızca açık silme talebi ve yetkili yönetici işlemiyle çalışır; mevcut kullanıcıya silme uygulanmadı.
5. **Eski araç plaka araması:** Model seçilmemiş eski araçlar sosyal araç sorgusundaki zorunlu model eşleşmesi nedeniyle bulunamıyordu. Model tablosu isteğe bağlı eşleştirilir; yanlış model görseli atanmaz ve özelleştirme hazır sayılmaz. Gizli eski plaka yine bulunamaz.
6. **Harita:** WebGL olmayan tarayıcıda boş harita yerine Leaflet/OSM standart harita yedeği eklendi. Başarısız bağlantı açık hata verir; 3B çalışıyormuş gibi gösterilmez. Kaynak bilgisi sürekli görünür.
7. **Mobil bağlantılar:** Native paylaşım bağlantısı `capacitor://` yerine gerçek web gönderi adresini kullanır. Müzik API adresi ve yalnızca üç açık native origin için CORS eklendi; keyfi origin kabul edilmez. Spotify servis anahtarları bulunmadığı için şarkı servis entegrasyonu tamamlandı sayılmaz.
8. **Performans ve düzen:** Script sırası korunarak `defer`, üst üste binen periyodik sorgu koruması, videolarda `preload=none`, mobil taşma/alt güvenli alan/diyalog kaydırma/16px giriş alanları. Mevcut 20 öğelik Keşfet cursor sayfalaması korundu. RPC sarmalayıcılarında tekrar ağır bundle yerine ucuz yetki ön kontrolü kullanılır. Sayısal hızlanma veya bant genişliği tasarrufu ölçülmedi.
9. **Bağımlılıklar:** Next 16.4.1, React/React Server Components 19.2.8, Vite 8.1.6, Zod 4.6.6, Sharp 0.35.5 ve güvenli geçişli sürümler kilitlendi. pnpm 11'in okumadığı manifest override alanı yerine workspace ayarı kullanıldı. Yalnızca doğrulanan `fast-uri@3.1.9` güvenlik yaması yedi günlük bekleme kuralından açık istisna aldı; genel kural korunur.

## 3. Değiştirilen dosyalar

Tam dosya listesi: [stage7-changed-files.txt](stage7-changed-files.txt). Yeni Android ikon/açılış PNG'leri mevcut Kıyı SVG kaynaklarından üretildi; motosiklet görselleri yeniden oluşturulmadı.

| Dosyalar | Değişiklik |
|---|---|
| `public/release-readiness.js`, `.css` | Silme talebi girişi, mobil düzen ve harita kaynak alanı |
| `public/kiyi.html`, `cloud-domain.js`, `explore-system.js` | Defer, sorgu çakışması, video veri tüketimi |
| `public/map-layers.js` | WebGL yokluğunda standart harita ve görünür kaynak |
| `public/supabase-account.js` | İptal edilmiş oturum temizliği |
| `public/social-interactions.js`, `music-picker.js` | Native paylaşım/API origin |
| `lib/native-origin.mjs`, `app/api/music/[[...path]]/route.ts`, `app/route.ts` | Sınırlı CORS, HTML cache ve temel güvenlik başlıkları; kapsamlı CSP değildir |
| `public/privacy.html`, `terms.html` | Mevcut gerçek sunucu davranışına göre teknik metin taslakları |
| `mobile/package*`, `capacitor.config.json`, `src/native-runtime.js`, `.gitignore` | Android bağımlılığı, native yapılandırma, üretim çıktılarının depodan ayrılması |
| `mobile/android/**`, `scripts/prepare-artwork.mjs` | Android proje, izin/güvenlik ayarları, marka ikonları ve açılış görselleri |
| `mobile/ios/App/App/Info.plist`, `PrivacyInfo.xcprivacy` | İzin ve veri toplama manifest taslağı |
| `mobile/scripts/check-release.mjs`, `app-store/*`, `README.md` | Gerçek durum, yayın engelleri ve cihaz komutları |
| `supabase/functions/kiyi-media/index.ts` | Rezervasyondan önce canlı oturum denetimi |
| Üç migration ve `supabase/rollback/stage7-security.sql` | Aşağıdaki sunucu değişiklikleri ve geri alma |
| `tests/stage7-*.{mjs,sql,py}`, mevcut hesap/harita/medya/test dosyaları | Yeni güvenlik, native ve silme testleri; eski test uyarlamaları |
| `public/mobile-check.html`, `docs/admin/stage7-*` | Sadece QA için üç gerçek iframe viewport'u, sonuç ve kanıtlar |

Yönetici paneli ön yüzü değiştirilmedi; mevcut 34 testi yeniden çalıştırıldı. Sunucu moderasyon/silme düzeltmeleri ortak RPC içindedir.

## 4. Supabase güvenliği ve migration sonuçları

Proje: `oswpkwwbjwyktuqcakhr`. Üç migration canlıda başarıyla uygulandı; yerel dosya adları uzak migration geçmişiyle eşleştirildi:

- `20261024214830_stage7_security_performance.sql`
- `20261024215326_stage7_account_erasure.sql`
- `20261025051135_stage7_legacy_plate_search.sql`

Yeni tek tablo `kiyi_private.stage7_function_backup`: eski fonksiyon tanımlarının yedeği; RLS açık, istemci yetkisi yok. Mevcut komut katmanları, `media_allowed`, `social_vehicle` ve yönetici `ops_command` güncellendi. Mevcut profil, araç/özelleştirme, rozet, tercih ve bildirim tablolarının yalnızca talep edilen hesap silme anındaki temizliği genişletildi. Yeni kova veya alternatif kredi/sosyal tablo oluşturulmadı.

`kiyi-media` Edge Function v2 canlıdır. Önceki `verify_jwt:false` yapılandırması korunur; fonksiyon kendi bearer/Auth ve servis/cleanup secret kontrollerini uygular. Bu, anonim yükleme açıldığı anlamına gelmez.

Kontrol sonuçları:

- RLS kapalı `public.kiyi_*` tablosu: **0**. Yedek tabloyu istemci okuması ve canlı oturum yardımcısına istemci execute yetkisi: **false**.
- Mevcut özel tabloların politikası olmaması kasıtlı kapalı erişimdir; yetkilendirilmiş RPC kullanılır. Güvenlik danışmanı bunları INFO olarak bildiriyor; gelişigüzel policy eklenmedi.
- Kredi/hak tablolarına doğrudan REST yazımı, sahte Premium/verified/bakiye alanı, yabancı araç ve moderasyon denemeleri reddedildi. Yönetici MFA/rol/oturum izni korundu.
- **Kalan WARN:** sızdırılmış parola koruması kapalı. Mevcut bağlayıcıdan Auth ayarı değiştirilemiyor; Supabase dokümanında bu koruma Pro ve üstü olarak belirtiliyor. Ücretli plan açılmadı. Dashboard üzerinden işletmeci kontrolü gerekir.
- Canlı oturum kontrolünde SQL sahibi tarafından yürütülen, JWT rolü olmayan rollback fixture'ları için ayrı test yolu bulunur. İnternet üzerinden gelen gerçek imzalı `authenticated` token bu yolu kullanamaz; eski token reddi HTTP ile ayrıca test edildi.
- Özel `kiyi-media` kovası korundu; görüntü/ses 5 MiB, video 20 MiB; kullanıcı 50 MiB, proje yükleme bütçesi 500 MiB, saatte 30 yükleme sınırları korundu. Bunlar uygulama bütçeleridir; tüm Supabase planının trafik faturasını garanti etmez. Gerçek aylık egress/diğer uygulama tüketimi ölçülmedi. Otomatik video transcode yok.
- Önceden verilmiş imzalı URL'nin süresi dolana kadar geçerli olabilmesi standart Storage sınırıdır. Yeni URL verme denetlenir; fiziksel silme dosyaya erişimi sonlandırır.

Geri alma dosyası yedek fonksiyon tanımlarını geri yükler; kullanıcı verisini veya silinmiş kişisel bilgiyi geri getirmez. Edge Function önceki sürümüyle birlikte koordineli uygulanmalıdır. Canlıda rollback yapılmadı; gerçek kullanıcıya karşı silme deneyi yapılmadı. Önceki ortak `lab` uygulama şemasına müdahale edilmedi.

Koruma doğrulaması: fixture temizliğinden sonra Aşama 6 sonundaki profil/araç/cüzdan/özelleştirme/görünüm kontrol toplamlarının **beşi de aynı**. Gerçek test hesapları ve bunlara ait Storage dosyaları: **0**. Katalog: **39** model. Gizli fixture parolaları/tokenları depoya veya rapora eklenmedi.

## 5. Test sonuçları ve başarısız denemeler

Kanıt dosyaları: [stage7-evidence](stage7-evidence/).

| Kontrol | Sonuç |
|---|---|
| Ana uygulama Node testleri | **158/158 geçti**, 0 atlandı; mevcut 151 korunarak 7 yeni test eklendi |
| Yönetici paneli Node testleri | **34/34 geçti** |
| Üretim web build | Başarılı |
| Ana proje üretim bağımlılık audit | **0 düşük / 0 orta / 0 yüksek / 0 kritik**; başlangıç 4/9/7/3 idi |
| Derleme/geliştirme araçları dahil audit | **0 düşük / 0 orta / 0 yüksek / 0 kritik**, 775 bağımlılık; son audit başarılı |
| Native üretim bağımlılık audit | **0 açık**; bu sonuç iOS/Android güvenlik sertifikasyonu değildir |
| Canlı SQL regresyonları | Stage3 garaj, Stage4 gönderi, Stage5 sosyal, Stage5 gizlilik/sayfalama, Stage6 sosyal, eşikler, bildirim gizliliği, domain hediye/kredi, domain konum, Stage7 güvenliği: **10 dosya geçti**, fixture'lar rollback edildi |
| Gerçek Auth / HTTP | İki hesap, kredi/parça ayrımı, fotoğraf/video, hayalet/Premium/engel, MFA moderasyon, silme/Storage temizliği, çıkmış token reddi geçti |
| iOS ve Android Capacitor sync | İkisi de geçti; native derleme değildir |
| Mağaza gönderim kontrolü | **Beklenen exit 1: hazır değil**, engeller aşağıda |

İlk başarısızlıklar saklanmadı:

- Defer eklenince eski test script ayrıştırıcısı 13 render testini yükleyemedi; ayrıştırıcı düzeltildi. Eski yayın kontrol testi artık doğrulanmış backend bayraklarını yanlış biçimde hep kapalı bekliyordu; gerçek engelleri test edecek şekilde düzeltildi. Son tam çalıştırma başarılıdır.
- İlk eski konum SQL testi plaka aramasında kaldı. Gerçek model-siz eski araç hatası migration ile düzeltildi. Testte ayrıca yeni varsayılan özel garajın açıkça yayınlanması, zorunlu viewport ve GPS hız sınırının denetlenmesi gerekiyordu. Üretim sınırları gevşetilmedi; test fixture zaman damgası işlem içinde ilerletildi. Son konum testi geçti; gizli eski plaka için negatif kontrol eklendi.
- İlk gerçek HTTP serisinde geçici video dosyası çalışma alanı temizliğinde kayboldu (`FileNotFoundError`); gerçek MP4 yeniden hazırlanarak video bölümü ayrı başarıyla tamamlandı. İlk Aşama 6 HTTP tekrarında ağ bağlantısı koptu; tüm script tek çalıştırmada bitmiş gibi raporlanmadı. Sonraki odaklı HTTP ve SQL kontrolleri yukarıdaki sonuçları doğruladı.
- Çok komutlu fixture temizliğinde MCP `requestState` hataları alındı; tek CTE ile fixture'lar temizlendi ve sıfır kaldığı doğrulandı.
- pnpm ilk override alanını okumadı, sonra yeni güvenlik yamasını yaş sınırı engelledi. Doğru workspace ayarı ve sadece denetlenmiş sürüm istisnasıyla kurulum/audit/build/test tekrar geçti. Derleme araçlarının ek taramasında 7 düşük / 22 orta / 27 yüksek açık bulundu; desteklenen Zod 4 seçimi, React RSC, Vite ve geçişli bağımlılıklar güncellendi. Esbuild yükseltmesinden sonra Drizzle şeması yalnızca SQL metnine dışa aktarılarak kontrol edildi; veritabanına uygulanmadı. React hooks eklentisi kendi paket çözümleyicisinden yüklenerek doğrulandı.
- Tarayıcıda WebGL açılmadı; bu gerçek bulgu üzerine standart harita yedeği eklendi ve gerçek karoların yüklenmesi doğrulandı. 3B bu ortamda doğrulanmadı.

## 6. Mobil uyumluluk ve performans sınırları

360×800, 390×844 ve 430×932 iframe viewport'larında gerçek uygulama kontrol edildi. Profil, Keşfet, Gelen Kutusu ve haritada ölçülen yatay belge taşması yok. Dar ekranda kutu sekmeleri kasıtlı yatay kaydırılır. Harita raster görselleri üç genişlikte de yüklendi. [Görsel kontrol](stage7-viewports.jpg).

Bu kontroller bulut masaüstü tarayıcısı içindedir; **fiziksel telefon, Android emülatörü veya iOS simülatörü testi değildir**. Tarayıcı görsel kontrolleri oturum açılmamış görünümde yapıldı; hesaplı işlemler gerçek Auth HTTP/RPC ile test edildi. Gerçek klavye/OS seçici, girişli tüm ekranların dokunma davranışı ve kamera/mikrofon izin diyaloğu doğrulanmadı.

Native Android: minimum SDK 24, hedef/derleme 36; açık metin trafik ve otomatik yedek kapalı. Java bulunuyor, Android SDK/adb yok. iOS için Xcode yok. İmzalı native paket ve cihaz performansı raporlanamaz. Mevcut sıkıştırılmış motosiklet varlıkları/katmanları korundu; 18 modelin ayırt edici şeffaf varlık testleri geçti. Fiziksel GPU/düşük bellek ve motorun tüm parça kombinasyonları manuel cihazda denenmeli.

## 7. App Store için hazır olanlar

Yerel iOS proje yapısı, Kıyı adı ve ikon/açılış varlıkları, izin açıklamaları, veri toplama manifest taslağı, web paketinin iki platforma kopyalanması, sunucuda gizlilik/ekonomi/moderasyon, uygulama içi silme talebi ve hesap işlemi takibi mevcut. Android proje ve marka varlıkları eklendi. Web sürümü yayınlandı; hiçbir mağaza otomatik gönderilmedi.

## 8. App Store ve Play için eksikler

- Apple Developer, Team/sertifikalar/provisioning, Bundle ID sahipliği, App Store Connect; Android keystore, SDK derleme ve Play Console.
- **StoreKit / Google Play Billing sunucu doğrulaması ve satın alımları geri yükleme**. Mevcut uygulama kredi defteri ve Premium yetkisi bunların yerini tutmaz.
- İşletmeci adı ve gerçek destek e-postası, saklama ve silme süresi; son hukuki metinler, App Privacy/Data Safety ve yaş derecesi.
- Gerçek e-posta doğrulama/kurtarma, son native yapıdan mağaza görselleri, cihaz/TestFlight/Play test kanalı.
- Telefon push için APNs yetkisi/anahtarları, Firebase projesi/FCM yapılandırması ve cihaz izin/teslimat testleri yok. Push **çalışmıyor ve çalışıyor diye gösterilmiyor**.
- Otomatik fotoğraf/video içerik sınıflandırması bağlı değil. AWS Rekognition yönetilen resim ve video moderasyonu için değerlendirildi; kullanım bazlı maliyet, bölge/mahremiyet ve insan incelemesi gerekir. İşletmeci hesabı, anahtarları, bütçe ve içerik politikası olmadan servis açılmadı. Dosya doğrulaması uygunsuz görseli otomatik algılama değildir.
- OSM standart karo sunucusu yoğun üretim için SLA sağlamaz. Görünür kaynak, normal tarayıcı cache/referrer ve sınırlı mevcut viewport yüklemesi kullanılır; toplu/offline indirme yok. Ölçekli kullanım için uygun sağlayıcı/bütçe kararı gerekir.

## 9. Gerçek cihazda yapılması gerekenler

En az bir küçük ve bir büyük iPhone, bir orta seviye Android üzerinde: giriş/kayıt/kurtarma, klavye açık form ve yorum, alt navigasyon/safe area, garaja dört araç, tüm motor katmanları, gerçek medya seçimi ve iptali, zayıf ağda tekrar yükleme, yorum/etiket/bildirim hedefleri, canlı GPS/izin reddi/arka plan, paylaşım bağlantısı, token yenileme/çıkış, MFA yönetici iş akışı ve silme talebi. Mağaza sandbox ödemeleri ve geri yükleme ayrıca zorunludur. Push bağlanırsa izin reddi ve iki platformda teslimat da denenmeli.

## 10. Yayından önce hesap sahibinin yapması gerekenler

1. Apple/Google geliştirici ve imzalama erişimlerini, Bundle ID'yi ve mağaza ürün kimliklerini kesinleştir.
2. Destek/işletmeci bilgilerini, silme-saklama sürelerini ve hukuki/mağaza gizlilik beyanlarını onayla.
3. Gerçek mail akışını ve Auth parola/oturum ayarlarını kontrol et; mağaza ödeme doğrulama/restore entegrasyonunu tamamlat.
4. Mac/Xcode 26+ ve Android SDK ile imzalı test yapıları al; yukarıdaki cihaz kontrollerini ve TestFlight/Play testlerini tamamla.
5. Moderasyon görevlisi/müdahale süresi, otomatik denetim ve harita kapasitesi bütçesini belirle. Push isteniyorsa APNs/FCM erişimini sağla.
6. Son ekran görüntüleri, yaş derecesi ve inceleme hesaplarını hazırla. Ancak bundan sonra **mağazaya gönderim için açık onay** ver.

### Başvurulan resmi kaynaklar

- [Apple App Review Guidelines — kullanıcı içeriği, gizlilik, ödeme](https://developer.apple.com/app-store/review/guidelines/)
- [Apple uygulama içinden hesap silme](https://developer.apple.com/support/offering-account-deletion-in-your-app/)
- [Apple güncel gönderim gereksinimleri](https://developer.apple.com/news/upcoming-requirements/)
- [Supabase parola güvenliği](https://supabase.com/docs/guides/auth/password-security)
- [Supabase oturumlar](https://supabase.com/docs/guides/auth/sessions)
- [Capacitor push kurulumu](https://capacitorjs.com/docs/apis/push-notifications)
- [AWS Rekognition fiyatlandırma](https://aws.amazon.com/rekognition/pricing/)
- [OSM karo kullanım politikası](https://operations.osmfoundation.org/policies/tiles/)
- [pnpm güncel yapılandırma](https://pnpm.io/settings)
