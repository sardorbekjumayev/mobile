# Stepix · mobile

O'quv markazlari uchun Stepix mobil ilovasi — bitta ilova, ikkita rol:
**o'quvchi** va **o'qituvchi**. Rol tokendan keladi, ilova ochilganda mos
ekranlar to'plami ko'rsatiladi.

## Ishga tushirish

```sh
flutter pub get
flutter run
flutter build apk --release
```

`STEPIX_API_BASE_URL` berilmasa **`https://api.169-58-198-20.sslip.io/v1`**
ishlatiladi — nginx orqasidagi Mobile API (`backend`, `MOBILE_PORT=3003`,
TLS Let's Encrypt). Ya'ni telefon hech qanday sozlamasiz ishlaydi.

Kompyuterdagi backendga qarab ishlash uchun manzilni ochiq berish kerak:

```sh
flutter run --dart-define=STEPIX_API_BASE_URL=http://10.0.2.2:3003/v1      # emulyator
flutter run --dart-define=STEPIX_API_BASE_URL=http://192.168.1.50:3003/v1  # LAN telefon
```

LAN IP uchun `android/app/src/main/res/xml/network_security_config.xml`
ichiga o'sha IP'ni `<domain>` qilib qo'shing: ilova sukut bo'yicha faqat
HTTPS bilan gaplashadi, istisno faqat `10.0.2.2` va `localhost` uchun.

| dart-define | Nima uchun |
|---|---|
| `STEPIX_API_BASE_URL` | API manzili. Sukut bo'yicha `https://api.169-58-198-20.sslip.io/v1` |
| `STEPIX_APP_VERSION` | `X-App-Version` va `GET /settings?version=`. Server shu asosda `force_update` qaytaradi |

### Tarmoq bo'yicha nima qayerda

* `android/app/src/main/AndroidManifest.xml` — `INTERNET` ruxsati. Reliz build
  faqat shu faylni o'qiydi; ruxsat debug manifestda turganida `--release` APK
  hech qayerga so'rov yubora olmasdi.
* `android/app/src/main/res/xml/network_security_config.xml` — ochiq HTTP
  taqiqlangan, istisno faqat emulyator xostlari.
* `ios/Runner/Info.plist` — ATS o'z holicha; faqat `NSAllowsLocalNetworking`.

Tekshirish:

```sh
flutter analyze
flutter test
```

## Arxitektura

```
lib/
  app/          config · router · MaterialApp
  core/         api (Dio + envelope) · session · storage · theme
  data/         models · repositories (bitta endpoint = bitta metod)
  features/     auth · student · teacher · profile · shared widgetlar
  l10n/         uz · ru · en — faqat mijoz matnlari
```

Uch qoida butun kod bo'ylab takrorlanadi:

1. **Server matnlari tarjima qilinmaydi.** Xato xabarlari, bildirishnoma
   sarlavhalari, fan va guruh nomlari `_i18n` dan `Accept-Language` bo'yicha
   keladi. `l10n/strings.dart` faqat mijozning o'z matnlarini saqlaydi —
   ikkinchi nusxa muqarrar ravishda eskiradi.
2. **Ruxsatni router hal qiladi.** `app/router.dart` dagi bitta `redirect`
   sessiya holatiga qarab qaerga kirish mumkinligini aytadi. Qirq ekranga
   tarqatilgan tekshiruv — teshigi bor tekshiruv.
3. **Repozitoriylar `ApiClient` interfeysiga bog'lanadi**, Dio'ga emas. Shu
   sababli testlar HTTP stacksiz, backendsiz ishlaydi (`test/fake_api_client.dart`).

## Ekranlar

| Kod | Ekran | Endpointlar |
|---|---|---|
| M1–M3 | Welcome · telefon · parol | `POST /auth/login` |
| M4 | O'quvchi asosiy | `GET /home` · `GET /group` |
| M6 | Guruh | `GET /group/:id` |
| M7–M9 | Testlar · test · natija | `GET /test` · `/start` `/answer` `/submit` · `/result` |
| M10 | Reyting | `GET /leaderboard` · `GET /badge` |
| M11 | Profil | `GET /profile` · `GET /progress` · `GET /badge` |
| M12–M14 | O'qituvchi asosiy · guruhlar · guruh | `GET /teacher/home` · `/teacher/group` |
| M15 | O'quvchi tahlili | `GET /teacher/student/:id` |
| M16 | Yo'qlama | `POST /teacher/attendance` |
| M17 | Guruh testlari | `GET /teacher/test` · `/teacher/test/:id` |
| M18 | Bildirishnomalar | `GET /notification` · `POST /notification/read` |
| M19 | Sozlamalar | `GET /settings` · `POST /auth/change-password` |

To'liq shartnoma: `stepix_architecture/02-API-MOBILE.md`.

## Hali ulanmagan

- **FCM.** `ProfileRepository.registerDevice` / `unregisterDevice` tayyor,
  lekin `firebase_messaging` qo'shilmagan — push kelganda feed baribir
  haqiqat manbai bo'lib qoladi.
- **Avatar yuklash.** `POST /profile/avatar` repozitoriyda bor; rasm tanlash
  uchun plagin qo'shilmagan.
- **To'lov.** `POST /subscription/checkout` Payme/Click sahifasini tashqi
  brauzerda ochadi — 3-D Secure ichki webview'da buziladi.
