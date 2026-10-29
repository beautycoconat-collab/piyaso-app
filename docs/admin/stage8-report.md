> Güncel durum: 26 Ekim teslimat tamamlama raporu [stage8-completion-report.md](stage8-completion-report.md). Aşağıdaki metin 25 Ekim kontrol noktasıdır.

# Kıyı — Aşama 8 uygulama ve doğrulama raporu

25 Ekim 2026. Başlangıç: Aşama 7 son kaynak commit'i `ea941bb3464e99f73a18985fb8a81b2076fa4f5b`.

**Durum: koşullu hazırlık; mağaza yayınına hazır değil. Bütün entegrasyonlar tamamlandı iddiası yok.** Güvenlik ve hazırlık kodu mevcut projeye uygulandı. Dış erişim ve ortam gerektiren doğrulamalar aşağıda ayrı belirtilir. GitHub, kullanıcının bu aşamadaki “GitHub’ı beklet” seçimiyle beklemeye alındı. Apple/Google hesabı açılması istenmedi. Ücretli servis/abonelik alınmadı, gerçek kullanıcıya test bildirimi gönderilmedi.

## A. Uygulanan işler

- Son kaynak eski çalışma kopyasının üzerine yazılmadan ayrı checkout'a alındı. Önceki kaynak, plaka tasarımları, 21 otomobil/18 motosiklet, mevcut garaj ve sosyal sistem korundu.
- **Plaka araması:** yalnızca tam plaka sorgusu, harf/boşluk normalizasyonu, boş sorguyla toplu profil listesinin kapatılması ve sunucuda dakikada 20 arama sınırı. Mevcut benzersiz plaka/sahiplik ve silinmiş/gizli araç kuralları korunur. İlk plaka kaydı sahiplik kanıtı değildir; otomatik doğrulama rozeti verilmez. Kanıt/itiraz prosedürü `docs/operations/plate-verification.md` içinde.
- **Konum:** başkaları için 0,01 derece yuvarlama (yaklaşık kilometre ölçeği), hareket yönünü kaldırma ve güncelleme zamanını dakikaya yuvarlama. Kişi kendi konumunu görebilir. Premium paylaşımı kapatmayı, onay listesini veya engeli aşamaz. Antalya/İzmir sınırları değiştirilmedi; konum geçmişi API'si eklenmedi. Harita isteği 60/dakika.
- **Hassas komutlar:** profil, doğrulama, destek, silme talebi ve hediye için ek sunucu hız sınırları; anonim Auth hesaplarının kalıcı hesap komutlarını kullanmasının reddi. Aşama 7 canlı oturum denetimi korunur.
- **Hesap:** şifre sıfırlama isteği, adres çubuğundan tokenı hemen temizleyen web dönüş sayfası, şifre eşleşmesi/uzunluk denetimi, Auth user doğrulaması ve parola sonrası oturum kapatma akışı. Diğer cihazlardan çıkış eklendi. Gerçek e-posta teslimatı ve bağlantı dönüşü henüz canlı E2E doğrulanmış değildir.
- **Medya:** mevcut özel kova/limitler kullanılır; Edge Function servis yanıtlarına nesne/tür kontrolleri eklendi. Deno tip kontrolü ve mevcut dosya/yetki testleri geçti. `kiyi-media` v3 canlı. Önceki `verify_jwt:false` ayarı korunur; fonksiyon kendi bearer/Auth/oturum/worker-secret kontrollerini uygular.
- **Moderasyon:** tehdit, olası telefon ifşası, bağlantı spamı için konservatif otomatik ön tarama; resim/video sınıflandırıcısı yoksa insan incelemesi. Yeni/değişen gönderi ve yorumlar mevcut yönetici şikâyet kuyruğuna `source=automated` ile düşer. Ayrıntı “kullanıcı şikâyeti değildir” diye açıkça etiketlenir. Bu teknik kaydın reporter alanı içerik sahibidir; kullanıcı kendini şikâyet etmiş gibi yorumlanmamalıdır. Aynı aktif inceleme yinelenmez. Sınıflandırıcı içeriği otomatik güvenli saymaz veya nihai kaldırma kararı vermez. Eski içerikler topluca yeniden taranmadı. Görsel/video NSFW modeli bağlı değildir.
- **Ekonomi:** mevcut atomik cüzdan/defter/satın alma korunur. Sunucu ödeme adaptörü, doğrulayıcı yokken 503 ile kapanır; test satın alımı üretimde reddedilir. Kredi değeri istemciden alınmaz. Bu modül henüz bir canlı ödeme endpoint'i veya StoreKit/Play Billing doğrulayıcısı değildir, cüzdana para yazmaz. Gerçek ödeme tamamlandı sayılmaz.
- **Push:** izin, tercih, gerçek transport ve kalıcı tekilleştirme sınırı isteyen sunucu adaptörü hazır. Anahtar yoksa `pending_credentials`, izin yoksa `disabled`; telefona bildirim gönderildi denmez. Kalıcı push teslimat kuyruğu/lease deposu henüz bağlı değil. Mevcut uygulama içi sosyal/hediye/şarkı/admin bildirimleri değişmedi.
- **Hata izleme:** sadece sabit kod alanı gönderilir; mesaj, stack, URL, plaka, konum, e-posta veya token aktarılmaz. Mevcut özel `ops_events` ve yönetici sağlık görünümü kullanılır. Dakikada 10 sunucu sınırı ve istemcide dakika başına sınır var. Çevrimdışı ekran bandı eklendi. Genel istemci/API ve harita hata bağlantıları var; bütün sunucu/ödeme/teslimat hataları için eksiksiz kapsama veya dış alarm teslimatı iddiası yok. Yeni anonim sabit kodlu istemci olayları 30 gün sonra, yalnızca bu olay türleri için temizlenir. Mevcut hesap/audit kayıtları silinmez. Beş dakikalık cron; 15 dakikada en az 10 API/medya/harita hatasında yönetici sağlık kuyruğuna saatte en fazla bir uyarı koyar. Dış e-posta/push alarmı değildir. Retention, kuyruk, tekilleştirme ve istemci execute reddi rollback testi geçti.
- **Mobil:** mevcut Capacitor iOS/Android projeleri kullanılır. Web paket temizliğine sınırlı yeniden deneme eklendi. İki sync işlemi geçti. Bu, native derleme değildir. Android debug APK için GitHub workflow hazırlandı; çalıştırılmadı.
- **Yasal taslaklar:** topluluk, silme, içerik kaldırma, konum ve KVKK sayfaları gizlilik sayfasına bağlandı. İşletmeci, saklama, aktarım ve hukuki onay alanları açıkça eksik işaretlidir. Yeni hukuki uyumluluk veya rıza onayı iddiası yok.
- **E-posta:** mevcut Supabase sağlayıcısı için doğrulama/sıfırlama/güvenlik/silme durumu HTML şablonları hazır; Dashboard'a uygulanmadı. Güvenlik/silme e-postası gönderim kuyruğu henüz yok. Mevcut uygulama içi silme talebi ve durum takibi korunur.
- **CI:** push/PR için web TypeScript, ESLint (app/lib), bütün public JS syntax, Deno Edge check, unit/integration testler, audit, build ve istemci anahtar taraması. Ayrı manuel workflow'lar izole DB regresyonu ve Android debug APK içindir. GitHub'a yüklenip çalışmadıkları için Actions sonucu verilmez.

