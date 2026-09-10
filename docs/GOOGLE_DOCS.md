# Google Docs in class notes

Google Docs is an optional, read-only connection. It is separate from the local student profile and ChatGPT/Codex sign-in. The app never asks for a Gmail password and does not request inbox access.

## One-time setup

No shared Google OAuth client is bundled. A valid Google Cloud client is required before a genuine sign-in link can be created.

1. Open [Google Cloud](https://console.cloud.google.com/) and create or select a project.
2. Enable the [Google Drive API](https://console.cloud.google.com/apis/library/drive.googleapis.com) and [Google Docs API](https://console.cloud.google.com/apis/library/docs.googleapis.com).
3. Configure the Google Auth Platform consent screen. For a personal external app in Testing, add your Google account as a test user. Organizational restrictions may require administrator approval.
4. Open [Google OAuth Clients](https://console.cloud.google.com/auth/clients), create a client, and choose **Desktop app**, not Web application.
5. In Kief Skool, open a class, choose **Notes**, and expand Google setup. Enter the client ID and client secret in the local app, then save. Do not paste access tokens, passwords, or credentials into a chat or repository.
6. Choose **Connect Google Docs**. Use your normal system browser to choose the account and grant consent. The callback returns to a temporary loopback port on your own computer.
7. Return to Notes, browse or search your documents, and choose the document to link to that class.

Google may show an unverified/testing-app warning for your own development client. Confirm that the project and client belong to you; do not bypass warnings for an unknown app. Testing projects can require periodic reconnection. For distribution with one shared client, the publisher must complete the appropriate Google consent/verification requirements rather than asking students to ignore warnings.

Advanced local configuration may use `KIEF_SKOOL_GOOGLE_CLIENT_ID` and `KIEF_SKOOL_GOOGLE_CLIENT_SECRET`, or `KIEF_SKOOL_GOOGLE_CLIENT_FILE` pointing to a downloaded Desktop client JSON file. Environment-managed configuration is not editable through the UI.

## Permissions and data

The requested scope is `https://www.googleapis.com/auth/drive.readonly`. Google grants read-only access to all Drive files; this app limits its UI to listing Google Docs and importing explicitly selected documents. This is broader than access to one picked file and is disclosed before connecting. No Drive modifications or Gmail access are requested.

Each class can link up to 20 documents. The Docs API reads all document tabs, including nested tabs, rather than relying on an export that may omit tabs. Each imported plain-text copy is limited to 100,000 bytes and records its title, document ID, Google modification time, and local refresh time. An oversized document fails instead of silently truncating. This is a plain-text snapshot, not a full-fidelity copy of formatting, images, or interactive content. Export a Google Doc to PDF and upload it to Materials for visual document processing.

Linked copies appear separately from manually written local notes. **Refresh** updates only the linked copy. **Unlink** removes the local class association, not the Google document. **Disconnect** removes this app's locally saved Google tokens; existing local notes remain available. Remove the app in [Google account connections](https://myaccount.google.com/connections) to revoke the Google-side grant as well.

Linked document text can become tutor context only when the student explicitly sends a tutor message after reviewing the provider consent notice. Importing/refreshing a Google document alone does not send it to an AI provider.

## Security and routes

OAuth uses a random, one-use, five-minute state, PKCE S256, a separate loopback callback listener, fixed Google endpoints, and bounded requests. Access/refresh tokens and client configuration stay in permission-restricted `google-docs-private.json`, never in frontend storage, source control, material downloads, or in-app backups. It is permission-restricted local storage, not an application-encrypted vault. Backups include the linked note content, not the credentials.

- `GET /api/google-docs/status`: redacted readiness and disclosure.
- `POST /api/google-docs/config`: `{clientId,clientSecret?}`.
- `POST /api/google-docs/connect`: `{}`; returns a real authorization URL only after configuration.
- `DELETE /api/google-docs/connection`: remove local tokens.
- `GET /api/google-docs/files?q=...&pageToken=...`: bounded Google Docs listing.
- `POST /api/courses/:id/google-docs`: `{fileId}`; attach a local snapshot.
- `POST /api/courses/:id/google-docs/:docId/refresh`: `{}`; refresh an existing association.
- `DELETE /api/courses/:id/google-docs/:docId`: unlink without deleting the source.

## Primary references

- [Google OAuth for installed applications](https://developers.google.com/identity/protocols/oauth2/native-app)
- [Drive scopes](https://developers.google.com/workspace/drive/api/guides/api-specific-auth)
- [Drive download and export](https://developers.google.com/workspace/drive/api/guides/manage-downloads)
- [Google Docs document tabs](https://developers.google.com/workspace/docs/api/how-tos/tabs)
