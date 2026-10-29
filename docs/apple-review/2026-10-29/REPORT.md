# PİYASO — Apple App Store onay öncesi kabul raporu

**29 Ekim 2026, Türkiye saati · Nihai karar: GÖNDERİME HAZIR DEĞİL.**

Başlangıç: 28 Ekim `STORE-REPORT.md`, kaynak `1ed152b63eacccaa4b949eb2deb5d6ba97d34ded`, önceki temel `cbfd5bcfc369de7d757a0871620b04a5e6fb1ae5`. Çalışma dalı: `audit/apple-compliance-20261029`. Önceki 362 testlik kapsam korunup yeni güvenlik testleri eklendi. Üretim dağıtımı, üretim verisi/hesabı silme veya ücretli servis açma yapılmadı. Capacitor 8.5.3 ve mevcut tasarım yapısı korundu.

Kaynaklar: [güncel App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/), [16 Ekim 2026 resmi değişiklik duyurusu](https://developer.apple.com/news/?id=92th7e5i), [hesap silme açıklaması](https://developer.apple.com/help/app-review/guideline-reference/5-1-1-account-deletion), [App Privacy](https://developer.apple.com/app-store/app-privacy-details/), [Supabase Auth hard delete](https://supabase.com/docs/reference/javascript/auth-admin-deleteuser). Resmi Apple sayfasında son güncelleme 16 Ekim 2026 olarak doğrulandı. Yeni 2.3.14 yaratıcı varlıklar, 2.5.19 gizli/belgelenmemiş işlevler ile güncellenen UGC/çocuk güvenliği kapsamı incelendi.

Bu rapordaki **DÜZELTİLDİ**, belirtilen kaynak/izole test kapsamını ifade eder; canlı backend veya imzalı iOS paketi için otomatik uygunluk değildir. **UYGUN** yalnız adı verilen testi geçtiği ölçüde kullanılır. İnsan operasyonu ve yapılmayan native/gerçek Auth testleri başarılı işaretlenmedi.

## A. Apple kurallarına uyumluluk

| Kural / Piyaso işlevi | Sonuç | Gerçek kanıt ve açık koşul |
|---|---|---|
| 1.2 — UGC genel kabul | **EKSİK** | Gönderi, yorum, profil, plaka, medya, hediye/şarkı metni vardır. Bildirim, engel, sunucu yetkisi ve yönetici kararları izole testlerde mevcut. Tam içerik ön filtresi, gerçek insan moderasyonu, yanıt süreleri ve yayınlanmış gerçek iletişim eksik. |
| 1.2 — gönderi/yorum/kullanıcı şikâyeti | **UYGUN** | `social-safety`, `social-interactions`, özgün stage4/5/6 SQL ve panel 34 testinde RPC, görünürlük ve yetki sınırları doğrulandı. Gerçek native iki oturum kabulü bekliyor. |
| 1.2 — çocuk güvenliği/acil ihlal girişi | **DÜZELTİLDİ** | Çocuk istismarı, rıza dışı özel görüntü ve acil tehdit seçenekleri eklendi. Görüntüyü yeniden paylaşmama ve acil tehlikede 112 açıklaması var. Nöbet, eskalasyon, hukuki bildirim ve görsel/video ön incelemesi insan operasyonu olarak açık. |
| 1.4.4–1.4.5 — sürüş güvenliği | **EKSİK** | Güvenli park halinde kullanım açıklamaları mevcut; yarış/hız teşviki bir uygulama işlevi değil. Gerçek sürüş sırasında test yapılmadı; mağaza tanıtımı aynı sınıra uymalı. |
| 1.5 — geliştirici/destek iletişimi | **EKSİK** | `support.html` ve uygulama içi destek yolu hazır. Gerçek işletmeci ve herkesin ulaşabildiği destek e-postası sağlanmadı. Taslak nihai Support URL sayılmaz. |
| 1.6 — veri güvenliği | **EKSİK** | Oturum guard, RLS ve yetkisiz yazma reddi testli. Canlı Auth leaked-password protection WARN açık; gerçek Auth/medya ve üretim kurtarma kabulü tamam değil. |
| 2.1 — uygulama bütünlüğü | **ERİŞİM BEKLİYOR** | Yerel build ve iOS sync geçti. Xcode derlemesi, imzalı IPA, gerçek cihaz ve tam inceleyici hesabı yok. Ücretli satış native görünümde sunulmaz; mevcut demo/beta işaretleri nihai paket öncesi giderilmeli. |
| 2.2 — beta/demo dağıtımı | **EKSİK** | Paket geliştirme durumunda. TestFlight kabulü sonrasında gerçek hizmet sürümü seçilmeli; demo etiketi kaldırmak tek başına yeterli değil. |
| 2.3 — doğru metadata | **DÜZELTİLDİ** | Eski Kıyı/ücretli satış/şarkı katalog iddiası içeren metadata dosyası yeni Piyaso taslaklarına yönlendirildi. App Store Connect'e girilmiş veya hukuken onaylanmış sayılmaz. |
| 2.3.3 / 2.3.14 — ekran görüntüsü ve yaratıcı varlıklar | **ERİŞİM BEKLİYOR** | Gerçek son native yapıdan görüntü yok. Çekim planı hazır; sahte ekran veya üretilmiş taslak final ekran görüntüsü sunulmadı. |
| 2.3.6 / 2.3.8 — yaş beyanı | **EKSİK** | UGC, medya, konum ve sosyal etkileşim envanteri hazır. İşletmecinin yaş hedefi ve gerçek moderasyon ile yaş anketi tamamlanmalı. Kids Category seçilmedi. |
| 2.5.1 — SDK/public API/native kalite | **ERİŞİM BEKLİYOR** | Capacitor sürümleri korundu. Apple toolchain, SDK birleşik gizlilik raporu ve cihaz performansı doğrulanmadı. |
| 2.5.2 — paket içinde işlev | **UYGUN** | Capacitor yerel `www` paketi; uzak `server.url` yok. Backend veri API'leri kullanılıyor; sync doğrulandı. |
| 2.5.4 — arka plan hizmetleri | **UYGUN** | Background location modu yok; pause/hidden olaylarında GPS kapanışı mevcut testlerle doğrulandı. Fiziksel cihazda durma/geri dönüş kabulü açık. |
| 2.5.5 — IPv6-only | **ERİŞİM BEKLİYOR** | DNS64/NAT64 gerçek ağ/native testi yapılmadı. |
| 2.5.14–15 — kamera/mikrofon/dosya seçimi | **ERİŞİM BEKLİYOR** | İzin açıklamaları mevcut; gerçek iOS fotoğraf/video/kamera/Files seçimi ve upload testleri yok. Gereksiz olduğu cihazda anlaşılacak izin açıklamaları kaldırılmalı. |
| 2.5.19 — gizli/dormant işlevler | **EKSİK** | İnceleme notlarına mevcut ödeme/native OAuth/push sınırları eklendi. Nihai pakette geliştirici demo yolları ve kapalı işlevler/ürün beyanı tekrar gözden geçirilmeli; incelemeden sonra gizli özellik açılmamalı. |
| 3.1.1 — bu adayda ücretli dijital satış | **UYGULANAMAZ** | `paidPurchasesEnabled=false`. Native Premium girişinde fiyat, çalışmayan satın alma ve StoreKit restore butonları kaldırıldı; ücretsiz jeton ekonomisi korunur. Bu, IAP'ın hazır olduğu anlamına gelmez. |
| 3.1.1 / 3.1.2 — ileride ücretli jeton/Premium | **ERİŞİM BEKLİYOR** | Gerçek StoreKit, ürün kimlikleri, bundle/account token, imzalı transaction, sunucu doğrulama, pending, restore/entitlement, iade/iptal/renewal/sandbox eksik. Mimari sözleşme `docs/operations/store-purchases.md`; istemci `verified` alanı ödeme kanıtı kabul edilmez. |
| 4.2 — asgari işlevsellik | **ERİŞİM BEKLİYOR** | Profil/garaj/sosyal/harita özellikleri ve yerel paket mevcut; yalnız web kabuğu başarısına dayanarak uygunluk verilmedi. Gerçek son iOS sürümünde 12 adım kabul gerekir. |
| 4.8 — alternatif giriş | **UYGULANAMAZ** | Native callback kurulmadığından Apple/Google sağlayıcıları native'de kapalı; e-posta/parola sunuluyor. Native gate testli. Sosyal giriş açılacaksa eşdeğer gizlilik sağlayan giriş ve SIWA yapılandırması yeniden ele alınmalı. |
| 5.1.1(i) — gizlilik politikası | **EKSİK** | Uygulamada bağlantı var; veri/retention taslağı hazır. İşletmeci, destek, saklama ve üçüncü taraf koşulları kesin değil. |
| 5.1.1(ii) / 5.1.5 — konum rızası | **DÜZELTİLDİ** | Hayalet harita kimliği Premium'a da kapatıldı; yaklaşık konum/yön sınırı ve engel korundu. Cursor gerçek UUID vermez, gizli server salt kullanır. 202 işaretli sayfalama testi de geçti. Üretime uygulanmadı; gerçek izin reddi/OS callback kabulü açık. |
| 5.1.1(v) — tam hesap silme | **ERİŞİM BEKLİYOR** | Yeni parola yeniden doğrulama + SQL fence + Storage delete + Auth Admin hard delete + Auth yokluk doğrulama adayı eklendi. İzole SQL ve taklit Auth/Storage testli. Ortak Auth kapsamı ve gerçek Supabase kabulü çözülmeden kapalıdır; `serverAccountDeletionTested=false` korunur. |
| 5.1.2 — veri kullanımı/paylaşım | **EKSİK** | Harita/engel/hayalet teknik sınırı güçlendirildi. App Privacy, harita/CDN istekleri, sağlayıcı logları ve gerçek trafik/native manifest son uyumu bekler. Üçüncü taraf AI sınıflandırıcı bağlı değil. |
| 5.1.4 — çocuk verileri | **EKSİK** | Genel yasaklar ve bildirim akışı taslakta; yaş kapsamı, çocuk güvenliği işletimi ve gerekli hukuki kararlar açık. |
| 5.2 — fikri haklar / üçüncü taraf hizmetleri | **EKSİK** | Logo/araç/marka/görsel lisansları ve harita sağlayıcısı koşullarının işletmeci onayı gerekir. Yeni medya/lisans satın alınmadı. |
| 5.3–5.5 — bahis, VPN, MDM | **UYGULANAMAZ** | Piyaso'da bu işlevler yok. Ortak Supabase'deki başka projenin tabloları Piyaso işlevi sayılmadı. |

### Sosyal güvenlikte kontrol edilen yüzeyler

Gönderi/yorum raporları içerik kimliğiyle; profil raporu hedef kullanıcıyla çalışır. Profil adı/kullanıcı adı/plaka ve profil görselleri için profil bildirimi yolu, post medya/video için post bildirimi yolu kullanılır. Ayrı bir videonun bildiriminde mevcut post'un report menüsü kullanılır. Hediye/şarkı ve profil metinleri dahil tüm UGC için kapsamlı ön filtre kabulü **tamam değildir**.

Engelleme: feed, yorum/profil, takip ve harita verilerinde sunucu kontrolleri mevcut; iki taraflı konum gizleme yeni testte geçti. Raporlar yönetici RPC'sine gider; rol/MFA/karar, içerik gizleme, sanctions ve admin audit mevcut panel/SQL testlerinde doğrulanır. Aynı kişinin tekrarlı ihlalleri için geçmiş/sanction araçları vardır; otomatik ihlal kararının doğru işlediği veya insanın zamanında yanıtladığı ileri sürülmedi. Rate-limit ve tekrar istek tekilliği testleri korundu.

Tam 1.2 kabulü için yayın öncesi uygunsuz içerik filtresi (sadece dosya MIME kontrolü veya birkaç kelime paterni değildir), görsel/video güvenliği, insan ekibinin kapasitesi, ihlal itirazı, acil/çocuk güvenliği eskalasyonu, yetkili kayıt erişimi ve gerçek destek iletişimi tamamlanmalı. Zararlı çocuk istismarı örnekleri test verisi yapılmaz.

## B. Tamamlanan düzeltmeler ve testler

| Değişiklik | Dosyalar | Doğrulama |
|---|---|---|
| Tam silme için sunucu adayı | `supabase/functions/piyaso-delete-account/{index.ts,coordinator.mjs}`, `lib/account-erasure.mjs`, `supabase/admin/apple-account-erasure.sql` | Service-only yetki, parola/kimlik eşleşmesi, sahiplik kapsamı, media hata yolları, legal hold, cross-app/paid order reddi, in-flight upload ve cascade/peer izolasyonu |
| Silme ekranı ve yerel çıkış | `public/release-readiness.js`, `public/supabase-account.js` | Onay/parola zorunlu; pending yanıtı başarı sayılmaz; parola temizliği; yalnız `deleted/authDeleted=true` onaylanır |
| Hayalet harita ve cursor gizliliği | `supabase/admin/apple-location-privacy.sql`, `public/cloud-domain.js`, `app.js`, `ghost-profiles.js`, `premium-paywall.js` | Premium kimlik sızıntısı kapalı; yaklaşık koordinat, heading null, iki taraflı engel; 200+2 sayfa, 202 benzersiz işaret; cursor UUID değil |
| Native yasal/destek bağlantıları | `mobile/src/link-policy.js`, `native-runtime.js` | Yerel yasal sayfa allowlist; HTTPS dış bağlantı; unsafe scheme/credential URL reddi |
| Yanıltıcı native ödeme kontrolleri | `public/premium-paywall.js` | Native'de yapılandırılmamış TL planı/purchase/StoreKit restore yok; eski preview davranışı için regresyon korundu |
| Güvenlik bildirim seçenekleri ve destek | `public/social-safety.js`, `support.html`, `app-readiness.js` | Mevcut RPC/kayıt yapısı korunur; gerçek destek e-postası uydurulmaz |
| Başvuru ve CI kayıtları | `app-store/*`, `.github/workflows/isolated-db.yml`, `scripts/testing/mobile-db.mjs` | Yeni Apple SQL senaryosu mevcut embedded CI komutuna dahil; bu tur GitHub Actions koşmuş sayılmaz |

İki SQL dosyası **aday patch** olarak tutulur, üretim migration defterine uygulanmadı. Canlıya alınmadan mevcut PostgreSQL 17 şemasında migration/advisors ve rollback süreci gerekir. Özgün 24 SQL assertion paketi değiştirilmedi. Önceki talep-only silme testleri yeni tam-silme kontratını sınayacak şekilde güncellendi; eski Premium ile hayalet kimliği açma metin beklentisi yeni gizlilik davranışına çevrildi. Yetki kontrolleri gevşetilmedi.

### Geçen kontroller ve kanıt sınırları

**391 ayrı test başarılı:** önceki 362 kapsamı + 29 yeni test. Ana tam koşu 312; son eklenen native senaryo ve 3 Edge testi ayrı koşuda geçti (ana toplam 316). Yönetim paneli 34; izole veritabanı/medya/kurtarma 41. Tekrar koşulan örtüşen testler toplamı artırmak için sayılmadı. Atlanan test yok. `evidence/TEST-SUMMARY.json` ve ham loglar bu hesaplamayı gösterir.

- Ana kaynak: `node --test --test-force-exit tests/*.test.mjs tests/*.test.cjs`; yeni Edge dosyası ve son native senaryo ayrı doğrulandı. `--test-force-exit` tamamlanan testlerden sonra fixture handle'larının süreci açık tutmasını önler; bitmemiş veya başarısız testi başarıya dönüştürmez.
- Yönetim: 28 Ekim audit dalı, 34/34; kodu bu çalışmada değiştirilmedi.
- DB: `test-mobile-database`, `test-mobile-journeys`, `test-apple-database` 41/41. PGlite PostgreSQL 18.6/PostGIS; gerçek üretim PostgreSQL 17 çok bağlantılı yük testi değildir.
- SQL cascade testinde gerçek embedded `auth.users` satırı silindi ve profil/garaj/post/wallet/media yokluğu, peer hesabının korunması ve eski session ile komut reddi doğrulandı. **GoTrue/Supabase Auth servisinin kendisi taklit adaptördür.** Gerçek hosted Supabase Auth veya gerçek Storage delete kabulü yapılmadı.
- Yeni Edge handler sınırlı giriş, yöntem/MIME/JSON ve varsayılan kapalı konfigürasyonu gerçek TS handler koduyla VM'de doğrular. Canlı Edge dağıtımı değildir.
- Ana uygulama TypeScript, public JS sözdizimi, scoped client-secret taraması, yerel framework build ve Capacitor iOS sync geçti. Root TypeScript denetimi `supabase/functions` dizinini dışlar; yeni Edge handler transpile/VM testleriyle doğrulandı, Deno tam type-check yapılmış sayılmaz. Bu IPA veya iOS testi değildir.
- Apple release gate beklenen exit 1 ile gönderimi engellemeyi sürdürüyor. Yanlış `true` kutusu işaretlenmedi.

İlk test denemelerinde bağımlılıkların ve üretilen `startup.html` dosyasının yokluğu, eski silme/hayalet metin beklentileri ve reward_identity FK temizleme sırası sorunları görüldü. Bağımlılık/üretim adımları tamamlanıp gerçek davranış düzeltildi; başarılı final logları esas alındı. Daha önce yarıda kesilen veya özeti gelmeyen koşular başarılı sayılmadı.

### Native kalite kontrol envanteri

| Kontrol | Mevcut bulgu | Kabul durumu |
|---|---|---|
| App lifecycle / resume | Pause olayı konumu durdurur, resume hesap yeniler; otomatik paylaşım açmaz | Kod/bridge testli, iPhone bekler |
| Splash / simge | Önceki Piyaso artwork ve Xcode asset catalog korunur | iPhone launch/scale bekler |
| Safe Area / çentik / Dynamic Island | viewport-fit ve mevcut CSS korunur | Fiziksel ekran/döndürme bekler |
| Klavye / form / erişilebilirlik | Silme formu label/status ve parola autocomplete içerir | VoiceOver, Dynamic Type, focus ve keyboard örtüşmesi bekler |
| Geri navigasyon | Mevcut modal/composer/history kararları testli | iOS back/edge gesture ve legal sayfa dönüşü bekler |
| Kamera / fotoğraf / video / Files | İzin metinleri ve HTML dosya seçimleri mevcut | Gerçek picker, iptal, sınırlı fotoğraf erişimi ve yükleme bekler |
| Bağlantı kesintisi | API hatası gösterilir; silme sahte başarı üretmez | Gerçek çevrimdışı/zayıf ağ/timeout kabulü bekler |
| Oturum / süreç öldürme | Refresh ve server session guard testli; istemci sessionStorage kullanır | Native cold start/kill sonrası oturum ve güvenli saklama ayrıca değerlendirilmeli |
| Konum izin reddi | Konumdan bağımsız harita; sharing kullanıcı başlatır | iOS izin reddi/approximate/revoke testi bekler |
| HTTPS / ATS | Allow arbitrary loads/background location yok | Gerçek ağ/IPv6-only kabulü bekler |
| Privacy manifest / SDK | Uygulama manifesti mevcut, SDK manifestleri Xcode'da birleşmeli | Archive privacy report/required reasons ve App Privacy eşleştirmesi bekler |
| Performans / bellek | Varlık ve harita fallback testleri mevcut | Instruments, bellek baskısı, WebGL context kaybı ve uzun tur testi bekler |
| WebGL/3D fallback | Mevcut raster fallback, viewport ve marker regresyonu korundu | Fiziksel düşük kaynaklı cihaz bekler |

## C. Açık teknik engeller

1. **Ortak Auth ve gerçek silme:** yalnız üretim Supabase projesi görünür; mevcut development branch yok. Üretime dokunmadan gerçek Auth/Storage sınaması için ayrılmış ücretsiz test projesi veya sağlanmış izole ortam gerekir. Yeni ücretli branch açılmadı. Ayrılmış Auth ve yasal saklama stratejisi kararlaştırılmadan silme endpoint'i kapalı kalır. Ücretli/operatör hesap silme için ayrı anonimleştirme ve saklama tasarımı gerekir; genel Apple hesap silme uyumluluğu bitmedi.
2. **Gerçek Auth:** e-posta doğrulaması, gerçek inbox teslimi, password recovery dönüş/allowlist, login/logout/refresh ve iki gerçek cihaz oturumu kabulü. Native Google/Apple callback kurulu değil; native butonlar kapalı. SIWA açılırsa nonce/token güvenliği ve silmede Apple token iptali gerekir.
3. **Native:** macOS/Xcode, Apple Developer Team, provisioning/signing, gerçek iPhone/iPad, TestFlight. Linux sync/build sonuçları bunları doğrulamaz. Güncel Apple upload/toolchain şartı gönderim tarihinde yeniden kontrol edilmeli; eski Xcode gate etiketi uygun SDK kullanıldığını kanıtlamaz.
4. **UGC operasyonu:** tüm yüzeylerde etkili içerik ön filtresi, görsel/video incelemesi, ihlal yanıtı, çocuk güvenliği/acil nöbet, gerçek destek ve itiraz. Bu işlemler teknik checkbox ile tamamlanamaz.
5. **Güvenlik ve kurtarma:** Supabase advisor `auth_leaked_password_protection` WARN açık. [Resmi düzeltme açıklaması](https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection). RLS açık/politika yok INFO kayıtları varsayılan ret yaklaşımından ayrı değerlendirilir; topluca erişim açılmadı. Üretim backup/restore ve çok bağlantılı çift harcama/yarış kabulü açık.
6. **Ödemeler:** bu adayda ücretli satış kapalı. Açılması için StoreKit + gerçek ürünler + server verification/notifications/restore/refund/pending/entitlement/sandbox gerekir. Ücretsiz ödül ledger testi satın alma testi değildir.
7. **Dağıtım:** yeni SQL/Edge, support ve uygulama değişiklikleri kontrollü dağıtımdan sonra gerçek uçlarda doğrulanmalı. Bu çalışmada üretim değiştirilmedi. Yaş, lisans ve gizlilik beyanları tamamlanmadan App Store başvurusu yapılmamalı.

## D. Kullanıcıdan gereken bilgiler ve kararlar

| Gereken | Neden gerekli | Şimdiki durum |
|---|---|---|
| Apple Developer üyeliği, Team ve App Store Connect erişimi | Bundle sahipliği, sertifika, TestFlight, başvuru | Erişim bekliyor; parola/secret bu rapora yazılmaz |
| `com.kiyi.antalya` için sahiplik veya seçilmiş yeni bundle ID | Hesaba kaydedilmiş doğru kimlik | Marka gerekçesiyle kendiliğinden değiştirilmedi |
| Gerçek işletmeci yasal adı ve iletişimi | 1.5, privacy/terms, seller/review bilgileri | Sağlanmadı |
| Gerçek destek e-postası ve destek sorumlusu | Ulaşılabilir iletişim, inceleme erişimi | Sağlanmadı |
| Yaş hedefi, moderatör/nöbet/yanıt süresi | 1.2/çocuk güvenliği/yaş anketi | İşletmeci kararı |
| Veri sınıfına göre saklama, silme, yasal hold ve yedek rotasyonu | Tam silme ve açık privacy açıklaması | Hukuki/işletmeci kararı; süre uydurulmadı |
| Paylaşılan Auth'ı ayırma veya tüm uygulamalar için hesap stratejisi | Başka uygulamalara zarar vermeden gerçek Auth silme | Açık |
| Ücretli satış kararı | İlk sürüm ücretsiz mi, IAP hangi aşamada | Teknik adayda kapalı; gelecekte açmak ayrı kabul gerektirir |
| Gerçek test posta kutusu ve izole Supabase Auth/Storage ortamı | Üretim kullanıcılarını silmeden gerçek servis kabulü | Erişim bekliyor |
| macOS/Xcode/CI ve iPhone erişimi | İmzalama, cihaz, TestFlight, gerçek screenshot | Erişim bekliyor |
| Görsel/araç/harita kullanım hakları | 5.2 ve sağlayıcı koşulları | İşletmeci teyidi |

## E. App Store inceleme hazırlığı

Başvuru açıklaması, kısa tanıtım, anahtar kelimeler, kategori önerisi, privacy/terms/support/silme taslakları, İngilizce Review notları, demo verisi planı, App Privacy ve yaş envanteri ile ekran görüntüsü planı: **`app-store/apple-review-20261029/SUBMISSION-DRAFTS.tr.md`**.

Gerçek demo hesabı ve kalıcı parolası oluşturulmadı: izole Auth ortamı yok; üretime test kullanıcı/veri eklenmedi. SQL fixture'ları gerçek Apple login bilgisi değildir. İnceleme için A/B sosyal hesapları ve ayrı silinebilir C hesabı planlandı. Operatör hesabı, kişisel plaka, özel medya ve gerçek konum screenshot'a alınmaz.

| İnceleyici adımı | Hazırlanan/testli bölüm | Başvuru öncesi kalan |
|---|---|---|
| 1. Uygulamayı aç | Yerel paket/entry regresyonu | Son imzalı yapıda launch/crash/ağ |
| 2. Demo hesapla giriş | E-posta Auth transport/guard | İzole gerçek demo hesabı ve erişim notları |
| 3. Profil | Bundle izolasyonu | Gerçek iOS görünüm ve medya |
| 4. Garaja araç ekle | Özgün SQL + A senaryosu | Native form/picker ve kayıt kalıcılığı |
| 5. Harita, konum iznini reddet | GPS bağımsız harita/fallback kodu | Gerçek OS reddi sonrası kesintisiz devam |
| 6. Gönderi paylaş | SQL post ve Edge medya izolasyonu | Gerçek Auth/Storage/cihaz UGC filtre kabulü |
| 7. Takip et | B senaryosu ve engel kontrolleri | İki gerçek oturum |
| 8. Beğeni/yorum | Bildirim ve etkileşim SQL'i | Native E2E |
| 9. Şikâyet/engelle | Rapor menüleri, SQL/panel, ghost block | Gerçek insan moderation döngüsü |
| 10. Jeton/hediye | Ücretsiz ödül/ledger/tekillik | İki hesapta gerçek gönderim; ücretli satış yok |
| 11. Privacy/terms/support aç | Paket bağlantı allowlist ve yerel dosyalar | Son işletmeci metinleri, gerçek Support/Privacy URL |
| 12. Silmeyi kontrollü test et | Şifreli onay ve izole cascade senaryosu | Ayrılmış gerçek Auth C hesabı, gerçek medya, eski JWT ve cihaz çıkışı |

Kabul planı hazırdır; on iki adımın gerçek native E2E olarak geçtiği iddia edilmez. Nihai ekran görüntüsü sayısı **0**. App Store Connect privacy/yaş/review alanları doldurulmuş sayılmaz.

## F. Nihai karar

**GÖNDERİME HAZIR DEĞİL.**

Bu çalışma kaynak düzeyindeki hesap silme doğruluğu, hayalet konum gizliliği, native bağlantılar ve yanıltıcı ödeme görünümüne ilişkin öngörülebilir eksikleri azalttı; test kapsamı büyüdü. Gönderim için gerçek Auth/silme/medya, insan UGC operasyonu ve iletişimi, hukuki saklama/metinler, macOS/native/TestFlight ve final mağaza beyanları zorunlu olarak açık kalıyor.

Apple onay garantisi verilmez. Kullanıcıdan alınmamış işletmeci bilgisi, saklama süresi, ürün kimliği, demo parola veya cihaz sonucu uydurulmadı.
