# Araç görseli değişikliği

2026-10-23 (Türkiye). Yalnız haritadaki açık profil kartı ve araç rengi önizlemesi değiştirildi. Kilitli/hayalet/engellenmiş profil selector kontrolü korundu. Harita işaretçisi, fiyat ve satın alma mantığı değişmedi. Yeni veritabanı nesnesi yok.

Kaynak: kullanıcının 13A5C638-D4D6-48B6-AFB3-CA0E044E13E6.jpeg dosyası.
Görsel: public/assets/profile-sedan-v1.webp (şeffaf, 1536×1024, yaklaşık 104 KB).
Düzenleme: yerleşik image_gen, background-extraction. İstem: Beyaz stüdyo arka planını ve zemini şeffaflaştır; beyaz sedanı, siyah camları, farları, tekerlekleri, açıyı, boyutları ve 1536×1024 tuval içindeki yerleşimini koru; plaka/yazı ekleme; yalnız hafif yarı şeffaf temas gölgesi bırak. PNG sonucu uygulama için WebP formatına dönüştürüldü.

kiyiSedanShowcase ortak görünümü SVG gövde maskesiyle canlı boyanır; cam/tekerlek ve far alanları özgün renkte kalır. Plaka esc ile kaçırılmış HTML metnidir; görselin ön tamponuna bindirilir ve renklendirilmez. Her örnekte benzersiz SVG kimlikleri kullanılır.

Doğrulama: mevcut 89 otomatik test geçti. Preview supervisor, başka /site vinext sürecine ait kilit nedeniyle başlayamadı. Kaynakta bunun için geçici altyapı değişikliği yapılmadı. Tarayıcı/gerçek cihaz görsel kontrolü tamamlanmadı.

Düzeltme: status-system.js içindeki mevcut vehicleShowcase(p,mine) ile ad çakışması giderildi. Eski profil görünümü işlevi aynı kaldı. Yeni renderer kiyiSedanShowcase adını kullanır. Yükleme sırası testi, daha sonra yüklenen durum/profil scriptinden sonra hem harita kartının hem boyama önizlemesinin aynı araç varlığını ve SVG gövdesini ürettiğini kontrol eder.

Düzeltme doğrulaması: 91 otomatik test geçti. Başka checkout yolundan kalmış .vinext geliştirme kilidi ayrıldı; supervisor başladı ancak Cloud Browser terminal.local:4173 bağlantısı ERR_CONNECTION_REFUSED verdi. Görsel tarayıcı QA hâlâ doğrulanmadı.

Kompakt düzen: harita önizlemesi mobilde en fazla 248 px (çok dar ekranda 230 px), avatar 76/68 px. Boyama önizlemesi araç ve renk açıklamasını tek sırada gösterir. SVG viewBox üst/alt boşluğu azaltır. Plaka artık ayrı mutlak HTML katmanı değildir; 430×78 birimlik SVG tampon plakası olarak aracın koordinat sistemi içinde aynı ölçekte çizilir. Gövde filtrelemesi panel sınırlarını tahmin etmek yerine tüm silüette parlaklık ve korunan cam/far alanlarını kullanır; ayna, sütun, çamurluk ve eşik dahil boyanır.
SVG renderer ile 248 px fiziksel genişliğin 2x çıktısında beyaz/mor/yeşil/siyah kontrol edildi. Bu tarayıcı ekran görüntüsü değil, çizim doğrulamasıdır. Mobil tarayıcı QA ayrı olarak doğrulanmış sayılmaz.


## Kaplama önizlemesi
Harita kartındaki önizleme mobilde en fazla 194 px, çok dar ekranda 184 px olarak küçültüldü. Boya maskesi XOR clip yerine beyaz/siyah maske ve ayna geri ekleme katmanı kullanır. Cam koruma alanları daraltılarak ayna ve ön cam kenarındaki beyaz gövde şeritleri kapsandı.

