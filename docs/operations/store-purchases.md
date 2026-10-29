# Piyaso mağaza satın alma sözleşmesi — 28 Ekim 2026

Durum: tasarım ve gönderim engeli; çalışan Apple/Google satın alma entegrasyonu değildir. Ücretsiz kazanılan jeton akışı korunur. `paidPurchasesEnabled:false` mevcut sürümde mağaza satın alma entegrasyonunun kapalı olduğunu belirtir; gelecekteki ücretli ürün kararını iptal etmez.

## Sunucu doğrulaması

1. Kimliği doğrulanmış kullanıcının başlatma isteği, sunucunun ürün/platform/uygulama kimliği/ortam izin listesine uymalıdır. İstemciden gelen fiyat, miktar veya `verified:true` kabul edilmez.
2. Apple imzalı işlem ve sunucu bildirimleri sertifika zinciri, bundle ID, ortam, ürün, transaction ID ve appAccountToken eşleşmesiyle doğrulanmalı; gerektiğinde App Store Server API ile sorgulanmalıdır. Google purchaseToken, package/product eşleşmesi ve sahipliği Play Developer API üzerinden sorgulanmalıdır. Google RTDN tek başına ödeme kanıtı değildir; Apple bildirim gövdesi de doğrulanmadan kullanılmaz.
3. Bekleyen/başarısız işlemlere jeton verilmez. Sağlayıcının doğrulanmış işlemi ile kullanıcı hesabı kalıcı olarak eşleştirilir. Google purchaseToken ve Apple transaction ID için platformla birlikte UNIQUE kısıtı gerekir; bildirim event ID ayrıca tekilleştirilir.
4. Satın alma kaydı, cüzdan kilidi, tekil kredi ledger kaydı ve bakiye değişikliği tek veritabanı transaction'ında gerçekleşir. Tekrar istek aynı sonucu döndürür. Google acknowledge/consume işlemi kalıcı kayıt sonrası yeniden denenebilir kuyrukla yapılır; başarısız ağ isteği yeniden kredi oluşturmaz.
5. İade/iptal/voided işlem sağlayıcıdan doğrulanır. Orijinal satın almaya bağlı tekil ters ledger kaydı oluşturulur. Harcanmış jeton için mevcut bakiyeyi körlemesine negatif yapmadan borç/kısıtlama ve itiraz prosedürü tanımlanmalıdır. Ücretsiz kazanılmış jeton ayrı kaynak olarak korunur. Abonelik iptali ile gerçekleşmiş iade aynı olay sayılmaz.
6. Geri yükleme ve hesap değiştirme işlemleri aynı satın alımı iki hesaba kazandırmamalıdır. Bildirim tekrarları, gecikmeli/sırasız olaylar, iade sonrası tekrar bildirim ve pending→purchased geçişi sandbox hesaplarıyla test edilmelidir.

## Uygulamadan önce zorunlu olanlar

Apple/Google hesapları, ürün kimlikleri, sözleşmeler, sunucu API kimlik bilgileri ve secret yönetimi; gerçek sağlayıcı doğrulaması; ledger migration'ları; sandbox satın alma/geri yükleme/iade testleri. Bunlar olmadan ödeme düğmesi etkinleştirilmez. Mevcut sahte kredi ve sipariş RPC çağrılarının reddi izole testte doğrulanmıştır; bu, mağaza doğrulamasının uygulanmış olduğu anlamına gelmez.

Resmî kaynaklar: https://developer.apple.com/app-store/review/guidelines/ · https://developer.apple.com/documentation/appstoreserverapi · https://developer.android.com/google/play/billing/security · https://support.google.com/googleplay/android-developer/answer/9858738
