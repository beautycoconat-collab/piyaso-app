## Spotify bağlantısı — yeni

Durum oluşturma ve Şarkı hediye et aynı katalog seçicisini kullanır. Spotify sunucu bağlantısı hazırlanmıştır. Etkinleşmesi için Sites üretim ortamına `SPOTIFY_CLIENT_ID` ve gizli `SPOTIFY_CLIENT_SECRET` tanımlanmalıdır. Bunlar yalnızca sunucuda kullanılır; tarayıcıya veya ZIP'e gömülmez.

Anahtarlar olmadan Spotify sekmesi açıkça bağlantının etkin olmadığını söyler. Apple/iTunes ayrı bir seçenek olarak çalışmaya devam eder. Canlı Spotify erişimi bu teslimatta geliştirici bilgileri olmadığı için doğrulanamadı. Token alma, token tekrar kullanımı, arama, erişim reddi ve kota hataları taklit HTTP yanıtlarıyla test edildi; bunlar canlı servis testi değildir.

Spotify araması 10 sonuç ve TR pazarı kullanır. Başlangıç listesi arama tabanlı keşiftir; resmi Spotify Türkiye popülerlik listesi olduğu iddia edilmez. Tam müzik oynatımı yoktur. Seçilen kartta Spotify kaynağı ve gerçek parça bağlantısı bulunur. Hediye ekonomisinin mevcut 60 kredi işleyişi korunur.

Güncel test: `node --test tests/*.cjs tests/status-api.test.mjs tests/spotify-api.test.mjs` — 65 test.

# Kıyı — profil ve kalıcı durum paylaşımı (22 Ekim 2026)

Bu sürüm, önceki mor-beyaz arayüzü ve cihazdaki kredi/özelleştirme kayıtlarını korur. Yeni durumlar sunucuda kullanıcı kimliğiyle saklanır; fotoğraflar ve ses kayıtları R2, kayıtlar D1 kullanır.

## Çalıştırma

Node 22.13+ ve pnpm gerekir. `pnpm install --frozen-lockfile`, ardından `pnpm build`.
İlk yerel çalıştırmada aşağıdaki komutla şemayı uygula:

```sh
node --import ./scripts/sites-env.mjs ./node_modules/wrangler/bin/wrangler.js d1 execute DB --local --config dist/server/wrangler.json --persist-to .wrangler/state --file drizzle/0000_curly_harry_osborn.sql
pnpm dev
```

Üretim için Cloudflare Worker uyumlu sunucu ve `.openai/hosting.json` içindeki `DB` / `BUCKET` bağlantıları gerekir. Sites bunları yayında sağlar. Bu sürüm statik dosyaları yalnızca Netlify'a sürükleyerek sunucu özellikleriyle çalıştırılamaz.

## Kimlik ve erişim

Sites'ın doğruladığı `oai-authenticated-user-id` yeni kayıtların sahibidir. Giriş yapılmadan paylaşım, yorum, beğeni veya oy gönderilemez. Başka barındırma sisteminde bu başlık internetten doğrudan kabul edilmemeli; doğrulanmış kimliği sunucu katmanı sağlamalıdır. Takipçiye özel kayıtlar, bağlı dosyalar ve silme yetkisi API'de kontrol edilir. Sunucu takip ilişkileri gerçek kullanıcılar için geçerlidir; önceki örnek profiller demo olarak kalır.

Önceki cihaz paylaşımları silinmez; profilde ayrı bir eski kayıt alanında görünür. Eski kredi ekonomisi, hediye ve harita sistemi bu sürümde hâlâ önceki demo sınırlarına sahiptir. Yeni durum sistemi kalıcı sunucu verisi kullanır.

## Özellikler ve sınırlar

- Kartsız plaka / araç alanı; yalnızca kendi profilinde düzenleme kalemleri.
- Tam ekran oluşturucu, 1000 karakter, emoji, hashtag, fotoğraf/kamera paneli, tek şarkı, 2–4 seçenekli anket.
- JPG/PNG/WebP, en fazla 5 MB; MIME ve dosya imzası sunucuda doğrulanır.
- Tarayıcı desteklerse 60 saniyeye kadar ses kaydı (WebM / MP4); izin hataları Türkçe gösterilir.
- Beğeniler, yorumlar, sahip tarafından silme ve kullanıcı başına tek anket oyu.
- Apple/iTunes katalog araması ve popüler liste; tam müzik oynatma yok. Katalog bağlantısı kurulamazsa gerçek hata gösterilir; sahte arama sonucu üretilmez.
- Mobil düzen VisualViewport ve güvenli ekran alanlarını kullanır. Fiziksel iPhone Safari klavye, kamera ve mikrofon kontrolleri bu ortamda doğrulanamadı.
- Native mobil klasörü korunmuştur. Kalıcı sunucu işlemleri barındırılan uygulamada ve ChatGPT girişinde çalışır; App Store kimlik entegrasyonu ve yayın hazırlığı ayrıca gereklidir.

