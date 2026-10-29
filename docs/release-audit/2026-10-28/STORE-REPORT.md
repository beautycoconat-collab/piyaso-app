# PİYASO — APP STORE / GOOGLE PLAY HAZIRLIK RAPORU

28 Ekim 2026 · Kaynak dalı: `audit/piyaso-release-20261028`

**Son karar: YAYINA HAZIR DEĞİL.** Mağaza hesapları dışında da tamamlanmamış gerçek Auth, cihaz, silme, operasyon ve üretim kurtarma kontrolleri vardır. Kaynak ve izole test ilerlemesi, mağazaya gönderilebilir imzalı uygulama anlamına gelmez.

Bu rapor aynı günkü genel raporun mobil dağıtım kapsamındaki devamıdır. Web uygulaması yayını, PWA/service worker, Vercel ve SEO kapsam dışıdır; önceki rapordaki web yayın önerileri bu sürümün gereği değildir. Mevcut önizleme korunmuştur. Production dağıtımı yapılmadı; üretim kullanıcı verileri silinmedi veya sıfırlanmadı.

## 1. Mevcut mobil altyapı ve sonuç

| Konu | iOS | Android |
|---|---|---|
| Teknoloji | Mevcut Capacitor 8.5.3 + Swift/SPM | Mevcut Capacitor 8.5.3 + Gradle |
| Görünen ad | Piyaso | Piyaso |
| Teknik kimlik | `com.kiyi.antalya`; sahiplik doğrulanmadı | `com.kiyi.antalya`; sahiplik doğrulanmadı |
| Minimum sistem | iOS 15 | Android API 24 |
| Hedef/toolchain | Xcode/macOS gerekli | compile/target API 36, AGP 8.13.0, Gradle 8.14.3, Java 21 gerekli |
| Yerel paket hazırlama | `npm run sync:ios` geçti | `npm run sync:android` geçti |
| Native derleme | Çalıştırılamadı: `xcodebuild: command not found` | Denendi: Gradle indirmesi `Network is unreachable` ile durdu; SDK ve Java 21 de mevcut değil |
| İmzalı çıktı | IPA yok | AAB yok |
| Gerçek cihaz | Yapılmadı | Yapılmadı |
| Gönderime hazır mı? | HAYIR | HAYIR |

Uzak `server.url` kullanılmıyor; uygulama varlıkları yerel pakete hazırlanıyor. Framework değiştirilmedi. Teknik kimlik yalnızca marka gerekçesiyle değiştirilmedi. Native simge/açılış PNG'lerindeki eski K/Kıyı varlıkları mevcut onaylı Piyaso logosundan yeniden üretildi; yeni logo tasarlanmadı. iOS simgesi görsel olarak incelendi.

Kamera, fotoğraf/medya, mikrofon ve yalnızca kullanım sırasındaki konum açıklamaları/izinleri incelendi. Android'de INTERNET, CAMERA, RECORD_AUDIO ve coarse/fine location mevcut; camera/GPS zorunlu donanım değil. Cleartext ve Android backup kapalı. iOS'ta arka plan konumu ve keyfi HTTP açılmadı. Native push plugin/APNs/FCM kurulumu yok; uygulama içi bildirim testleri sistem push bildirimi değildir.

## 2. Test sayıları ve kanıt sınırları

**Toplam 362/362 geçti: ana uygulama 297, yönetim paneli 34, izole SQL/senaryo 31; 0 başarısız, 0 atlanan.** Bunlara çalıştırılamayan gerçek cihaz/Auth/native build kabul kontrolleri dahil değildir. Ayrıntılar `evidence/store-test-summary.json` dosyasındadır. Ham çıktılar aynı evidence klasörüne alınmıştır. İlk tüm `.mjs` koşusunda ödeme modu değişikliğine bağlı eski test beklentisi başarısız oldu; test artık açıkça kapalı mod ile etkin satın alma doğrulamasını ayrı doğrular. Mevcut güvenlik doğrulaması kaldırılmadı. Nihai sonuç aşağıdaki kanıt dosyasına göre değerlendirilmelidir.

