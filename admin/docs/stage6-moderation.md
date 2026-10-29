# Aşama 6 moderasyon genişletmesi

Mevcut Şikâyetler ve İçerik Moderasyonu sayfaları kullanıldı. `src/operations.js` durum filtresi, şikâyetten içerik/karar geçmişi, içerik gizleme ve süreli hesap kısıtlama eylemleri sunar. BFF oturumu, MFA ve mevcut sunucu rolleri korunur. SQL kaynağı ana Kıyı uygulamasının `supabase/migrations/*stage6*.sql` dosyalarıdır; canlı ortak veritabanına uygulanmıştır. Eski temel şema dosyalarını mevcut veritabanına yeniden uygulamayın.

`npm ci --ignore-scripts` sonrası `npm test`: 34 geçti, 0 başarısız. İlk denemede kurulu olmayan PGlite dört test dosyasını engellemişti; bağımlılık kurulduktan sonra düzeldi. `npm run build` ve `npm run validate` başarılı. Ana uygulamadaki `tests/stage6-admin-http.py` ile gerçek TOTP MFA ve geçici moderatör hesabı üzerinden şikâyet inceleme, karar, içerik gizleme, audit ve süreli askı test edildi; normal hesabın yetkisiz isteği reddedildi. İki geçici hesabın tamamı temizlendi.

Tam rapor ana uygulama deposundaki `docs/admin/stage6-report.md` içindedir. Aşama 7'ye geçilmedi.