`public/car-wraps.js` dokuz izinli kaplama tanımlar. Renklerin altında kare desen kartları vardır. Seçim yalnız üst önizlemeyi değiştirir; kredi harcamaz, görünümü veritabanına kaydetmez. Kalıcı kaplama satın alma için ürün/fiyat, sunucu envanteri ve yetki doğrulaması ayrıca gerekir. Renk seçimi kaplama önizlemesini temizler. Mevcut renk satın alma akışı korunur.

Yerleşik image_gen ilk logolu isteği reddetti. Ayrı, özgün ve logosuz dokuz desen üretildi: Çikolata Dalgası, Pembe Yıldız, Örümcek Ağı, Pembe Kedi, Pembe Leopar, Klasik Leopar, Retro Çiçek, Yarış 95, Halloween. Bunlar referans fotoğraflardaki marka/karakter logolarının birebir kopyası değildir.

Son istem özeti: Tek bir eşit 3×3 kare atlas; her hücrede özgün, düz baskı folyosu; süt/çikolata dalgası, pembe yıldız/kurdela, kırmızı-mavi örümcek ağı, pembe kedi/fiyonk, fuşya leopar, altın leopar, turkuaz-yeşil-turuncu retro çiçek, kırmızı-sarı 95 yarış, turuncu-mor Halloween; bilinen karakter, marka logosu ve araç fotoğrafı olmadan.

Üretilen atlas 1254×1254 (hücreler 418×418), `public/assets/car-wrap-atlas-v1.webp`, yaklaşık 520 KB. Tek dosya kare kartlarda ve kaput/yan/tampon için ayrı perspektif desenlerinde kullanılır. Doku, gövde parlaklık maskesi ve orijinal fotoğraf gölgeleriyle birleştirilir. Camlar, farlar, koyu donanım ve plaka korunur.

Dokuz kaplamanın ve dört düz rengin SVG çizimleri kontrol edildi. Gerçek mobil Safari etkileşimi doğrulanmadı; yerel çizim incelemesi tarayıcı testi olarak sunulmaz. Önizleme seçimi, izinli desenler, benzersiz SVG kimlikleri, kredi/kayıt olmaması ve düz renge dönüş otomatik testlerle kontrol edilir.


## Referansa göre üç yerleşim düzeltmesi
Barbie, Yarış 95 ve Kinder artık tekrarlanan desen değildir. Yerleşik image_gen ile beyaz sedan hedefi ve kullanıcının her bir araç referansı birlikte kullanılarak üç ayrı şeffaf araç görseli üretildi; özgün sedan açısı/tuvali korundu. Dosyalar `public/assets/wraps/barbie-v2.webp`, `race95-v2.webp`, `kinder-v2.webp` (1536×1024). Kare kartlar için aynı düzenin sade SVG sunumları vardır. Kullanıcının dinamik plakası bu fotoğrafların üzerinde ayrı çizilir.

İstemler: pembe gövde üstünde kapıda tek büyük siyah Barbie yazısı ve küçük çiçek; kırmızı gövde üstünde kapıda tek büyük altın 95, beyaz/siyah kontur ve arkaya uzanan sarı şimşek/alev; beyaz gövde üstünde kapıda siyah K/kırmızı inder yazısı ve alt gövdede siyah kenarlı kırmızı dalga, arkada mavi etiket. Hiçbirinde desen/logolar tekrar edilmez, tampon plakası gömülmez, cam/far/lastik korunur.

Örümcek Adam referansına yönelik görsel düzenleme isteği image_gen tarafından moderation_blocked/other ile reddedildi. Bu dördüncü tasarım tamamlanmış olarak bildirilmedi; mevcut genel ağ deseni korunur. Üç başarılı üretimin uygulama çizimleri kontrol edildi. Gerçek telefon Safari testi tamamlanmadı. Üç kaplama da mevcut önizleme kapsamındadır; kalıcı satın alma/kayıt eklenmedi.

## Araç Garajı ve yedi model (2026-10-23)
Kendi profilindeki küçük üstten araç ve ikinci kalem kaldırıldı. Plaka tek erişim düğmesidir. `vehicle-garage.js` mevcut plaka galerisi ve ücretli renk işleyicilerini koruyarak Plaka / Renk ve Kaplama / Araç Modeli sekmelerini açar. Profil altına ayrıca boya paneli eklenmez.

