# Piyaso — App Store başvuru taslakları

29 Ekim 2026 · **TASLAK — App Store Connect'e gönderilmedi.**

Bu paket 28 Ekim mağaza raporundaki `audit/piyaso-release-20261028` kaynak durumunu ve bu çalışmanın başvuru hazırlığını esas alır. Çalışan native yapı, gerçek Auth/silme, destek iletişimi, moderasyon operasyonu ve hukuki onay tamamlanmadan nihai metin sayılmaz. Köşeli parantezli alanlar işletmeci tarafından doldurulmalıdır. Kodda bulunan politika taslakları, çalışan bir destek adresi veya bağlayıcı saklama kararı yerine geçmez.

Önceki `app-store/STORE-METADATA.tr.md` içindeki Kıyı adı, harici şarkı kataloğu ve etkin ücretli satın alma anlatımı bu sürüm için kullanılmamalıdır. Güncel görünen marka Piyaso; şarkı adı elle girilir; `paidPurchasesEnabled:false`. Ücretli ürünler açılırsa bu paketin ödeme ve inceleme bölümleri yeniden hazırlanmalıdır.

## 1. Mağaza metinleri

| Alan | Taslak |
|---|---|
| Ad | Piyaso |
| Alt başlık | Antalya otomobil topluluğu |
| Tanıtım metni | Antalya'daki otomobil topluluğuyla buluş. Garajını oluştur, paylaşımları keşfet ve konum paylaşımını kendi tercihinle yönet. |
| Anahtar kelimeler | antalya,otomobil,araç,garaj,topluluk,harita,konyaaltı,lara,profil,motosiklet |
| Ana kategori önerisi | Sosyal Ağ |
| İkincil kategori | İsteğe bağlı Yaşam Tarzı; kategori seçimi nihai işlevlerle onaylanacak |
| Birincil dil | Türkçe |
| Teknik Bundle ID | `com.kiyi.antalya` — hesap sahipliği/uygunluğu doğrulanmadı; marka adı gerekçesiyle değiştirilmez |
| Destek URL | [Doğrulanmış herkese açık HTTPS destek sayfası] |
| Gizlilik URL | [İşletmeci tarafından onaylanmış herkese açık HTTPS gizlilik sayfası] |
| Telif hakkı | [Yıl ve hak sahibi gerçek kişi/kuruluş adı] |

### Açıklama taslağı

Piyaso, Antalya'daki otomobil ve motosiklet meraklılarını bir araya getirir.

Garajına aracını ekle, profilini düzenle ve topluluğun paylaşımlarını keşfet. İlgini çeken kişileri takip et; gönderileri beğen, yorum yap ve kendi hikâyeni paylaş.

Haritayı konum izni vermeden gezebilirsin. Konum paylaşımını başlatmayı seçtiğinde izin istenir; paylaşımı istediğin zaman durdurabilirsin. Başkalarına gösterilen konumlar yaklaşık konumdur. Takip etmek, başka bir kişinin konumuna erişim izni vermez.

Uygulamadaki görevlerden ve günlük ödüllerden kazandığın jetonları uygun hediyelerde ve araç özelleştirmelerinde kullan. Şarkı hediyesinde şarkının adını kendin yazarsın; Piyaso müzik dinleme veya müzik aboneliği hizmeti değildir.

Paylaşımları şikâyet edebilir, kullanıcıları engelleyebilir ve gizlilik tercihlerini yönetebilirsin.

Piyaso'yu güvenli şekilde park halindeyken kullan. Uygulama navigasyon, trafik güvenliği, yarış veya acil yardım hizmeti değildir.

**Editör notu — mağaza metnine dahil edilmeyecek:** Bu açıklama, listedeki işlevler son iOS yapısında kabul edildikten sonra kullanılabilir. Premium satışı, otomatik müzik kataloğu, gerçek zamanlı trafik, CarPlay, kesin konum takibi, arka plan konumu ve gerçek telefon push bildirimi vaat edilmez. Ücretli özellik açılırsa ilgili açıklama ve satın alma bilgileri eklenir. Kurgusal örnek profiller gerçek topluluk yoğunluğu gibi pazarlanmaz.

## 2. Gizlilik politikası taslağı

**Yayımlanmadan önce doldurulacak:** [Veri sorumlusu/işletmeci gerçek adı], [iletişim e-postası ve adresi], [yürürlük tarihi], [hukuki dayanaklar], [saklama tablosu], [yurt dışı aktarım yöntemi ve alıcılar], [hak başvurusu yöntemi]. Metin hukuki onay bekler.

