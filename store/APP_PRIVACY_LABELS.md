# App Privacy "Nutrition Label" — answers for App Store Connect

App Store Connect → your app → **App Privacy**. Below are the exact answers that
match what Book Scanner actually does. If you later add analytics or crash
reporting SDKs, you must update these.

## Does the app collect data? → **YES**

Answer the flow per data type. For every type below:
- **Used for tracking?** → **No** (the app does not track across other
  companies' apps/sites)
- **Linked to the user's identity?** → **Yes** (everything is tied to the
  account)

### 1. Contact Info → Email Address
- Collected: **Yes**
- Purpose: **App Functionality** (account creation and sign-in)
- Linked to identity: **Yes**
- Used for tracking: **No**

### 2. User Content → Photos or Videos
- Collected: **Yes** (page photos)
- Purpose: **App Functionality**
- Linked to identity: **Yes**
- Used for tracking: **No**

### 3. User Content → Other User Content
- Collected: **Yes** (recognized/edited page text; project & book names)
- Purpose: **App Functionality**
- Linked to identity: **Yes**
- Used for tracking: **No**

### 4. Identifiers → User ID
- Collected: **Yes** (Firebase account UID used to scope your data)
- Purpose: **App Functionality**
- Linked to identity: **Yes**
- Used for tracking: **No**

## Data types NOT collected (do not check these)
- Location, Contacts, Browsing/Search history, Health, Financial info,
  Purchases, Contacts, Sensitive info.
- **Diagnostics / Analytics:** Not collected — the app includes **no**
  analytics or crash-reporting SDK (no Firebase Analytics, no Crashlytics).
  ⚠️ If you add Crashlytics or Analytics later, add "Diagnostics → Crash Data /
  Performance Data" here.

## Notes on Firebase
Using Firebase Auth, Firestore, and Storage for **app functionality** (storing
your own content in your own account) does **not** by itself count as tracking
or third-party data sharing for advertising. The answers above reflect that.

## Account deletion (required disclosure)
Apple requires that apps offering account creation also offer in-app account
deletion, and that the App Privacy section and metadata make deletion available.
Point reviewers to: **Account menu → Delete account** in the app.