Modeller: BMW 3 Serisi (G20), Audi A3 (8Y Sportback), Mercedes C Serisi (W206), Volkswagen Golf (Mk8), Renault Clio (V), Fiat Egea (Tipo sedan), Toyota Corolla (E210). Bu liste satış sıralaması iddiası değildir. Mevcut serbest metin araç bilgisi bilinen modelle eşleşirse o görsel seçilir; eşleşmeyen araçlarda önceki sedan korunur. Açık model seçimi kullanıcı alanından `vehicle_model` komutuyla kaydolur. Sunucu yalnız izinli yedi kimliği kabul eder; bakım, yaptırım, oturum ve hesap kilidi kontrolleri mevcut komutta kalır. RLS/doğrudan yazma yasakları değişmez. `kiyi_appearance.vehicle_model` eklenir; `kiyi_private.person` açık alan listesine eklenir. Seçim profilin `car` bilgisini günceller; boya, plaka, galeri ve kredi kayıtlarına dokunmaz. Model başına yeni ücret eklenmedi.

Yeni görseller yerleşik image_gen ile üretildi: `public/assets/models/{bmw-3,audi-a3,mercedes-c,vw-golf,renault-clio,fiat-egea,toyota-corolla}-v1.webp` (1536×1024, gerçek alfa). Ortak istem (Subject yerine yukarıdaki modelin tam İngilizce adı): “Use case: product-mockup. Asset type: transparent car configurator sprite. Primary request: one photorealistic [Subject], pearl WHITE unwrapped body with black windows, black tires, stock wheels, normal trim. Front three-quarter view facing LEFT, front bumper on left and visible passenger side stretching right. Camera eye height just above headlights, long side clearly visible. Landscape 1536x1024 composition, complete car centered from x=80 to x=1450 and y=240 to y=850, generous transparent padding. Studio soft neutral lighting, accurately recognizable model silhouette and grille. Blank white FRONT license plate panel, no letters, no added text or labels. Pure transparent background, natural soft contact shadow, no environment. Exactly one car, not a collage. Body should be bright white including mirror shells and bumpers, glass remains dark. This will be recolored in a web app.” Resmî üretici fotoğrafı değildir.

`vehicle-models.js` her model için cam/far/jant/ayna maskesi ve tampon plaka ölçüsü taşır. Dokuz kaplama her seçili modelde önizlenir. Yeni modelde eski sedanın hazır kaplama fotoğrafına dönülmez; Kinder, Barbie ve 95 tek yan yerleşim olarak, kalanları gövde dokusu olarak çizilir. Kaplama hâlâ önizlemedir; satın alma/kalıcı kaplama kaydı bu değişikliğin kapsamında değildir.

Doğrulama: 7 model × 4 görünüm yerel SVG çizimi karşılaştırıldı; 7 × 9 kaplama ve renk render kontrolleri, demo kayıt/geri alma ve hesaplı komut hata testleri. SQL regresyonu `tests/vehicle-models.sql`: yedi modelin kayıt/okuma turu, bakiye/plaka/boya korunması, geçersiz/eksik kimlik, başka kullanıcı hedefleme, doğrudan tablo yazma, askıdaki hesap ve oturumsuz çağrı engelleri. Canlı DDL öncesi izole PGlite üzerinde mevcut canlı işlev tanımlarıyla başarılı; migration iki kez çalıştırılarak yeniden uygulanabilirlik kontrol edildi. Canlı şema/izinler salt okunur sorguyla doğrulandı; gerçek kullanıcı profiline test yazılmadı. Yönetilen önizleme eski /site PID14 kilidinde durduğu için mobil Safari etkileşimi doğrulanamadı; SVG incelemesi tarayıcı testi değildir.

