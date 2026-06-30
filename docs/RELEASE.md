# 發版流程（Release Runbook）

本文件記錄 **AI Prompt Builder** 的「升級版號 → 提交 → 發布」完整流程。
Repo：`github.com/wulove1029/ai-prompt-builder`，版本直接在 `main` 分支發布。

---

## 0. 前置工具

| 工具 | 用途 | 檢查 |
|---|---|---|
| `python` + `PyInstaller` | 打包 `.exe` | `python -m PyInstaller --version` |
| `git` | 版本控制 | `git --version` |
| `gh`（GitHub CLI，已登入） | 建立 Release | `gh auth status` |

---

## 1. 升級版號（**兩個地方都要改**）

版號同時存在兩處，務必一起改、保持一致：

1. `gstack_prompt_builder.py` 約第 60 行：`APP_VERSION = "x.y.z"`
2. 根目錄 `VERSION` 檔

版號規則：採 **patch 遞增**（`0.1.0 → 0.1.1 → … → 0.1.4`）。
功能型大改可考慮升 minor（如 `0.2.0`）。

> 注意：本檔為 **UTF-8 + CRLF、無 BOM**。用編輯器改沒問題；若用腳本改，請以 binary 方式讀寫避免換行/編碼被破壞。

改完先做語法檢查：

```bash
python -m py_compile gstack_prompt_builder.py
```

---

## 2. 打包 `.exe`

使用既有的 PyInstaller spec（`console=False`、icon `app_icon.ico`）：

```bash
python -m PyInstaller --noconfirm "gstack Prompt Builder.spec"
```

產物：`dist/AI Prompt Builder.exe`（約 37 MB）。
`build/`、`dist/` 已被 `.gitignore`，不會進版控。

---

## 3. 提交（commit + push）

只 stage 該進版控的檔案（**不要** 把 `dist/`、`build/`、`.understand-anything/` 加進來）：

```bash
git add gstack_prompt_builder.py VERSION
git commit -m "feat: vX.Y.Z — <一句話描述>"
git push origin main
```

---

## 4. 發布 GitHub Release（**必須附上 `.exe`**）

```bash
gh release create vX.Y.Z "dist/AI Prompt Builder.exe" \
  --target main \
  --title "vX.Y.Z" \
  --notes-file release-notes.md
```

- GitHub 會把附件名稱的空白換成點 → 上架後為 `AI.Prompt.Builder.exe`。
- `--target main` 會在目前 `main` 的 HEAD 上建立 tag `vX.Y.Z`。

---

## 5. 驗證

```bash
# 程式內「檢查更新」會打的端點，確認回傳新版且有 .exe
gh api repos/wulove1029/ai-prompt-builder/releases/latest \
  -q '.tag_name + "  assets=" + ([.assets[].name]|join(","))'
```

預期輸出類似：`v0.1.4  assets=AI.Prompt.Builder.exe`

---

## 自動更新合約（為什麼 Release 一定要附 `.exe`）

程式內 `_AppUpdateChecker`：

1. 查 `GET /repos/<repo>/releases/latest`
2. 比較 `tag_name`（去掉 `v`）與 `APP_VERSION`，較新才提示更新
3. 找附件：先找名稱等於 `UPDATE_ASSET_NAME`（`"AI Prompt Builder.exe"`），找不到就 fallback 找任何 **`.exe`** 結尾的附件
4. 沒有 `.exe` → 回報「release 沒有 .exe asset」，使用者無法更新

→ 因此每次發 Release **務必附上打包好的 `.exe`**，否則舊版使用者的自動更新會失效。

---

## 注意事項

- 版號要 **兩處同步**（`APP_VERSION` + `VERSION`）。
- Release **一定要附 `.exe`**，否則 updater 失效。
- 直接在 `main` 提交與發布（本 repo 的既有慣例）。
- 別把 `dist/`、`build/`、`.understand-anything/` 提交進版控。

---

## 範例：v0.1.4（本次）

| 項目 | 值 |
|---|---|
| 版號 | `0.1.3` → `0.1.4` |
| 內容 | 新增 8 個 Matt Pocock 技能、GUI 改向量圖示去 emoji、嚴重度標記文字化 |
| Release | https://github.com/wulove1029/ai-prompt-builder/releases/tag/v0.1.4 |
