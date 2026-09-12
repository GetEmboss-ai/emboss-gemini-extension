# Emboss for Gemini CLI and Antigravity

Fill PDF forms without leaving your terminal. Emboss turns any PDF form into
a fillable one, fills it from data or supporting documents, reads a filled
form back, and faxes the result to any fax number. All through Emboss's
remote MCP server.

## What it does

- **Make a form fillable**: upload a flat or scanned PDF and get back a real
  AcroForm PDF with detected fields.
- **Fill from values**: see a form's fields and fill them with values you
  already have.
- **Fill from context**: point at notes, a document, or pasted text and let
  Emboss pull out the answers.
- **Fill a batch**: fill the same form once per row of a CSV or spreadsheet.
- **Fax the result**: send a finished PDF to any fax number and track delivery.

## Install in Gemini CLI

```
gemini extensions install https://github.com/GetEmboss-ai/emboss-gemini-extension
```

Then run `gemini`, ask it to work with a PDF form, and sign in when your
browser opens on the first tool call.

## Install in Antigravity

```
git clone https://github.com/GetEmboss-ai/emboss-gemini-extension
agy plugin install ./emboss-gemini-extension
```

**Note:** Antigravity CLI does not yet send OAuth tokens to remote HTTP MCP
servers (tracked in
[google-antigravity/antigravity-cli#25](https://github.com/google-antigravity/antigravity-cli/issues/25),
open). Until that's fixed, authenticate with an Emboss API key instead: add
a static `Authorization` header to `mcp_config.json` in your installed
plugin directory (typically `~/.gemini/config/plugins/emboss/mcp_config.json`;
run `agy plugin list` to confirm the path on your machine):

```json
{
  "mcpServers": {
    "emboss": {
      "serverUrl": "https://api.getemboss.ai/mcp",
      "headers": {
        "Authorization": "Bearer sk_live_yourkey"
      }
    }
  }
}
```

Get an API key from your Emboss Dashboard, then Account, then API keys.
Never commit a key to source control.

## Manual alternative

Both clients also accept a hand-written `mcpServers` entry in their
`settings.json` instead of installing this repo. For Gemini CLI
(`~/.gemini/settings.json` or your workspace `.gemini/settings.json`):

```json
{
  "mcpServers": {
    "emboss": {
      "httpUrl": "https://api.getemboss.ai/mcp",
      "timeout": 300000
    }
  }
}
```

## Pricing

The first 5 form creations, 5 context fills, and 5 standard fills each month
are free; free operations are limited to 5-page forms. See
[getemboss.ai/pricing](https://getemboss.ai/pricing) for full pricing.

## Privacy

See [getemboss.ai/privacy](https://getemboss.ai/privacy).

## Support

[edwin@getemboss.ai](mailto:edwin@getemboss.ai)

## Development

```
bash scripts/check.sh
```
