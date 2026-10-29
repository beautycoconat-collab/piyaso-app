# Aşama 8 — Yarım kalan teslimat ve temizlik işlerinin tamamlanması

26 Ekim 2026, Türkiye saati. Başlangıç kaynak: `76b192a7f9db434fb1b05a7740cad1221f2c096c`. Bu rapor 25 Ekim raporundaki teslimat kuyruğu ve temizlik açıklarının güncel sonucudur.

**Sonuç:** yarım kalan kuyruk, güvenlik bildirimi bağlantısı, tercih ekranı, worker ve temizlik kodu tamamlandı. Gerçek e-posta/telefon teslimatı veya mağaza yayını tamamlanmış sayılmıyor. GitHub kullanıcı seçimiyle beklemede; mağazalara gönderim yok.

## Uygulananlar

- Mevcut `kiyi_notifications` olaylarından, aynı transaction içinde özel ve kalıcı dış teslimat kuyruğu. Yeni dış kanal tercihleri varsayılan kapalı; tarihsel gönderim/backfill yapılmaz.
- E-posta ve telefon kanalları için bağımsız açma/kapatma, 11 olay türü tercihi ve mevcut Gelen Kutusu ayarlarından ayrı ekran. Telefon OS izni bu ekrandan istenmez. Tercih açmak gerçek teslimat olduğunu söylemez.
- Service-role yetkili `kiyi_delivery_worker`: 20 işlik batch, iki dakikalık benzersiz lease, SKIP LOCKED, yeniden deneme gecikmesi, beş deneme sınırı, eski lease ile ACK reddi.
- Her gönderimden hemen önce hesap, engel, içerik görünürlüğü ve tercih tekrar kontrol edilir. Claim'den sonra süresi dolan iş de reddedilir.
- Provider HTTP kabulü `accepted` olarak kaydedilir; posta kutusuna/cihaza teslim edildiği iddia edilmez. Ağ zaman aşımında aynı Idempotency-Key kullanılır. Gerçek exactly-once için sağlayıcının anahtarı kalıcı tekilleştirmesi gerekir; queue lease tek başına ağ garantisi değildir.
- Yeni `kiyi-delivery` Edge worker: gateway JWT kontrolü ve service-role anahtarı eşleşmesi; sadece HTTPS/443, açık hostname listesi, redirectsiz istek ve 15 saniye zaman aşımı. Normal hesap RPC/HTTP worker'ına erişemez. Sağlayıcı ayarı yoksa iş sahiplenmeden bekler. Aktif gönderim takvimi oluşturulmadı; global e-posta/push bayrakları kapalı bırakıldı.
- Profil doğrulama sonucu Gelen Kutusu'na ve izin varsa dış kuyruğa bağlandı; değişmeyen durum tekrar bildirilmez. Diğer oturumların kapatıldığını sunucuda doğrulayan güvenlik bildirimi ve oturum bazlı tekilleştirme eklendi.
- Tamamlanan hesap silmesinde dış tercihler temizlenir, diğer bekleyen işler iptal edilir; önceden açıkça izin verilmiş tek tamamlanma e-postası kısa ömürlü kuyrukta kalabilir. Silinmiş kullanıcıya yeni bir uygulama içi kutu oluşturulmaz.
- Push cihazı canlı Auth oturumuna bağlı olmalıdır. Eski `session_id` boş kayıtlar gönderime uygun değildir. Oturum sona erdiğinde uygunluk kalkar. Yerel cihaz kayıt/izin SDK entegrasyonu ve APNs/FCM erişimi hâlâ dış entegrasyondur; normal istemciye güvenli olmayan bir kayıt endpoint'i açılmadı.
- İşler 24 saatte sona erer; sona ermiş ek teslimat metaverisi 30 gün sonra mevcut sağlık cron'u üzerinden temizlenir. Gelen Kutusu, profil/araç ve finansal defter bu temizlikte silinmez. Yeni pending işlerde alıcı başına 200/global 5000 kapasite sınırı; doluluk özel yönetici olay kaydına düşer, in-app bildirim korunur.

## Migration ve dosyalar

Canlı migration geçmişiyle eşleşen dosyalar:

- `20261025202420_stage8_delivery_outbox.sql`
- `20261025203013_stage8_security_delivery.sql`
- `20261026102823_stage8_delivery_erasure.sql`
- `20261026103425_stage8_delivery_expiry_fence.sql`

İki yeni RLS'li private tablo: `delivery_preferences`, `delivery_outbox`. `kiyi_devices` tablosuna oturum ilişkisi eklendi. Mevcut notification/verification/case olayları kullanılır. Politikalara gelişigüzel erişim eklenmedi. Yeni kova veya ekonomi tablosu yok.

