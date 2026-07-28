# iOS App Store — Technical Submission Checklist

Everything you need to get Book Scanner from this repo into the App Store.
Ordered so you can work top to bottom.

---

## 0. Blockers to resolve first

- [ ] **⚠️ In-app account deletion (REQUIRED by Apple).** Apps that let users
      create an account MUST let them delete it in-app, or App Review rejects
      under Guideline 5.1.1(v). _Status: implemented — Account menu → "Delete
      account". Verify it works end to end before submitting._
- [ ] **Unique app name.** "Book Scanner" is likely taken — confirm/choose a
      name when you reserve it (see APP_STORE_LISTING.md).
- [ ] **Apple Developer Program membership** ($99/yr) active:
      https://developer.apple.com/programs/
- [ ] **Rotate the App Review account password.** The old password was
      previously committed to this public repository and remains in Git
      history. Store the replacement only in Firebase and App Store Connect.

---

## 1. Accounts & identifiers

- [ ] Sign in to **App Store Connect** (https://appstoreconnect.apple.com) with
      your Developer account.
- [ ] **Bundle ID** is `com.bookscanner.bookScanner` (already set in the Xcode
      project). Register it at
      Developer → Certificates, IDs & Profiles → Identifiers (or let Xcode
      auto-create it during the first archive).
- [ ] Create the app record in App Store Connect: **My Apps → + → New App**
      - Platform: iOS
      - Name: (your chosen name)
      - Primary language, Bundle ID, SKU (any unique string, e.g. `bookscanner01`)

## 2. Signing (in Xcode)

- [ ] Open the workspace (NOT the project):
      ```bash
      open ios/Runner.xcworkspace
      ```
- [ ] Select the **Runner** target → **Signing & Capabilities**:
      - Check **Automatically manage signing**
      - **Team:** select team `NR6H8UUF43`. This matches the TeamIdentifier in
        the archive's embedded provisioning profile. (`U38KEH9A34` appears in
        the certificate label but is not the provisioning TeamIdentifier.)
      - Confirm the bundle identifier matches `com.bookscanner.bookScanner`
- [ ] Firebase requires no extra capability here. (Push notifications are NOT
      used, so no APNs setup needed.)

## 3. App icon & launch screen

- [ ] Provide a **1024×1024** App Store icon (no alpha, no rounded corners) plus
      the standard iOS icon set. Easiest path: use a tool like `flutter_launcher_icons`,
      or drop images into
      `ios/Runner/Assets.xcassets/AppIcon.appiconset`.
- [x] Launch screen uses the app's solid brand blue and no Flutter placeholder.

## 4. Version & build number

- [ ] `pubspec.yaml` → `version: 1.0.0+1` means **marketing version 1.0.0**,
      **build 1**. Bump the `+N` build number on every upload to the same version.

## 5. Build the release archive

From the repo root (note the UTF-8 locale — CocoaPods needs it on this Mac):

```bash
export LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
flutter build ipa --release
```

This produces `build/ios/archive/Runner.xcarchive` and, if signing succeeds, an
`.ipa` under `build/ios/ipa/`. If you prefer the GUI, run
`flutter build ios --release` then **Xcode → Product → Archive**.

Local verification completed:
- [x] `flutter analyze` passes with no issues.
- [x] `flutter test` passes.
- [x] Unsigned iOS release build succeeds.
- [x] Signed Xcode archive succeeds and passes app-settings validation.
- [ ] IPA export currently requires registering
      `com.bookscanner.bookScanner` and creating an App Store provisioning
      profile for team `NR6H8UUF43`.

## 6. Upload

Either:
- **Xcode Organizer** (Window → Organizer → select archive → Distribute App →
  App Store Connect → Upload), or
- **Transporter** app (drag in the `.ipa`), or
- CLI: `xcrun altool` / `xcrun notarytool` (Xcode Organizer is simplest).

## 7. Screenshots (required)

You must upload screenshots for the largest supported iPhone display:
- [x] **6.9" iPhone** — the supplied screenshots are 1320 × 2868, an accepted
      size for iPhone 16 Pro Max.
- [ ] Upload 1–10 screenshots in App Store Connect. Three are currently
      available in `store/screenshots/`.
- iPad shots only required if you leave iPad support on. To ship iPhone-only,
  set the app to iPhone in target settings.

**Current target status:** `TARGETED_DEVICE_FAMILY = "1,2"` supports both
iPhone and iPad, but no iPad screenshots are currently checked into
`store/screenshots/ipad/`. Before submission, either add iPad screenshots or
change the Runner target to iPhone-only (`TARGETED_DEVICE_FAMILY = "1"`).

Capture from the iOS Simulator:
```bash
open -a Simulator
flutter run --release    # or launch the built app
# In Simulator: Device → screenshot (⌘S) on each key screen
```
Good screens to show: sign-in, project list, book grid with pages, a page with
recognized text, PDF export.

## 8. App Store Connect metadata

- [ ] Paste content from **APP_STORE_LISTING.md** (name, subtitle, description,
      keywords, promotional text, category, support URL).
- [ ] Complete **App Privacy** using **APP_PRIVACY_LABELS.md**.
- [ ] Set **Privacy Policy URL** — host `PRIVACY_POLICY.md` publicly first
      (GitHub Pages works) and fill in your support email inside it.
- [ ] Answer **Export Compliance**: the app uses only standard HTTPS/TLS
      encryption → typically **"uses exempt encryption"** (no CCATS needed).
      Add to `ios/Runner/Info.plist` to skip the prompt each upload:
      ```xml
      <key>ITSAppUsesNonExemptEncryption</key>
      <false/>
      ```
- [ ] **Content Rights:** you own/created the content → no third-party content.
- [ ] **Age Rating:** complete questionnaire → expect 4+.

## 9. Review notes (help the reviewer)

Provide a **demo account** so reviewers can sign in without creating one:
- [ ] Create a test account in the app (e.g. `review@yourdomain.com`) and put the
      email + password in **App Review Information → Sign-In required → Demo account**.
- [ ] In the notes, mention: "Camera is used to scan pages; OCR runs on-device.
      Account deletion is available under the account menu."

## 10. Submit

- [ ] Select the uploaded build in the version page.
- [ ] Click **Add for Review → Submit**.
- [ ] First reviews typically take 24–48 h.

---

## Firebase reminders (already done, verify)
- Email/Password sign-in **enabled** in Firebase Auth ✅
- Firestore + Storage created, with security rules deployed ✅
- iOS app registered in Firebase; `GoogleService-Info.plist` present in
  `ios/Runner/` ✅

## Known constraints
- **Min iOS version: 15.5** (ML Kit requirement) — older devices won't see the app.
- The **macOS** build is separate and cannot go to the Mac App Store as-is (its
  sandbox is disabled to support Firebase keychain). This checklist is iOS-only.