| Kontrol | Sonuç / sınır |
|---|---|
| 24 özgün SQL paketi | **24/24 geçti**, özgün SQL assertion'ları değiştirilmedi |
| Ek izole senaryo/medya/kurtarma testleri | **7/7 geçti** |
| Yönetim paneli regresyonu | **34/34 geçti** |
| TypeScript | `tsc --noEmit` geçti |
| Uygulama/kitaplık lint | `eslint app lib` geçti; tüm depo lint'i yerine geçmez |
| Yerel framework build | Geçti; mağaza native build'i değildir, yayınlanmadı |
| Bağımlılık taraması | Ana pnpm ve mobil npm: **0 kritik/yüksek/orta/düşük** |
| İstemci gizli anahtar taraması | 285 istemci metin varlığı geçti; sınırlı desen taramasıdır |
| Tarayıcı JS sözdizimi | Geçti |
| Mağaza hazır olma kontrolleri | iOS ve Android bilinçli olarak başarısız: eksikler varken gönderimi engelliyor |
| Yerel tarayıcı | Hesap silme talep sayfası açıldı; gerçek hesapla talep gönderilmedi |
| Gerçek cihaz / TestFlight / Play | **0** |

İzole veritabanı: PGlite PostgreSQL 18.6, PostGIS 3.6 ve pgcrypto. Üretimin PostgreSQL 17 sürümüyle birebir aynı sunucu değildir. Canlı uygulama şeması/fonksiyonları/politikaları ve güvenli katalog ayarları kullanılır; gerçek kullanıcı satırları, Auth oturumları veya medya kopyalanmaz. Test reward salt'ı üretimden farklıdır. Auth ve Storage yardımcı şemaları test karşılıklarıdır. Tek bağlantıyı sıraya alan PGlite, çok bağlantılı PostgreSQL yarış yük testi değildir.

Tekrarlama: `node --test tests/*.test.mjs tests/*.test.cjs`, `node --test scripts/test-mobile-database.mjs scripts/test-mobile-journeys.mjs`; yönetim checkout'unda `node --test tests/*.test.mjs`. SQL testlerini üretimde çalıştıran bir bağlantı eklenmedi.

## 3. A–E senaryolarında gerçekten doğrulananlar

| Senaryo | İzole doğrulama | Tamamlanmayan gerçek akış |
|---|---|---|
| A | İki test kimliğinden ilkiyle profil, araç/plaka, harita, gönderi ve garaj rozeti | Supabase kayıt/e-posta, cihaz formu, fiziksel konum |
| B | İkinci kimlikten takip, beğeni, yorum ve alıcı bildirim kaydı | İki gerçek uygulama oturumu ve push |
| C | Günlük ödül tekrarında ek bakiye yok; 8 aynı gift request'inde bir hediye ve bir 20 jeton borç | Çok bağlantılı eşzamanlı gerçek ağ yükü ve mağaza satın alma |
| D | Başkasının garajı/cüzdanı, sahte kredi/sipariş ve satın alma RPC'leri reddediliyor | Gerçek cihazdan JWT/ağ saldırı senaryosu |
| E | SQL kimlik bağlamı değişip dönünce profil/garaj/bakiye/rozet korunuyor | Gerçek çıkış/giriş, arka plan ve süreç öldürme |

Bu tablo beş tam gerçek kullanıcı E2E senaryosunun bittiği anlamına gelmez. Bunlar hâlâ açık kabul testleridir. Manuel şarkı adıyla gönderme korunmuştur; harici katalog eklenmemiştir.

## 4. Düzeltmeler ve güvenlik

