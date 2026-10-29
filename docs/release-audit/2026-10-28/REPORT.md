# PİYASO YAYIN HAZIRLIK RAPORU

Tarih: 28 Ekim 2026. İncelenen ana kaynak başlangıcı: `cbfd5bcfc369de7d757a0871620b04a5e6fb1ae5`.
Dal: `audit/piyaso-release-20261028`. Yönetim paneli ayrı checkout ve aynı adlı dalda; başlangıcı `5a9462e997a136305db6892b50fb1b8b7b27638b`.

## 1. Genel durum

| Soru | Sonuç | Gerekçe |
|---|---|---|
| Teknik olarak kullanıma hazır mı? | KISMEN | Derleme ve mevcut otomatik testler geçti; tüm gerçek kullanıcı akışları doğrulanmadı. |
| Gerçek kullanıcı kabulüne hazır mı? | HAYIR | İki hesap izolasyonu dahil tam uçtan uca test ve geri yükleme tatbikatı eksik. |
| Web üzerinden genel yayına hazır mı? | HAYIR | Önizleme çalışıyor; bu denetim sürümü dağıtılmadı ve zorunlu kabul kontrolleri tamamlanmadı. |
| App Store / Google Play için hazır mı? | HAYIR | Mağaza hesapları, imzalı derleme, cihaz testi ve satın alma doğrulaması gibi engeller var. |

Karar: **YAYINA HAZIR DEĞİL**. Bu karar uygulamanın hiç çalışmadığı anlamına gelmez; güvenli genel yayın kabulünün henüz kanıtlanmadığı anlamına gelir.

## 2. Kapsam ve kanıt sınırları

Mevcut proje kullanıldı; sıfırdan uygulama kurulmadı. Ana checkout başlangıcında 913 takip edilen dosya ve 347 JS/TS/Python/SQL dosyası envanterlendi. Hesap, medya, sosyal işlemler, garaj, harita, jeton, rozet, yönetim, dağıtım ve ilgili testler hedefli incelendi. **913 dosyanın her satırı elle denetlenmiş değildir.** Statik tarama, test ve üretim metadata incelemesi tam güvenlik ispatı değildir.

Gerçek dağıtım Sites/Cloudflare üzerinde; mevcut kaynakta Vercel yapılandırması ve bağlı Vercel erişimi bulunamadı. Ana uygulamanın GitHub deposu da doğrulanamadı: erişilebilir GitHub sonuçlarında yalnızca müzik kurulum deposu ve iki başka proje göründü. Müzik deposu ana uygulama deposu olarak kullanılmadı.

Production uygulama dağıtımı yapılmadı. Canlı veritabanındaki tek kalıcı denetim müdahalesi aşağıdaki Storage izin kapatmasıdır. Kullanıcı verileri silinmedi/sıfırlanmadı; gerçek kullanıcılara hediye veya bildirim gönderilmedi.

## 3. Test sonuçları

| Test / kontrol | Gerçek sonuç |
|---|---|
| Ana uygulama Node testleri | **284/284 geçti**, 0 başarısız, 0 atlandı. Tam koşu 103,3 saniye. |
| Yönetim paneli Node + izole PGlite/PostgreSQL testleri | **34/34 geçti**, 0 başarısız, 0 atlandı. |
| Toplam otomatik test | **318 geçti / 318 çalıştırıldı**. Tekrarlanan hedefli koşular toplama yeniden eklenmedi. |
| Hesap yarış durumu regresyonu | Altı yeni test tam koşuya dahil; geciken bundle ve directory medyasını da kapsıyor. |
| Canlı HTTP negatif kontroller | Medya yükleme, hesap bundle ve admin RPC: kimliksiz isteklerin üçü de **401**. Node test toplamından ayrı. |
| Canlı Storage RLS negatif kontrol | Sahte UUID ile `authenticated` doğrudan nesne INSERT işlemi engellendi; transaction rollback. |
| Marka SQL geçişi | Üç fonksiyonun marka değişikliği transaction içinde derlendi; eski marka sayısı 0; rollback. Kalıcı uygulanmadı. |
| Production build | Ana uygulama ve yönetim paneli başarılı. Panel çıktısı geçerli ESM `fetch` export ediyor. |
| TypeScript | `tsc --noEmit` başarılı. |
| Lint | 0 hata, **146 uyarı**. `app lib --max-warnings 0` başarılı. |
| Tarayıcı JS sözdizimi / istemci sır taraması | Başarılı. Sınırlı secret/service-role örüntü kontrolü. |
| Bağımlılık audit | 0 kritik, 0 yüksek, **1 orta** uyarı. |
| Ana uygulama SQL regresyonu | **24 paket çalıştırılamadı**: allowlist edilmiş izole PostgreSQL bağlantısı yok. Üretim koruması kaldırılmadı. |
| Kullanıcı senaryoları A–E | **5 tam E2E senaryosu tamamlanmadı**. Mevcut unit/SQL testlerini bu senaryoların tamamı saymadım. |
| Gerçek iPhone / Safari / TestFlight | **0 senaryo doğrulandı**. Bu ortam Chrome; iOS cihazı değildir. |
| Mağaza hazırlık kontrolü | Başarısız/bloklu: mevcut development bayrakları ve dış gereklilikler nedeniyle. Bir ürün testi olarak 318 sayısına dahil edilmedi. |

