# Piyaso — mobil yayın hazırlığı

29 Ekim 2026. **APP STORE GÖNDERİMİNE HAZIR DEĞİL.**

Güncel kabul raporu: [Apple uyumluluk ve kabul](../docs/apple-review/2026-10-29/REPORT.md). Başlangıç raporu: [28 Ekim mağaza denetimi](../docs/release-audit/2026-10-28/STORE-REPORT.md).

Ücretsiz jeton/sosyal/garaj işlevleri korunur. Ücretli satın alma kapalıdır; native Premium ekranında yapılandırılmamış fiyat/satın alma/restore kontrolleri gösterilmez. Gerçek StoreKit testi yapılmadı.

Şifreyle yeniden doğrulayan, Storage/veri ve gerçek Auth kimliğini silmeyi hedefleyen endpoint adayı eklendi. Aday kapalı ve üretime uygulanmamıştır. Ayrılmış Auth, onaylı saklama politikası ve gerçek Supabase Auth/Storage kabulü gerekir; yalnız talep oluşturma başarı sayılmaz. Ayrıntı: [silme kapsamı](../docs/apple-review/2026-10-29/ERASURE-OPERATIONS.md).

Capacitor 8.5.3 korunur. Yerel web build ve iOS sync, Xcode archive veya gerçek iPhone/TestFlight testinin yerine geçmez. İşletmeci/destek/nihai hukuk metinleri, UGC-insan moderasyonu, gerçek e-posta akışları, cihaz/izin/medya/performans ve mağaza formları açık kalır. Üretim dağıtımı yapılmadı.
