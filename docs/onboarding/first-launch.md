# Piyaso ilk açılış ve hesap akışı

Akış: bulutlu karşılama → şehirde keşif → araç sosyal profili → plaka önizlemesi → araç kişiselleştirme önizlemesi → hazır ekranı. Üstteki Giriş yap düğmesi mevcut e-posta ve sosyal giriş ekranını açar. Yeni hesaplar profil adı/kullanıcı adı/semt hazırlığını tamamlar. Misafirler tanıtımı bitirip uygulamayı inceleyebilir; bu işlem gerçek hesap oluşturmaz. Tamamlanmış hesaplar yeniden tanıtıma zorlanmaz. Profildeki “Piyaso tanıtımını gör” düğmesi akışı tekrar açar. İnceleme bağlantısı: `/?onboarding=1`.

## Hesap bağlantısı

Mevcut Supabase hesabı, parola girişi, doğrulama, şifre yenileme, profil komutu ve sunucu cüzdanı kullanılır. Yeni bir kullanıcı/veritabanı veya ikinci bir kimlik sistemi eklenmedi. Yeni profil güncellemesi yalnızca kullanıcı adı, profil adı ve semti gönderir. Canlı konum paylaşımı ve bildirim izinleri tanıtım ekranlarından otomatik istenmez.

Google/Apple butonları `/auth/v1/settings` yanıtındaki gerçek sağlayıcı durumunu kullanır. 27 Ekim 2026 kontrolünde ikisi de kapalı, e-posta açık. Kapalı sağlayıcılar arayüzde “Yakında” durumundadır; çalışmayan bir giriş başarısı gösterilmez. Açıldıklarında kod değişmeden kullanılabilirler.

Sosyal girişte rastgele 32 bayt PKCE doğrulayıcısı ve SHA-256 challenge kullanılır. Rastgele dönüş nonce'u yalnız bu tarayıcı oturumunda saklanır; dönüşte eşleşmesi ve süresi denetlenir. Kod URL'den hemen temizlenir ve tek kullanımlık verifier kaldırılır. Oturum Supabase `/user` ve mevcut hesap bundle komutuyla doğrulanmadan aktif olmaz. İstemcide client secret/service role bulunmaz.

## Google bağlantısını açmak

Google Auth Platform'da uygulama için Web OAuth istemcisi hazırlanır. Authorized JavaScript origin:

`https://kiyi-antalya-tur.modesttuna8.chatgpt.site`

Authorized redirect URI:

`https://oswpkwwbjwyktuqcakhr.supabase.co/auth/v1/callback`

Google Client ID ve Client Secret, Supabase projesinin Authentication → Sign In / Providers → Google bölümüne girilip sağlayıcı açılır. Gerekli kapsamlar yalnız temel profil, e-posta ve OpenID'dir. Google uygulamasının yayın/test kullanıcısı ayarları ayrıca tamamlanır.

## Apple bağlantısını açmak

Apple Developer hesabında Sign in with Apple destekli App ID ile ilişkili Services ID, web domaini ve return URL hazırlanır. Return URL aynı Supabase callback adresidir. Apple sağlayıcısının Services ID, Team ID, Key ID ve imzalı istemci secret ayarları Supabase panelinde tamamlanır. Özel `.p8` anahtarı veya client secret kaynak koduna veya sohbete konulmaz. Web OAuth Apple secret anahtarı altı ayda bir yenilenmelidir.

## Supabase dönüş adresleri

Authentication → URL Configuration altında Site URL mevcut üretim kökü olmalı. Redirect URL allow list, bu üretim kökü için `https://kiyi-antalya-tur.modesttuna8.chatgpt.site/**` desenini (veya query parametrelerine izin veren eşdeğer kesin deseni) içermeli; başka alan adları eklenmez. Frontend dönüşü aynı origin'deki `/?piyaso_auth=1&auth_state=<rastgele>` adresidir. Şifre yenileme `auth-recovery.html` kullanır. Sağlayıcı etkinleştirildikten sonra gerçek bir kullanıcıyla izin ekranı, iptal, dönüş, yenileme ve çıkış uçtan uca kontrol edilmelidir.

Kaynaklar:
- https://supabase.com/docs/guides/auth/social-login/auth-google
- https://supabase.com/docs/guides/auth/social-login/auth-apple
- https://supabase.com/docs/guides/auth/sessions/pkce-flow
- https://github.com/supabase/auth-js/blob/master/src/GoTrueClient.ts

## Kontroller

`node --test tests/first-run-flow.test.mjs tests/first-run-auth.test.mjs tests/supabase-account.test.mjs`

Yeni/geri dönen kullanıcı, misafir/hesap ayrımı, geri/ileri/atla geçişleri, profil ön doldurma, kapalı sağlayıcı, PKCE challenge/nonce/süre denetimi, e-posta doğrulama gerekliliği, dar profil payload'ı, oturum iptali ve sunucu bakiyesi izolasyonu test edilir. Yerel preview altyapısı mevcut başka vinext süreciyle çakıştığından mobil görsel kontrol yayımlanan sürümde yapılır. Gerçek Google/Apple girişi sağlayıcı ayarları beklenirken doğrulanmış sayılmaz.

## 28 Ekim 2026 görsel yenileme

