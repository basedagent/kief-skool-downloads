# Document reading

## What happens when a student adds a material

1. The app saves the original bytes locally with a SHA-256 fingerprint. Files are limited to 20 MB.
2. A separate, time-limited Node process extracts native text and generates WebP previews. PDF processing no longer requires a separately installed `pdftotext` program.
3. Scans and raster images use bundled offline English OCR. No AI provider receives the upload during local processing.
4. The material records processing status, page count, attempted pages, warnings, preview images, and extracted text. "Processed" is not a guarantee of perfect reading.
5. The student can review previews, download the unchanged original, ask about a page, or ask about the material.

Supported inputs are PDF, PNG/JPEG/WebP, DOCX, PPTX, and UTF-8 TXT/Markdown/CSV/TSV. Legacy `.doc`/`.ppt`, spreadsheets, audio, video, arbitrary archives, and password-protected documents are not supported as readable tutor sources. Unsupported originals remain downloadable. Export legacy Office files to PDF or modern Office formats first.

PDFs have an initial native-text pass before rendering/OCR, so expensive image processing does not prevent reading the later native-text pages. Defaults: 200 rendered/OCR pages, up to 2,000 native-text PDF pages, 500,000 extracted characters, 200 saved images, 128 MB of generated images, and a two-minute worker deadline. Limits or failed pages create explicit warnings and partial status. DOCX pagination is not inferred. PPTX slide order and speaker notes are extracted, but editable charts, shapes, animation, and exact slide layout are not reconstructed. Export to PDF when visual layout matters.

OCR and vision can misread handwriting, formulas, columns, low-resolution text, or graphs. A successful import is not a claim to understand every pixel. The UI and tutor preserve these qualifications.

## Existing uploads

Use **Materials > Open > Reprocess**. It processes the preserved original into a new derived directory and atomically updates the resource metadata. The original, resource ID, import date, and fingerprint stay unchanged. Existing readable text is retained if a retry yields no readable text or images. Previously generated files remain local for recovery; exports include only the current registered derivatives.

## Tutor coverage

Opening a tutor or importing a material makes no inference request. The student must confirm sharing with the selected provider.

**Review entire document** sends all extracted text and, when enabled, all registered page/embedded images in bounded batches. A request contains at most 48,000 source characters, eight images, and 12 MiB of encoded image data; API payloads are also capped at 16 MiB before transmission. More than one batch produces evidence digests followed by a synthesis. All batches must succeed before a complete summary is returned. Up to 32 batches are supported; larger reviews are rejected with an instruction to split the document. Long reviews may take minutes and use multiple metered provider requests. **Stop review**, closing the tutor, or disconnecting the browser cancels active local provider work and prevents subsequent batches. A remote provider may still charge for work already accepted.

**Include page images** requires a vision-capable model. Turning it off sends extracted text only and explicitly excludes visual-only details from coverage claims. There is no silent provider fallback.

Turning off full review uses selected text excerpts and at most one image. An explicit page question uses the selected page. Class-wide questions retrieve excerpts from the syllabus, materials, and linked Google notes; they do not review the entire class library. Select a material for a complete review.

If a selected material has neither readable text nor usable images, the API returns 422 before inference. The tutor must not guess a document's content from its title.

## Implementation

- `server/material-extraction.mjs`: portable, isolated extraction; offline OCR; Office ZIP/XML safety bounds.
- `server/files.mjs`: immutable original import, reprocessing, confined generated files, public metadata, backup references.
- `server/tutor.mjs`: source selection and coverage-aware prompts.
- `server/tutor-review.mjs`: complete batch traversal and evidence synthesis.
- `server/tutor-providers.mjs`: multiple image inputs across provider adapters.

The installer uses `npm ci --omit=dev --ignore-scripts`. PDF rendering relies on the supported platform's prebuilt `@napi-rs/canvas` optional package; OCR language data ships as an npm dependency. Installation needs network access for npm packages, but extraction does not need a cloud OCR account.

## References

- [PDF.js](https://mozilla.github.io/pdf.js/)
- [Tesseract.js](https://github.com/naptha/tesseract.js)
- [OpenAI image input guidance](https://developers.openai.com/api/docs/guides/images-vision)
