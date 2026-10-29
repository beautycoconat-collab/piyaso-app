# Harita görünümü ve profil düzenlemesi — 26 Ekim 2026

- Harita türü başlığı Harita görünümü oldu; Konum simgesi ve Harita alt sekmeleri eklendi.
- Ok, Otomatik (seçili araç türü), Motosiklet ve işaretçi renkleri cihazda saklanır. Başka kullanıcının harita işaretçisi, hesap/araç bilgisi ve konum paylaşım yetkileri değişmez.
- Tercih Leaflet ve MapLibre öz işaretçisine ve oturum açmış kullanıcının mevcut bulut işaretçisine uygulanır. Google harita eski uyumluluk yolu da aynı çiziciyi kullanır.
- Profil sekmeleri Garajım / Gönderiler / Rozetler; varsayılan Garajım. Yalnız sahibinin garajında Araçları yönet butonu mevcut yönetim akışını açar.
- Plaka tasarımı, araç verileri ve veritabanı şeması değiştirilmedi.

Doğrulama: 177/177 test başarılı (174 önceki + 3 yeni); son küçük otomatik renk düzenlemesinden sonra ilgili 3 test tekrar geçti. Üretim derlemesi başarılı. İlk yeni test çalıştırmasında test kaynak dilimi hatası, genel çalıştırmada iki testte browser event globali hatası vardı; düzeltildi ve yeniden çalıştırıldı. Yerel tarayıcı önizleme yönlendirmesi ERR_CONNECTION_REFUSED verdi; fiziksel cihaz testi yapılmadı.

## Araç filtresi ve ok rengi düzeltmesi

Tümü / Otomobil / Motosiklet filtresi harita üstünden kaldırılarak Harita görünümü penceresine taşındı. Araç simgelerinde yerel renk ezmesi kaldırıldı: mevcut garaj görünümü aynı kalır. Renk paleti yalnız Ok seçiliyken görünür. Panel ve simge hizaları kompaktlaştırıldı. 178/178 test ve üretim derlemesi başarılı.

## Son kullanıcı düzeltmesi: tek simge seçimi

Ayrı araç türü filtresi ve onu oluşturan kod kaldırıldı; haritada tüm izinli araçlar gösterilmeye devam eder. Konum simgesi tercihi bu filtrenin yerine geçer ve yalnız kendi işaretçisini etkiler. Ok varsayılanı/önizlemesi mor; renkler yalnız ok için. Motosiklet üst görünümü ayna, far, çatal, depo, sele, egzoz ve lastik ayrıntılarıyla yenilendi, garaj rengi korunur. 178/178 test ve derleme başarılı.

## Ortak kart ölçüleri

Açıklama metni kaldırıldı. Konum simgesi ve Harita sekmeleri ortak kart sınıflarını, aynı kareye yakın önizleme oranını, kolon aralığını ve etiket satırını kullanır. İçerik alanı sabit yükseklikte; renk paleti açıldığında da pencere sıçramaz. 179/179 test ve üretim derlemesi başarılı.

## Kayıtlı araç / kendi işaretçisi ve görünür profil sekmeleri

Sabit içerik yüksekliği kaldırıldı; ortak kart ölçüleri korunur. Profilin sekmeleri girişten bağımsız görünür; yerel araç görünümü ayrı, gerçek garaj ve rozet verileri mevcut yetkili RPC üzerinden gelir. Garajdan kareler, izin verilen fotoğraf gönderilerini sayfalı (ilk 12; devamı varsa +) gösterir. Araçları yönet mevcut garaj yönetimini açar.

Yeni garage-map-profile.js sahibinin garage_list yanıtındaki aracı seçer, otomobil için kiyiSedanShowcase ve motosiklet için motorcycleSVG ile kayıtlı görünümü tekrar kullanır. Aynı türde birden fazla araç seçilebilir. Kayıtlı olmayan tür uydurulmaz. Kendi işaretçisi değişince mevcut yerel ve bulut işaretçisi güncellenir; diğer kullanıcılar değişmez. Oturum kapanınca özel araç önbelleği temizlenir. Girişsiz örnek haritada yalnız yerel, açıkça Sen · Demo etiketli kendi işaretçisi gösterilir. Gerçek hesapta konum yoksa konum uydurulmaz, paylaşım izni otomatik açılmaz.

