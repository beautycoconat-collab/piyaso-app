# Kıyı Yönetim 2.0

Ayrı origin üzerinde Türkçe, mor marka kimliğine sahip operasyon paneli. Bu sürüm yalnız M1 giriş ekranından ibaret değildir. Gerçek Supabase RPC’leriyle kullanıcı, moderasyon, katalog, ekonomi, bölge ve veri taleplerini yönetir. İlk araştırma: `docs/arastirma-ve-mimari.md`; kapsam ve sınırlar: `docs/teslim-durumu.md`.

## Uygulanan modüller

Genel bakış; kullanıcı arama/filtre/detay/yaptırım; plaka ve fotoğraf moderasyonu; plaka değişikliği ve sahiplik başvuruları; Antalya bölgeleri; Premium destek hakları ve hayalet durumları; fenomen/rozet/sıralama; hediye ve özelleştirme kataloğu; kredi paket sunumu ve bonus kampanyaları; gönderimler ve mali defter; satın alma kayıtları; iade incelemesi; çift yetkilili kredi düzeltme; şikâyetler; içerik moderasyonu; itirazlar; duyurular; uygulama ayarları; destek; veri/silme talepleri ve medya temizleme; teknik durum; gerçek aktiflik istatistikleri; şarkı bağlantı geçmişi; denetim kayıtları; yetkililer.

Ana uygulama katalogları, kapatma anahtarlarını ve duyuruları sunucudan alır. Hesabı askıdaki kullanıcı destek ve itiraz yolunu kullanabilir. İzmir bölgesi oluşturulmadı; mevcut Antalya geometrileri korundu.

## Güvenlik

Supabase Auth + zorunlu TOTP/AAL2. Şifreli HttpOnly/Secure/SameSite=Strict cookie; tarayıcı JS’sine admin access/refresh token dönmez. Sunucuda publishable key + çağıranın JWT’si kullanılır; service role kullanılmaz. Her çağrıda gerçek üyelik, Auth oturumu, lease ve rol kontrol edilir. Oturum: 15 dakika boşta/8 saat mutlak. Kritik işlemler yeni MFA gerektirir.

Özel tablolarda RLS açık ve doğrudan erişim kapalı. RPC dispatcher’ları boş search_path, kimlik/yetki kontrolleri, gerekçe, idempotency ve audit kullanır. Kredi düzeltmesi talep eden kişiden farklı onaylayan gerektirir; kimse kendi cüzdanına düzeltme yapamaz. Normal harcama ve teslim aynı transaction içindedir. Mevcut çalışan finans tabloları yeniden oluşturulmadı.

Admin kesin GPS görmez. Kullanıcılar arası harita noktaları yaklaşık; bölgesel sayı gösterilir. Eski GPS otomatik temizlenir. Medya URL ömrü 60 saniyedir. Silme işinde dosyalar gerçekten kaldırılmadan tamamlandı denmez. Ortak Supabase Auth ve başka uygulamanın `lab` verileri korunur.

## Veritabanı snapshot’ları

`supabase/admin-foundation.sql`, `admin-operations.sql`, `domain-operations.sql`, `operations-schedule.sql`, `operations-hardening.sql` canlıya uygulanmış nesnelerin kaynak snapshot’larıdır. Mevcut projede baştan tekrar çalıştırmayın; migration geçmişiyle uzlaştırın. `scripts/generate-domain.mjs` mevcut uygulamanın alınmış fonksiyon snapshot’larından denetlenen değişiklikleri üretir. Son hardening dosyası önceki tanımları güvenlik/itiraz için günceller.

## İlk sahip hesabı

Henüz yönetici üyeliği yok. Kıyı’da oluşturulmuş, e-postası doğrulanmış ve sahibi tarafından açıkça seçilmiş hesap gerekir. Yalnız DB sahibi `kiyi_private.bootstrap_admin(uuid,reason)` üzerinden ilk Super Admin’i oluşturabilir. Anon/authenticated/service_role bu fonksiyonu çalıştıramaz. Varsayılan şifre, tahmini e-posta veya otomatik sahip atama yoktur. Şifre ve TOTP kodu sohbetten alınmaz.

## Doğrulama ve çalıştırma

Node 22+: `npm ci`, `npm test`, `npm run build`, `npm run validate`. PGlite yalnız test bağımlılığıdır; çalışma zamanında npm paketi yoktur. `src/` arayüzü ve `worker/server.template.mjs`, `scripts/generate-worker.mjs` ile tek Worker ESM’ye gömülür.

25 admin test grubu: izole gerçek PostgreSQL, yetki/MFA/lease, katalog/debit/idempotency, çift yetkili kredi, moderasyon/itiraz, duyuru izinleri, konum gizliliği, silme ve HTTP güvenliği. Mekânsal testte PostGIS topolojisi taklit edilir; gerçek sınır geometrisi testi değildir. Ana uygulamanın mevcut 73 testi ve 3 yeni yapılandırma testi vardır. İç ekranlar ayrı sentetik QA ortamında kontrol edildi; örnek kullanıcı/işlem üretime eklenmedi. İlk gerçek yöneticiyle üretim giriş/TOTP uçtan uca testi henüz yapılamadı.

## Dış bağlantı sınırları

- Apple/Google ödeme ürünleri, makbuz doğrulama, abonelik webhooks ve gerçek iade/ters ibraz henüz bağlı değil. Panel başarılı tahsilat uydurmaz; TL mağaza fiyatını değiştirmez.
- APNs/FCM, SMTP ve SMS bağlı değil. Duyurular uygulama içidir.
- Spotify canlı erişimi bu çalışmada doğrulanmadı; şarkı fiyatı/bağlantı geçmişi yönetilir, lisanslı oynatma sunulmaz.
- Supabase CPU/Storage/fatura/yedek/PITR altyapı panelinde; geri yükleme tatbikatı yapılmadı. Hata tablosu veri toplama hattı tam bir APM sistemi değildir.
- Dağıtık WAF/rate-limit ve saldırı telemetrisi henüz yok; Worker isolate ön limiti ve Supabase Auth limiti var.
- 250 bin kullanıcı yük testi yapılmadı. Listeler 50’lik, offset en fazla 10 bindir; daha büyük derin tarama için cursor dönüşümü gerekir. Arama bağımsızdır.
- KVKK metinleri, saklama gerekçeleri, yurt dışı aktarım ve mağaza yayını hukuki/işletmesel son inceleme gerektirir.
