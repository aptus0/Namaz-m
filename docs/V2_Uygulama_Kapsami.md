# Namazim V2 - Uygulama Icerik Kapsami

## 1) Navigasyon Yapisi

Bottom navigation (4 ana ekran):

1. Vakitler
2. Ramazan / Takvim
3. Gunun Icerigi (Hadis)
4. Ayarlar

## 2) Ekranlar

### 2.1 Vakitler (Home)

Amac:

- Bugunun namaz vakitlerini gostermek
- Bir sonraki vakte kalan sureyi buyuk ve net sunmak

Bilesenler:

- Ust bar: secili il + degistir + yenile
- Odak alan: bir sonraki vakit + kalan sure + progress gorseli
- Kartlar: Imsak, Gunes, Ogle, Ikindi, Aksam, Yatsi
- Aksiyonlar: Aylik Takvim, Bildirimleri Yonet

Durumlar:

- Ilk acilis: il secimi uyarisi
- Offline: Room cache + son guncelleme etiketi

### 2.2 Ramazan / Takvim

Amac:

- Ramazanda imsak/iftar takibi
- Diger aylarda aylik vakit listesi

Bilesenler:

- Ay secici
- Sekmeler: Aylik Vakitler / Ramazan (Imsakiye)
- Gun gun listeleme
- Bugun karti: sahur/iftara kalan sure

### 2.3 Gunun Icerigi (Hadis)

Amac:

- Gunluk dini icerigi sade ve okunur sunmak

Bilesenler:

- Icerik karti: baslik, metin, kaynak
- Etiket: Hadis / Ayet / Dua
- Aksiyonlar: Paylas, Kopyala, Favori
- Opsiyonel gezinme: Dun / Bugun / Yarin

### 2.4 Ayarlar

Bolumler:

- Il secimi (Turkiye illeri + arama)
- Bildirimler (vakit bazli ac/kapat)
- Bildirim zamani (tam vaktinde / 5 dk once / 10 dk once)
- Tema (Acik / Koyu / Sistem)
- Veri kaynagi secimi (Diyanet / alternatif)
- Hakkinda ve gizlilik

## 3) Detay Akis Ekranlari

1. Il Sec
2. Bildirim Ayarlari
3. Favoriler
4. Icerik Detay
5. Hakkinda / Kaynaklar

## 4) Veri Modeli ve Kaynak

Il listesi:

- MVP: `assets/cities_tr.json` (81 il)
- Ileri: place endpoint + cache (Turkiye ile sinirli)

Ana API stratejisi:

1. Diyanet AwqatSalah (resmi, auth/login)
2. Fallback acik API (resmi olmayan)

## 5) Mimari Oneri (Java + Android)

- MVVM + Repository
- Katmanlar:
  - data: Retrofit API, DTO, Room
  - domain: use-case'ler
  - ui: Activity/Fragment, ViewModel
- Cache:
  - bugunun vakitleri
  - aylik vakitler

## 6) Kutuphane Seti (Java/Gradle)

UI:

- Material Components (Material 3)
- Navigation Component
- RecyclerView + DiffUtil
- Opsiyonel: Lottie

Network:

- Retrofit
- OkHttp + Logging Interceptor
- Moshi veya Gson (tek secim)

Local:

- Room

DI:

- Hilt

Background:

- WorkManager
- AlarmManager (tam vakit bildirimi hassasiyeti gerekiyorsa)

Tarih/Saat:

- Java 8 time API + coreLibraryDesugaring

## 7) V2 Tasarim Prensipleri

- Modern, temiz, hizli deneyim
- Material 3 kart yapisi
- Acik/Koyu tema
- Tek aksan rengi (ayarlar uzerinden degisebilir)
- Kalan sure odakli ana ekran
- Aktif vakit gorsel vurgusu

## 8) Android Ekran Adlari (Oneri)

- `PrayerTimesFragment`
- `CalendarFragment`
- `DailyHadithFragment`
- `SettingsFragment`
- `CitySelectActivity` veya `CitySelectFragment`
- `NotificationSettingsFragment`
- `FavoritesFragment`
- `AboutFragment`

