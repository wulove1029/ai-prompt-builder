# AI Prompt Builder

PyQt6 desktop prompt builder for gstack, Matt Pocock skills, Ruflo, Superpowers, and UI/UX Pro Max workflows.

## Run From Source

```powershell
python -m venv .venv
.\.venv\Scripts\pip install -r requirements.txt
.\.venv\Scripts\python gstack_prompt_builder.py
```

## Build Windows EXE

```powershell
pyinstaller "gstack Prompt Builder.spec"
```

The built application is created at:

```text
dist/AI Prompt Builder.exe
```

## GitHub Release Auto Update

The app checks GitHub Releases for newer versions and can replace the running EXE on Windows.

The GitHub Actions release workflow automatically patches the built EXE to use the current repository (`owner/repo`) as its update source.

For local testing, you can override the update source with an environment variable:

```powershell
$env:AI_PROMPT_BUILDER_UPDATE_REPO = "your-github-name/ai-prompt-builder"
python gstack_prompt_builder.py
```

The source fallback lives here in `gstack_prompt_builder.py`:

```python
UPDATE_REPO = os.environ.get("AI_PROMPT_BUILDER_UPDATE_REPO", "YOUR_GITHUB_USERNAME/ai-prompt-builder")
```

Release tags should use semantic versions, for example:

```text
v0.1.0
v0.1.1
v0.2.0
```

The release asset must include:

```text
AI Prompt Builder.exe
```

The included GitHub Actions workflow builds and uploads that asset automatically when you push a tag.

## Publish To GitHub

```powershell
git init
git add .
git commit -m "initial release"
git branch -M main
git remote add origin https://github.com/YOUR_GITHUB_USERNAME/ai-prompt-builder.git
git push -u origin main
git tag v0.1.0
git push origin v0.1.0
```

After the tag is pushed, GitHub Actions will build the EXE and attach it to a GitHub Release.