### Veritabanı işlemleri

Canlı migration'lar:

1. `20261025114603_stage8_access_privacy.sql`: private fonksiyon yedeği, komut sınırları, kapalı listeleme, konum hassasiyeti ve sabit kodlu tanılama.
2. `20261025114725_stage8_dispatcher_grant.sql`: mevcut invoker RPC'nin yeni güvenlik dispatcher'ına kontrollü authenticated çağrı yetkisi. İç komut zinciri istemciye açılmaz.
3. `20261025115514_stage8_text_review.sql`: rapor kaynağı alanı ve yeni/değişen içerik ön inceleme tetikleyicileri.
4. `20261025122024_stage8_health_retention.sql`: anonim kayıt temizliği ve yönetici kuyruğu eşiği; cron aktif ve test edildi.

Yeni tablo yalnızca RLS'li ve istemci erişimi kapalı `kiyi_private.stage8_backup`; mevcut `kiyi_reports` genişletildi. Yeni kova/cüzdan/sosyal tablo oluşturulmadı. `supabase/rollback/stage8-*.sql` davranışı geri alır; kayıtları silmez, canlıda uygulanmadı.

## B. Test sonuçları

Kanıtlar: `docs/admin/stage8-evidence/`.

- Başlangıç **158/158**, son ana uygulama **166/166**, yönetici **34/34** test geçti. Testler atlanmadı.
- Web `tsc --noEmit` geçti. Edge kodu web tsconfig'inden ayrılıp kendi Deno ortamında ayrıca kontrol edildi; tipi hatalı kodu gizlemek için bir test kapatılmadı. Başlangıçta raw HTML modülü ve Deno ortam ayrımı eksikti; düzeltildi.
- `eslint app lib --max-warnings 0`, tüm public JS syntax ve Deno 2.9.6 `check` geçti. Eski browser scriptlerinin tamamı için semantik ESLint kapsamı iddiası yok.
- Canlı DB'de önceki 10 SQL regresyon dosyası geçti. Yeni erişim/konum ve moderasyon dosyaları da geçti; SQL fixture'ları rollback edildi. Premium'a rağmen gerçek dönen koordinatın `[36.87,30.64]` olması, heading'in boş olması ve paylaşımı durdurunca noktanın kaybolması test edildi.
- **İki gerçek Auth hesabı, iki cihaz oturumu:** giriş, refresh, diğer oturumu iptal, mevcut ve ilgisiz hesabın korunması, kendi cüzdanını okuma/başkasını okuyamama, doğrudan Premium yazma reddi, global çıkış sonrası JWT tekrarının reddi geçti. Gerçek e-posta kaydı veya teslimat testi değildir. Test hesapları ve geçici parolaları temizlendi.
- Recovery/ödeme/push testleri adaptör ve taklit HTTP testleridir; gerçek sağlayıcı sonucu olarak sunulmaz.
- Bağımlılık audit: **0 düşük/orta/yüksek/kritik**. İstemci anahtar taraması sınırlı desen kontrolüdür; bütün sır formatları için matematiksel güvence değildir.
- Üretim web build geçti. iOS sync geçti; ilk Android sync `ENOTEMPTY` ile başarısız oldu, tekrar geçti ve temizleme sınırlı retry ile düzeltildi. APK/AAB/IPA veya simülatör derlemesi üretilmedi.
- Yerel görsel preview daemon'u çalışıyor bildirse de bulut tarayıcısı `ERR_CONNECTION_REFUSED` verdi; bu deneme başarılı mobil görsel test sayılmadı. Ardından yayınlanan v127 üzerinde 360/390/430 iframe genişliklerinde profil ve harita kontrol edildi: yatay taşma yok, raster karoları üçünde de yüklendi. Görsel kanıt: `stage8-viewports.jpg`. Girişli ekranların tamamının görsel testi veya fiziksel cihaz testi yok.
- İzole DB gate, izolasyon secrets eksikken beklenen biçimde reddetti. Gerçek restore yapılmadı.

