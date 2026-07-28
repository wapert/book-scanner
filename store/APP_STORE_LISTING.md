# App Store 上架文案 — 書頁掃描 Book Scanner

> 直接複製貼上到 App Store Connect。主要語言建議設為 **繁體中文（台灣）**，可另加英文版。

---

## App 名稱（Name，≤30 字元）
```
書頁掃描 Book Scanner
```
> ⚠️「Book Scanner」在 App Store 很可能已被使用，名稱必須全站唯一。保留名稱時請確認，
> 若被佔用可改用：`書頁掃描 · 文字擷取`、`掃書王 Book Scanner`、`頁面掃描器`。

## 副標題（Subtitle，≤30 字元）
```
拍照掃描・文字辨識・匯出 PDF
```

## 分類（Category）
- 主要：**生產力（Productivity）**
- 次要：**工具程式（Utilities）**（或教育 Education）

---

## 宣傳文字（Promotional Text，≤170 字元，可隨時更新）
```
把整本書變成可編輯的數位文字。拍下書頁，App 在裝置端立即辨識文字（支援中英文），依專案／書本／頁面分類整理，並可一鍵匯出 PDF，資料雲端同步。
```

## 描述（Description）
```
書頁掃描把你的手機變成快速又有條理的書本數位化工具。拍下任何一頁，App 會在裝置端辨識文字、自動壓縮圖片，並將內容整齊地存放在雲端，讓你的資料在所有裝置上同步。

【為閱讀與研究而生】
用圖書館的方式整理掃描內容：專案（Projects）裝著書本（Books），書本裝著頁面（Pages）。無論是研究專案、一門課程，還是一整個書櫃，都能井然有序，不再是相簿裡一堆散亂的照片。

【裝置端文字辨識】
每一頁掃描後都會經過裝置端 OCR，辨識出的文字直接附在該頁，隨時可讀、可編輯、可再利用。中文與拉丁文字皆支援。辨識完全在你的裝置上進行，不會把頁面送到第三方 OCR 服務。

【文字可編輯】
OCR 只是起點，不是終點。點開任何一頁即可檢視並修正辨識出的文字，隨時可重新辨識。

【匯出 PDF】
一鍵把整本書轉成乾淨的多頁 PDF，方便分享、列印或存檔。

【自由整理】
• 拖曳調整書本內頁面的順序
• 選取並把頁面移動到其他書本
• 專案、書本、頁面皆可重新命名或刪除

【檔案小、同步快】
照片在上傳前會自動壓縮，一整頁通常只有數百 KB，同步快速又省空間，同時保持清晰可讀。

【登入即跨裝置同步】
用 Email 建立帳號後，你的專案、書本、頁面與辨識文字都會安全地同步到雲端。在另一台裝置登入，一切都在。

【隱私】
你的掃描內容儲存在專屬於你帳號的私人雲端空間，只有你能存取。詳見隱私權政策。

書頁掃描適合學生、研究者、老師，以及任何想把讀過的書中文字擷取並保存下來的人。
```

## 關鍵字（Keywords，≤100 字元，逗號分隔）
```
掃描,書本,文字辨識,OCR,PDF,文件,掃描器,筆記,學習,研究,數位化,書頁,中文辨識,scanner,book
```

## 支援網址（Support URL，必填）
```
https://github.com/wapert/book-scanner
```

## 行銷網址（Marketing URL，選填）
```
https://github.com/wapert/book-scanner
```

## 隱私權政策網址（Privacy Policy URL，必填）
```
（見 docs/privacy.html — 用 GitHub Pages 發佈後填入該網址）
```

---

## App 審核資訊（App Review Information）
- **登入帳號**：審核員需要一組測試帳號才能通過登入頁。請見 `store/app_review_test_account.md`，
  在 App Store Connect 的「App 審核資訊 → 登入資訊」填入測試 Email / 密碼。
- **備註（Notes）建議填**：
```
This app requires an account to sync scanned pages. A test account is provided
above. The camera is used to photograph book pages; text recognition (OCR) runs
on-device. Account deletion is available in-app under the account menu.
No special hardware required.
```

## App 隱私（App Privacy，資料蒐集揭露）
在 App Store Connect「App 隱私」填寫（詳見 `store/APP_PRIVACY_LABELS.md`）：
- **聯絡資訊 → 電子郵件地址（Email Address）**：用途 App 功能、連結身分、非追蹤。
- **使用者內容 → 照片（Photos）**：掃描的頁面照片；App 功能、連結身分、非追蹤。
- **使用者內容 → 其他使用者內容**：辨識／編輯的文字、專案與書本名稱；App 功能、連結身分、非追蹤。
- **識別碼 → 使用者 ID**：Firebase 帳號 UID；App 功能、連結身分、非追蹤。
- **未蒐集**：位置、聯絡人、健康、財務、瀏覽紀錄；**無**分析或當機回報 SDK。

## 年齡分級（Age Rating）
- 一律選「無」不當內容 → 通常為 **4+**。

## 版本資訊（What's New，首次上架可寫）
```
首次發布 🎉
• 用相機掃描書頁
• 裝置端文字辨識（中文＋拉丁文字）
• 依「專案 → 書本 → 頁面」分類整理
• 可調整順序、移動頁面、匯出 PDF
• Email 安全登入，雲端同步
```

---

## 截圖需求（Screenshots）
App Store 至少需要 **6.9" iPhone**（1320 × 2868，iPhone 16 Pro Max）。建議 4–6 張，涵蓋：
1. 登入畫面
2. 專案列表
3. 書本頁面縮圖（2 欄網格）
4. 單頁 + 辨識出的文字
5. 匯出 PDF
6. （選）移動／排序頁面

已產生的截圖見 `store/screenshots/`（iPhone）與 `store/screenshots/ipad/`（iPad 13"）。
