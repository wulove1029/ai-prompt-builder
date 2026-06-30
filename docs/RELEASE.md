# 發版流程（Release Runbook）

**AI Prompt Builder** 從 v0.2.0 起改為 **onedir + Inno Setup 安裝檔** 的發布／更新方式
（與 `markdown_viewer` 專案相同），徹底解決舊版 onefile「Failed to load Python DLL」的更新問題。
Repo：`github.com/wulove1029/ai-prompt-builder`，發布由 CI 在推 tag 時自動完成。

---

## 架構（為什麼這樣最穩）

- **PyInstaller onedir**（`gstack Prompt Builder.spec`）：產出 `dist\AI Prompt Builder\` 資料夾，
  `python*.dll` 與相依 DLL 都實體放在 `_internal\` 裡，**執行時不解壓到 `%TEMP%\_MEI`** → 不會再有 DLL 載入失敗。
- **Inno Setup 安裝檔**（`installer.iss`）：把上面的資料夾包成 `AI_Prompt_Builder_Setup_vX.Y.Z.exe`，
  **每位使用者安裝**（`PrivilegesRequired=lowest`）→ 裝到 `%LocalAppData%\Programs\AI Prompt Builder`，**免 UAC**。
- **更新 = 下載安裝檔再執行它**（不再就地替換 exe）：安裝檔覆蓋舊版並自動重啟，是乾淨的獨立程序。

---

## 1. 升級版號（兩處）

1. `gstack_prompt_builder.py` 約第 62 行：`APP_VERSION = "x.y.z"`
2. 根目錄 `VERSION` 檔

安裝檔的版號由 CI 從 tag 帶入（`/DMyAppVersion=`），不需手改 `installer.iss`（它有預設值供本機測試）。

> 檔案是 UTF-8 + CRLF、無 BOM；用腳本改請以 binary 讀寫。改完 `python -m py_compile gstack_prompt_builder.py`。

---

## 2. 提交 + 推 tag（CI 自動打包發布）

```bash
git add gstack_prompt_builder.py VERSION
git commit -m "feat: vX.Y.Z — <描述>"
git push origin main
git tag vX.Y.Z
git push origin vX.Y.Z
```

推 tag 後 `Release` workflow 會：安裝 Inno Setup → `pyinstaller --noconfirm "gstack Prompt Builder.spec"`（onedir）
→ `ISCC.exe /DMyAppVersion=<tag> installer.iss` → 用 `softprops/action-gh-release` 上架 `installer_output/*.exe`。

---

## 3. 本機測試打包（選用）

```bash
python -m PyInstaller --noconfirm "gstack Prompt Builder.spec"
```
```powershell
& "C:\Program Files (x86)\Inno Setup 6\ISCC.exe" "/DMyAppVersion=0.2.0" installer.iss
# 靜默安裝測試（免 UAC）：
.\installer_output\AI_Prompt_Builder_Setup_v0.2.0.exe /VERYSILENT /SUPPRESSMSGBOXES
# 安裝位置：%LocalAppData%\Programs\AI Prompt Builder\AI Prompt Builder.exe
```

---

## 4. 驗證

```bash
gh run list --limit 3
gh api repos/wulove1029/ai-prompt-builder/releases/latest \
  -q '.tag_name + "  assets=" + ([.assets[].name]|join(","))'
```
預期：`vX.Y.Z  assets=AI_Prompt_Builder_Setup_vX.Y.Z.exe`

---

## 自動更新合約（`_AppUpdateChecker` / `_download_and_install_update`）

1. 查 `/releases/latest`，比較 `tag_name` 與 `APP_VERSION`，較新才提示。
2. 取附件：名稱含 **`setup`** 的 `.exe`（即安裝檔）。
3. 下載後驗證 **大小 + SHA-256**（GitHub asset 的 `size`/`digest`），不符就中止、不執行。
4. 只接受 **HTTPS + GitHub 主機**的下載來源。
5. 以乾淨環境啟動安裝檔（脫離本程序）→ 關閉本程式 → 安裝檔覆蓋安裝並重啟新版。

→ 每次發布**務必有 `*Setup*.exe`**（CI 自動產生）。

---

## 從舊版（onefile）轉移

v0.1.x 是單一 exe；v0.2.0 起是安裝檔。**第一次要手動下載 `AI_Prompt_Builder_Setup_vX.Y.Z.exe` 安裝一次**
（裝到 AppData）。之後在已安裝版本內按「檢查更新」就會走安裝檔流程，全自動且不再出 DLL 錯誤。
舊的桌面單一 exe 可自行刪除。

---

## 版本紀錄

| 版號 | 內容 |
|---|---|
| `0.1.4` | 新增 8 個 Matt Pocock 技能、GUI 向量圖示、嚴重度文字化 |
| `0.1.5` | 新 App 圖示、更新器加大小/雜湊驗證 |
| `0.1.7` | 修自動更新重啟（onefile 環境繼承問題） |
| `0.2.0` | **改採 onedir + Inno Setup 安裝檔**；更新改為「下載安裝檔→執行」（同 markdown_viewer），永久解決 DLL 更新問題；每位使用者安裝免 UAC |