## Model bazında kaplama oturtma düzeltmesi
`KiyiWrapFits` her araç için ayrı kapı sınırı, yazı ölçeği/eğimi, kaput yazısı dönüşümü, üç yüzey doku dönüşümü ve özgün amblem/ızgara koruması içerir. Eski ortak 560 birimlik yan yazı kaldırıldı: Kinder, Barbie ve 95 artık aracın kendi kapı alanına kırpılır; çamurluklara ve kapı kollarına taşmaz. Kaput yazısı ayrı kaput sınırına kırpılır; ön amblem üstüne sürüklenmez. Diğer altı desen ön/yan/kaput yüzeylerinde ayrı perspektifle çizilir.

| Model | Tekil düzeltme |
| --- | --- |
| BMW 3 Serisi | İki böbrek ızgarası ayrı korunur; kaput ambleminin beyaz hale bırakan koruması daraltıldı. Kapı yazısı iki teker arasına küçültüldü. |
| Audi A3 | Dört halka ve ana ızgara korundu; alt hava girişinde beyaz boya lekesi oluşturan geniş maske kaldırıldı. |
| Mercedes C Serisi | Kaput amblemi ile ızgaradaki yıldız ayrı korundu; tampon boyasına taşan koruma daraltıldı. |
| Volkswagen Golf | Yuvarlak ön amblem/üst çıta korundu; hatchback kapısına göre yazı boyu ve eğimi ayarlandı. |
| Renault Clio | Elmas amblem/üst ızgara korundu; kısa yan panelde metin ve dalga kapı altında sınırlandı. |
| Fiat Egea | Ön FIAT amblemi/ızgarası korundu; sedan yan paneli ve kaput için ayrı doku/yazı açıları ayarlandı. |
| Toyota Corolla | Amblem çevresindeki beyaz hale, ön cam direği, çamurluk kenarı ve tampon altındaki beyaz maske şeritleri düzeltildi. |

Jant korumaları görünür iki jantın içine daraltıldı; siyah lastik arkasını korumak amacıyla konmuş üçüncü elipsin tampon boyasını engellediği görüldü ve kaldırıldı. Gövde rengiyle boyanabilen kapı kolları beyaz bırakılmaz. Kaplama/renk önizleme kapsamı ve satın alma işleyişi değişmedi.

QA: her modelin dokuz kaplaması ayrı 3×3 yerel SVG çizim sayfasında incelendi (63 birleşim); eski sedanın dokuz görünümü de karşılaştırıldı. `node scripts/verify-vehicle-wraps.cjs` özgün amblem merkezinde beş piksel örneğini her model/kaplamada kaynak WebP ile karşılaştırır (kanal başına en fazla 3 fark). Script için Sharp gerekir; kurulmuş Sharp veya Codex runtime bağımlılığı kullanılır. Bu dosya UI tarayıcı testi yerine sunulmaz. Yönetilen mobil önizleme önceki ortam kilidi nedeniyle doğrulanamadı; gerçek Safari son kontrolü hâlâ yapılmış değildir.

## Referans tasarımı düzeltmesi — Yarış 95, Örümcek Ağı, Barbie
Kullanıcının 00:46 telefon görüntüleri önceki küçük 95/yazı yaklaşımının tasarımı korumadığını gösterdi. Bu sürümde yalnız maske iyileştirmesiyle yetinilmedi; `kiyiReferenceLivery` içinde üç ayrı yerleşim oluşturuldu.

- Yarış 95: izinli modelin kapı alanını kullanan büyük, siyah/beyaz konturlu altın 95; sarı/turuncu arka alevler, ön çamurluk şimşeği ve kaputta oval Rust-eze amblemi. Tekrar eden desen ya da küçük 95 etiketi yok.
- Örümcek Ağı: atlas kaldırıldı. Kırmızı kaput/üst gövde, mavi alt yanlar ve çamurluklar; tek merkezden yayılan büyük ağ çizgileri ve kaputta iki beyaz/siyah göz. Ön, yan ve kaput ayrı kırpılır. Mevcut adsız sedan da aynı yerleşimi kullanır.
- Barbie: pembe gövde üzerinde kapıda geniş, kalın sabit SVG el yazısı. Tarayıcının cursive fontuna bağımlı ince ve küçük metin kaldırıldı. Yeni çizim `assets/wraps/barbie-lettering-v3.svg`; üç kare katalog görseli de yeni tasarımla eşleştirildi.