### Hesap ve profil

Piyaso hesabı oluşturulduğunda e-posta adresi ve kimlik doğrulama bilgileri giriş hizmeti tarafından işlenir. Kullanıcı kimliği, kullanıcı adı, isteğe bağlı profil adı, biyografi, sosyal bağlantılar, araç/plaka bilgileri, görseller ve gizlilik tercihleri uygulama hizmeti için saklanır. Parola, profil içeriği olarak yayımlanmaz. Herkese açık olarak seçtiğin alanları diğer kullanıcılar görebilir. Plaka yazmak resmî araç sahipliği doğrulaması değildir.

### Kullanıcı içerikleri ve etkileşimler

Gönderi, yorum, fotoğraf/video/ses, beğeni, takip, engelleme, hediye, araç etiketi ve rozet/görev kayıtları hizmetin sunulması için işlenir. Medya özel depoda tutulur ve izin verilen görüntülemeler için süreli bağlantılar kullanılır. Bir içeriği görmeye yetkili kişinin ekran görüntüsü alması veya içeriği dışarıda paylaşması teknik olarak tamamen engellenemez. Gönderi menüsü ve profil seçenekleri aracılığıyla şikâyet/engel özellikleri kullanılabilir.

### Konum ve harita

Haritayı gezmek için konum izni zorunlu değildir. Cihaz konumuyla paylaşımı sen başlattığında konum işlenir. Sunucuya aktarılan konum ile diğer kullanıcılara gösterilen yaklaşık konumun hassasiyeti, son yapıdaki teknik envantere göre açıklanır. Yaklaşıklaştırma anonimlik garantisi değildir. Konum paylaşımı, görünürlük ve engelleme kuralları birlikte uygulanır; takip tek başına konum yetkisi sağlamaz. Paylaşımı durdurabilir veya cihaz ayarlarından izni kaldırabilirsin. Mevcut uygulamada arka plan konum izni talep edilmez.

**Hayalet mod için aday düzeltme:** Bu çalışmadaki SQL adayı, haritada Hayalet kullanıcıların kimliğinin Premium yetkisiyle açılmasını engeller; yaklaşık hayalet işaretleri haritada kalır. Aday üretime dağıtılmadı. Sosyal profil görünürlüğü ayrı bir davranıştır; Hayalet modu “tüm uygulamada herkesten görünmezlik” diye tanımlamayın. Son native yapıdaki harita ve sosyal profil davranışları birlikte doğrulandıktan sonra politika, izin öncesi açıklama ve ayar metinleri aynı açık kapsamı anlatmalıdır.

### Jetonlar ve ödüller

Ücretsiz kazanılan jeton bakiyesi, harcama kayıtları, envanter, hediyeler ve ödül ilerlemesi sunucuda tutulur. Kötüye kullanımı azaltmak için doğrulanmış e-postadan sunucuya özel anahtarla türetilen özet kullanılabilir. Böyle bir özet kişisel veri/pseudonim kayıt değerlendirmesinden otomatik olarak çıkmaz. Mevcut sürümde gerçek parayla dijital ürün satın alma kapalıdır. Satış açılmadan önce işlem/abonelik verileri, mağaza sağlayıcısı ve saklama kuralları ayrıca açıklanır.

### Güvenlik, destek ve hizmet sağlayıcılar

Şikâyet, destek başvurusu ve moderasyon kayıtları yetkili personele gösterilir. Sunucu/harita/barındırma hizmetleri ağ ve istek verilerini işleyebilir. Mevcut kod Supabase, OpenFreeMap/OpenStreetMap tabanlı harita kaynakları ve barındırma altyapısıyla bağlantı kurar; nihai alt işleyen, ülke, veri aktarımı ve saklama listesi işletmeci tarafından doğrulanmalıdır. Dış bağlantılar ilgili hizmette açılır. Uygulamada üçüncü taraf reklam veya reklam amacıyla uygulamalar arası izleme doğrulanmamıştır; sağlayıcıların ağ/log uygulamaları ayrıca incelenmelidir.

### Saklama ve silme

[Her veri türü için süre, başlangıç olayı, silme/anonimleştirme yöntemi ve gerekçe doldurulacak.] Veriler süresiz tutulacakmış veya tüm kayıtlar anında yok oluyormuş gibi bir taahhüt verilmez. Kodda görülen kısa süreli görünürlük sınırları, yedek ve günlüklerin hukuki saklama süresi değildir. Hesap silme akışının ve ortak Auth kimliğinin kapsamı onaylanıp gerçek servis testi tamamlanmadan “hesabın tamamen silinir” ifadesi yayımlanmaz.