| Sorun | Önem | Yapılan iş / doğrulama |
|---|---|---|
| Bağımlılık uyarıları | Orta | satori 0.33.5, fflate 0.7.5 ve native xcode bağımlılığı altındaki uuid 11.1.1; iki audit sonucu sıfır; yerel build kontrolü |
| Android geri davranışı ve native devam | Yüksek | Composer/modal önce kapanır, sonra geçmiş/harita/minimize; ön plana gelince hesap yenilenir, hata yakalanır; 5 bridge testi, cihaz testi bekliyor |
| Native şifre sıfırlama dönüş adresi | Yüksek | E-posta dönüşü capacitor localhost yerine tanımlı HTTPS origin; callback allowlist ve gerçek e-posta testi bekliyor |
| Yapılandırılmamış native OAuth | Yüksek | Apple/Google native callback kurulana kadar fail-closed; çalışan e-posta/ücretsiz jeton mantığı korunur |
| Mağaza hazırlık kapısı | Yüksek | iOS/Android ayrı koşullar, gerçek Auth/silme/kurtarma/UGC gereklilikleri; ücretli ürün açıksa sunucu doğrulama ve restore kanıtı zorunlu |
| Dışarıdan hesap silme talebi | Yüksek | Bağımsız talep sayfası, geçici Auth oturumu, parola kalıcı kaydedilmez, işlem sonrası yerel logout; 3 transport testi; üretime dağıtılmadı, silme tamamlandı denmez |
| Eski native görseller | Orta | Mevcut Piyaso logo kaynağından platform ikon ve splash PNG'leri |
| Storage bypass regresyonu | Kritik | Önceki denetimde kapatılan doğrudan INSERT yolu izole RLS testinde reddedildi; sahip olunan PNG Edge yüklemesi geçti; yetkisiz, MIME/byte uyumsuz ve fazla büyük dosya reddedildi |

Medya testi gerçek Edge handler'ını ve uygulamanın SQL izin/registry fonksiyonlarını çalıştırır. HMAC test JWT'si ve bellek içi object store kullanır; gerçek Supabase Auth/Storage uçtan uca testi değildir. Gerçek kullanıcı yükleme/okuma/silme hâlâ zorunlu.

Canlı güvenlik advisor kontrolünde `auth_leaked_password_protection` WARN açık. Diğer 147 bulgu RLS açık/politika yok INFO; özel tablolarda varsayılan ret tasarımını doğrudan açık erişim olarak yorumlamadım. Sızdırılmış parola koruması bu erişimle değiştirilemedi; sahip Dashboard/Management API erişimi ve plan uygunluğu gerekir. Ücretli plana geçilmedi.

Marka SQL'i (`release-audit-brand.sql`) izole şemada test edildi; üretime uygulanmadı. Yerel Auth şablonları Piyaso; barındırılan Auth şablonları/gönderen adı ve SMTP son ayarı doğrulanmadı. Storage düzeltmesinin önceki migration kayıt hatası nedeniyle migration defteri uzlaştırması ayrıca açık. Bu tur canlı backend'e mutasyon uygulanmadı.

## 5. Yedek ve geri dönüş

İzole DB dump'ı ve medya byte/checksum'ları AES-256-GCM ile şifrelendi, kaynak test DB kapatıldı, object store temizlendi, yeni DB örneğine yüklenip profil/cüzdan/garaj ve medya checksum'ları karşılaştırıldı. Bozulmuş şifreli yedek reddedildi. Geçici anahtar/dosyalar temizlendi. Bu gerçek bir **izole kurtarma tatbikatıdır**; üretim Supabase managed backup/PITR erişimi, bucket yedeği, harici saklama, anahtar erişimi, RPO/RTO ve gerçek geri yükleme kabulü tamamlanmış değildir. `docs/operations/backup-restore.md` işletim planı korunur.

## 6. Mağaza kuralları ve ödeme

Ücretli dijital jeton/hediye/Premium satışı etkinleştirilecekse uygun Apple IAP / Google Play Billing akışı, sunucu doğrulaması, tekil sağlayıcı işlem ledger'ı, restore, pending, iade/iptal gerekir. Mevcut pakette bunlar tamamlanmış değildir. İstemciden gelen `verified` alanı kabul edilmez. Ayrıntılı uygulanacak sözleşme: `docs/operations/store-purchases.md`. Ücretsiz kazanılan jeton sistemi değiştirilmedi.

