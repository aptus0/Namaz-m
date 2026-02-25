# Namazim

Namazim, namaz vakitleri, Ramazan takibi ve gunluk dini icerik odakli bir mobil uygulama projesidir.

## V2 Icerik Kapsami

Bu surumde hedeflenen ana moduller:

1. Vakitler
2. Ramazan / Takvim
3. Gunun Icerigi (Hadis)
4. Ayarlar

Detayli kapsam ve ekran bazli icerik icin:

- `docs/V2_Uygulama_Kapsami.md`

## Veri Kaynagi Stratejisi

Oncelik:

1. Diyanet AwqatSalah REST servisi (auth/login ile resmi akis)
2. Alternatif saglayici (fallback)

Not: Servis erisim/limit kurallari operasyonel olarak proje disinda takip edilir.

## Mimari Hedef (V2)

- MVVM + Repository
- Data / Domain / UI katmanlari
- Cache: Room (bugun + aylik vakitler)
- Offline goruntuleme

## Kisa Yol Haritasi

1. MVP ekranlari: Vakitler, Takvim, Gunun Hadisi, Ayarlar, Il Sec
2. Bildirim akisi (vakit bazli ve offset destekli)
3. Favoriler ve icerik detaylari
4. Hakkinda/Gizlilik sayfalari