Yedi model için ayrıca `reference` dönüşümleri belirlendi. Önceki küçük katalog etiketi dönüşümü Kinder ve diğer mevcut akışlar için korunur. Gövde maskesi amblemleri, camları, farları, jantları korumaya devam eder. Kredi tahsilatı ve kaplamanın yalnız önizleme olması değişmedi. Referanslar kullanıcının `IMG_2014(3).jpeg` ve `IMG_2021(2).jpeg` dosyalarıdır; farklı otomobil gövdelerine uyarlama yapılmıştır.

Kontrol: 99 uygulama testi; 7×9 yerel SVG karşılaştırma çizimi, eski sedan kontrolü, 63 model/kaplama amblem örnekleme karşılaştırması. Mobil Safari etkileşimi test edilmiş değildir; kullanıcıdan gelen ekran görüntüleri üzerinden yerleşim sorunu değerlendirildi.

## Ortak garaj önizlemesi, dama bayrağı ve göz hizası (2026-10-24)
- Plaka, Renk ve Kaplama, Araç Modeli bölümleri tek ortak araç önizlemesi kullanır. Başlık → araç önizlemesi → üç bölüm düğmesi → bölüm içeriği sırası uygulanır. Plaka ekranında da seçili araç görünür. Renk/model panellerindeki kopya önizlemeler kaldırıldı; renk ve kaplama işleyicileri ortak garaj kökünü günceller. Bölüm düğmeleri kaydırma sırasında önizlemenin üstüne taşınmaz.
- 95 rakamı tarayıcı fontu/negatif harf aralığı yerine `race-number-v4.svg` sabit kontur çizimidir. DejaVu Sans Bold rakam konturları dönüştürülmüş, bağımsız aralık ve siyah/beyaz kontur tanımlanmıştır; font dosyası yüklenmez. Kaynak lisansı `assets/wraps/DejaVu-LICENSE.txt` içindedir.
- Kaputtaki önceki oval Rust-eze yazısı kaldırıldı. Her modelin dört kaput köşesiyle tanımlanan `hoodPlane` üzerinde 8×5 siyah/beyaz hücre, dalga eğrileri ve kıvrım gölgesi çizilir. Eski adsız sedanın 95 görünümü de bu çizime geçirildi.
- Örümcek gözleri aynı kaput düzleminde karşılıklı simetrik eğrilerdir; birbirinden bağımsız ekran koordinatlarıyla yerleştirilmez. Modelin bakış açısına göre ikisi birlikte yansıtılır. Ağ ve gövde renkleri korunur.

Doğrulama: 102 uygulama testi (ortak önizleme/nav sırası; önizleme panel dışında olduğunda renk/kaplama güncellemesi dahil), 7×9 SVG çizimleri ve amblem piksel karşılaştırması. Gerçek tarayıcı denemesi yönetilen önizlemenin eski `/site` PID14 kilidinde başlamaması nedeniyle tamamlanamadı. Bu kaynak değişikliğiyle ilgisiz önizleme altyapısı değiştirilmedi; telefon Safari doğrulaması yapılmış değildir.

### İşaretlenen beyaz gövde boşlukları (2026-10-24)

