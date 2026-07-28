# App Store 審核測試帳號 (App Review Test Account)

App Store 審核員需要一組帳號才能通過登入頁。請先建立以下帳號，再填入 App Store Connect
的「App 審核資訊 → 登入資訊」。

## 建議帳號 (Suggested credentials)

| 欄位 | 值 |
|---|---|
| **Email** | `review@bookscanner.app` |
| **Password** | `BookReview#2026` |

> Firebase 密碼登入不會寄驗證信，Email 不需真實可收信；此帳號僅供審核使用。
> 密碼至少 6 碼即可，可自行更換，但務必與填入 App Store Connect 的一致。

## 如何建立此帳號（擇一）

**方法 A — 在 App 內建立（最簡單）**
1. 打開 App → 登入頁點「建立帳號 / Sign Up」
2. 輸入上面的 Email 與密碼
3. 點「建立帳號」即完成

**方法 B — 在 Firebase 主控台建立**
1. 前往 [Firebase Console → Authentication → Users](https://console.firebase.google.com/project/book-scanner-b550d/authentication/users)
2. 點「新增使用者 / Add user」
3. 填入上面的 Email 與密碼 → 儲存

> ✅ 此帳號**已預先建立示範資料**：兩個專案（讀書筆記、研究資料），內含書本、
> 多頁掃描圖片與中文辨識文字，審核員一登入即可看到功能完整的畫面。
> （uid：`rgGeQFxQ0XUqGjL2IY5uQXaFP8C3`）

---

## App Store Connect「登入資訊」欄位

- **需要登入 (Sign-in required)**：勾選 ✅
- **使用者名稱 (User name)**：`review@bookscanner.app`
- **密碼 (Password)**：`BookReview#2026`

## 審核備註 (Review Notes) — 可直接貼上

```
This app requires an account to sync scanned book pages across devices. Test
credentials are provided in the sign-in information above.

Notes for the reviewer:
- Sign in with the provided email/password to access all features
  (Projects, Books, Pages, OCR text, PDF export).
- The camera is used only to photograph book pages that the user chooses to scan.
- Text recognition (OCR) runs on-device via Google ML Kit; page contents are not
  sent to any third-party OCR service.
- Users can delete their account and all associated data in-app:
  account menu (top-right) → "Delete account".
- No location, contacts, microphone, or special hardware is used.
```