Chrome önizlemede açılış, tanıtım sayfaları, araç rengi seçimi, giriş formu, boş formun reddi, Keşfet yönlendirmesi ve girişsiz gönderi oluşturmanın giriş ekranına yönlenmesi görüldü. Yenileme sonrası sayfa başlığı Piyaso oldu. Harita 3B desteğinin kullanılamadığını bildirerek standart haritaya geçti; bu gözlem **3B harita geçti** olarak sayılmadı. Fiziksel dokunma, yavaş ağ, internet kopması/yeniden bağlanma, video yükleme ve mobil bellek ölçümü yapılmadı. Görsel açılış süresinden LCP/performans skoru türetilmedi.

## 4. Bulunan hatalar ve düzeltmeler

| Bulgu | Önem | Etki / düzeltme | Son durum |
|---|---|---|---|
| Doğrudan Storage upload bypass | YÜKSEK | `kiyi_media_insert` permissive politikası Edge dosya kontrolü/kota kaydını aşabiliyordu. Yalnızca bu eski INSERT politikası kaldırıldı. Bucket private, okuma/silme yetkileri korundu. | Canlı kapatıldı; aynı authenticated INSERT reddedildi, HTTP kimliksiz upload 401. Gerçek Edge upload E2E ayrıca bekliyor. |
| Eski refresh isteğinin yeni hesabı kapatması / yeni token ile eski payload | YÜKSEK | Refresh, DB komutları, profil bundle ve directory medya sonuçlarında kullanıcı kimliği/oturum sürümü kontrolü eklendi. Bundle yerel değişkende hazırlanıp ancak oturum hâlâ aynıysa ekrana yazılıyor. Eski hataların yeni oturumu kapatması engellendi. | Altı yeni regresyon testi başarılı; kaynak dalında, henüz dağıtılmadı. |
| Hesap isteğinin sınırsız bekleyebilmesi | ORTA | Destekleyen tarayıcılarda 15 saniyelik istek timeout'u; `AbortSignal.timeout` olmayan tarayıcıda çağrı çökmez. | İlgili hesap testleri başarılı; gerçek bağlantı kopması E2E bekliyor. Eski tarayıcıda timeout garantisi yok. |
| Eski marka metinleri | ORTA | Ana uygulama, native görünür adlar, meta başlık, mesajlar, yerel e-posta şablonları ve ayrı yönetim paneli Piyaso yapıldı. | Önizleme başlığı doğrulandı; canlı dağıtım, SQL marka geçişi ve Auth sağlayıcı şablon/gönderen ayarı bekliyor. |
| İsim geçişinde eski sunucu hata metniyle uyumsuzluk | ORTA | Hem eski hem yeni kısıtlama yanıtları tanınıyor; kullanıcıya Piyaso gösteriliyor. | Regresyon testi geçti. Teknik `kiyi_*` adları/URL'ler değiştirilmedi. |
| Tamamlanmış tasarıma uymayan eski composer testi | DÜŞÜK | Eski “Daha Fazla” düzen beklentisi güncel footer ile düzeltildi; metin/medya/anket/görünürlük koruma doğrulamaları sürdürüldü. Marka nedeniyle karakter sayımı 14 olarak düzeltildi. | Tam test koşusu geçti; test silinmedi. |
| Vendor/bundle/CJS lint kapsamı | DÜŞÜK | Üretilmiş bundle ve üçüncü taraf dosyaları ayrıldı, gerçek CJS/UMD için uygun kural kapsamı verildi. Hook olmayan harita yardımcısının adı düzeltildi. | 0 lint hatası; 146 mevcut uyarı açıkça kaldı. |
| `satori` SVG kaçış uyarısı | ORTA | `vinext > @vercel/og > satori` 0.16.0; düzeltme >=0.33.5. Uygulamada OG görsel endpointi bulunmadı. Uyum testi olmadan büyük sürüm override yapılmadı. | Açık; build zincirinde güvenli güncelleme/uyumluluk testi gerekli. |
| Sızdırılmış parola koruması kapalı | ORTA | Supabase security advisor doğruladı. Bağlı araç Auth ayarını değiştirme imkanı vermiyor. | Açık; Dashboard üzerinden etkinleştirilmeli ve kayıt/reset testi yapılmalı. |

