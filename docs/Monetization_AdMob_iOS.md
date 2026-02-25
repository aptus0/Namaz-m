# Namazim iOS - AdMob Monetization Strategy

## AdMob IDs

- Application ID: `ca-app-pub-3321006469806168~2800259705`
- Banner unit ID: `ca-app-pub-3321006469806168/6554983522`

## Placement Strategy (Revenue + Retention)

1. Banner
- `Takvim` ekraninin altinda
- `Hadis` ekraninin altinda
- `Vakitler` ekraninda banner yok (premium hissi korumak icin)

2. Interstitial
- `Takvim -> Gun Detay` acilisinda
- `Hadis -> Favoriler` acilisinda
- Gunluk limit: en fazla 2 gosterim

3. Rewarded
- "Reklamsiz 24 Saat" acma
- Kullanici odul alinca tum reklam formatlari 24 saat durdurulur

4. App Open
- Uygulama aktif oldugunda gunde en fazla 1 kez
- Ilk acilista gosterilmez

## Release Hazirligi

- Interstitial/Rewarded/AppOpen icin ayri production unit ID olusturulacak.
- Gelistirme asamasinda test unit ID kullanilir.
- App Store oncesi AdMob policy ve App Store policy kontrol listesi tamamlanir.

## Policy Notes

- Namaz bildirimi sonrasi rahatsiz edici anlarda interstitial gosterimi tetiklenmez.
- Rewarded zorunlu degil, kullanici odakli opt-in akistir.
- Hassas dini icerik ekranlarinda reklam yogunlugu sinirli tutulur.
