# Kıyı — son proje kaynakları

Bu ZIP, kaynak kodları, yerel görselleri, mobil proje dosyalarını, veritabanı şemalarını ve çalıştırma dosyalarını içerir. Git geçmişi, node_modules, erişim anahtarları ve canlı kullanıcı veritabanı içermez.

## Son düzenlemeler
- Gelen kutusunda hediye görselleri satır içinde 27×30 piksele sınırlandı; sprite görselleri dahil.
- Plaka Ara üzerinden açılan tam sayfa favoriler ve hediye kutusunda tekrar eden başlık/sekme kaldırıldı. Kapatma ve gelen/gönderilen kontrolleri korundu.
- Profil kredi cüzdanı sağ üstteki ikonların altına taşındı.
- Kullanıcı adları @ biçiminde; profil ziyaretleri hesap kimliğiyle sunucuya kaydedilir.

## Kurulum
Node.js 22.13+ ve pnpm gerektirir. Proje klasöründe:

    pnpm install --frozen-lockfile
    pnpm build

Yerel geliştirme, veritabanı şemaları ve Cloudflare bağlamaları için README.md dosyasının Çalıştırma bölümünü okuyun. D1, R2 ve kimlik doğrulama ortamı kurulmadan sunucu özellikleri çalışmaz. Yerel ZIP'i açmak tek başına canlı hesap/veri aktarımı yapmaz.

## Mevcut sınırlar
- Hediye/kredi ekonomisi ve demo hediye bildirimleri halen cihazdaki kayıtlardır; gerçek kişiler arası hediye aktarımı bağlı değildir.
- Üç örnek hediye bildirimi tasarım önizlemesidir; kaldırılabilir.
- Profil ziyaret listesi yalnızca giriş yapan gerçek hesapların açtığı sunucu profilleri için kayıt üretir. İki gerçek hesap arasında canlı test henüz yapılmadı.
- Müzik kataloğu kurulmadı. README'deki Spotify/Apple bölümü önceki entegrasyon kodunu anlatır; canlı sağlayıcı erişimi veya yayın izni sağlandığı anlamına gelmez. Ayrı hazırlanan MusicBrainz kurulum paketi isteğe bağlıdır ve henüz bu projeye uygulanmadı.
- Buluşmalar şu anda Yakında durumundadır.
- ZIP App Store'a gönderilebilen imzalı IPA değildir. Apple imzalama/yayın işlemleri ayrıca gerekir.