- Audi A3, Golf, Clio, Egea ve Corolla için gövdeye taşan kaba ızgara koruma poligonları kaldırıldı. Koyu ızgara malzemesi mevcut luminans maskesiyle korunur; marka amblemleri ayrı maskelerle korunmaya devam eder. Krom ızgara şeritleri görünüm rengine dahil olur.
- Clio ön camının sağ sınırı A sütunundan geri çekildi. Egea/Corolla ön cam üst ve yan sınırları modele göre düzeltildi; Egea ayna kapağına erişim genişletildi.
- Mercedes uzak farının gövdeye taşan alt sınırı ve ön jant koruma elipsi düzeltildi. Corolla farının kaput üstüne taşan düz kenarı, farın gerçek kavisini takip eder.
- `scripts/verify-vehicle-wraps.cjs` kullanıcı işaretleriyle eşleşen 13 noktada kırmızı kaplamanın gövdeyi kapladığını da kontrol eder; 63 model/kaplama için amblem koruma karşılaştırması sürer. Gerçek far LED'leri, amblemler, lastikler ve camlar korunur.
- Yönetilen tarayıcı önizlemesi eski `/site` PID 14 kilidi yüzünden başlatılamadı; uygulama kodu bu altyapı hatası için değiştirilmedi. Raster SVG kontrolü gerçek iOS Safari kontrolü yerine geçmez.

### Kaput hizası ve araç üzerinde plaka önizlemesi (2026-10-24)

- Yedi katalog modeli ve eski sedan için kaputun dört köşesi yeniden ölçüldü. Bayrak ve iki göz bu dört köşeye göre, kenarlardan içeride çizilir. Bayrak öne taşınıp ambleme yaklaşmaz. Her modelin yarış/örümcek çizimi yerel raster çıktıda ayrı incelendi.
- Garajdaki plaka kartları artık ek isim/satın alma penceresi açmaz. Seçim geçici garaj durumuna yazılır ve ortak araç önizlemesini günceller; profil/para/envanter değişmez. Alt yazı aynı bölümde girilir ve her tuşta araç üzerindeki plakaya yansır.
- Ayrı `Kaydet ve kullan`/kredili açma düğmesi mevcut `applyPlateStyle` işlemini çağırır. Mevcut kimlik doğrulama, sunucu fiyat/yetki kontrolleri korunur. Gerekli alt yazı boşsa kayıt yapılmaz; başarısız kayıtta önizleme kalır.
- Ortak `kiyiVehiclePlate` SVG çizimi altı katalog tasarımının mevcut çerçeve dosyalarını bütün modellerde kullanır; TR, plaka numarası ve alt yazı aynı önizlemenin içindedir. Model/boya/kaplama sekmesi değişirken geçici plaka korunur. Plaka/isim HTML kaçışlaması ve tasarım izin listesi uygulanır.
- 104 uygulama kontrolü; 63 kaplama/amblem karşılaştırması; 8 araç × 6 plaka tasarımı yerel SVG çıktısı. Gerçek iOS Safari doğrulaması, önceki önizleme altyapısı kilidi nedeniyle yapılmadı.

### Koyu garaj / hediye teması ve aksesuar denemeleri (2026-10-24)

- `public/garage-dark.css` yalnızca garaj ve hediye/şarkı gönderme diyaloglarını koyu kömür rengine (`#222125`) geçirir. Kartlar, form alanları, alt işlem çubuğu, seçili durumlar ve kapatma düğmeleri aynı palettedir; uygulamanın diğer sayfaları değişmez.
- Renk bölümündeki açıklama başlığı ve o başlığa bağlı ikinci cüzdan DOM'dan kaldırılır. Ortak başlık satırının sağında çalışan jeton cüzdanı/yükleme düğmesi ve ayrı mor elmas göstergesi vardır. Elmas göstergesi açıkça `Yakında` durumundadır: bakiye 0, satın alma/debit servisi yok. Mevcut satın alma fiyat ve işlemleri jetonla devam eder; elmas/jeton yeniden adlandırması veya dönüşümü yapılmadı.
- Yeni Aksesuar sekmesi 7 seçeneği cam/tavan kategorilerine ayırır: mor LED, buz mavisi LED, kalp LED, yazılı LED (12 karakter), fiyonk, yıldız ışıkları, kalpli tavan. İki slot birlikte seçilir; kategori başına kaldırma vardır. Model bazlı ön cam düzlemi ve tavan koordinatları ile SVG önizlemesi üretilir; LED camın dışına taşmaz.
- Aksesuarlar açıkça önizleme ürünleridir. Sadece geçici garaj durumuna yazılır; para, profil veya envanter kaydı yapmaz. Renk/kaplama/model/plaka değiştirirken geçici seçim korunur. Yeni garaj girişinde sıfırlanır. Gerçek hesapta kalıcı kullanım ve elmas ekonomisi bu sürümün parçası değildir.
- 106 uygulama testi ve mevcut 63 model/kaplama/amblem karşılaştırması geçti. 8 araçta 7 aksesuarın yerel SVG çıktısı alındı; cam/tavan yerleşimleri ayrı incelendi. Yönetilen önizleme aynı `/site` PID 14 kilidiyle açılmadı; gerçek mobil tarayıcı/CSS doğrulaması yapılamadı.