## Doğrulama

`node --test tests/*.cjs tests/status-api.test.mjs`

61 kontrol geçer: önceki coğrafya/harita/kredi testleri ve yeni API yetkilendirme, dosya erişimi, tek oy, yorum/beğeni, silme ve çapraz kaynak denetimleri. Tarayıcıda oluşturucu, metin sayacı, hashtag rengi, anket ve alt paneller kontrol edildi.

---

Aşağıdaki notlar önceki sürümlerin geçmiş açıklamalarıdır; bu sürümdeki güncel kurulum ve sınırlar yukarıdadır.

# Kıyı — Antalya otomobil topluluğu

Türkçe, mobil öncelikli etkileşimli web prototipi. Saf HTML/CSS/JavaScript; harita Leaflet, QR qrcode-generator. Derleme gerektirmez. `dist/` herhangi bir statik HTTPS sunucuda çalışır. İleride mobil kabukla kullanılabilir; mevcut veri adaptörü localStorage'dır.

## Açma

`python3 -m http.server 8080 --directory dist` ardından http://localhost:8080

Test: `node --test tests/core.test.cjs`

## Çalışan demo

Plaka arama: `07 dem001` → `07 DEM 001`. Aramaya kapalı ve engelli profiller filtrelenir. Demo kayıt/düzenleme, fotoğraf, Instagram/TikTok kullanıcı adları, takip/takipten çıkma, takipçi listesi, takipçi konum onayı, engelleme ve yerel şikâyet kayıtları tarayıcıda saklanır. Sosyal kullanıcı adları kurgusaldır. Demo kayıtta sadece `07 DEM 004` gibi kurgusal plakalar kabul edilir.

Premium 49,90 TL/ay olarak sunulur; satın alma yoktur. Demo Premium düğmesi yalnızca prototip erişimini açar, konumu başlatmaz. Tura başla, görünürlük, süre, Hayalet mod, tur bitirme, alan dışı ve 2 dakikadan eski konumu gizleme çalışır. Sayfa kapanınca konum izleme durur; tur yeniden yüklemede devam etmez. Demo araçlar 2 dakika sonra eskir. Harita kontrolü ve arama ayrı özelliklerdir. Gerçek konum tercihi yalnızca bu cihazda işlenir ve hiçbir sunucuya yayımlanmaz. Harita döşemeleri OpenStreetMap'ten gelir; internet gerekir.

Bölgeler `dist/core.js` içindeki `zones` koordinat dizileridir. Taslak sınırlar saha doğrulaması gerektirir. Yaklaşık konum 0,002 derecelik ızgaraya yuvarlanır. Bu bir konum gizlilik garantisi değildir; gerçek sisteme geçmeden server-side bölge/izin/yuvarlama politikası kurulmalıdır.

Davet bağlantısı mevcut origin'i kullanır; yerleşik paylaşım desteklenmiyorsa kopyalama vardır. QR gerçek bağlantıyı kodlayan indirilebilir SVG'dir. Şimdiki yayın özel erişimlidir. Herkese açık kalıcı reklam adresi seçilmeden QR basılmamalıdır. Davet ödülü yoktur.

## Bağlanmayan gerçek servisler

Kimlik/telefon OTP, plaka sahipliği doğrulaması, veritabanı, moderasyon, ödeme ve canlı konum servisi yok. Demo premium ve localStorage güvenlik sınırı değildir.

Gerçek sürümde kimlik doğrulaması, profil arama izni, iki yönlü engel, onaylı takipçi ve Premium yetkisi her sunucu isteğinde denetlenmeli. Plaka sahipliği belgeleri özel depoda, kısa ömürlü erişimle tutulmalı; açık profillere belge URL'si eklenmemeli. Ham konum istemcilere dağıtılmamalı; sunucu yalnızca bölge içi, zaman aşımına uğramamış ve izin verilen yaklaşık veriyi döndürmeli. Tur bitişi ve Hayalet mod sunucu oturumunu da iptal etmeli; konumlar kısa TTL ile silinmeli.

