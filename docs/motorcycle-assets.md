# Motosiklet görsel ve katman envanteri

18 özgün, logo içermeyen yan görünüm. Üretici fotoğrafı kopyalanıp yeniden yayımlanmadı. Bunlar model odaklı üretilmiş illüstrasyonlardır; resmi üretici fotoğrafı veya CAD ölçüm modeli değildir. Ön/arka görünümler eklenmedi.

Üretim yöntemi: built-in image_gen. Temel prompt: “Original realistic studio 3D rendering of [model and distinctive body description], strict right-side profile facing right, white body panels, black tires/seat, gray metal wheels, transparent 1536×1024 canvas, no logos/text/ground/shadow.” PCX/R25/MT-25 ve diğer 15 model ayrı çağrılarla üretildi; NS200 ve Drift L ayırt edici siluetleri düzeltilerek yeniden üretildi.

Mobil dosyalar: public/assets/motorcycles/*-side-v1.webp, 1024×683. Orijinaller: docs/artwork-source/motorcycles/*-side-v1.png. Katman koordinatları public/motorcycle-assets.js içinde, işleyici public/motorcycle-customizer.js içinde.

| Model | Temel katmanlar | Ek katmanlar | WebP boyutu | SHA-256 |
|---|---|---|---:|---|
| Honda PCX 125 | Renk, kaplama, jant rengi/şeridi, far, alt ışık, sele | exhaust, mirror, windshield | 110 KiB | d65185ef7ea32f78fff2509d8b570d80f62579b791817fbf68835f56ea3460f2 |
| Honda Activa 125 | Renk, kaplama, jant rengi/şeridi, far, alt ışık, sele | — | 104 KiB | 266eb3c1562a19aa95a85cc57cf3572c49d82ef766488661f498413851e3af48 |
| Honda Forza 250 | Renk, kaplama, jant rengi/şeridi, far, alt ışık, sele | windshield | 118 KiB | a4a028e7b2063479bd8024258245e38a4705ff9485c42cc7dc385ac4d299d1b7 |
| Yamaha NMAX 155 | Renk, kaplama, jant rengi/şeridi, far, alt ışık, sele | windshield | 104 KiB | 8d0eb86b7897ab7805bf7eb4169c59d726de0964d24a7aa9267ee434178f392f |
| Yamaha XMAX 250 | Renk, kaplama, jant rengi/şeridi, far, alt ışık, sele | windshield | 111 KiB | 1bb40d73a570c3bf3edd91102369780693bf2ec85b1f28ad439a2a8e04a26df6 |
| TVS Jupiter 125 | Renk, kaplama, jant rengi/şeridi, far, alt ışık, sele | — | 97 KiB | 051833a5fd04feab7c73f2b5f2e039e46dbc1f79dde1b231887ae92073177ac4 |
| Mondial 125 Drift L | Renk, kaplama, jant rengi/şeridi, far, alt ışık, sele | — | 143 KiB | a3add8789f550f67296f0b3753fea2fa074a089107b024cf458950f955886991 |
| Mondial Wing 50 | Renk, kaplama, jant rengi/şeridi, far, alt ışık, sele | — | 96 KiB | c130395a0bd0e7684056dad73f5af612222a3bfa4af73f55aaa3459a567d49cf |
| Kuba CG50 Pro | Renk, kaplama, jant rengi/şeridi, far, alt ışık, sele | — | 185 KiB | f2b176fc6360154641f2b9c9d2794ed99b69fbc0b92965966f6fe2946eb3f179 |
| RKS New Light Pro | Renk, kaplama, jant rengi/şeridi, far, alt ışık, sele | — | 97 KiB | b48fc2cc5deac2de9a032d13458a1336a89cb118ec3a7c58940c54848fc6918b |
| Yamaha R25 | Renk, kaplama, jant rengi/şeridi, far, alt ışık, sele | exhaust, mirror, windshield | 139 KiB | 60e0ee917ed624d9a36abb80788db69f119d3e131c39b690f2b1783a11178c4f |
| Yamaha MT-25 | Renk, kaplama, jant rengi/şeridi, far, alt ışık, sele | exhaust, mirror | 142 KiB | aebf38345ccfa292c174ff7964552612aec62eb65bc97b70948b60d0cd483f5a |
| CFMOTO 250SR | Renk, kaplama, jant rengi/şeridi, far, alt ışık, sele | windshield | 140 KiB | f0e0e23790105046a9dbda18e6f22fb0d8f8b14169e92489234148f140c19f79 |
| CFMOTO 250NK | Renk, kaplama, jant rengi/şeridi, far, alt ışık, sele | — | 151 KiB | 610248fd9f82d8d62555a425e1ec711c142e3deb7a1a500342a65e66e45db2a6 |
| Kawasaki Ninja 400 | Renk, kaplama, jant rengi/şeridi, far, alt ışık, sele | windshield | 146 KiB | f0d2121250bb2c0be6227919d9a1497d758ef2958c526418cf98228f67b7da6c |
| Honda CBR250R | Renk, kaplama, jant rengi/şeridi, far, alt ışık, sele | windshield | 138 KiB | 3784891c51eecd444029b5dbb7f41cf0ee22340aabaf1fb285981f61d7f6346b |
| Bajaj Pulsar NS200 | Renk, kaplama, jant rengi/şeridi, far, alt ışık, sele | — | 149 KiB | 240b0d988c660b72bae4625f6521e4af56b591e1c3f2781e87a3b02f625fcb85 |
| KTM Duke 250 | Renk, kaplama, jant rengi/şeridi, far, alt ışık, sele | — | 148 KiB | ebff5bba4a8788821d621e3ed77654b4fda3d03644697132673a7eeb0a30a3c9 |

Egzoz ve ayna alternatifleri yalnız PCX 125, R25 ve MT-25 için açıldı. Ön cam yalnız ön cam katmanı bulunan modellerde açılır. Diğer modellerde kategori açıklaması gösterilir; uygun olmayan ürün backend kataloğunda da yoktur. Bütün modellerde temel yedi kategori bulunur.

Karbon deseni yalnız gövde/panel maskesinde uygulanır. Renk maskesi sele ve mekanik bölgeleri ayırır; jantlar kendi koordinatlarında, aydınlatma kendi bölgesinde güncellenir. Katmanlar 18 model için raster piksel farkıyla test edildi. Bu test gözle kontrolü tamamlar; fiziksel parça uyumluluğu veya yol mevzuatı onayı değildir.

## Model bazlı panel düzeltmesi

`docs/motorcycle-panel-fits.json` kaynak görselin 1024×683 koordinatlarında 18 modelin ayrı gövde parçalarını, ön/arka aydınlatma alanlarını, havalandırma boşluklarını ve test noktalarını saklar. `bodyPanels` ayrı maskeler halinde birleştirilir; üst üste gelen çokgenler birbirini keserek beyaz boşluk açmaz. Ön çamurluklar boyanabilir; tekerleği çevreleyen genel daire artık çamurluğu kesmez. Ön cam konumları ilgili kaynak görsele göre düzeltildi. Renk işleyicisi kaynak yüzeyin gölge ve çizgilerini korur.

`motorcycle-garage.js` model kataloğunu ve sahip olunan motorların düzenleyicisini ortak `.vehicle-garage` düzeninde açar. Önizleme ve sekmeler sabit, seçimler kaydırılabilir, uygulama/kaydetme alanı altta sabittir. Seçimler taslakta kalır; ücret ve kayıt mevcut sunucu ürün kataloğu, envanter ve sürüm denetimini kullanır. Renk/kaplama seçimleri yeni pencere açmaz. Kategori okları yalnız o kategorideki seçenekleri değiştirir.

Doğrulama: 18 modele dokuz kaplamanın uygulanması, boyanabilir yüzey örnekleri, korunmuş far/sele/mekanik örnekleri, aks merkezleri, taslak izolasyonu ve kategori geçişleri otomatik testlerle kontrol edilir.