### Mavi elmas, plaka yakın görünümü ve jant modelleri (2026-10-24)

- Garajdaki çift bakiye kaldırıldı. Ortak başlık yalnız mavi elmas simgeli 0 bakiyeyi ve elmas yükleme düğmesini gösterir; mor elmas/yakında satırı yoktur. Plaka ve renk kartlarının altın jeton simgeleri yalnız garaj içinde mavi elmasla değiştirilir. Hediye cüzdanının altın jetonları korunur.
- Mavi elmas sunucu bakiyesi/ödeme henüz yoktur. Fiyat rakamları görsel hazırlık olarak kaldı. Garajdaki ücretli renk açma düğmesi kaldırılır ve eski altın bakiye debit çağrısına geçiş engellenir. Plaka kayıt yardımcı metodu yalnız zaten açık tasarımları işleyebilir. Yükleme düğmesi mevcut durumu açıklar; ödeme yapılmış gibi davranmaz.
- İşaretlenen plaka alt açıklama/satın alma kutusu ve genel galeri alt notu kaldırıldı. İsimli plakalar için yalnız aynı yerde alt yazı girişi kalır; seçim araç üzerinde önizlenir.
- Plaka sekmesinde modelin gerçek plaka koordinatlarından hesaplanan yakın görünüm otomatik açılır. Kullanıcı Aracın tamamı/Plakaya yaklaş düğmesiyle görünümü değiştirir. Diğer sekmeler tam araç görünümünü kullanır. Yedi katalog modelinde plaka, merkezini koruyarak %25 büyütüldü; amblemler korunur.
- Jant sekmesi 6 ayrı SVG modeli sunar: Sport 5, Çift Kol, Gümüş Mesh, Türbin, Siyah Sport, Altın Mesh. İki tekerleğin mevcut model bazlı iç jant elipslerine uygulanır. Lastik dış sınırı ve gövdeye dokunulmaz. Orijinal jant düğmesi kaplamayı kaldırır. Seçim şimdilik önizlemedir; profil/para/envanter değişmez ve diğer garaj seçimleriyle birlikte gösterilir.
- 110 uygulama kontrolü, mevcut 63 model/kaplama/amblem karşılaştırması; 8 araç × 6 jant ve 8 araç için plaka yakın görüntüsü yerel SVG çıktılarında kontrol edildi. Gerçek Safari/CSS görünümü, bilinen önizleme altyapısı kilidi yüzünden doğrulanamadı.

### İsim alanının görünürlüğü, ayrıntılı jantlar ve hediye paneli (2026-10-24)