İlk 100 kampanyası için telefon sağlayıcısından doğrulanmış ve tekilleştirilmiş telefon kimliği kullanılmalı. Kayıt tamamlanması tek transaction içinde idempotency anahtarıyla işlenmeli; kampanya satırı kilitlenip sayaç <100 ise artırılmalı ve kullanıcıya unique hediye hakkı yazılmalı. Başlangıç her kullanıcının kayıt tamamlanma anı, bitiş bir takvim ayı sonrası olmalı. Tekrarlanan kayıt/OTP çağrısı hediye yenilememeli. Paralel 101 kayıt, tekrar çağrı ve ay sonu tarihi entegrasyon testleri olmadan kampanya aktive edilmemeli. Kart/otomatik ücret alınmaz; bitiş sadece Premium yetkisini kaldırır.

## Doğrulama

5 Node testi: plaka normalizasyonu, arama gizliliği/engel, iki bölge ve alan dışı, Premium/onay/eski konum, yaklaşık konum. Tarayıcıda arama, profil kaydı, yeniden yükleme, takip, Premium denemesi, tur başlatma/bitirme, Hayalet mod, alan dışı/eski konum, zoom ve işaret özeti kontrol edildi. Gerçek GPS izni, telefon, ödeme ve çok kullanıcılı sunucu akışları bu prototipte test edilmiş değildir.

## Harita tasarımı v0.2

Harita tam ekran, mobilde alt gezinmenin üstünde çalışır. Konyaaltı/Lara bölge düğmeleri, Hayalet mod anahtarı, yakınlaştırma ve Antalya'ya dön düğmeleri bulunur. Araç seçimi alt profil panelini açar. `dist/map-v2.js` harita sunumunu ve demo rotalarını içerir; tur yaşam döngüsü `app.js` içindedir. Demo araçlar gerçek zamanlı sunucu verisi değil, açıkça etiketlenmiş rotalarda interpolasyonla hareket eder. Simülasyon kişisel konum içermez. Konum ve Premium sunucu entegrasyonları hâlâ bağlı değildir. Haritada demo önizleme ücretsiz görülebilir; tur başlatma Demo Premium gerektirir. Taslak bölge sınırları daraltılmıştır; gerçek saha doğrulaması gereklidir.

### v0.3 Görsel referans uyumu

Harita stili MapLibre/OpenFreeMap üzerinden sadeleştirilmiştir: açık yollar, daha az etiket, turkuaz su. WebGL olmayan cihazlarda Esri Light Gray tabanını kullanan canvas yedek harita bulunur; su rengi istemcide eşlenir. Katkı sağlayıcı atıfları korunur. Navigasyon SVG çizgi ikonlarına çevrildi. Küçük gerçekçi üstten araç işareti ve Zeytin profil kesiti üretildi; bunlar yapay görsel/demo varlıklarıdır. `assets/map-car.png` ve `assets/zeytin-car.png` proje içinde saklanır. Demo rotaları gerçek yol eşleştirme servisine bağlı değildir; yol merkezine birebir oturma garantisi yoktur. 390×844 iframe ile telefon yerleşimi, işaret seçimi ve profil paneli kontrol edildi. Test tarayıcısı WebGL desteklemediğinden vektör render motoru o ortamda görsel olarak doğrulanamadı; yedek harita doğrulandı.


### v0.4 Gerçek yol geometrisi

Elle çizilen düz demo rotaları kaldırıldı. Konyaaltı için Akdeniz Bulvarı, Lara için Eski Lara Yolu/Lara Caddesi yol geometrileri OpenStreetMap tabanlı OSRM Route servisinden alındı. Ham GeoJSON yanıtları `data/` içinde, üretim betiği `scripts/build-road-data.py` içinde saklanır. `python scripts/build-road-data.py` paketlenmiş `dist/road-data.js` verisini yeniden üretir. Lisans: ODbL 1.0, © OpenStreetMap katkıda bulunanlar. Kaynak: https://router.project-osrm.org/ ve https://www.openstreetmap.org/copyright, alım tarihi 2026-10-21.