Referanslardaki lavanta, pembe ve şeftali bulutlar, mor/pembe aksiyonlar, harita pinleri, Antalya sahil sahnesi ve araç sosyal profil görseli uygulandı. Beş ilerleme noktası ve geri/ileri düğmeleri kullanılır. Plaka il kodu/harf/rakam alanları doğrulanır; girilen plaka sonraki kişiselleştirme ekranındaki araçta gösterilir. Garaj tanıtımında renk, jant, kalp aksesuarı ve plaka stili mevcut araç çizimiyle önizlenir. Bunlar yerel tanıtım önizlemeleridir, kullanıcının gerçek aracını veya hesabını değiştirmez. Gerçek araç kaydı mevcut garajdan yapılır. Görseller built-in Imagegen ile üretildi ve public/assets/onboarding altında WebP olarak optimize edildi.

## Kullanıcının sağladığı görsellerle güncelleme

1. Karşılama ekranında kullanıcı tarafından sağlanan pastel arka plan ve Piyaso logosu kullanılır. Önceki metin logo ve ekstra taç kaldırıldı.
2. Keşif ekranında kullanıcının verdiği harita üzerinde, mevcut `carWithOwner` ve `assets/map-car.png` işaretçileri kullanılır. Dört araç ve profil, haritadaki iki ana yol boyunca ayrı bir HTML katmanında requestAnimationFrame ile beraber ilerler. Aynı orijinal carWithOwner çıktısı kullanılır; SVG foreignObject ve SMIL gerekmez. Durdur/başlat denetimi vardır; hareket azaltma tercihinde animasyon duraklatılır. Bunlar tanıtım animasyonlarıdır, gerçek konum verisi veya konum izni kullanılmaz.
3. Sosyal profil tanıtımı korunur.
4. Plaka tanıtımında kullanıcının verdiği 07 PYS 01 görseli kullanılır. Başlıklar, metinler, form alanları ve devam akışı korunur.

Yeni dosyalar `public/assets/onboarding/welcome-sky-v2.webp`, `city-map-v2.webp`, `piyaso-logo-v2.webp`, `license-plate-v2.webp`. Logo ve plakanın dış fonları built-in Imagegen background-extraction düzenlemesiyle kaldırıldı: mevcut şekil, yazı, renk, doku ve perspektif korunarak yalnız dış beyaz/kareli zemin gerçek alfa şeffaflığa dönüştürüldü. Arka plan ve harita JPEG’leri yalnız WebP olarak kodlandı. Tarayıcı kontrolünde görseller yüklendi, araçların konumları zamanla değişti ve durdurma işleminden sonra sabit kaldı.

## Mobil görünürlük düzeltmesi ve karşılama kompozisyonu

Haritanın araç/profil işaretçileri SVG foreignObject katmanından normal HTML katmanına taşındı. Harita görselinin object-fit:cover ölçeği ve merkez kırpması hesaplanıp yolların görsel koordinatlarıyla eşleştirilir. İşaretçiler ilk karede çizilir; durdurma, yeniden başlatma ve sayfadan ayrılmada animasyon temizliği korunur. Araçlar sürekli ekran dışına çıkmasın diye rotalar görsel içindeki yol kesimleriyle sınırlandı.

Karşılama; kullanıcının verdiği logo, bulut arka planı, altın taç, dört konum pini, slogan, alt buton ve ilerleme noktalarıyla yeniden düzenlendi. Mobilde eski giriş tasarımından kalan düz arka plan kaldırıldı. Gerçek telefon durum çubuğu taklit edilmez.

390 × 800 ve 390 × 654 CSS pikselde görsel kontrol yapıldı. Dört HTML işaretçisinin görünür ve görsellerinin yüklenmiş olduğu, konumlarının zamanla değiştiği, durdurulduğunda aynı kaldığı ve yeniden başlatılabildiği doğrulandı. Bu kontroller bulut Chrome tarayıcısındadır; fiziksel iOS Safari testi yapılmadı. Görsel kanıt: [mobil ekranlar](mobile-entry-proof-v3.jpg).

## Yeni yol görseli ve slogan

Kullanıcının sağladığı yeni bulutlar üzerindeki kıvrımlı yol görseli `public/assets/onboarding/cloud-road-v4.webp`, yeni Piyaso logosu `piyaso-logo-v4.webp` olarak kullanıldı. İlk görseldeki yerleşime göre logo üst bölüme, slogan hemen altına ve başlayalım butonu alt bölüme konumlandırıldı; taç ve konum pinleri kompozisyonu tamamlar. Metin tam olarak “Arabana özel sosyal medya hesabı” oldu. İkinci ekranın başlık/açıklama grubu normal boyutta 19, kısa boyutta 14 CSS piksel yukarı taşındı. Diğer ekran içerikleri ve araç hareketi korunur.

Logo checkerboard fonu built-in Imagegen ile background-extraction düzenlemesinden geçirilip gerçek alfa şeffaflığa dönüştürüldü. İstem: yalnız dış kareli zemini ve pinin iç boşluğunu şeffaflaştır; yazı, renk, oran, parlaklık ve perspektifi koru; yeniden tasarlama ve taç ekleme. Yol fotoğrafı yalnız WebP olarak kodlandı. 390 × 800 ve 390 × 654 boyutlarda kontrol edildi. Görsel kanıt: [yeni mobil giriş](mobile-entry-proof-v4.jpg).
