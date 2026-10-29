#!/usr/bin/env bash
# AI-OS Single Source of Truth Template Generator
# Generates templates/project from master repository files and computes manifest

set -euo pipefail

CHECK_MODE=false
while [[ $# -gt 0 ]]; do
    case "$1" in
        --check|-c)
            CHECK_MODE=true
            shift
            ;;
        *)
            echo "Unknown argument: $1" >&2
            echo "Usage: build-templates.sh [--check]" >&2
            exit 1
            ;;
    esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TEMPLATE_DIR="$ROOT_DIR/templates/project"

if [ ! -f "$ROOT_DIR/VERSION" ]; then
    echo "❌ Missing VERSION file at repo root" >&2
    exit 1
fi
VERSION=$(cat "$ROOT_DIR/VERSION" | tr -d '[:space:]')

TARGET_DIR="$TEMPLATE_DIR"
TMP_DIR=""

if [ "$CHECK_MODE" = true ]; then
    TMP_DIR=$(mktemp -d 2>/dev/null || mktemp -d -t 'ai-os-build')
    TARGET_DIR="$TMP_DIR/project"
    mkdir -p "$TARGET_DIR"
    cp -r "$TEMPLATE_DIR/." "$TARGET_DIR/"
    echo "🔍 Checking template synchronization against master..."
else
    echo "🔨 Building AI-OS project template (v$VERSION)..."
fi

# 1. Sync playbooks and prompts into .ai-os/
mkdir -p "$TARGET_DIR/.ai-os/playbooks"
mkdir -p "$TARGET_DIR/.ai-os/prompts"
cp -r "$ROOT_DIR/playbooks/"* "$TARGET_DIR/.ai-os/playbooks/"
cp -r "$ROOT_DIR/prompts/"* "$TARGET_DIR/.ai-os/prompts/"
mkdir -p "$TARGET_DIR/.ai-os/optional/claude-hooks"
if [ -d "$ROOT_DIR/.ai-os/optional/claude-hooks" ]; then
    cp -r "$ROOT_DIR/.ai-os/optional/claude-hooks/"* "$TARGET_DIR/.ai-os/optional/claude-hooks/"
fi

# 2. Sync security filters, verification layer, and githooks
mkdir -p "$TARGET_DIR/.ai"
mkdir -p "$TARGET_DIR/.githooks"
mkdir -p "$TARGET_DIR/.ai-os/scripts"
cp "$ROOT_DIR/.ai/secret-patterns.txt" "$TARGET_DIR/.ai/secret-patterns.txt"
cp "$ROOT_DIR/.ai/secret-allowlist.txt" "$TARGET_DIR/.ai/secret-allowlist.txt"
[ -f "$ROOT_DIR/.ai/deps-approved.txt" ] && cp "$ROOT_DIR/.ai/deps-approved.txt" "$TARGET_DIR/.ai/deps-approved.txt"
[ -f "$ROOT_DIR/.ai/import-aliases.txt" ] && cp "$ROOT_DIR/.ai/import-aliases.txt" "$TARGET_DIR/.ai/import-aliases.txt"
[ -f "$ROOT_DIR/.ai/verify.conf" ] && cp "$ROOT_DIR/.ai/verify.conf" "$TARGET_DIR/.ai/verify.conf"
cp "$ROOT_DIR/.githooks/pre-commit" "$TARGET_DIR/.githooks/pre-commit"
chmod +x "$TARGET_DIR/.githooks/pre-commit"
cp "$ROOT_DIR/scripts/ai_os_verify.py" "$TARGET_DIR/.ai-os/scripts/ai_os_verify.py"
cp "$ROOT_DIR/scripts/ai-os-verify.sh" "$TARGET_DIR/.ai-os/scripts/ai-os-verify.sh"
cp "$ROOT_DIR/scripts/ai-os-verify.ps1" "$TARGET_DIR/.ai-os/scripts/ai-os-verify.ps1"
cp "$ROOT_DIR/scripts/ai-os-run" "$TARGET_DIR/.ai-os/scripts/ai-os-run"
cp "$ROOT_DIR/scripts/ai-os-run.ps1" "$TARGET_DIR/.ai-os/scripts/ai-os-run.ps1"
chmod +x "$TARGET_DIR/.ai-os/scripts/"*

