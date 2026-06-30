# 發版流程（Release Runbook）

本文件記錄 **AI Prompt Builder** 的「升級版號 → 提交 → 發布」完整流程。
Repo：`github.com/wulove1029/ai-prompt-builder`，版本直接在 `main` 分支發布。

> **重點：發布是由 CI 自動完成的。** 你不需要在本機打包 exe。
> 只要**推送 tag `vX.Y.Z`**，GitHub Actions（`.github/workflows/release.yml`）就會在雲端用
> **Python 3.12** 打包，並把 `AI Prompt Builder.exe` 上架到對應的 Release。
> （本機打包只用於自己測試，不會是最終發布的檔案。）

---

## 0. 前置工具

| 工具 | 用途 | 檢查 |
|---|---|---|
| `git` | 版本控制 + 推 tag 觸發發布 | `git --version` |
| `python` + `PyInstaller`（選用） | 只在「本機想先測試打包」時需要 | `python -m PyInstaller --version` |
| `gh`（選用） | 看 release / CI 狀態 | `gh auth status` |

---

## 1. 升級版號（**兩個地方都要改**）

版號同時存在兩處，務必一起改、保持一致：

1. `gstack_prompt_builder.py` 約第 61 行：`APP_VERSION = "x.y.z"`
2. 根目錄 `VERSION` 檔

版號規則：採 **patch 遞增**（`0.1.0 → 0.1.1 → …`）。功能型大改可考慮升 minor（如 `0.2.0`）。

> 注意：本檔為 **UTF-8 + CRLF、無 BOM**。用編輯器改沒問題；若用腳本改，請以 binary 方式讀寫避免換行/編碼被破壞。

改完先做語法檢查：

```bash
python -m py_compile gstack_prompt_builder.py
```

---

## 2. 提交（commit + push main）

只 stage 該進版控的檔案（**不要** 把 `dist/`、`build/`、`.understand-anything/` 加進來）：

```bash
git add gstack_prompt_builder.py VERSION   # 圖示更新時再加 app_icon.ico
git commit -m "feat: vX.Y.Z — <一句話描述>"
git push origin main
```

---

## 3. 發布 = 推 tag → CI 自動打包並上架

```bash
git tag vX.Y.Z
git push origin vX.Y.Z
```

推上去後，`Release` workflow 會自動：
1. checkout、安裝 `requirements.txt`
2. 用 **Python 3.12** 跑 `pyinstaller "gstack Prompt Builder.spec"`
3. 透過 `softprops/action-gh-release` 建立 Release 並附上 `AI Prompt Builder.exe`
   （GitHub 會把附件名空白換成點 → `AI.Prompt.Builder.exe`）

> ⚠️ 不要再手動 `gh release create` 上傳本機 exe——CI 會用它的 3.12 版**覆蓋**你的附件，造成本機(3.13)與發布版(3.12)不一致的混淆。讓 CI 當唯一發布來源。

---

## 4. 驗證

```bash
# 看 CI 跑完沒
gh run list --limit 3

# 程式內「檢查更新」會打的端點，確認回傳新版且有 .exe
gh api repos/wulove1029/ai-prompt-builder/releases/latest \
  -q '.tag_name + "  assets=" + ([.assets[].name]|join(","))'
```

預期類似：`v0.1.5  assets=AI.Prompt.Builder.exe`

---

## 自動更新合約（為什麼 Release 一定要有 `.exe`）

程式內 `_AppUpdateChecker` / `_download_and_install_update`：

1. 查 `GET /repos/<repo>/releases/latest`，比較 `tag_name`（去 `v`）與 `APP_VERSION`，較新才提示。
2. 找附件：先找名稱等於 `UPDATE_ASSET_NAME`（`"AI Prompt Builder.exe"`），找不到就 fallback 找任何 **`.exe`**。
3. **下載後驗證**：檔案大小需等於 GitHub asset 的 `size`，若 asset 有 `digest`（sha256）再比對雜湊；不符就中止、**不替換**（避免換上半個壞檔導致 `Failed to load Python DLL`）。
4. 替換前等 exe **完全解鎖**（onefile 啟動器母程序可能仍鎖檔），再就地覆蓋並重啟；失敗會還原 `.bak`。

→ 因此每次發 Release **務必有打包好的 `.exe`**（CI 會自動附上），否則自動更新會失效。

---

## 注意事項

- 版號要 **兩處同步**（`APP_VERSION` + `VERSION`）。
- **發布靠推 tag，不要手動上傳 exe**（會被 CI 覆蓋）。
- 更新器修好後，使用者需**手動安裝一次該版**，之後的自動更新才會走到新邏輯。
- 別把 `dist/`、`build/`、`.understand-anything/` 提交進版控。

---

## 版本紀錄

| 版號 | 內容 |
|---|---|
| `0.1.4` | 新增 8 個 Matt Pocock 技能、GUI 改向量圖示去 emoji、嚴重度標記文字化 |
| `0.1.5` | 新 App 圖示（對話框 + `>_`）、更新器強化（下載大小/雜湊驗證 + 等檔案解鎖再替換）、修正本發版文件 |