Sağlık migration ilk denemede bağlayıcının requestState hatasıyla uygulanmadı; ikinci denemede başarılı oldu ve fonksiyon testi geçti.

Başarısızlıklar: ilk migration'da eksik SQL sonlandırıcısı nedeniyle transaction geri alındı; sonra dispatcher'ın invoker yetkisi hatalı kaldı ve dar authenticated grant ile hemen düzeltildi. Başlangıç cüzdan testinin kendi cüzdanını okumanın da 403 olması beklentisi yanlıştı; doğru satır izolasyonunu test edecek şekilde değiştirildi. İlk başarısız günlük saklandı. Fixture temizliğinde iki özel FK nedeniyle işlem geri alındı; yalnızca iki test hesabının activity/presence kayıtları birlikte temizlenince sonuç 2 oldu. Gerçek kullanıcıya temizlik uygulanmadı.

## C. Güvenlik ve performans

- Gerçek kullanıcı profil/araç/cüzdan/özelleştirme/görünüm kontrol toplamlarının beşi Aşama 7 ile aynı. Gerçek kredi/Premium bakiyesi test için değiştirilmedi.
- RLS/grant ve önceki engel/hayalet/Premium testleri geçti. Security Advisor'da kasıtlı kapalı tablolar için INFO ve **sızdırılmış parola koruması kapalı** WARN devam ediyor. Bağlayıcı Auth yönetim ayarı sunmuyor; ücretli plan açılmadı. [Supabase parola güvenliği](https://supabase.com/docs/guides/auth/password-security).
- Hız sınırları hesap başınadır; dağıtık çok hesaplı saldırıya tek başına yeterli değildir. Signup/CAPTCHA/IP sınırları Auth sağlayıcısı ayarı gerektirir.
- Performans ölçümü: 20 adet **taklit HTTP** hesap açılışında istek sayısı 3'ten 2'ye indi (%33 daha az istek); CPU ortalaması ölçüm dosyasında. Bu sonuç gerçek ağ açılış süresi, LCP veya telefon performansı değildir. Gerçek cihaz/ağ performans ölçümü henüz yok.
- Mevcut Keşfet cursor sayfalaması ve medya limitleri korundu. Ücretsiz planın gerçek aylık kullanım/egress kotası garanti edilmedi.
- Backup/restore prosedürü hazır, gerçek otomatik yedek yok; Storage dosyaları SQL yedeğinin parçası değildir. Ortamda pg_dump/psql/Docker yok ve izole DB bağlantısı verilmedi. Üretime restore denemesi yapılmadı.

