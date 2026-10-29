# Hesap silme adayının kapsamı ve kabul koşulları

29 Ekim 2026. Bu dosya bir işletmeci onayı veya canlı dağıtım kaydı değildir.

Yeni Edge endpoint: `piyaso-delete-account`. Varsayılan kapalıdır. Sunucu `PIYASO_ACCOUNT_DELETION_ENABLED=true`, `PIYASO_AUTH_SCOPE=exclusive`, `PIYASO_ERASURE_POLICY=free-account-erasure-v1` değerlerini almadan hiçbir hesap üzerinde çalışmaz. Bu değerler test geçsin diye üretimde tanımlanamaz; önce aşağıdaki koşullar sağlanmalıdır. İstemci bu değerleri veremez.

## Kapsam

Yalnız e-posta/parolalı, Piyaso'ya ayrılmış Auth sistemindeki ücretsiz hesaplar. Diğer uygulama kayıtları, başka bucket'a ait sahiplik, yönetici/denetim geçmişi, ücretli sipariş veya açık yasal saklama varsa işlem durur. Mevcut proje başka uygulamaları da içerdiğinden `exclusive` olduğu ileri sürülmedi. SQL kontrolü yalnız gerçek FK ilişkilerini görür; FK'sız ortak kimlik kullanımı için işletmecinin kapsam incelemesi zorunludur. OAuth hesapları için parola varsayımı uygulanamaz; SIWA açılırsa token iptali ve uygun yeniden doğrulama ayrıca uygulanmalıdır.

## Veri davranışı — onaya sunulan ücretsiz hesap politikası

| Veri | Aday davranışı | Açık karar |
|---|---|---|
| Auth kullanıcı kimliği/oturumlar | Parolayla tekrar doğrulama, global logout, Auth Admin hard delete; yokluğu GET ile doğrulanır | Ayrılmış Auth, gerçek endpoint ve eski JWT testi |
| Profil, plaka, konum | Önce görünürlük ve yeni RPC'ler kapanır; Auth cascade ile silinir | Gerçek cihaz ve gerçek sunucu doğrulaması |
| Garaj, özelleştirme, gönderi, yorum, beğeni, oy, takip/engel/favori, ziyaret, bildirim | Auth cascade ile ilişkili kayıtlar silinir | FK'sız referanslar için nihai envanter |
| Medya | Registry + orphan owner prefix listesi; 100'lük batch ile Storage API delete; nesne kalırsa purge reddi | Gerçek object store, timeout ve yeniden deneme kabulü |
| Ücretsiz jeton/cüzdan/hediye/ledger ve ödül tanımlayıcıları | Silinir; jeton gerçek paraya çevrilmez | Hediye/ödül ve kötüye kullanım kayıtlarının tutulması gerekiyorsa alternatif anonimleştirme politikası |
| Destek/şikâyet/sanction kişisel kayıtları | Ücretsiz hesap politikasına göre temizlenir | Hukuki saklama incelemesi, `erasure_holds` ile durdurma |
| Ücretli finansal kayıtlar | Bu aday silmez; işlemi başlatmadan reddeder | Yasal saklama, anonimleştirme ve abonelik politikasının uygulanması |
| Yedekler/sağlayıcı logları | Bu endpoint temizlemez | İşletmeci saklama süresi, rotasyon ve restore sonrası yeniden silme listesi |

Hiçbir yasal saklama süresi uydurulmadı. `free-account-erasure-v1` bir teknik seçenek adıdır; hukuki yeterlilik beyanı değildir.

## Sıra ve başarısızlık

1. Mevcut bearer kullanıcı Auth `/user` ile doğrulanır. E-posta request body'den alınmaz.
2. Güncel parola ile yeni Auth token alınır; kimliği ilk kullanıcıyla aynı olmalıdır.
3. SQL service-role preflight kapsamı doğrular. Ortak media-worker kilidi altında pending upload varsa durur. Hazırlık profili kullanıma kapatır, paylaşımı ve konum noktasını kaldırır; yeni rezervasyonlar engellenir.
4. Oturumlar iptal edilir. Medya API ile temizlenir. Kalan medya varsa ilerlenmez.
5. Özel tablolardaki kişisel referanslar temizlenir; Auth Admin DELETE çağrılır. Cascade ile bağlı uygulama kayıtları silinir.
6. Auth GET yalnız 404 döndürürse `deleted/authDeleted=true` döner. Başka sonuçta başarı gösterilmez.
7. İstemci tamamlanmada uygulamanın yerel verilerini ve oturumu temizler, konumu durdurur. Parola hiçbir sonuçta formda bırakılmaz.

Auth, DB ve Storage arasında tek dağıtık transaction yoktur. Kısmi hata hesabı görünmez durumda bırakabilir. Ağ kesintisi sonrası retry/worker işletimi ve tamamlanma teyidi gerçek servislerle ayrıca kabul edilmelidir; adayın canlıya açılmasının ön koşuludur. Kullanıcı yeniden doğrulayabilir; teknik başarısızlıkları destek talebine çevirip tamamlanmış saymak yasaktır. HTTP yanıtı kaybolduktan sonra silinmiş hesabın tekrar giriş yapamaması tek başına istemci başarı kanıtı değildir.

## Güvenli uygulama sırası

Üretim dışı ayrılmış Supabase projesi erişimi → gerçek Auth/Storage ile izole test kullanıcıları → SQL adaylarını tek migration olarak Supabase CLI/advisors akışıyla oluşturma → sunucu secret'larını owner onayıyla tanımlama → endpoint'i yalnız test ortamına dağıtma → hata/yeniden deneme ve eski JWT testleri → işletmeci saklama kararları → kontrollü üretim değişikliği.

Mevcut üretimde kullanıcı veya Auth silinmedi. Yeni SQL/Edge üretime uygulanmadı. Mevcut `serverAccountDeletionTested=false` korunur.