### Haklar ve iletişim

Kişisel veriler ve hesap işlemleriyle ilgili başvurular için [doğrulanmış iletişim kanalı] kullanılır. Geçerli mevzuata göre erişim, düzeltme, silme ve itiraz taleplerinin yöntemi [işletmecinin onaylı prosedürü] ile açıklanacaktır. [Çocuklar için kullanım yaşı ve varsa ebeveyn süreci] ayrıca karara bağlanacaktır.

## 3. Kullanım koşulları taslağı

**İşletmeci ve yürürlük:** [Gerçek işletmeci, adres, iletişim, tarih]. [Asgari kullanıcı yaşı] ve sözleşme ehliyeti koşulları hukuki/ürün onayı bekler. App Store yaş derecesi otomatik olarak üyelik yaşı yerine geçmez.

Piyaso, araç topluluğu, profil, garaj, sosyal paylaşım ve isteğe bağlı yaklaşık konum özellikleri sunar. Kullanıcılar yalnızca paylaşma hakkına sahip oldukları içeriği yüklemeli; başkasının kimliğini/plakasını taklit etmemeli veya kişisel bilgilerini izinsiz yayımlamamalıdır.

Taciz, tehdit, nefret, spam, dolandırıcılık, cinsel sömürü, çocukların cinsel istismarı, rıza dışı mahrem görüntüler ve insan ticaretini kolaylaştıran içerikler yasaktır. Gerçek çocuk istismarı örnekleri moderasyon testi için yüklenmez; zararsız sentetik işaretleyiciler kullanılır. Şikâyet ve engelleme uygulamada erişilebilir olmalıdır. Yetkili ekip ihlalleri inceleyebilir, içerikleri kaldırabilir ve hesapları kısıtlayabilir; itiraz yöntemi ve müdahale süreleri [onaylanacak operasyon planı] ile yayımlanır.

Konum paylaşımı isteğe bağlıdır. Harita ve profil bilgileri doğruluk, sürüş güvenliği veya resmi sahiplik garantisi sağlamaz. Araç kullanırken uygulamayla etkileşime girilmemelidir. Yarış, aşırı hız, tehlikeli sürüş veya acil yardım hizmeti sunulmaz.

Ücretsiz jetonların kazanma/harcama kuralları ilgili ekranda gösterilir. Ücretli ürünler bu gönderim adayında kapalıdır. Ücretli jeton veya abonelik etkinleştirilirse Apple ürün bilgileri, fiyat/yenileme, iptal ve geri yükleme koşulları ayrı, doğru ve son sürümle uyumlu biçimde açıklanmalıdır. Jetonların nakde çevrilebilir olduğu taahhüt edilmez.

Hesap silme, veri saklama ve hak başvuruları gizlilik politikasına bağlıdır. İşletmeci adı, destek, fesih/itiraz, tüketici hakları ve uygulanacak hukuk hükümleri gerçek hukuk incelemesiyle tamamlanmadan bu taslak bağlayıcı son sözleşme olarak yayımlanmaz.

## 4. Hesap silme açıklaması

**Başlangıç davranışı ve aday düzeltme:** 28 Ekim kaynak durumunda uygulama ve bağımsız `account-deletion.html` sayfası yalnız `privacy_request` oluşturuyordu. Bu çalışmada uygulama içi parola ile yeniden kimlik doğrulayan bir Edge silme adayı hazırlanmıştır: önce veritabanında hesabı işleme kapatır, ardından Storage nesnelerini ve özel referansları temizler, Auth Admin DELETE çağrısı yapar ve kimliğin artık bulunmadığını kontrol eder. Aday varsayılan olarak kapalıdır ve üretime dağıtılmamıştır. SQL testleri ve taklit Auth servisi testleri, gerçek barındırılan Supabase Auth silme kabulü değildir; erişilebilen proje üretim projesi olduğundan gerçek silme testi orada yapılmaz.