182/182 test ve üretim derlemesi başarılı. Yeni araç seçimi/özelleştirme bağlantı testleri deterministik RPC yanıtlarıyla yürütüldü; bu turda yeni gerçek Auth hesabıyla GPS testi yapılmadı. Fiziksel cihaz testi yok.

Yayın sonrası tarayıcı kontrolü: Sen · Demo işaretçisi otomobilden oka anında değişti; profil sekmeleri ve Garajdan kareler / Araçları yönet göründü, Rozetler sekmesi açıldı. Gerçek oturum gerektiren veri için giriş ekranı korunur. Ek düzeltme: yerel araç sayacı 1; bulut araç sayacı garage_list sonucuyla güncellenir; eski tercihte seçili olup artık garajda olmayan araç türü için sahte araç yerine ok gösterilir. İlgili 8 test ve son derleme tekrar başarılı.

## Üstten ikonlar korunur

Seçim kartlarında nötr üstten otomobil ve motosiklet ikonları geri getirildi; model fotoğrafı ve Garaja ekle metni ikonun yerine kullanılmaz. Haritadaki kendi işaretçisi de aynı üstten ikon siluetini kullanır. Otomobilde kayıtlı boya, gövde panellerinde katalog kaplaması, far ve alt ışık; motosiklette boya, karbon/şerit kaplama, jant/şerit rengi, far, sele, ayna, cam, egzoz ve alt ışık üstten görünür parçalara uygulanır. Modelin silueti standart ikon olarak kalır; garajdaki yan görünüm haritaya taşınmaz. Satın alma/araç kayıtları ve başkalarının işaretçileri değiştirilmez.

183/183 test ve üretim derlemesi başarılı. İlk hedef testte test fixture'ında carWithOwner eksikti; fixture tamamlanıp yeniden geçti. Son şerit kaplama ekinden sonra ilgili 4 test ve derleme tekrar başarılı. Fiziksel GPS testi yapılmadı.

## İkon seçimi araç sahipliğinden bağımsız

Eklenen Sen · Demo örnek konumu kaldırıldı. Gerçek/izinli kendi konum işaretçisi yokken haritaya yeni örnek nokta eklenmez. Motosiklet/otomobil simgesi seçimi garaj şartına bağlı değildir ve ağ isteğini beklemez; kayıtlı aynı tür araç varsa özelleştirme kullanılır, yoksa nötr standart ikon. Seçim otomatik olarak oka döndürülmez ve garaj ekranına yönlendirilmez. Diğer hesapların işaretçileri etkilenmez. 184/184 test ve derleme başarılı.

## Sade ilk araç formu ve tek yönetim kartı

İlk araçta üstte tür seçimi, ardından marka/model ve plaka alanları; renk ve süslü tanıtım alanları kaldırıldı. Model mevcut vehicle_create sözleşmesi nedeniyle zorunlu kalır; model uydurulmaz. Boş gerçek hesapta ilk form dışında garaj özeti, filtreler ve Garajdan kareler gösterilmez; kayıt başarıyla tamamlanınca profil yeniden çizilir. Kaydın sunucu plaka kontrolleri korunur.

Profil garajında araç görseli, model adı ve tek ⊕ Araçlarımı yönet butonu aynı kartta. Yanındaki ayrı plaka ve Aracını düzenle bağlantısı kaldırıldı; diğer plaka tasarımları değişmedi. Alt tekrarlı yönetim butonu kaldırıldı. Garajdan kareler başlığı genel site header stilinden ayrıldı. Gerçek yönetim ekranı mevcut çoklu araç akışını kullanır; yerel örnek kart mevcut yerel araç editörüne gider.

187/187 test, üç yeni ilk araç/profil regresyon testi ve üretim derlemesi başarılı. Son başlık işaretleme düzeltmesinden sonra ilgili üç test ve derleme tekrar başarılı. Bu turda yeni gerçek hesap/araç oluşturulmadı; boş hesap davranışı mevcut RPC sözleşmesine uygun kontrollü yanıtla test edildi.