## D. Mobil durum

Mevcut iOS/Android proje ve ikon/açılışlar korundu. Linux ortamında Java var, Android SDK/adb ve Xcode yok. Gerçek klavye, native geri tuşu, düşük bellek, OS medya seçici ve izin reddi bu aşamada doğrulanmadı. Önceki safe-area/viewport düzeltmeleri korunur. Simülatör/cihaz testinin yerine sync sonucu sunulmaz. Android debug workflow hesabı açmadan çalışabilecek biçimde hazırlanmıştır fakat GitHub beklemede olduğu için çalışmadı.

## E. Kaynak ve GitHub teslimatı

Geliştirme mevcut Sites kaynak geçmişi üzerine yapıldı; ilk kaynak commit `429db17c172b86b8281ab6d203e1ebc0ac5b8862`; sağlık ve son kanıt güncellemesinin commit'i teslim mesajında belirtilecek. Bağlı GitHub hesabının erişilebilir depo listesi boş döndü; kullanıcı da sorulduğunda **“GitHub’ı beklet”** seçti. Dolayısıyla GitHub push, PR ve Actions run bağlantısı yok. Sites kaynak senkronizasyonu GitHub teslimatı diye gösterilmez. Workflow dosyaları kaynakla teslim edilir; çalışmış CI veya aktif branch protection iddiası yok.

## F. Bekleyen dış işlemler / eksik entegrasyonlar

| İş | Durum |
|---|---|
| Gerçek doğrulama/recovery e-postası, Auth redirect allowlist ve SMTP | Dashboard/SMTP/DNS ve gerçek posta kutusu testi bekliyor; geliştirici mağaza hesabı gerekmez |
| Güvenlik/silme sistem e-postaları | Gönderim kuyruğu/sağlayıcı entegrasyonu tamamlanmadı |
| Push | APNs/FCM kimliği ve gerçek transport/kalıcı teslimat lease deposu bağlı değil |
| Mağaza ödeme doğrulaması | Apple/Google doğrulayıcıları, gerçek ürünler, refund/restore entegrasyonu bağlı değil |
| Otomatik görsel/video model denetimi | Model bağlı değil; insan kuyruğuna yönlenir; masraflı servis eklenmedi |
| Log saklama ve kritik alarm | Anonim olay retention ve yönetici sağlık kuyruğu canlı/test edildi; dış alarm teslimatı bağlı değil |
| Yedek/restore | Prosedür hazır; şifreli hedef, erişim ve izole restore testi kurulmadı |
| GitHub ve CI çalıştırması | Kullanıcının seçimiyle beklemede |
| Native derleme/gerçek cihaz performansı | SDK/Mac/cihaz ortamı bekliyor; imzalama ve mağaza gönderimi sonraya bırakıldı |
| Hukuki metin / sahiplik delil politikası | İşletmeci bilgileri ve hukuki/operasyonel karar bekliyor |

## G. Kullanıcı müdahalesi olmadan doğrulanamayanlar

Mağaza hesabı açılması şu anda talep edilmiyor. Uygun zamanda mevcut GitHub deposunun erişimi, SMTP/DNS ve Auth Dashboard yapılandırması, işletmeci/destek bilgileri, yedekleme için özel hedef ve izole test ortamı, Mac/telefon test erişimi gerekir. Gerçek ödeme/push kimlik bilgileri ve hukuki onay daha sonraki entegrasyonlardır. **Bu liste dışındaki açık teknik işler de F tablosunda açıkça yer alır; hepsi yalnızca mağaza hesabına bağlanarak gizlenmez.**
