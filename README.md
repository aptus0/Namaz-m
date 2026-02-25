# Namazim

Namazim, namaz vakitleri, Ramazan takibi ve gunluk dini icerik odakli bir mobil uygulama projesidir.

## V2 Icerik Kapsami

Bu surumde hedeflenen ana moduller:

1. Vakitler
2. Ramazan / Takvim
3. Hadis (Gunluk / Kitaplar / Favoriler)
4. Ayarlar

Detayli kapsam ve ekran bazli icerik icin:

- `docs/V2_Uygulama_Kapsami.md`

## Veri Kaynagi Stratejisi

Oncelik:

1. Diyanet AwqatSalah REST servisi (auth/login ile resmi akis)
2. Alternatif saglayici (fallback)

Not: Servis erisim/limit kurallari operasyonel olarak proje disinda takip edilir.

## iOS Mimari Hedef (V2)

- SwiftUI tabanli moduler yapi
- `Core` (model + util), `Features` (ekranlar), `Services` (bildirim + konum)
- App state + local notification scheduler
- Alarm/hatirlatma akislarinin merkezi yonetimi
- Onboarding izin akisi (konum -> bildirim) + fallback il secimi
- Minimum deployment target: `iOS 18.0`

## iOS Dosya Yapisi

- `Namazım/Core`
- `Namazım/Features`
- `Namazım/Services`
- `Namazım/Namaz_mApp.swift` (uygulama girisi)

## iOS Ekran Seti

- Tablar: `Vakitler`, `Takvim`, `Hadis`, `Ayarlar`
- Alt ekranlar:
  - `Bildirim Ayarlari`
  - `Hadis Okuyucu`
  - `Kible (Pusula)`
  - `Kible (Harita)`
  - `Hakkinda / Kaynaklar`

## Hadis Modulu

- Ust sekmeler: `Gunluk`, `Kitaplar`, `Favoriler`
- Okuyucu ekrani: bolum bazli hadis kartlari, onceki/sonraki gezinme
- Kisisellestirme:
  - varsayilan hadis kitabi
  - yazi boyutu (kucuk/orta/buyuk)
  - sade okuma modu
- Bildirim akisinda deterministic gunun hadisi secimi ve hadis deep-link payload'i

## Brand ve Icon

- Premium icon konsepti: Altin hilal + minimal minare + lacivert zemin
- iOS icon varyantlari:
  - `icon-main.png`
  - `icon-dark.png`
  - `icon-tinted.png`
- Otomatik icon uretimi:

```bash
swift scripts/generate_app_icon.swift \
  /Users/samet/Desktop/Namazım/Namazım/Assets.xcassets/AppIcon.appiconset
```

## AdMob (iOS)

- SDK: `GoogleMobileAds` (Swift Package Manager)
- App ID: `ca-app-pub-3321006469806168~2800259705`
- Banner Unit ID: `ca-app-pub-3321006469806168/6554983522`
- Detayli strateji ve policy notlari:
  - `docs/Monetization_AdMob_iOS.md`

## iOS Build

```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
xcodebuild -project Namazım.xcodeproj -scheme Namazım \
-destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

## Kisa Yol Haritasi

1. MVP ekranlari: Vakitler, Takvim, Gunun Hadisi, Ayarlar, Il Sec
2. Bildirim akisi (vakit bazli ve offset destekli)
3. Favoriler ve icerik detaylari
4. Hakkinda/Gizlilik sayfalari

## Versiyonlama Akisi

Projede her degisiklikten sonra commit ve versiyon etiketi uretilmesi hedeflenir.

Otomatik akis icin:

```bash
./scripts/release.sh patch "kisa commit mesaji"
./scripts/release.sh minor "kisa commit mesaji"
./scripts/release.sh major "kisa commit mesaji"
```

Bu komut:

1. `VERSION` degerini artirir
2. tum degisiklikleri commitleyip
3. `vX.Y.Z` etiketi olusturur
