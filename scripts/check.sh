#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
fail=0
python3 - <<'EOF' || fail=1
import json, re
m = json.load(open("gemini-extension.json"))
assert re.fullmatch(r"[a-z0-9-]+", m["name"]) and m["name"] == "emboss", "name must be emboss (lowercase, dashes)"
assert re.fullmatch(r"\d+\.\d+\.\d+", m["version"]), "semver version"
assert m["description"] and len(m["description"]) <= 200
srv = m["mcpServers"]["emboss"]
assert srv["httpUrl"] == "https://api.getemboss.ai/mcp", "exact MCP url"
assert "command" not in srv and "headers" not in srv, "remote server: no command, no static headers"
assert m.get("contextFileName", "GEMINI.md") == "GEMINI.md"
print("manifest ok")
EOF
test -f GEMINI.md || { echo "GEMINI.md missing"; fail=1; }
grep -qi "never invent" GEMINI.md || { echo "GEMINI.md must carry the never-invent rule"; fail=1; }
grep -q "5 form creations" GEMINI.md || { echo "GEMINI.md must carry the free-tier sentence"; fail=1; }
if grep -rIl $'\xe2\x80\x94' --exclude-dir=.git . ; then echo "em dash found"; fail=1; fi
if grep -rIiE "guarantee|instant|blazing|fastest" README.md GEMINI.md ; then echo "forbidden claim"; fail=1; fi

python3 - <<'EOF' || fail=1
import json
p = json.load(open("plugin.json"))
assert p["name"] == "emboss", "plugin.json name must be emboss"
assert p.get("$schema") == "https://antigravity.google/schemas/v1/plugin.json", "plugin.json $schema exact"

c = json.load(open("mcp_config.json"))
srv = c["mcpServers"]["emboss"]
assert srv.get("serverUrl") == "https://api.getemboss.ai/mcp", "mcp_config.json must use serverUrl exactly"
assert "url" not in srv and "httpUrl" not in srv and "command" not in srv, "mcp_config.json: no url/httpUrl/command"
print("antigravity manifest ok")
EOF

test -f skills/emboss/SKILL.md || { echo "skills/emboss/SKILL.md missing"; fail=1; }
head -1 skills/emboss/SKILL.md | grep -q '^---$' || { echo "SKILL.md must start with YAML frontmatter"; fail=1; }
grep -q "^name: emboss$" skills/emboss/SKILL.md || { echo "SKILL.md frontmatter must set name: emboss"; fail=1; }

# GEMINI.md and skills/emboss/SKILL.md must stay in sync on the shared rules
# and examples (everything except the heading/frontmatter and the CLI-specific
# "Signing in" section, which legitimately differs between the two clients).
extract_shared() {
  awk '/^# Emboss/{p=1} p && /^## Signing in/{exit} p' "$1"
  echo "---examples---"
  awk '/^## Examples/{p=1} p' "$1"
}
if ! diff -q <(extract_shared GEMINI.md) <(extract_shared skills/emboss/SKILL.md) > /dev/null; then
  echo "GEMINI.md and skills/emboss/SKILL.md have drifted out of sync (shared section)"
  diff <(extract_shared GEMINI.md) <(extract_shared skills/emboss/SKILL.md) || true
  fail=1
fi

exit $fail
