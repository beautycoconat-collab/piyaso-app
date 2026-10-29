import {readFile} from 'node:fs/promises';
import {fileURLToPath} from 'node:url';
const status=JSON.parse(await readFile(new URL('../../app-store/release-status.json',import.meta.url),'utf8'));
export function releaseBlockers(s,platform='ios'){
 if(!['ios','android'].includes(platform))throw Error('Platform ios veya android olmalı.');
 const common={backendLive:'Canlı sunucu',realAuthenticationTested:'Gerçek Auth giriş testi',serverEnforcedPremiumTested:'Sunucuda Premium yetkilendirmesi',serverCreditLedgerTested:'Sunucuda atomik kredi kaydı',serverAccountDeletionTested:'Gerçek hesap ve veri silme',moderationInboxLive:'Çalışan moderasyon/destek',finalPrivacyPolicyApproved:'İşletmeci bilgileriyle son gizlilik metni',publicDeletionRequestAvailable:'Uygulamayı yüklemeden erişilen silme talebi',backupRestoreDrillApproved:'Üretim yedekleme ve geri yükleme kabulü',ugcSafetyApproved:'UGC ve çocuk güvenliği operasyonu',storeScreenshotsCapturedFromFinalBuild:'Son sürümün gerçek ekran görüntüleri',ageRatingQuestionnaireCompleted:'Yaş derecelendirme formu'};
 const native=platform==='ios'?{bundleIdOwnershipConfirmed:'Bundle ID hesabında doğrulanmalı',appleDeveloperReady:'Apple Developer hesabı',deviceAndTestFlightTested:'iPhone ve TestFlight testleri',xcode26ArchiveValidated:'Xcode 26+ imzalı arşiv doğrulaması'}:{androidApplicationIdOwnershipConfirmed:'Android Application ID sahipliği',googlePlayConsoleReady:'Google Play Console hesabı',androidDeviceTested:'Gerçek Android cihaz testi',androidAABValidated:'İmzalı Android AAB doğrulaması',googleDataSafetyCompleted:'Google Data Safety formu'};
 const payment=s.paidPurchasesEnabled===true?(platform==='ios'?{appleIAPVerifiedOnServer:'Apple satın alma doğrulaması',purchaseRestoreTested:'Satın alımları geri yükleme testi'}:{googleBillingVerifiedOnServer:'Google satın alma doğrulaması',googlePurchaseRestoreTested:'Google satın alma geri yükleme testi'}):{};
 const errors=Object.entries({...common,...native,...payment}).filter(([k])=>s[k]!==true).map(([,label])=>label);
 if(typeof s.paidPurchasesEnabled!=='boolean')errors.push('Ücretli satın alma kararı açıkça belirtilmeli');
 if(!s.operatorName?.trim())errors.push('İşletmeci adı');if(!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(s.supportEmail||''))errors.push('Destek e-postası');
 if(s.stage!=='production')errors.push('Demo yerine production sürümü');return errors;
}
if(process.argv[1]===fileURLToPath(import.meta.url)){const platform=process.argv[2]||'ios',errors=releaseBlockers(status,platform);if(errors.length){console.error((platform==='ios'?'APP STORE':'GOOGLE PLAY')+' GÖNDERİMİ HAZIR DEĞİL\n'+errors.map(x=>'• '+x).join('\n'));process.exitCode=1}else console.log('Belirtilen gönderim kontrolleri tamam. Mağaza onay garantisi değildir.');}
