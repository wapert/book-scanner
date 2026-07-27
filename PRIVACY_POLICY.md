# Privacy Policy — Book Scanner

_Last updated: 27 July 2026_

Book Scanner ("the app", "we", "us") is committed to protecting your privacy.
This policy explains what information the app collects, how it is used, and your
choices. **You must host this page at a public URL** (for example GitHub Pages)
and enter that URL in App Store Connect and in the app.

## Information we collect

**Account information.** When you create an account, we collect your **email
address** and a password. Authentication is handled by Google Firebase
Authentication. Your password is managed by Firebase and is never stored by the
app in readable form.

**Content you create.** The app stores the content you add:
- **Page photos** you capture with the camera.
- **Recognized and edited text** for each page.
- **Names and structure** of your projects, books, and pages.

This content is stored in your private, per-account space in Google Firebase
(Cloud Firestore and Cloud Storage) and is associated with your account
identifier so it can sync to your devices.

**Camera.** The app uses your device camera solely to photograph pages that you
choose to scan. Photos are only captured when you take them.

## How text recognition (OCR) works

Text recognition runs **entirely on your device** using Google's on-device ML
Kit. The content of your page images is **not** sent to any third-party OCR
service for recognition. The image itself is uploaded to your private Firebase
Storage space only so it can sync across your devices.

## How we use your information

- To create and secure your account.
- To store and sync your projects, books, pages, images, and text.
- To provide app functionality such as PDF export.

We do **not**:
- Use your data for advertising.
- Sell or share your data with third parties for their own marketing.
- Track you across other apps or websites.
- Include third-party analytics or advertising SDKs.

## Where your data is stored

Your data is stored on Google Firebase (Google Cloud Platform) infrastructure.
Access is restricted by security rules so that **only your authenticated account
can read or write your data**.

## Data retention and deletion

- You can delete individual pages, books, and projects at any time within the
  app. Deleting a page also removes its stored image.
- You can delete your entire account and all associated data from within the app
  under the account menu ("Delete account"). This permanently removes your
  Firestore data, stored images, and your authentication record.
- You may also request deletion by contacting us at the email below.

## Children's privacy

Book Scanner is not directed at children under 13 and does not knowingly collect
personal information from children.

## Changes to this policy

We may update this policy from time to time. Material changes will be reflected
by the "Last updated" date above.

## Contact

For privacy questions or data-deletion requests, contact:
**<your-support-email@example.com>**
