# Changelog

Bu dosya projedeki surum degisimlerini takip eder.

## [0.1.6] - 2026-02-25

### Added

- Hadis modulu yeniden tasarlandi: `Gunluk / Kitaplar / Favoriler` sekmeli yapi.
- Kitap ici okuma deneyimi eklendi: `HadithReaderView` (bolum, hadis kartlari, onceki/sonraki gezinme).
- Hadis veri semasi genisletildi:
  - `HadithBook`
  - `HadithSection`
  - `HadithItem`
  - `HadithDailySelection`
- Dovgulu gunun hadisi secim algoritmasi eklendi:
  - `index = (dayOfYear + installSeed) % poolCount`
- Bildirim hadis payload akisi eklendi:
  - `Oku` aksiyonunda okuyucuya deep-link
  - `Kaydet` aksiyonunda favoriye ekleme

### Changed

- Hadis bildirim uretimi tekrarlandi:
  - tekrarli tek request yerine ileriye donuk gunluk planlama (14 gun)
  - namaz oncesi hadis metni secimi deterministic hale getirildi
- Ayarlar ekranina Hadis paneli eklendi:
  - varsayilan koleksiyon
  - yazi boyutu
  - sade okuma modu
- Bildirim ayarlari ekranina varsayilan hadis kitabi secimi eklendi.

## [0.1.5] - 2026-02-25

### Added

- AdMob SDK entegrasyonu eklendi (SPM `GoogleMobileAds`).
- Banner reklam entegrasyonu eklendi (`Takvim` ve `Hadis` ekranlari altinda).
- Interstitial reklam stratejisi eklendi:
  - `Takvim -> Gun Detay`
  - `Hadis -> Favoriler`
  - gunluk max 2 gosterim limiti
- Rewarded reklam ile \"Reklamsiz 24 Saat\" kilidi eklendi.
- App Open reklam stratejisi eklendi (ilk acilis haric, gunde 1 kez).
- Premium marka icon seti eklendi:
  - `icon-main.png`
  - `icon-dark.png`
  - `icon-tinted.png`
- Icon uretim scripti eklendi: `scripts/generate_app_icon.swift`.
- AdMob strateji dokumani eklendi: `docs/Monetization_AdMob_iOS.md`.

### Changed

- `Info.plist` icine `GADApplicationIdentifier` eklendi.
- `Ayarlar` ekranina Premium/Reklam odakli rewarded unlock bolumu eklendi.

## [0.1.4] - 2026-02-25

### Added

- Premium iOS onboarding akisi eklendi: Splash + izin gerekcesi + fallback il secimi.
- Konum servisi eklendi (`LocationManager`): tek seferlik konum alma, sehir cozumleme, heading takibi.
- Kible ekranlari eklendi:
  - `Kible (Pusula)` haptic destekli hizalama
  - `Kible (Harita)` Apple MapKit tabanli yesil ok yonlendirmesi
- Ayarlar alti yeni detay ekrani eklendi: `Bildirim Ayarlari`.
- Premium tasarim stili eklendi: lacivert/altin vurgu, buyuk radius, soft shadow kartlar.

### Changed

- Tab bar adlandirmasi `Hadis` olacak sekilde duzenlendi.
- Takvim ekrani premium liste formatina gecirildi (grid yerine liste satirlari).
- Uygulama acilisinda bildirim izni isteme, onboarding izni akisiyla uyumlu hale getirildi.
- `Info.plist` konum izin aciklamalari eklendi.

## [0.1.3] - 2026-02-25

### Added

- iOS tarafinda temiz klasorlenmis yeni mimari kuruldu: `Core`, `Features`, `Services`.
- 4 ana ekran moduler dosyalara ayrildi: Vakitler, Takvim, Gunun Icerigi, Ayarlar.
- iOS bildirim altyapisi eklendi:
  - Namaz hatirlatici (oncesi + vakit girdi + alarm modu)
  - Gunluk hadis bildirimi
  - Namaz oncesi mini hadis bildirimi
  - Ertele/Kapat aksiyonlu alarm akisi
- Alarm gorunumu (`AlarmRingView`) full screen akisla uygulandi.
- Notification ayarlari UI'si her vakit icin ac/kapat + sure + mod + ses secimi ile eklendi.

### Changed

- SwiftData template yapisi kaldirildi ve uygulama girisi (`Namaz_mApp`) yeni state + notification yonetimiyle guncellendi.
- Proje iPhone 17 Pro simulator hedefinde basarili build verdi.

## [0.1.2] - 2026-02-25

### Added

- SwiftUI tab tabanli yeni ekran yapisi kuruldu: Vakitler, Takvim, Gunun Icerigi, Ayarlar.
- Vakitler ekranina kalan sure, aktif vakit vurgusu, haftalik sheet ve il secimi eklendi.
- Takvim ekranina aylik vakit listesi ve Ramazan odakli liste/kalan sure karti eklendi.
- Gunun Icerigi ekranina paylas, kopyala, favori akislari eklendi.
- Ayarlar ekranina il secimi, bildirim, tema ve veri kaynagi bolumleri eklendi.

## [0.1.1] - 2026-02-25

### Added

- `scripts/release.sh` eklendi (patch/minor/major bump + commit + tag).
- README icine standart versiyonlama akis komutlari eklendi.

## [0.1.0] - 2026-02-25

### Added

- V2 kapsam ve urun cercevesi dokumantasyonu eklendi.
- `README.md` ile proje kapsami ozetlendi.
- `docs/V2_Uygulama_Kapsami.md` olusturuldu.
- `VERSION` dosyasi eklendi.
