#!/usr/bin/env bash
# AI-OS Safe Upgrade Engine
# Upgrades downstream projects to the latest AI-OS version using manifest checksums

set -euo pipefail

TARGET_DIR="."
DRY_RUN=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --target|-t)
            TARGET_DIR="$2"
            shift 2
            ;;
        --dry-run|-d)
            DRY_RUN=true
            shift
            ;;
        *)
            echo "Unknown argument: $1" >&2
            echo "Usage: upgrade.sh [--target <path>] [--dry-run]" >&2
            exit 1
            ;;
    esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TEMPLATE_DIR="$ROOT_DIR/templates/project"

TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"
UPSTREAM_MANIFEST="$TEMPLATE_DIR/.ai-os/manifest.json"

if [ ! -f "$UPSTREAM_MANIFEST" ]; then
    echo "🔨 Upstream manifest missing, building templates first..."
    "$SCRIPT_DIR/build-templates.sh"
fi

TARGET_MANIFEST="$TARGET_DIR/.ai-os/manifest.json"

echo "🔄 AI-OS Upgrade Engine"
echo " Target Project: $TARGET_DIR"

if [ "$DRY_RUN" = true ]; then
    echo " ℹ️ Mode: DRY RUN (no files will be modified)"
fi

python3 -c "
import os, sys, hashlib, json, shutil
if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8', errors='replace')

template_dir = sys.argv[1]
target_dir = sys.argv[2]
dry_run = sys.argv[3] == 'true'

upstream_manifest_path = os.path.join(template_dir, '.ai-os', 'manifest.json')
target_manifest_path = os.path.join(target_dir, '.ai-os', 'manifest.json')

with open(upstream_manifest_path, 'r', encoding='utf-8') as fp:
    upstream_manifest = json.load(fp)

old_manifest = None
if os.path.isfile(target_manifest_path):
    try:
        with open(target_manifest_path, 'r', encoding='utf-8') as fp:
            old_manifest = json.load(fp)
    except Exception:
        old_manifest = None

text_extensions = {'.md', '.mdc', '.txt', '.json', '.sh', '.ps1', '.gitattributes', '.gitignore', ''}

def get_file_hash(path):
    if not os.path.isfile(path):
        return None
    with open(path, 'rb') as fp:
        data = fp.read()
    ext = os.path.splitext(path)[1].lower()
    if ext in text_extensions:
        data = data.replace(b'\r\n', b'\n')
    return hashlib.sha256(data).hexdigest()

stats = {'added': 0, 'upgraded': 0, 'preserved': 0, 'up_to_date': 0}
new_target_files = {}

for rel_path, up_hash in upstream_manifest.get('files', {}).items():
    src_file = os.path.join(template_dir, rel_path)
    dst_file = os.path.join(target_dir, rel_path)
    
    if not os.path.isfile(dst_file):
        print(f' [+] Added: {rel_path}')
        stats['added'] += 1
        if not dry_run:
            os.makedirs(os.path.dirname(dst_file), exist_ok=True)
            shutil.copy2(src_file, dst_file)
        new_target_files[rel_path] = up_hash
    else:
        current_hash = get_file_hash(dst_file)
        if current_hash == up_hash:
            stats['up_to_date'] += 1
            new_target_files[rel_path] = up_hash
        else:
            old_hash = old_manifest.get('files', {}).get(rel_path) if old_manifest else None
            if old_hash and current_hash == old_hash:
                # Unmodified by user since previous AI-OS install -> safely upgrade
                print(f' [UPGRADE] Upgraded: {rel_path}')
                stats['upgraded'] += 1
                if not dry_run:
                    shutil.copy2(src_file, dst_file)
                new_target_files[rel_path] = up_hash
            else:
                # User customized file -> preserve local copy
                print(f' [PRESERVED] Preserved customized: {rel_path}')
                stats['preserved'] += 1
                if not dry_run:
                    # Write .ai-os-new candidate for user inspection
                    new_candidate = dst_file + '.ai-os-update'
                    shutil.copy2(src_file, new_candidate)
                new_target_files[rel_path] = current_hash

if not dry_run:
    # Update target manifest
    os.makedirs(os.path.join(target_dir, '.ai-os'), exist_ok=True)
    updated_manifest = {
        'ai_os_version': upstream_manifest.get('ai_os_version'),
        'upgraded_at': upstream_manifest.get('generated_at'),
        'file_count': len(new_target_files),
        'files': new_target_files
    }
    with open(target_manifest_path, 'w', encoding='utf-8', newline='\n') as fp:
        json.dump(updated_manifest, fp, indent=4)
        fp.write('\n')

print('====================================================')
print(f' Upgrade Summary: {stats[\"upgraded\"]} upgraded, {stats[\"added\"]} added, {stats[\"preserved\"]} customized preserved, {stats[\"up_to_date\"]} already up-to-date.')
print('====================================================')
" "$TEMPLATE_DIR" "$TARGET_DIR" "$DRY_RUN"

# Ensure executable bit on hook in target if present
if [ -f "$TARGET_DIR/.githooks/pre-commit" ]; then
    chmod +x "$TARGET_DIR/.githooks/pre-commit" 2>/dev/null || true
fi
