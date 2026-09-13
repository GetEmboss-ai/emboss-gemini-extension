# Emboss

Emboss turns flat PDF forms into fillable AcroForm PDFs and fills them from
values, from documents or notes, or from a spreadsheet, and faxes a finished
PDF to any fax number. Every operation is
billed to the user's Emboss account. The first 5 form creations, 5 context
fills, and 5 standard fills each month are free; free operations are limited
to 5-page forms. `suggest_mapping` is billed as one context fill even when
called on its own, and `fill_batch` runs it automatically (also billed) if
called without an explicit `mapping`.

## Which tool for which task

| User wants | Tool sequence |
|---|---|
| Make a flat PDF fillable | `create_form`, then `get_form` |
| Fill a form from values you already have | `get_form` (to see fields), then `fill_form` |
| Fill a form from a document, notes, or pasted text | `fill_form_from_context`, then poll `get_job` |
| Fill one form per row of a spreadsheet/CSV | `suggest_mapping`, confirm the mapping with the user, then `fill_batch`, then poll `get_batch` |
| Check remaining free operations or billing | `get_usage` |
| Reuse a form already uploaded | `list_forms` first, instead of `create_form` |
| Fax a finished PDF to a number | `send_fax` with `to` in E.164 form and an `artifact_id` from any earlier result (or the `job_id` from `commit_proposal` or `fill_form_from_context` once `get_job` is ready, a `form_id`, or `pdf_url` / `pdf_base64`), then poll `get_fax`. A `sources` list faxes several artifacts as one packet: each entry is an `artifact_id` with an optional `pages` range; pay-per-call callers add an `artifact_token` per entry. |

## Rules

- Never invent field values. Only fill what the user gave you, or what a
  context document/CSV actually says.
- When `fill_form` returns `unmatched`, show the user those labels and ask
  what to do with them; do not guess.
- For choice fields, pick one of the options `get_form` returned (its label
  or value) rather than free text.
- For checkboxes, pass `yes` or `no`.
- `fill_form_from_context`, `fill_batch`, and `get_batch` can take a while.
  Poll `get_job` / `get_batch` about every 20 seconds and tell the user it is
  still running rather than going quiet.
- Present every `download_url` as a plain link the user can click.
- On a 402, relay the tool's `message` and point at `billing_url`: for
  `over_free_tier` explain that this month's free forms are used up; for
  `over_page_cap` explain that the form is over the 5-page free limit and a
  payment method is needed to continue.
- On `unsupported_file`, tell the user to export the document to PDF first;
  Emboss only accepts PDFs.
- Never paste long context text back into the chat. Summarize what was sent
  (e.g. "sent the 2-page intake note as context") instead of quoting it in
  full.
- Only call `delete_form` when the user explicitly asks to delete a form.
  It is permanent.
- Before `send_fax`, confirm the destination number with the user and show
  it back in E.164 form (for example +15025551212). Faxes are billed per
  page at delivery; a failed fax is not charged. Poll `get_fax` about every
  20 seconds until `status` is `delivered` or `failed`.

## Getting the PDF in

Prefer, in order:
1. A form already in the user's library: check with `list_forms` before
   creating a new one.
2. A public `https` link to the PDF: pass it as `pdf_url`.
3. `pdf_base64` for small files the user pasted, or that Gemini CLI can read
   from disk. Read the file and base64-encode it yourself. Keep base64
   uploads under 10 MB; for anything larger, ask the user to host it
   somewhere with a public link and use `pdf_url` instead.

The same choice applies to `context_urls` in `fill_form_from_context` and to
`csv_url` in `suggest_mapping` / `fill_batch`: a public https link is
preferred, inline text (`context_text`, `csv_text`) works for small content.

## Signing in

The first time a tool call needs it, Gemini CLI opens your browser to sign
in to Emboss. Sign in and click Allow to grant access. If you need to
disconnect later, go to your Emboss Dashboard, then Account, then Connected
apps.

If Emboss tools are missing or a tool returns `insufficient_scope` /
`unauthenticated`, run `/mcp` to check the server's connection status, or
reinstall the extension.

## Examples

**1. "Make this W-9 fillable"** (user attaches a PDF or gives a link)

- Call `create_form` with `pdf_url` (or `pdf_base64` if the file is only
  available locally).
- Call `get_form` with the returned `form_id` to confirm it is `ready` and
  see the fields.
- Say back: "Your W-9 is fillable. Download it here: `<download_url>`. It
  has N fields if you'd like me to fill any of them."

**2. "Fill out this rental application using my notes"**

- If the form is not already in the library, call `create_form` first, then
  `get_form` to see the fields.
- Call `fill_form_from_context` with `form_id` and `context_text` set to the
  user's notes (or `context_urls` if they gave a document link).
- Poll `get_job` with the returned `job_id` every ~20 seconds, telling the
  user it's still processing.
- When `status` is `ready`, say back: "Filled and ready:
  `<download_url>`. I filled N fields; M I couldn't find an answer for."

**3. "Fill this intake form for everyone in my spreadsheet"**

- Call `suggest_mapping` with `form_id` and `csv_url` (or `csv_text`).
- Show the proposed column-to-field mapping and confirm it with the user
  before proceeding (or take their corrected mapping).
- Call `fill_batch` with the confirmed `mapping`.
- Poll `get_batch` with the returned `batch_id` every ~20 seconds until
  `status` is `complete` or `failed`.
- Say back: "Filled N of M rows. Here's the zip: `<zip_url>`" and list any
  per-row errors.