Kod: `supabase/functions/kiyi-delivery/*`, `public/delivery-preferences.js`, mevcut `inbox.js`, `social-safety.js`, `supabase-account.js`, HTML cache sürümleri; rollback, CI/izole DB test listesi, e-posta activity şablonu ve operasyon belgesi. Tam liste `stage8-completion-files.txt` içindedir.

Rollback: `supabase/rollback/stage8-delivery.sql`. Eski dispatcher ve sağlık davranışını geri getirir, trigger'ları/gönderimi kapatır ve kayıtları private olarak korur. Frontend sürümüyle koordine edilmelidir. Süresi dolup temizlenmiş metaveriyi geri getirmez. Canlı rollback uygulanmadı.

## Doğrulama

- **174/174 ana uygulama testi** geçti, 0 atlandı. 166 test korundu; dış runner, erişim, hata/ACK, URL/idempotency ve tercih ekranı için 8 test eklendi.
- **16 canlı SQL regresyon dosyası** geçti; gerçek PostgreSQL üzerinde fixture'lar rollback edildi. Garaj/kredi/hediye, sosyal/engel/gizlilik, bildirimler, konum ve yeni kuyruk/hesap silme/expiry testleri dahildir.
- Web TypeScript, ESLint app/lib, tüm public JS syntax, Deno Edge type check, web üretim derlemesi ve istemci secret deseni kontrolü geçti. Bağımlılık audit'te bildirilen açık sayısı 0.
- Mevcut kullanıcı profil/araç/cüzdan/özelleştirme/görünüm kontrol toplamları başlangıçla aynı; gerçek kullanıcıya test bildirimi gönderilmedi ve gerçek bakiye değiştirilmedi.
- iOS ve Android Capacitor sync yeniden geçti. Bu sonuç APK/AAB/IPA, simülatör veya fiziksel cihaz derlemesi değildir; ortamda Xcode, adb/Android SDK, Docker, psql/pg_dump yok.
- Bugünkü runner/provider ve UI testleri taklit HTTP/VM testleridir; gerçek SMTP/FCM/APNs teslimatı değildir. Bugün iki yeni geçici gerçek Auth hesabıyla giriş/refresh, diğer cihazdan çıkış, global çıkış, JWT tekrarının reddi, cüzdan/Premium izolasyonu ve güvenlik bildiriminin koşulu/tekilliği yeniden doğrulandı. Bu rapor gerçek cihaz veya posta kutusu testi iddia etmez. İki test hesabı ve geçici parolaları temizlendi.

Başarısız denemeler gizlenmedi: bakımda çalışma dizini kaybolduğu için kaynak tekrar alındı; kaybolan kaydedilmemiş dosyalar tamamlandı. MCP requestState hatası olan SQL denemesi sonuç sayılmadı; tekrar test geçti. İlk kuyruk testindeki eski `blocker/blocked` sütun beklentisi gerçek `owner/target` şemasına düzeltildi. Paralel derleme sırasında özeti tamamlanmayan Node günlüğü başarı sayılmadı; ayrı tam koşuda 174/174 sonuç alındı. Son expiry sınırı ayrıca test edildi.

## Dış erişim bekleyenler

- Gerçek SMTP/alan adı/DNS ve Auth redirect izinleri; doğrulama/recovery e-postasının gerçek posta kutusunda teslim ve dönüş testi.
- Güvenilir, idempotent e-posta/push sağlayıcı bağlantısı ve sunucu secret'ları; hiçbir ücretli servis açılmadı. APNs/FCM/native izin ve cihaz kayıt testi.
- Şifreli yedek hedefi ve izole restore ortamı. Yedekleme prosedürü hazır; gerçek otomatik yedek/restore testi kurulmuş sayılmaz.
- Xcode/Mac, Android SDK ve fiziksel cihaz testleri; gerçek mağaza ödeme doğrulaması/restore ve imzalama.
- İşletmeci/destek bilgileri ve hukuki onay. Otomatik görsel/video model denetimi bağlı değil; insan incelemesi kuyruğu kullanılır.
- Sızdırılmış parola koruması Supabase danışmanında hâlâ kapalı uyarısı veriyor; bu bağlayıcı Auth yönetim ayarını değiştiremiyor. Mevcut plan/yetkiler Dashboard'dan doğrulanmalı, ücretli plan açılmadı.
- GitHub/PR/Actions kullanıcının bekletme seçimiyle çalıştırılmadı. Sites kaynağına kayıt GitHub teslimatı olarak sunulmaz.

Gönderim sözleşmesi ve gerekli server secret adları: `docs/operations/delivery.md`. Mevcut erişimlerle tamamlanan kod/test işi ile dış sağlayıcı ve cihaz doğrulaması bu raporda ayrı tutulur; genel mağaza durumu **yayına hazır değil**.
