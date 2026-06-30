# -*- mode: python ; coding: utf-8 -*-
# onedir（資料夾）模式：python.dll 與相依 DLL 都實體放在 App 資料夾旁，
# 不再於執行時解壓到 %TEMP%\_MEI —— 徹底避免 onefile 那種「Failed to load Python DLL」
# 的更新／重啟問題。最終由 Inno Setup（installer.iss）包成安裝檔。

a = Analysis(
    ['gstack_prompt_builder.py'],
    pathex=[],
    binaries=[],
    datas=[],
    hiddenimports=[],
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=[],
    noarchive=False,
    optimize=0,
)
pyz = PYZ(a.pure)

exe = EXE(
    pyz,
    a.scripts,
    [],
    exclude_binaries=True,
    name='AI Prompt Builder',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    upx_exclude=[],
    console=False,
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
    icon=['app_icon.ico'],
)

coll = COLLECT(
    exe,
    a.binaries,
    a.datas,
    strip=False,
    upx=True,
    upx_exclude=[],
    name='AI Prompt Builder',
)