Satori kaydı: https://github.com/advisories/GHSA-wx4j-mvgx-mqwp
Parola koruması: https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection

## 5. Modül durumu

| Modül | Kanıtlanan / eksik |
|---|---|
| Hesap | Token, PKCE, doğrulama bekleme ve sunucu cüzdan ayrımı otomatik test edildi. Gerçek signup, mail teslimi, reset, tekrar giriş, silme ve fotoğraf yükleme E2E bekliyor. Apple/Google giriş butonları kapalı “Yakında”. |
| Garaj | Model/araç/özelleştirme testleri geçti. Gerçek çoklu araç kaydı, yetersiz jeton ve yenileme sonrası kalıcılık iki test hesabıyla doğrulanmadı. Aksesuarların bazıları UI'da yalnızca ücretsiz önizleme olarak belirtiliyor; kaydedilen tam özellik sayılmadı. |
| Harita | Bölge/gizlilik/fallback kod testleri geçti; Chrome standart harita akışını gösterdi. iPhone 3B, dokunma, GPU/bellek ve gerçek konum senaryosu bekliyor. |
| Sosyal / Plaka Ara | Kaçış, görünürlük, filtre yarışı, giriş zorunluluğu, medya sınırları mevcut testlerde geçti. İki hesap takip/beğeni/yorum/bildirim ve özel plaka arama uçtan uca bekliyor. |
| Jeton / hediye / şarkı | İstemci gerçek bakiye/ödül yetkisini değiştiremiyor; sunucu request_id benzersizlikleri görüldü. Manuel şarkı adı akışı korundu, harici katalog eklenmedi. Günlük/davet ödülü ve eşzamanlı çift harcama tam SQL regresyonu bekliyor. |
| Rozet | Seviye/eşik/görsel/ilerleme mevcut Node testlerinde geçti; tüm görevlerin gerçek sunucu kazanımı ve tekrar ödül reddi E2E bekliyor. |
| Yönetim | İzole testler normal kullanıcı reddi, MFA, lease, rol, maskeleme, idempotency, audit ve revocation kontrolünü içeriyor. Gerçek admin MFA oturumu ile üretim paneli işlemi yapılmadı. |

## 6. Supabase güvenlik ve otomasyon sonucu

33 public uygulama tablosunda RLS açık. Kontrol edilen anon/authenticated grant'lerinde doğrudan cüzdan, garaj, rozet yazımı yok; anon admin çalıştırma yetkisi yok. Politikası olmayan RLS tabloları RPC üzerinden erişilen kapalı tablolar olabilir; advisor INFO uyarıları yetki açılarak susturulmadı. Bu metadata kontrolü, her RPC'nin tüm izin dallarının geçtiği anlamına gelmez.

Storage `kiyi-media` private; bucket sınırı 20 MB, dar MIME listesi var. Medya Edge Function JWT'yi kendi içinde Auth üzerinden doğruluyor; `verify_jwt=false` tek başına kimliksiz erişim kabulü anlamına gelmiyor. İstemcide yalnızca publishable anahtar görüldü; server service role anahtar değeri okunmadı/yazdırılmadı. Gizli anahtar örüntü taraması tüm olası sızıntıları dışlamaz.

Canlı SQL'de ledger/post/comment request benzersiz indeksleri ve reward kayıt anahtarları görüldü. Eşzamanlı istek ve tüm rozet/ödül kötüye kullanım senaryoları için izole SQL koşusu hâlâ gerekli.

Beş aktif pg_cron işi incelendi: gizlilik temizliği, istatistik, medya temizliği, sağlık ve davet ödülü. İncelenen son 24 saatte cron başarısızlığı 0. Bu, işlerin işlevsel çıktılarının tamamının doğrulandığı anlamına gelmez. Log sorgulama erişimi mevcut. Email/push delivery kapalı; uygulama içi bildirim ile harici push/e-posta birbirinden farklı. Piyaso'ya bağlı ChatGPT otomasyonu bulunmadı; ilgisiz otomasyonlar değiştirilmedi.