**Açılma sınırı:** Yalnız Piyaso’ya özel Auth kapsamı ve işletmecinin onayladığı `free-account-erasure-v1` ücretsiz hesap silme politikasıyla açılabilir. Ücretli sipariş, hukuki saklama engeli, yönetici hesabı veya başka uygulama referansı bulunan hesaplar bu adayın otomatik silme kapsamına alınmaz. Ortak kimliklerin ve istisnalı hesapların güvenli nihai silme yolu tamamlanmadan uygulamanın tüm hesaplar için Apple silme koşulunu karşıladığı söylenmez. `free-account-erasure-v1` onay bekleyen bir kapsam politikasıdır; kesin hukuki saklama süreleri belirlemez.

**Tamamlandıktan sonra kullanılacak metin:** “Profil → Hesabı yönet → Hesabı sil bölümünden işlemi başlat. Kimliğini doğruladıktan sonra silme kapsamını incele ve son onayı ver. İşlem sonucu ekranda bildirilir. Tamamlanan silmeden sonra oturum kapatılır. [Yasal nedenle saklanan veri türleri, dayanak ve süreler] dışında ilişkili veriler [silme/anonimleştirme yöntemi] ile işlenir.”

Bu ikinci metin, gerçek Auth/Storage/uygulama verisi silmesi test edilmeden uygulamaya veya mağazaya kopyalanmamalıdır. Yalnız talep oluşturulduysa kullanıcıya yalnız talebin kaydedildiği söylenir. Ağ kesintisinde sonuç bilinmiyorsa başarı bildirilmez. Etkin mağaza aboneliği ileride açılırsa hesap silmenin abonelik yönetimiyle ilişkisi açıklanmalıdır; silme gereksiz yere abonelik iptaline bağlanmamalıdır.

## 5. Destek sayfası taslağı

**Piyaso Destek**

Hesap, garaj, paylaşım, konum veya jeton işlemleriyle ilgili yardım için uygulamadaki “Destek ve hesap talepleri” bölümünü kullanabilirsin.