## İlk plaka boş durumu ve sade Keşfet akışı

Boş garaj kartı: araç çizgisel ikonu, Henüz araç eklenmemiş başlığı, kısa metin, İlk Plakanızı Ekleyin butonu. Buton mevcut ilk araç formunu açar; ilk kartın altında form/galeri gösterilmez. Açık/mor Kıyı teması korunur.

Keşfet üst sloganları, kategori satırı ve büyük gönderi yazma bandı kaldırıldı. Küçük Kıyı kelime logosu, mevcut gönderi oluşturma ve gelen kutusu kontrolleri kaldı. Sayfa tüm gerçek gönderileri mevcut sayfalama ve görünürlük kontrolleriyle ister. Gönderi başlığında kullanıcı adı ve zaman bir arada; düz akış, ince ayırıcılar ve büyük oranı korunan medya kullanıldı. Etkileşimler, moderasyon, özel medya ve profil erişimleri değişmedi.

189/189 test, iki yeni etkileşim/düzen testi ve üretim derlemesi başarılı. İlk genel çalıştırmada yalnız eski buton metnini bekleyen test başarısız oldu; kullanıcı talebindeki yeni metne güncellenip tüm testler yeniden geçti. Yeni gerçek hesap veya gönderi oluşturulmadı; boş durum ve akış renderı kontrollü testlerle doğrulandı.

## Referans düzeninde gönderi oluşturma

Kapatma/ortalanmış başlık, profil satırı, yuvarlatılmış metin alanı, ince ayırıcılı Medya / Plaka etiketle / Konum / Daha Fazla satırları ve altta geniş Paylaş butonu. Kıyı açık/mor paleti korunur. Görünürlük kontrolü native details içinde Daha Fazla altında; düzenlenen müzik/anket ve hedef kitle değeri korunur. Klavye viewport mekanizması, medya yükleme sınırları ve gerçek gönderi komutları değiştirilmedi.

191/191 test ve üretim derlemesi başarılı. Yeni testler oluşturma düzenini ve mevcut gönderi düzenlerken metin/medya/görünürlük/müzik/anket korunmasını doğrular. Bu turda yeni gerçek gönderi yayınlanmadı ve fiziksel mobil/klavye testi yapılmadı.

## Profil sadeleştirme, ortak önizleme, motosiklet kataloğu

Garajdan kareler metni/bölümü ve gereksiz fotoğraf sorgusu kaldırıldı. Profil altındaki Hesap, araç ve gizlilik ayarları çekmecesi kaldırıldı; gerçek form düğümleri ve işleyiciler korunup dişli menüsünün Hesap ve görünürlük ayarları girişinden açılır. Yerel profil düzenlemesi buraya yönelir; gerçek hesap düzenlemesi mevcut hesap ekranına gider. Gizlilik/koşullar bağlantıları ve hesap silme erişimi korunur; sözleşmeler silinmedi.

Ortak araç önizlemesinin açıklama/model/plaka yazıları kaldırıldı. Tüm sekmelerde yakın ve tam görünüm aynı sabit dış çerçevede ortalanır. Renk/kaplama önizlemelerinin kaldırılan başlık düğümüne yazma bağımlılıkları güvenli hale getirildi.

Araç Modeli seçicisi Otomobil / Motosiklet olarak ayrıldı. Mevcut 21 otomobil ve 18 incelenmiş motosiklet varlığı/kaydı korunur; Honda PCX/Forza/Activa, Yamaha NMAX/XMAX/R25/MT-25 ve mevcut diğer katalog modelleri görünür. Güncel satış sıralaması iddiası yapılmaz. Motosiklet seçimi girişli hesapta mevcut aracı açar veya mevcut ekleme formunda modeli hazır seçip plakayı ister; gerçek kayıt mevcut vehicle_create akışındadır. Yeni motosiklet parçaları veya satın alma yolları eklenmedi.

194/194 test ve derleme başarılı. Yeni testler çekmece kaldırılırken kontrollerin korunmasını, başlıksız önizlemeyi ve 21/18 model ayrımını kapsar. Bu turda yeni Supabase araç kaydı/migration yapılmadı, fiziksel cihaz testi yok.
