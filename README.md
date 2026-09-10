# Kief Skool

Your classes, deadlines, and study materials. On your computer.

Kief Skool is a local student planner with a liquid-glass interface. Add your own classes, see what is due next, save original syllabi and class materials, and mark work complete. No account is required. Your documents stay on your computer unless you explicitly use the optional online tutor.

![Kief Skool first-run workspace](preview.png)

## Install on a Mac

**First:** install [Node.js](https://nodejs.org/en/download) 22.12 or later if you do not already have it. The installer checks this and explains what is missing. Works with Apple Silicon and Intel macOS; no sudo or GitHub login required.

Open Terminal and run:

```bash
curl -fsSL https://raw.githubusercontent.com/basedagent/kief-skool-downloads/main/install.sh | bash
```

Then launch:

```bash
~/.local/bin/kief-skool start --open
```

If `~/.local/bin` is on your PATH, you can use `kief-skool start --open`. Keep the terminal running while you use the app. **Ctrl-C** stops the app.

This opens http://127.0.0.1:4311 in your browser. No hosted account, database setup, API key, Codex installation, or terminal course setup is needed.

### Prefer to inspect the installer first?

The one-line command executes downloaded code. Download and review it before running:

```bash
curl -fsSL https://raw.githubusercontent.com/basedagent/kief-skool-downloads/main/install.sh -o /tmp/kief-skool-install.sh
less /tmp/kief-skool-install.sh
bash /tmp/kief-skool-install.sh
```

The installer checks the versioned archive's SHA-256 before installation. It installs only under your user-owned `.local` directory, leaving your existing classes separate from application versions.

## Set up your semester

1. Click **Add a course** and enter your class title, code, term, and timezone.
2. Add a deadline from your syllabus.
3. Import your syllabus or notes from the course workspace.
4. Return to Home to see your next deadline and mark finished work complete.

You can try a clearly labeled synthetic demo first. The download never includes another student's class records or documents. A local profile is optional and does not require email verification.

## Privacy

Data on a Mac lives at `~/Library/Application Support/Kief Skool/`. Uploaded files are copied locally, with a hash and import timestamp. Automatic text extraction is optional; importing a syllabus does not invent or confirm deadlines. A PDF stays available even if text extraction is unavailable.

Version 0.4 includes built-in PDF text extraction, page previews, offline English OCR for scans/photos, and DOCX/PPTX text and embedded-image processing. Use **Reprocess text** for an older unreadable upload. Processing warnings identify unsupported content and incomplete coverage; no system PDF utility is required. See [supported formats and limits](docs/DOCUMENTS.md).

The core planner works offline while its local service is running. Optional tutoring sends relevant excerpts and questions to the selected model provider only when you request help. You do not need it to use the planner.

## Connect a tutor

Open **Tutor connections** in the sidebar, or the settings button inside a course tutor.

1. Choose **ChatGPT via Codex** to reuse your existing local ChatGPT login. If needed, install the official Codex CLI and use **Sign in with ChatGPT**. The default is GPT-5.6 Terra with medium reasoning, subject to your account's model access and usage limits.
2. Alternatively, choose **OpenAI API**, **Anthropic**, or **Gemini**, enter your API key and model ID, and save. The form links to each provider's key dashboard. These routes do not require Codex; API billing is separate from consumer subscriptions.
3. For another compatible service or local model, choose **Custom endpoint**, enter its API base URL and model, and add a key if required. This supports OpenAI-compatible Chat Completions servers, not arbitrary API formats. Model/image/reasoning support depends on the server.

**Test connection** sends only a tiny synthetic greeting, never your classes or files. It can consume account usage. Before chatting, review the destination and consent to sharing the displayed context. Changing connections requires consent again.

**Review entire document** works through all extracted text and enabled page images in bounded batches. Large reviews can take minutes and use multiple model requests. Turn off images for a text-only model, ask about a single page for a focused answer, or use **Stop review** to cancel.

ChatGPT OAuth tokens stay managed by Codex. Saved API keys live in an owner-restricted local `tutor-settings.json` file, are not application-encrypted, and are excluded from **in-app backup exports**. Optional Google credentials live separately in `google-docs-private.json` and are also excluded. A manual full-folder backup includes them. Keys are not stored in browser storage or returned by the settings API. Do not share your personal data directory or keys with friends.

Use **Export backup** in the app, or stop the app and back up the entire data directory. Keep backups private. Uninstalling the program preserves student data. The app is a single-user local service; do not expose its port to an untrusted network.

## Google Docs notes

Each class's **Notes** section can link selected Google Docs and refresh their local text copies without replacing notes you typed in the app. This is optional, read-only Drive access, not Gmail inbox access. A one-time Google Cloud **Desktop app OAuth client** is required; there is no bundled shared Google login. Enable both the Drive and Docs APIs, then follow the [Google Docs setup guide](docs/GOOGLE_DOCS.md).

## Useful commands

```bash
kief-skool start --open --port 4320
kief-skool status
kief-skool doctor
kief-skool upgrade
kief-skool uninstall --yes
```

The app runs in the foreground. Stop it with Ctrl-C before upgrading. Upgrade installs a newer published version; trying to install a version already present leaves it unchanged.

## Downloads

See [versioned releases](https://github.com/basedagent/kief-skool-downloads/releases) for archives and checksums. This repository is the public distribution channel. The development repository is private. Release packages include the generic runtime code, but no private class files or development history.

## Current limits

macOS is the tested installer target. Node.js 22.12+ and npm are prerequisites. This is a local browser app, not a signed native desktop app. Cloud sync, LMS integrations, automated authoritative syllabus parsing, and a backup restore wizard are not included. No user tracking or cloud account is required.