## 7. Zorunlu eksikler ve yayın engelleri

1. İzole ve migration'ları yüklenmiş PostgreSQL/Supabase hedefi sağlanmalı; 24 SQL paketi çalıştırılmalı. Üretim koruması bilinçli olarak korunuyor. Manuel şarkı SQL testi de izole koşucuya eklendi.
2. A–E akışları iki izole hesapla gerçek tarayıcıda tamamlanmalı; gerçek kişilere bildirim/hediye gönderilmemeli. Kayıt/doğrulama/reset e-postalarının teslimi ve hesap silme sonrası kalıcılık ayrıca doğrulanmalı.
3. Gerçek iPhone Safari üzerinde harita 3B/fallback, dokunma, fotoğraf/video, yavaş ağ, kesinti ve bellek testleri yapılmalı. Bu ortamda gerçek cihaz erişimi yok.
4. Şifreli DB + Storage yedeği, geri yükleme hedefi ve başarılı geri dönüş tatbikatı kanıtı gerekli. Depodaki mevcut plan zaten “otomatik yedek kurulmuş değildir” diyor. Sağlayıcı planındaki yedek kapasitesi bu araçlarla doğrulanmadı.
5. Sızdırılmış parola koruması, Auth e-posta şablonları/gönderen adı ve gerekiyorsa SMTP/push teslim yapılandırması tamamlanmalı. Yerel şablonun değişmesi sağlayıcı şablonunun güncellendiği anlamına gelmez.
6. Audit dalı doğru ana GitHub deposuna bağlanıp push/PR yapılmalı. Bağlı ana repo adresi bulunamadı. Sites kaynak dalı saklanabilir; bu bir GitHub push'u değildir.
7. İncelenen gerçek hosting Sites/Cloudflare. Vercel kullanılıyorsa doğru proje/ortam erişimi olmadan Vercel production env/SSL/dağıtım sağlığı kontrol edilmiş sayılamaz. Test ve production ayrılığı kurulmalı/doğrulanmalı.
8. Kaynak düzeltmeleri ve marka SQL'i review sonrası kontrollü dağıtılmalı; rollback planı ve son HTTP/UI smoke kontrolü uygulanmalı. Mevcut Supabase proje kimliği, API/table adları ve bağlantılar korunmalı.
9. Mağaza: Developer/Play hesapları, bundle ID sahipliği, gerçek ürün/IAP sunucu doğrulaması, restore, final hukuki metinler/operatör/destek, yaş derecesi, imzalı Xcode/Android çıktısı, TestFlight/Play internal test ve mağaza ekran görüntüleri. Bu denetim bunları tamamlanmış saymıyor.
10. PWA manifesti/service worker bulunmadı. Native iOS/Android isimleri güncellendi; mevcut olmayan PWA desteği yapılmış gibi gösterilmedi. PWA yayın hedefiyse ayrıca gereklilik kararı alınmalı; bu denetimde yeni özellik eklenmedi.

## 8. Güvenli teslim ve geri dönüş

Ana uygulama ve panel ayrı audit dallarında tutulur. Çalışan tasarım ve mevcut logo korunur. Kalıcı canlı Storage izin kapatması kullanıcı satırlarını değiştirmez; rollback için güvenlik bypass'ını tekrar açmak önerilmez. İstemci değişiklikleri Git revert ile geri alınabilir. Marka SQL'i yalnızca user-facing metni değiştirir ve transaction rollback ile derlenebilirliği kontrol edilmiştir; yayın sırasında ayrıca uygulanmalıdır.

Bu rapor bir tam penetrasyon testi veya bütün gerçek kullanıcı işlevlerinin onayı değildir. Test geçişi ile canlı kabul kanıtı ayrı tutulmuştur.

### Teslim doğrulaması

Ana uygulama ve yönetim paneli audit dalları Sites kaynak Git sunucusuna push edildi ve uzak commit kimliği kontrol edildi. Bu sunucu GitHub değildir; doğru ana uygulama GitHub repo bağlantısı hâlâ gerekli. Ana uygulamanın canlı Sites sürümü 203 olarak kaldı.

Canlı Storage bypass politikası 0 olarak yeniden doğrulandı. Aynı idempotent SQL'i migration defterine kaydetme çağrısı `Invalid or expired requestState` hatası verdi; deftere işlendiği iddia edilmiyor. SQL dosyası kaynakta saklıdır; yayın öncesi migration geçmişi uzlaştırılmalıdır.