Yeşil alanlar gerçek yolun her düğümünü izleyen 55 m yarıçaplı taslak koridorlardır; onaylı hizmet alanı veya yasal sürüş izni anlamına gelmez. Servisten alınan gidiş/dönüş yol döngüleri kullanılır. Araçlar 7 m/s demo hızında kümülatif mesafe üzerinden ilerler; her yol kıvrımı korunur, uç noktalar arasında kestirme yapılmaz. Bölge dışına çıkan işaretler gizlenir. Hesaplanan araç yönü 360 derece geçişlerinde tam tur dönmez. Konumlar gerçek kullanıcı konumu değildir. Bu sabit demo veri seti navigasyon, trafik veya yol açıklığı garantisi sunmaz. Çalışma anında yönlendirme servisine istek atılmaz; gerçek GPS ve sunucu entegrasyonları henüz yoktur.

`node --test tests/*.test.cjs`: 11 test başarılı. Kaynak GeoJSON eşitliği, döngü sürekliliği, yol kıvrımı, sabit mesafe ilerlemesi, koridor kapsamı, eski yanlış çizginin dışlanması ve yön geçişi eklendi. Konyaaltı/Lara araçları 390×844 mobil önizlemede yol üzerinde ve profil kartlarıyla kontrol edildi.


### v0.5 Kültür ve genişleyen Konyaaltı alanı

Kültür için 3805. Sokak/Kafeler Caddesi esas alınmıştır. Kaynak OSM way 127312949, Nominatim geometrisi `data/kultur-nominatim.json`; OSRM dönüş döngüsü `data/kultur-loop-osrm.json`. Bu, kullanıcının kafe yoğun bölge tarifi için seçilmiş taslak eşleştirmedir; canlı trafik/popülerlik ölçümü değildir. Kafeler Caddesi çevresi 180 m, dönüş bağlantıları 65 m tamponla birleştirilir. Yeni Kültür düğmesi ve kurgusal Kültür molası profili eklendi.

Konyaaltı sahil geometrisi batıya, Liman yönünde 30.605210 / 36.846621 noktasına uzatılmıştır. Kullanıcının tarif ettiği otopark/dönemeç henüz kesin teşhis edilmedi; haritada uç sınır açıkça taslak etiketlidir. “Otoparka kadar tamamlandı” iddiası yoktur. Kara tarafında 300 m, deniz tarafında 35 m asimetrik tamponla birkaç arka sokak sırası kapsanır. Bölge bir hizmet alanıdır; tamamı sürülebilir yol sayılmaz. Demo araçlar gerçek OSRM sürüş geometrilerinde kalır.

Alan üretimi shapely ile geçerli çokgen birleşimi yapar (`pip install shapely`; `python scripts/build-road-data.py`). Eski v0.4 ham kaynakları korunmuştur. Bölgelerin tamamını göster düğmesi ve Kültür merkezleme ayarı eklendi. 390×844 görünümde Kültür düğmesi, demo profil kartı, Konyaaltı ve alanı göster kontrolleri doğrulandı. 12 test başarılı; Liman uzatması, kara tarafındaki yeni kapsam, Kültür ve açık denizin dışlanması da test edilir.


### v0.6 Yalnızca yol güzergâhları

v0.5 geniş mahalle dolguları kaldırıldı. Harita artık `RoadData.displayRoutes` içindeki gerçek OSRM yol döngülerini 3,5 piksel çizgiyle gösterir. Konyaaltı, Lara ve Kültür ayrı yol katmanlarıdır. Bina/ev bloklarını boyayan `L.polygon` çağrısı harita görünümünden kaldırıldı. Arka bağlantılar geniş bir mahalle alanıyla değil, kaynakta bulunan gerçek dönüş yollarıyla temsil edilir.

Görünürlük denetiminde de geniş alanlar kaldırıldı; yalnızca yol eksenine 15 m teknik tolerans korunur. Shapely koridorlarındaki iç boşluklar veriye aktarılır ve `Core.insideZone` tarafından dışlanır; kapalı yol döngüsünün ortasındaki konut adaları kapsama alınmaz. Görünür harita bu toleransı alan dolgusu olarak çizmez. 14 test başarılı: ev adası dışlama, kaynak geometri ve görünümde polygon bulunmaması dahil. Konyaaltı ve Kültür 390×844 mobil görünümde görsel olarak kontrol edildi. Liman'daki tarif edilen özel otopark hâlâ teyit edilmedi.


### v0.7 Sarı işaretli Konyaaltı bölümündeki yol ağı