- Plaka isim alanı sekmelerin hemen altına, ürünlerden önce taşındı. İsim destekleyen dört karta `İsim ekle` rozeti eklendi. Seçimde `Plakana ismini yaz` alanı açılır ve gerekirse görünür konuma kayar; yazı anında araç plakasında gösterilir. Ayrı pencere veya satın alma kutusu geri getirilmedi.
- Jant sekmesi ön tekerleğin mevcut model koordinatlarına otomatik yakınlaşır; Aracın tamamı/Janta yaklaş düğmesi vardır. Jant tasarımına tıklayınca yakın görünüm korunur. 12 katalog modeli: önceki altı tasarım yeniden çizildi; İnce 6, Aero Disk, Y Kol, Derin Çanak, Bronz Yarış, Rose Mesh eklendi. Kol kenarları, ışık geçişleri, iç çanak, fren diski/delikleri, kaliper ve bağlantı başları ayrı SVG katmanlarıdır. Jantlar hâlâ önizleme durumundadır.
- Pırlanta plaka araç önizlemesinde esnetilmiş JPEG çerçeve yerine ince metal kenar ve tek tek fasetli taşlarla çizilir. Plaka yüzü/numarası genişletilir, TR ve oran korunur. Her çizimin desen/gradient kimlikleri ayrıdır.
- Hediye gönderme paneli viewport'un yanlarına ve altına oturur; üst köşeler yuvarlaktır. Dört sütun, daha küçük ürün görselleri ve kartlar kullanılır. Buket, yüzük ve kedi kartlarına sabit parıltılı arka plan ve küçük alev rozeti eklendi. Gönderim, fiyat ve seçim akışı değiştirilmedi; seçim tek başına hediye göndermez.
- 112 uygulama kontrolü ve 63 kaplama/amblem piksel karşılaştırması geçti. 8 araç × 12 jant; 8 araçta jant yakın görünümü ve pırlanta yakın görünümü yerel SVG çıktılarıyla kontrol edildi. Yönetilen önizleme tekrar `/site` PID 14 kilidiyle durdu; Safari ve gerçek CSS yerleşimi doğrulanamadı.
# Gerçekçi jant ve ortak plaka görselleri (2026-10-24)

- 12 jant seçeneği, Imagegen ile ayrı üretilmiş şeffaf ürün görsellerini kullanır. Kart ve araç üzerindeki ön/arka jant aynı dosyadan çizilir; modele özel tekerlek elipsleri korunur.
- Jant yakın görünümü iki tekerleğin sınırlarından hesaplanır; arka tekerleği kırpmaz.
- Pırlanta dahil plaka kartları, profil ve araç aynı `kiyiVehiclePlate` çizimini kullanır. Gerçek çerçeve dosyaları ölçülen açıklıklara göre yerleştirilir. İsim metni alt çerçevede canlı güncellenir; HTML olarak yorumlanmaz.
- Hediye paneli üç sütun kullanır.
- Jantlar/aksesuarlar/kaplamalar önizleme kapsamındadır. Elmas satın alma altyapısı bu değişiklikte eklenmedi.
- Yönetilen tarayıcı önizlemesi mevcut Vinext sunucu kilidi nedeniyle kullanılamadı; yerel SVG çıktıları ve otomatik testler kontrol edildi.


### Model-specific hood alignment and rim browsing
The rim tab keeps its compact live preview sticky within the garage scroll area, retaining both wheels in frame. Each vehicle now has its own hood quadrilateral and artwork insets; a projective mapping aligns the flag and paired eyes to that surface. Kinder uses the same model body masks and side perspective, with a continuous lower red wave and a larger door wordmark. Reviewed native renders of all eight vehicle views; 113 automated tests pass. Managed browser preview was unavailable, so mobile scrolling still needs device confirmation.

### Expanded garage (v118)
Fourteen model assets added, including separate M4 Coupe/Cabrio and Tourneo Courier. Each uses measured windshield, lamp, wheel, plate, hood and door coordinates. Six principal wraps tested on every new model; Kinder, Race95 and spider renders visually reviewed. Two photoreal sport rims include red/yellow brake calipers. Four headlamp and four underbody color previews combine with existing accessories. Gift modal overrides wrapper padding and viewport width. Preview-only accessories and rims remain preview-only; no payment changes.

Assets: `public/assets/models/*-v1.webp`, new red/yellow rims in `public/assets/rims/`. Created with built-in image generation, converted to WebP. Prompt: isolated white exact-model car, front three-quarter facing left, transparent 1536x1024 studio configurator view; original silver wheels and blank plate. Rim prompts: orthographic forged sport alloy with drilled disc and red/yellow caliper on transparency. Browser QA unavailable due managed preview service conflict.