# 3. Sync Git and provider configurations
cp "$ROOT_DIR/.gitattributes" "$TARGET_DIR/.gitattributes"
mkdir -p "$TARGET_DIR/.cursor/rules"
cp "$ROOT_DIR/.cursor/rules/agents.mdc" "$TARGET_DIR/.cursor/rules/agents.mdc"
mkdir -p "$TARGET_DIR/.github"
cp "$ROOT_DIR/.github/copilot-instructions.md" "$TARGET_DIR/.github/copilot-instructions.md"
cp "$ROOT_DIR/.github/CODEOWNERS" "$TARGET_DIR/.github/CODEOWNERS"

for ad in "CLAUDE.md" "GEMINI.md" "CODEX.md"; do
    cp "$ROOT_DIR/$ad" "$TARGET_DIR/$ad"
done

if [ -f "$ROOT_DIR/mcp.json" ]; then
    cp "$ROOT_DIR/mcp.json" "$TARGET_DIR/mcp.json"
fi

# 4. Compile rules for template
"$SCRIPT_DIR/compile-rules.sh" --project "$TARGET_DIR"

# 5. Generate .ai-os/manifest.json using Python
python3 -c "
import os, sys, hashlib, json, datetime

target_dir = sys.argv[1]
version = sys.argv[2]
check_mode = sys.argv[3] == 'true'
real_template_dir = sys.argv[4]

manifest_path = os.path.join(target_dir, '.ai-os', 'manifest.json')
text_extensions = {'.md', '.mdc', '.txt', '.json', '.sh', '.ps1', '.py', '.conf', '.gitattributes', '.gitignore', ''}

file_hashes = {}
for root, dirs, files in os.walk(target_dir):
    for f in sorted(files):
        full_path = os.path.join(root, f)
        if full_path == manifest_path:
            continue
        rel_path = os.path.relpath(full_path, target_dir).replace(os.sep, '/').replace(chr(92), '/')
        
        with open(full_path, 'rb') as fp:
            data = fp.read()
        
        ext = os.path.splitext(f)[1].lower()
        if ext in text_extensions:
            data = data.replace(b'\r\n', b'\n')
        
        h = hashlib.sha256(data).hexdigest()
        file_hashes[rel_path] = h

sorted_hashes = {k: file_hashes[k] for k in sorted(file_hashes.keys())}

gen_at = datetime.datetime.now(datetime.timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')
if not check_mode and os.path.isfile(manifest_path):
    try:
        with open(manifest_path, 'r', encoding='utf-8') as efp:
            prev = json.load(efp)
            if prev.get('ai_os_version') == version and prev.get('files') == sorted_hashes:
                print(f' [SUCCESS] Manifest .ai-os/manifest.json already up-to-date ({len(sorted_hashes)} files indexed)')
                sys.exit(0)
    except Exception:
        pass

manifest = {
    'ai_os_version': version,
    'generated_at': gen_at,
    'file_count': len(sorted_hashes),
    'files': sorted_hashes
}

if check_mode:
    real_manifest_path = os.path.join(real_template_dir, '.ai-os', 'manifest.json')
    if not os.path.isfile(real_manifest_path):
        sys.stderr.write('❌ Error: Missing manifest.json in ' + real_template_dir + '\n')
        sys.exit(1)
    
    with open(real_manifest_path, 'r', encoding='utf-8') as fp:
        real_manifest = json.load(fp)
    
    # Compare file counts and file hashes
    drift_detected = False
    if real_manifest.get('files') != sorted_hashes:
        drift_detected = True
        sys.stderr.write('❌ Error: Template file hashes differ from generated master files!\n')
        for k in sorted_hashes:
            if k not in real_manifest.get('files', {}):
                sys.stderr.write(f'   + Missing from template: {k}\n')
            elif real_manifest['files'][k] != sorted_hashes[k]:
                sys.stderr.write(f'   ~ Modified hash: {k}\n')
        for k in real_manifest.get('files', {}):
            if k not in sorted_hashes:
                sys.stderr.write(f'   - Obsolete in template: {k}\n')
    
    if drift_detected:
        sys.exit(1)
    print(' [PASS] Zero drift detected between master and templates/project.')
else:
    with open(manifest_path, 'w', encoding='utf-8', newline='\n') as fp:
        json.dump(manifest, fp, indent=4)
        fp.write('\n')
    print(f' [SUCCESS] Generated .ai-os/manifest.json ({len(sorted_hashes)} files indexed)')
" "$TARGET_DIR" "$VERSION" "$CHECK_MODE" "$TEMPLATE_DIR"

if [ -n "$TMP_DIR" ] && [ -d "$TMP_DIR" ]; then
    rm -rf "$TMP_DIR"
fi
