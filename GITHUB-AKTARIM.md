# Piyaso ana uygulaması — GitHub aktarım paketi

29 Ekim 2026, Türkiye saati. Hedef depo adı: `beautycoconat-collab/piyaso-app`.

GitHub bağlantısında bu depo bulunamadı; mevcut bağlantı yeni depo oluşturma işlemi sunmuyor. GitHub'a push yapılmadı. Bu ZIP, talep edilen eksiksiz kaynak alternatifi olarak hazırlandı. Üretim dağıtımı, üretim veritabanı değişikliği ve müzik deposu değişikliği yapılmadı.

## İçerik ve kaynak

- Ana uygulama: mevcut `audit/apple-compliance-20261029` çalışması; kaynak commit `4a6361bd0567fffe6074ce3e6f970256a82692d7`. Uygulama yeniden oluşturulmadı.
- Yönetim paneli: `admin/`; mevcut `audit/piyaso-release-20261028` geçmişi ana uygulama geçmişine ayrı bir merge parent olarak eklendi. Özgün yönetici yetkileri ve testleri korundu.
- Supabase: mevcut 43 migration, SQL adayları/rollback dosyaları ve Edge Functions korunur. Apple denetimindeki aday SQL/Edge düzeltmeleri üretime uygulanmış sayılmaz.
- Mobil: Capacitor yapılandırmaları, iOS ve Android proje kaynakları, sanat varlıkları ve kilit dosyaları korunur. Gerçek imzalama anahtarları dahil değildir.
- Bağımlılıklar: kökte `package.json` / `pnpm-lock.yaml`; `mobile/` ve `admin/` içinde `package.json` / `package-lock.json`. Tekrar kurulabilen `node_modules` ve derleme önbellekleri pakete alınmaz. Kurulum için paket kayıtlarına ağ erişimi gerekir.
- Testler ve ham sonuçlar: `tests/`, `scripts/test-*.mjs`, `admin/tests/`, `docs/github-transfer/2026-10-29/evidence/`.
- Güvenli Git geçmişi: ZIP içindeki `git-history/piyaso-app.bundle`; dosya bütünlüğü listesi: `TRANSFER-MANIFEST.sha256`.

## Anahtarlar ve geçmiş

`.env`, gerçek API anahtarları, Supabase sunucu secret'ları, erişim token'ları, sertifika özel anahtarları, imzalama dosyaları ve yerel araç durumları dahil edilmez. `admin/.env.example` yalnız yer tutucu içerir. `.gitignore` iç içe bağımlılıkları, ortam dosyalarını, yerel Supabase ayarlarını, Python önbelleklerini ve imzalama dosyalarını kapsar.

Tarayıcıda kullanılabilen Supabase publishable anahtarı da talep doğrultusunda çıkarılmıştır. Tarayıcı hesap entegrasyonu `SUPABASE_PUBLISHABLE_KEY` ile üretilen ve Git tarafından yok sayılan `public/supabase-config.local.js` dosyasını okur. Sunucu/service-role anahtarı bu dosyaya yazılamaz; oluşturma komutu bu sınıftaki girdiyi reddeder. Sunucu secret'ları yalnız ilgili sunucu secret deposunda tutulmalıdır. Yapılandırma olmadan gerçek hesap bağlantısı çalışmaz; çevrimdışı bir Supabase servisi sunulmaz.

Önceki commit'ler publishable anahtar içerdiğinden güvenli geçmişte bu değerler yer tutucuyla değiştirildi ve üretilmiş Python bytecode çıkarıldı. Commit sırası, ebeveyn ilişkileri, yazarlar ve tarihler korunur; bu işlem commit SHA'larını değiştirir. Kaynak SHA ile güvenli SHA eşlemesi `docs/github-transfer/2026-10-29/commit-map.json` içindedir. Gizli değer içerebilen ham `.git` yapılandırması aktarılmaz.

## Yerel kurulum ve doğrulama

Node.js 24 ve `pnpm@11.25.0` kullanın. Aşağıdaki komutlar yalnız yerel kurulum/derleme/test içindir.

```bash
corepack enable
pnpm install --frozen-lockfile
npm ci --prefix mobile
npm ci --prefix admin
```

Gerçek hesaplarla çalışmadan önce yalnız publishable anahtarı `SUPABASE_PUBLISHABLE_KEY` ortam değişkenine güvenli biçimde verin. Değeri bu dosyaya veya Git'e yazmayın. Hesap entegrasyonlarının mevcut proje URL'si korunmuştur. Canlı HTTP testleri de anahtarı aynı ortam değişkeninden okur; varsayılan doğrulamada çalıştırılmaz.

```bash
node scripts/prepare-startup.mjs
node --test --test-force-exit tests/*.test.mjs tests/*.test.cjs
node --test scripts/test-mobile-database.mjs scripts/test-mobile-journeys.mjs scripts/test-apple-database.mjs
npm test --prefix admin
npm run build --prefix admin
npm run validate --prefix admin
npm run build
node node_modules/typescript/bin/tsc --noEmit
npm run sync:ios --prefix mobile
python3 scripts/check-repository-secrets.py .
```

Son komut Git bundle'dan geri yüklenen gerçek bir Git checkout'unda çalışır. Desen taraması tüm olası gizli bilgi biçimlerinin yokluğunu matematiksel olarak kanıtlamaz.

## Git geçmişini geri yükleme ve ayrı depoya aktarma

ZIP kökünden:

```bash
git clone --branch audit/apple-compliance-20261029 git-history/piyaso-app.bundle ../piyaso-app-git
cd ../piyaso-app-git
git remote remove origin
git bundle verify ../piyaso-app/git-history/piyaso-app.bundle
git fsck --full
```

GitHub'da boş `piyaso-app` deposu oluşturulup erişim verildikten sonra yalnız bu yeni depoyu hedefleyin. `piyaso-music-cloudflare` adresini kullanmayın. Mevcut dolu bir deponun üstüne force push yapmayın.

```bash
git remote add origin https://github.com/beautycoconat-collab/piyaso-app.git
git push origin audit/apple-compliance-20261029
git push origin audit/apple-compliance-20261029:main
```

Bu komutlar burada çalıştırılmadı. GitHub depo bağlantısı veya uzak commit doğrulaması yapılmış gibi sunulmaz.

## Doğrulama sonuçları ve sınırlar

391/391 test başarılı: ana uygulama 316, yönetim paneli 34, izole veritabanı/medya/kurtarma 41. Başarısız veya atlanan test yok. Web derlemesi, TypeScript, JS/Python sözdizimi, yönetim paneli derlemesi ve artifact doğrulaması, iOS sync ve anahtar yapılandırma kontrolleri başarılı.

İzole PostgreSQL/PGlite ve taklit Auth/Storage kabulü gerçek hosted Supabase kabulü değildir. Xcode archive, imzalı IPA, fiziksel cihaz, TestFlight ve gerçek hesap silme/Storage testleri yapılmadı. Apple release gate beklenen exit 1 ile gönderimi engellemeyi sürdürüyor. Önceki Apple raporundaki açık işler korunur; bu aktarım App Store onayı anlamına gelmez.
