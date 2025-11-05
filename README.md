# Simulador-Ley-de-Enfriamiento-de-Newton
<<<<<<< HEAD

## Builds: Android APK y iOS IPA

Este repo ya trae flujos de CI para generar ambos artefactos:

- Android: `.github/workflows/flutter-build.yml` (job `android`)
	- Produce `build/app/outputs/flutter-apk/app-release.apk`.

- iOS unsigned: `.github/workflows/flutter-build.yml` (job `ios`)
	- Produce un `.ipa` sin firma para pruebas internas con Xcode.

- iOS TestFlight (firmado): `.github/workflows/ios-testflight.yml` (opcional)
	- Requiere secrets para firmar y subir a TestFlight.

### Cómo ejecutar los workflows

1. Empuja cambios a `main` o lanza manualmente desde la pestaña Actions (Run workflow).
2. Descarga los artefactos generados desde el job correspondiente.

### Secrets requeridos para iOS TestFlight

Configura estos secrets en GitHub (Settings → Secrets and variables → Actions → New repository secret):

- `IOS_APP_BUNDLE_ID`: Bundle ID (p. ej. `com.tuempresa.tuapp`).
- `IOS_APPLE_ID`: Tu Apple ID (correo de la cuenta developer).
- `IOS_TEAM_ID`: Team ID de tu cuenta (10 caracteres).
- `ASC_KEY_ID`: App Store Connect API Key ID.
- `ASC_ISSUER_ID`: App Store Connect Issuer ID.
- `ASC_KEY_CONTENT_BASE64`: Contenido del App Store Connect API Key en base64 (archivo `.p8`).
- `IOS_CERT_P12_BASE64`: Certificado de distribución iOS en base64 (archivo `.p12`).
- `IOS_CERT_PASSWORD`: Password del `.p12`.
- `IOS_PROFILE_BASE64`: Provisioning Profile en base64 (Ad Hoc o App Store) para el Bundle ID.

Después, ejecuta el workflow `iOS TestFlight (signed)` y se subirá la build a TestFlight.

### Build local en macOS (alternativa)

Si prefieres compilar localmente en un Mac:

1. Abre `ios/Runner.xcworkspace` en Xcode.
2. En el target `Runner` → `Signing & Capabilities`, selecciona tu `Team` y ajusta el `Bundle Identifier`.
3. Menú `Product` → `Archive` y distribuye a `TestFlight` o `App Store`.
4. Para generar IPA sin firma: `flutter build ipa --release --no-codesign`.

Notas:
- Un `.apk` solo funciona en Android. En iPhone necesitas `.ipa` y firma válida de Apple.
- El modo TestFlight es la ruta más simple para probar en iPhone sin cables.
=======
>>>>>>> ae54f78 (Despliegue con vercer)