Kullanıcının sarı çizimi yaklaşık olarak Atatürk Bulvarı, kıyı ve Dumlupınar'ın sahil bağlantısına hizalanarak `data/konyaalti-street-network.json` içinde seçim sınırı olarak tutuldu. Sınır bir alan dolgusu olarak ekrana çizilmez. OpenStreetMap API 0.6 map verisinden 512 araç yolu parçası kırpıldı. Özel/no-access etiketli 13 yol dışlandı; yaya yolu, merdiven, bisiklet yolu ve patika türleri seçilmez. Bu filtre harita etiketlerine dayanır, sahadaki güncel erişim durumunu garanti etmez. Tekil şerit geometrisi olmayan yerlerde yolların merkez çizgileri kullanılır; fiziksel şerit sayısı uydurulmaz.

Ana kıyı yolu mevcut koyu yeşil #327c59 / 3.5px / 0.9 opaklıkta korunur. Ara sokaklar #6baa83 / 2px / 0.45 opaklıkta ayrı bir Canvas katmanında gösterilir. Ev ve parseller doldurulmaz. RoadData.secondaryRoads, OSM way kimliği, adı, türü ve kırpılmış geometriyi taşır. Seçim sınırı kolayca düzenlenebilir. `scripts/extract-konyaalti-network.py` ham OSM XML girdilerinden bu kompakt kaynak dosyasını üretir; yol ağı kaynak dosyası proje içinde korunur. `scripts/build-road-data.py` bunu uygulama verisine ve delikleri korunan dar yol görünürlük koridorlarına dönüştürür.

Gün batımı demo aracı, 500. Sokak / Belediye Caddesi / Atatürk Bulvarı / 6. Cadde bağlantılarında OSRM'den alınmış gerçek yol döngüsünü izler. Bu bir demo simülasyonudur; gerçek kullanıcı geçmişi veya canlı konumu yayınlanmaz. Konyaaltı ana/ara yol renkleri, ara sokaktaki araç profil kartı ve Kültür geçişi 390×844 görünümde kontrol edildi. 16 test başarılı. Sarı çizimin coğrafi hizası yaklaşık olduğundan seçim sınırı hâlâ taslaktır; Liman'daki özel otopark noktası kesinleşmiş değildir.


### v0.8 Cadde seçimi ve hafif bölge dolgusu

Kullanıcının son isteğiyle Konyaaltı ikincil çizgileri yalnızca adı Cadde/Caddesi veya Bulvar/Bulvarı içeren OSM yollarına indirildi: 109 yol parçası, bunların 40'ı Atatürk Bulvarı parçaları. Küçük sokak, isimsiz bağlantı ve servis yollarının soluk çizgileri kaldırıldı. Ana kıyı hattının koyu yeşil stili korunur.

Kullanıcının çizdiği seçim alanı bu kez açıkça istenen görsel bölge işareti olarak %10 opak yeşille doldurulur. Dolgu bağımsız `coverage` panelinde z-index 350'dedir; yollar ve araçlar üstünde kalır. Bu dolgu yol izni veya konutlarda konum paylaşımı anlamına gelmez; mevcut dar yol denetimi korunur. Şekil sarı çizimden yaklaşık hizalanmıştır. 390×844 görünümde cadde/kıyı ayrımı ve dolgu okunabilirliği kontrol edildi. 16 test başarılı; cadde filtresi, Atatürk kapsamı ve dolgunun ayrı altta çizilmesi doğrulanır.


### v0.9 Üç sayfa ve araç sahibi paneli

Ana gezinme Keşfet / Plaka Ara / Profil olarak üç sayfaya indirildi; takip listeleri Profil içinden erişilir. Varsayılan ekran haritadır. Pastel park, yol ve deniz renkleri vektör stilinde düzenlendi. WebGL bulunmayan cihazlarda Esri World Topo haritası kullanılır; sağlayıcıya göre görünüm farklılaşabilir. Gerçek yol çizgileri ve önceki Konyaaltı seçim dolgusu korunur.

Araç işaretine dokununca büyük alt panel açılır: araç görseli, kurgusal sahibin adı, araç bilgileri, sosyal bağlantı, takip ve tam profil düğmesi. İnsan fotoğrafları veya referanstaki etkinlik işaretleri kopyalanmadı. Konumlar demo simülasyonudur. Mobil 390×844 önizlemede harita, üçlü menü, araç paneli, takip durumunun değişmesi ve boşluk/küçük harf içeren plaka araması doğrulandı. JavaScript sözdizimi kontrolleri ve mevcut 16 test başarılı.