Apple/Google giriş sağlayıcıları native callback yapılandırılmadan açılmaz. Apple'ın alternatif giriş gerekliliği son sunulan giriş seçeneklerine göre yeniden değerlendirilmeli; Sign in with Apple etkinleştirilirse hesap silmede token iptali de gerekir.

Şikâyet/engelleme/izin sınırları SQL testlerinde mevcut; gerçek moderasyon nöbeti, yanıt SLA'sı, çocuk güvenliği standardı/iletişimi, nihai yaş anketi ve uygunsuz içerik operasyon kabulü tamam değil. Kamera/konum izin reddi, hayalet mod ve kesin konum paylaşımı iki gerçek hesapla ayrıca test edilmeli. Gizlilik/koşullar, destek ve silme sayfalarının son işletmeci adı, gerçek destek e-postası, saklama süreleri ve işlemin tamamlanma süresi yok; uydurulmadı. Yeni talep sayfasının herkese açık HTTPS URL'si ve içeriği dağıtım sonrası doğrulanmalı. Bu sayfalar bir web uygulaması yayını değildir.

Apple için yalnızca destek talebi oluşturmak yeterli hesap silme kanıtı sayılmadı. Gerçek uygulama içi silme başlatma, kimlik doğrulaması ve Piyaso verileri/medyasının tamamının temizlenmesi (ortak Auth kimliği etkileri dahil) kabul testinden geçmelidir.

## 7. Hesaplar açılınca yapılacaklar

**Apple:** Bundle ID sahipliği ve takım; sertifika/provisioning; Xcode ile simulator ve imzalı archive; privacy manifest bağımlılıkları/export compliance; iPhone/iPad safe area, klavye/kaydırma, izin reddi, arka plan, oturum, yavaş/kapalı ağ; App Store Connect gizlilik/yaş/support/deletion URL'leri; inceleme hesabı; TestFlight; ücretli ürün varsa ürünler/sandbox/server notification/restore/iade.

**Google:** Paket sahipliği ve Play App Signing/upload key; Java 21/SDK 36 ile unit/debug ve imzalı AAB; gerçek Android sürüm/ekran/geri tuşu/izin/background testleri; Data Safety, yaş/içerik formu ve sosyal uygulama politikaları; kapalı test şartları hesaba göre; inceleme erişimi; ücretli ürün varsa Play Billing ürünleri/API/RTDN/sandbox/restore/iade.

CI iş akışları hazırlandı: iOS imzasız simulator build, Android debug+unit, izole DB. Doğru GitHub deposu doğrulanamadığı için bu CI koşuları yapılmış sayılmaz. Kaynak sunucusu GitHub değildir; eski music installer deposu ana uygulama olarak kullanılmadı.

## 8. Gönderim engelleri

1. Gerçek Supabase kayıt, e-posta doğrulama, şifre sıfırlama, hesap silme ve iki hesaplı beş tam E2E senaryo.
2. Gerçek Auth/Storage medya kabulü ve PostgreSQL 17'de çok bağlantılı çift harcama testi.
3. Üretim DB+medya yedek/restore onayı ve sızdırılmış parola koruması ayarı.
4. Marka SQL ve hosted Auth şablon/gönderen düzeltmelerinin kontrollü uygulanması.
5. İşletmeci/destek/saklama/UGC-çocuk güvenliği operasyonu, final hukuk metinleri ve çalışan dış silme URL'si.
6. iOS/Android native derleme, gerçek cihaz, imzalama, mağaza formları ve mağaza hesapları.
7. Ücretli jeton satışını açmadan önce gerçek sağlayıcılı IAP/Billing. Native sistem push isteniyorsa APNs/FCM ve izin teslim testleri de eksik.

**Piyaso şu anda App Store veya Google Play'e gönderilmeye hazır değildir.** İzole SQL regresyonu ve bağımlılık açıkları kapatılmıştır; yukarıdaki kabul engelleri test edilmiş gibi gösterilmemiştir.