- Hesabına erişemiyorsan: [giriş gerektirmeyen, doğrulanmış destek e-postası/formu].
- Gizlilik ve veri talepleri: [gerçek veri sorumlusu iletişim kanalı].
- Uygunsuz içerik: gönderi/yorum menüsünden veya profil seçeneklerinden şikâyet oluştur; başka kullanıcıyı profilden engelleyebilirsin.
- Hesap silme: uygulamada Profil → Hesabı yönet → Hesap silme; [doğrulanmış dış silme açıklaması URL'si].
- Acil güvenlik bildirimleri: [görevli ekip ve doğrulanmış kanal]. Yakın ve gerçek tehlikede uygulamadaki inceleme sonucunu bekleme; bulunduğun yerdeki acil yardım hizmetlerine başvur.

Destek talebinde parolanı, tek kullanımlık giriş kodunu, tam ödeme bilgisini veya gereksiz kimlik belgesini paylaşma. [İşletmeci adı], [çalışma saatleri] ve [yanıt hedefi] işletmeci tarafından belirlenecektir. Bu alanlar doldurulmadan çalışan destek hizmeti iddia edilmez. Destek/gizlilik sayfasının ayrı HTTPS barındırılması bir web uygulaması yayını değildir; bu çalışmada dağıtım yapılmaz.

## 6. Moderasyon operasyonunun onaylanacak bölümü

| Süreç | Asgari işletim kararı ve kabul kanıtı |
|---|---|
| Olağan şikâyet | Görevli ekip/vekil, erişim yetkileri, yanıt hedefi, bildirim alındı ve sonuç akışı |
| Acil ihlal | Çocuk güvenliği, rıza dışı mahrem içerik, tehdit ve kişisel bilgi ifşası için öncelik; yetkili kişi ve nöbet/eskalasyon |
| İçerik kaldırma | Gönderi, yorum, profil metni, kullanıcı adı/plaka ve medyanın görünürlüğünü durdurma; cache/süreli medya URL etkisi |
| Tekrarlı ihlal | Uyarı/kısıtlama/askı politikası, kaçınma örüntülerinin değerlendirilmesi, itiraz ve kayıt erişimi |
| Görsel/video | Otomatik sınıflandırıcı bulunmadığında uygulanacak insan incelemesi, kapasite ve erişim güvenliği; metin filtresi yeterli kabul edilmez |
| Çocuk istismarı | Sorumlu kişi; güvenli kısıtlama, delil/saklama ve yetkili makama bildirim yükümlülüğünün hukuken belirlenmesi; hukuki dayanak olmadan süre uydurulmaz |
| Denetim | Yönetici kimliği, işlem, gerekçe ve zaman kaydı; en az yetki/MFA ve yetkisiz erişim testi |

Bu tablo operasyonu kurmaz ve gerçek insan moderasyonu yerine geçmez. Apple 1.2/5 kapsamındaki kabul, çalışan şikâyet düğmesinden daha geniştir.

## 7. App Review notları ve demo planı

### App Review notları — İngilizce taslak

Piyaso is a Turkish-language automotive community app for Antalya. It provides user profiles, garages, social posts, following, likes/comments, optional location sharing, earned in-app coins, gifts, and customization.

Review credentials: [review account email], [password entered only in App Store Connect review information]. Contact: [real review contact name, email and telephone]. No credentials are included in this repository.

Location permission is optional. You can browse the map after declining permission. Sharing starts only after an explicit user action and is stopped when the app leaves the foreground. Displayed positions are approximate; the app is not a navigation or traffic-safety service.

The submitted configuration must be identified here: [build/version and payment mode]. Paid purchases are currently disabled in the development candidate. Earned coins and gifts must not be represented as successful App Store purchases. No Apple/Google OAuth button should be enabled without a configured and tested native sign-in flow.

Report content from its menu, and report/block users from the profile options. Support, privacy policy, terms, and account deletion are reached from account/profile settings. [Insert the final verified paths if labels change.]

Account deletion: [describe the deployed, tested server deletion path and provide a separate disposable review account]. A new password-reauthenticated deletion candidate prepares/fences application data, removes Storage objects and private references, calls Auth Admin DELETE, and checks that the Auth identity is missing. It is disabled by default and not deployed. It requires an exclusive Piyaso Auth scope and an operator-approved free-account-erasure-v1 policy; paid orders, legal holds, administrator accounts and cross-app references are outside the automatic candidate. SQL and mocked Auth tests do not establish hosted Supabase Auth acceptance. These remain submission blockers; do not send this paragraph as a claim of completed deletion.

All review data must be clearly identified as fictional. There is no reviewer-specific hidden behavior, and no real user's data is used for review fixtures. [List any region or entitlement restrictions and provide legitimate test access without bypassing access controls.]

**Review owner checklist:** Gerçek çalışan inceleme hesabı, kesintisiz backend, gerekiyorsa ikinci etkileşim hesabı ve ayrı silinebilir hesap; tüm parolalar yalnız güvenli inceleme alanına girilir. İnceleme bitmeden bu hesaplar otomatik silinmez/şifreleri değiştirilmez. App Review hesabı oluşturulmuş değildir.

### İzole demo veri manifesti

| Hesap/varlık | Hazırlanacak içerik | Güvenlik sınırı |
|---|---|---|
| İnceleme A | Doğrulanmış e-posta, profil, 1 araç, 1 zararsız gönderi, kazanılmış test jetonları | Gerçek kişi/plaka/konum yok; üretim cüzdanı değiştirilmez |
| İnceleme B | Etkileşim/engel/şikâyet hedefi, 1 zararsız yorum | A ile eşleşen test kümesi; kimlik bilgilerinin uygulama içine gömülmesi yok |
| Silme C | Profil, garaj, gönderi, özel medya, jeton/ilişkili test verisi | Tek kullanımlık; başka uygulamaya ait hesap/veri taşımamalı |
| Medya | Hakları doğrulanmış araç fotoğrafı ve kısa zararsız video | Gerçek çocuk veya mahrem içerik yok; EXIF/konum içeriği denetlenir |
| Harita | İzin reddinde kullanılabilir boş/normal harita, sentetik test işareti gerekiyorsa açık demo etiketi | Simülasyon gerçek kullanıcı yoğunluğu olarak sunulmaz |

İzole yerel SQL senaryoları barındırılan Supabase Auth kimliği değildir. Bu manifest hesap oluşturulduğunu veya inceleyicinin giriş yapabileceğini göstermez. Üretime fixtures yüklemek bu belgeyle otomatik yetkilendirilmez.

### 12 adımlı native kabul planı

Her satır için build/hash, cihaz/iOS sürümü, zaman, test hesabı takma adı ve sonuç kaydedilir. Başarısızlıkta ekran/hata kimliği tutulur; parola/token kaydedilmez. Aşağıdaki plan henüz gerçek cihazda çalıştırılmış değildir.

| Adım | İşlem | Beklenen sonuç ve ek kontrol |
|---|---|---|
| 1 | Temiz kurulumla aç | Splash kapanır, başlangıç ekranı görünür; çökme/boş ekran yok. Ağsız açılış anlamlı hata/yeniden deneme sunar. |
| 2 | A demo hesabıyla giriş | Gerçek Auth giriş ve doğrulanmış e-posta; yanlış parola ve süresi dolmuş oturum anlaşılır hata verir. Arka plan/geri dönüşte oturum yenilenir. |
| 3 | Profili görüntüle | Yalnız A'nın verisi; önceki hesabın görselleri/bakiyesi kalmaz. Büyük yazı ve VoiceOver kontrol edilir. |
| 4 | Garaja araç ekle | Doğrulamalar çalışır, kayıt tekrar açınca kalır; başkasının garajına yazılamaz. Kamera/medya izni reddinde güvenli geri dönüş. |
| 5 | Haritayı aç, konumu reddet | Harita kullanılabilir, paylaşım başlamaz. 3D yüklenemezse standart harita/fallback; harita hatası boş ekran üretmez. |
| 6 | Zararsız gönderi paylaş | Metin/medya kayıt ve görünürlük; aşırı boyut/dosya türü reddi; ağ kesintisi aynı gönderiyi iki kez oluşturmaz. |
| 7 | B'yi takip et | Takip durumu sunucuda kalır; takip konum yetkisi vermez. |
| 8 | Beğeni/yorum | Tekrarlı tıklama tutarlı; bildirim doğru hesapta; engelli/gizli içeriğe erişim reddi. |
| 9 | Şikâyet/engel | Gönderi, yorum ve profil raporu yönetim kuyruğuna ulaşır. B'nin içeriği/konumu izin sınırlarına göre kalkar. Yönetici kaldırma ve tekrarlı ihlal kaydı doğrulanır. |
| 10 | Jeton/hediye | Ücretsiz ödül bir kez verilir; hediye bir kez borçlanır. Satış kapalıysa sahte satın alma/başarı yok. Ücretli mod açılırsa sandbox, pending, restore, iade testleri ayrıca zorunlu. |
| 11 | Politika ve destek | Gizlilik/koşullar uygulama içinde açılır; geri dönüş çalışır. Son gerçek destek kanalı ve herkese açık HTTPS URL'ler cihazdan denenir. |
| 12 | C hesabını kontrollü sil | Kimlik doğrulama ve onay; iptal hiçbir veri silmez. Tamamlanınca Auth kimliği ve ilişkili verilerin son durumu doğrulanır, oturum kapanır, eski token/re-login reddedilir. A/B ve başka hizmetlerin verileri değişmez. |

Ek kabul: şifre sıfırlama e-postası gerçek posta kutusuna ulaşmalı; native uygulamaya dönüş doğru hesabı açmalı; destekle temasa geçmeden silme mümkün olmalı; silme sırasında ağ kesilirse yeniden deneme ve tamamlanma sorgusu güvenli olmalı. Hesap silme için yalnız bir test HTTP stub'ı başarı kanıtı değildir.

## 8. App Privacy veri envanteri

**Durum:** App Store Connect formu doldurulmadı. Aşağıdaki eşleme kaynak kod envanteridir; gerçek trafik/log, alt işleyen sözleşmesi ve son native bağımlılık manifestleriyle son kontrol gerektirir. Apple formunda veri kategorisi, amaç, kullanıcıya bağlantı ve izleme ayrı değerlendirilir. Bir alanın isteğe bağlı olması tek başına beyan dışında kalmasını sağlamaz.

| Veri / Apple kategori adayı | Kaynak ve amaç | Hesapla bağlantı | İzleme / tamamlanacak nokta |
|---|---|---|---|
| İsim | Profil adı; uygulama işlevi | Evet | Reklam amaçlı izleme saptanmadı |
| E-posta | Supabase Auth, destek; giriş/güvenlik | Evet | Sağlayıcı log/saklama koşulu onaylanacak |
| User ID | Auth UUID, kullanıcı adı, oturum ilişkisi | Evet | App functionality; JWT/refresh token uygulama verisi gibi yayımlanmaz |
| Kesin/yaklaşık konum | Cihaz sensörü, sunucu pozisyonu, harita görünürlüğü | Evet | Son aktarım hassasiyetini paket trafiğiyle ölç; yaklaşık gösterim kesin konum toplanmadığı anlamına gelmez |
| Fotoğraf/video | Profil, araç, gönderi; içerik paylaşımı | Evet | Özel Storage; EXIF ve üçüncü taraf görüntüleme sınırları |
| Ses verisi | Ses/video yükleme yolu | Evet | Son yapıda erişilebilir işlev/izin ile eşleştir |
| Diğer kullanıcı içeriği | Gönderi, yorum, biyografi, plaka/araç, şarkı adı, sosyal bağlantı | Evet | Plaka, alan/semt ve fotoğraf birlikte kimlik belirleyebilir |
| Müşteri desteği | Şikâyet/destek/silme başvuruları | Evet | Metin ek kişisel veri içerebilir; saklama ve erişim onayı |
| Ürün etkileşimi | Beğeni/takip/engel/ziyaret, günlük ödül, rozet ve görev | Evet | İşlev; dashboard analitiği ayrıca değerlendirilir |
| Satın alma geçmişi | Orders/ledger; şu anda ücretsiz jeton/hediye harcamaları, satış kapalı | Evet | Apple Purchase History beyanını gerçek işlem kapsamıyla eşleştir; finansal ödeme bilgisi toplanıyor varsayma |
| Diğer veriler / güvenlik özeti | E-posta HMAC özeti, davet ve kötüye kullanım önleme kayıtları | Evet veya yeniden ilişkilendirilebilir | Otomatik anonim kabul edilmez; kategori/amaç kararı gerekli |
| Tanılama | Sınırlı hata kodu `ops_events`, backend teknik logları | Loga göre belirlenecek | Üçüncü taraf logları, IP, süre ve hesap ilişkisi incelenmeli |
| IP/ağ metaverisi | Supabase/barındırma/harita istekleri | Sağlayıcıya göre belirlenecek | Veri türü/amaç ve gerçek saklama; üçüncü taraf toplama beyanı incelenmeli |
| Cihaz/push token | Şemada alan var; native APNs/FCM bağlı değil | Etkinleşirse evet | Kod/şema varlığı gerçek toplama kanıtı değildir; etkinleştirmeden önce envanteri güncelle |

Kaynakta reklam SDK'sı/IDFA kullanımı doğrulanmadığı için ATT izni sırf formalite olarak eklenmez. Gerçek izleme devreye girerse Apple koşulları ve kullanıcı izni ayrıca ele alınır. `PrivacyInfo.xcprivacy` App Store Connect gizlilik formunun yerine geçmez. Uygulama manifestinde `NSPrivacyAccessedAPITypes` boş; Capacitor/SDK birleştirilmiş gizlilik raporu Xcode arşivinde kontrol edilmelidir. Gerekli API gerekçe kodları tahmin edilerek eklenmez.

Saklama karar tablosunda her satıra veri sahibi, veri işleyen/ülke, hukuki dayanak, süre, süreyi başlatan olay, aktif DB silme yöntemi, medya/önbellek/yedek silme ve erişim sorumlusu eklenmelidir. Kodda 30 günlük tanılama veya teslimat temizliği bulunması tüm kişisel veriler için 30 gün saklama taahhüdü değildir.

## 9. Yaş derecelendirmesi içerik envanteri

| Başlık | Kaynak durum / App Store Connect'e yanıt için not |
|---|---|
| Kullanıcı üretimi içerik | Var: profil, ad, plaka, gönderi, yorum, görsel/video/ses, bağlantı, şarkı adı |
| Kullanıcı iletişimi | Yorum, takip, hediye/şarkı ithafı var; özel/anonim rastgele sohbet olduğu iddia edilmez |
| Web erişimi | Harita ve dış sosyal bağlantılar var; uygulama içinde sınırsız tarayıcı varmış gibi işaretlenmez, son native davranış kontrol edilir |
| Reklam | Kaynakta doğrulanmış reklam servisi yok; son paket/sağlayıcılar incelenir |
| Şiddet, cinsellik, küfür, madde kullanımı | Amaçlanan katalog içeriği değil; UGC üzerinden oluşabilir. Sıklık cevabı işleyen filtre/insan moderasyonu ve gerçek içerik politikasına göre verilir |
| Kumar/gerçek para oyunları | İncelenen işlevlerde yok; ücretsiz jeton/hediye sistemi nakit kazanma/kumar olarak pazarlanmaz |
| Yarış/tehlikeli sürüş | Harita ve araç teması var; aşırı hız/yarış teşviki olmamalı; araç kullanırken kullanım uyarısı gerekir |
| Yaş doğrulama/ebeveyn kontrolü | Uygulanmış kabul edilmedi; hedef yaş, yaş beyanı ve gerekiyorsa erişim kısıtı kararı bekliyor |
| Sağlık/tıbbi bilgi | İncelenen işlevlerde yok |

Nihai sayı/etiket tahmin edilmez. App Store Connect'in güncel anketi işletmeci tarafından doğru yanıtlanmalı; mağaza metni ve görseller her izleyiciye uygun olmalı. UGC filtresi olmadan “kötü içerik yasak” metni tek başına düşük yaş derecesi gerekçesi değildir.

## 10. Ekran görüntüsü planı

**Hiçbir nihai App Store ekran görüntüsü üretilmedi.** Son imzalı native build'den desteklenen ekran sınıflarında alınacak. Web görüntüsünü telefon çerçevesine yerleştirmek native test kanıtı değildir. Boyut/cihaz zorunlulukları yükleme günündeki App Store Connect şartlarından alınır.

| Sıra | Sahne | Doğruluk ve gizlilik kontrolü |
|---|---|---|
| 1 | Antalya haritası, bölge görünümü | Gerçek veri veya açıkça kurgusal test verisi; kesin özel konum görünmez; trafik/navigasyon iddiası yok |
| 2 | Kullanıcı profili ve garaj | Gerçek kişiye ait e-posta/plaka yok; hakları doğrulanmış görsel; onaylı Piyaso tasarımı |
| 3 | Araç ekleme/özelleştirme | Gerçekte çalışan seçenekler; ücretsiz/jeton gereksinimi doğru |
| 4 | Sosyal akış, gönderi ve yorum | Zararsız örnek içerik, gerçek kişi verisi yok; dolu ekran gerçek etkinlik gibi yanıltılmaz |
| 5 | Günlük ödül ve hediye | Ücretsiz kazanım ile ücretli satın alma ayrımı; satış kapalıysa fiyat/satın alma reklamı yok |
| 6 | Konum ve güvenlik tercihleri | Gerçekte çalışan izin/engel/şikâyet; hayalet işlevi yanlış anlatılmaz |

Dosya adında build, cihaz, dil ve sıra; dahili kayıtta test kanıtı ve kullanılan sentetik hesap seti tutulur. Status bar ve safe area kırpılmamalı; Dynamic Island/çentik içerik örtmemeli. Alt yazılar gerçek işlevi açıklamalı; mevcut olmayan premium, CarPlay, push veya gerçek zamanlı trafik vaat etmemeli. Preview video gerekiyorsa uygulamanın ekran kaydından hazırlanmalı. Creative assets (2.3.14) ayrı pazarlama varlıklarıdır; app-in-use screenshot yerine geçirilmez.

## 11. Kaynaklar ve tamamlanma kapısı

Resmî kaynaklar (29 Ekim 2026 erişimi):

- Apple App Review Guidelines: https://developer.apple.com/app-store/review/guidelines/
- 16 Ekim 2026 değişiklik duyurusu: https://developer.apple.com/news/?id=92th7e5i
- Hesap silme: https://developer.apple.com/help/app-review/guideline-reference/5-1-1-account-deletion
- App Privacy: https://developer.apple.com/app-store/app-privacy-details/
- Yaş derecelendirmesi: https://developer.apple.com/help/app-store-connect/manage-app-information/set-an-app-age-rating/

Aday silme ve hayalet düzeltmeleri için son kabul raporundaki değişen dosya/test listesi esas alınır; bu belgede aday durumları üretim davranışı olarak sunulmaz.

Kod kanıtı: `public/privacy.html`, `terms.html`, `location-privacy.html`, `community-rules.html`, `content-policy.html`, `release-readiness.js`, `deletion-request.mjs`, `supabase-account.js`, `social-safety.js`, `cloud-domain.js`, `ghost-profiles.js`, `mobile/ios/App/App/PrivacyInfo.xcprivacy`, `app-store/release-status.json`, `docs/operations/store-purchases.md`, `docs/release-audit/2026-10-28/STORE-REPORT.md`.

**Gönderimden önce gereken gerçek bilgiler:** işletmeci/veri sorumlusu ve destek adresi; inceleme iletişimi; yaş/hedef kitle ve moderasyon sorumluları; veri türü bazında saklama/yasal istisna; Auth'ın ortak kullanımına ilişkin karar; ücretli ürünlerin ilk sürüm kararı; Apple Developer/Team/Bundle ID; demo hesapları; son native test ve ekran görüntüleri. Bu belge bu eksiklerin giderildiğini iddia etmez.