### v0.10 Sade harita ve Google Maps bağlantı noktası

Logo kutusu, sağdaki kontrol yığını ve sürekli açık büyük tur paneli kaldırıldı. Yakınlaştırma harita jestleriyle yapılır; bölge düğmeleri merkezler. Konum akışı ve süre/görünürlük ayarları küçük Tur ayarları düğmesinden açılır; araç sahibi alt paneli korunur.

`dist/map-config.js` içindeki `googleMapsApiKey` şu an boştur. Gerçek Google Maps JavaScript API renderer'ı `dist/google-map.js` içinde hazırlandı: standart roadmap, varsayılan kontrol yığını kapalı, gerçek Google Map üzerine yerel yol çizgileri ve OverlayView araçları. Resmî API dışında Google tile adresleri kullanılmaz. Google Cloud projesinde Maps JavaScript API, faturalandırma ve bu sitenin HTTPS alan adına kısıtlı tarayıcı anahtarı gerekir. Anahtar olmadan mevcut Esri/OpenFreeMap haritası açıkça geçici harita olarak etiketlenir. Google bağlantısı gerçek anahtarla test edilmedi ve tamamlanmış sayılmaz. API hata durumu kullanıcıya gösterilir.


### v0.12 Üst sırada bölge seçimi

Kullanıcının seçtiği v0.10 açık gri harita görünümü korundu. Tur ayarları düğmesi kaldırıldı, Konyaaltı / Lara / Kültür düğmeleri üst sıraya taşındı. Hayalet mod aynı sırada kompakt ve erişilebilir etiketli düğme olarak korunur. Google anahtarı hâlâ boş; gerçek Google Maps bağlantısı anahtar girildiğinde etkinleşir.


### v0.13 Google Maps anahtarı

Kullanıcının sağladığı, site ve Maps JavaScript API kısıtlamaları yapılandırılmış tarayıcı anahtarı map-config.js üzerinden bağlandı. Google'ın resmî JavaScript API'si native roadmap görünümünü yükler; bölge düğmeleri, yollar ve araç sahibi paneli korunur. Anahtar tarayıcıda görünür; sunucu anahtarı değildir. Kısıtlamalar kaldırılmamalıdır. OverlayView projeksiyonu ilk karede henüz hazır değilken araç çizimi ertelenir.

Google API yüklemesi ve native OverlayView araçları tarayıcıda çalıştı; Zeytin araç sahibi paneli tıklamayla açıldı. Ancak Google konsolu BillingNotEnabledMapError döndürdü. Anahtarın Google Cloud projesinde faturalandırma etkinleşmeden gerçek harita bağlantısı tamamlanmış değildir. 16 mevcut test ve JavaScript sözdizimi kontrolü geçti. Site dışındaki yerel test adresi için alan adı kısıtlaması gevşetilmedi.

## iOS / App Store hazırlığı (21 Ekim 2026)

Geliştirme iOS projesi `mobile/` altında. Kurulum/eksik listesi: [app-store/READINESS.md](app-store/READINESS.md). Web ve native geliştirme sürümü hâlâ yerel demo ekonomisini kullanır. Apple Developer veya Supabase bağlanmadı; imzalı IPA üretilmedi. `cd mobile && npm run check:release` bu eksikler tamamlanmadan başarısız olmalıdır.

## Güncel sürüm: Aşama 7

Güncel kurulum ve yayın engelleri için `docs/admin/stage7-report.md` ve `app-store/release-status.json` kaynaklarını esas alın. Yukarıdaki demo/D1 ve tarihsel test sayıları önceki sürümlerdendir. Güncel sosyal/garaj/ekonomi sistemi Supabase kullanır; mevcut canlı veritabanında eski temel SQL dosyalarını yeniden çalıştırmayın.

Ana uygulama: `pnpm install --frozen-lockfile`, `pnpm dev`, üretim için `pnpm build`. Testler: `node --test tests/*.test.cjs tests/*.test.mjs`. Mobil: `cd mobile`, `npm ci`, `npm run sync:ios` veya `npm run sync:android`; mağaza engelleri için `npm run check:release`.

## Aşama 8
Güncel uygulama/test ve açık işler: [Aşama 8 raporu](docs/admin/stage8-report.md). GitHub kullanıcı seçimiyle beklemede; workflow dosyaları henüz GitHub üzerinde çalışmadı. E-posta/push/mağaza ödeme sağlayıcılarının bağlı olduğu iddia edilmez.
