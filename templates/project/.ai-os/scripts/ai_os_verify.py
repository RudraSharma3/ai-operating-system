#!/usr/bin/env python3
"""
AI Operating System Verifier Core (scripts/ai_os_verify.py)
Stdlib-only (Python 3.9+) verification engine for coding-agent hallucination defense:
- deps: audit added package dependencies against .ai/deps-approved.txt
- imports: static resolution of imports against manifests, stdlib, and aliases
- registry-check: online validation of maturity and typosquatting heuristics (requires --online)
- run: command runner capturing execution proof into .ai/evidence/
- evidence: validation of un-stale evidence records for current commit
"""

import argparse
import ast
import datetime
import hashlib
import json
import os
import re
import subprocess
import sys
import time
import urllib.error
import urllib.request

# Ensure UTF-8 output even on legacy Windows terminals
if hasattr(sys.stdout, "reconfigure"):
    try:
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    except Exception:
        pass
if hasattr(sys.stderr, "reconfigure"):
    try:
        sys.stderr.reconfigure(encoding="utf-8", errors="replace")
    except Exception:
        pass

# Documented stdlib fallback list for Python 3.9 (sys.stdlib_module_names introduced in 3.10)
FALLBACK_STDLIB_MODULES = {
    "__future__", "_thread", "abc", "aifc", "argparse", "array", "ast", "asynchat",
    "asyncio", "asyncore", "atexit", "audioop", "base64", "bdb", "binascii",
    "binhex", "bisect", "builtins", "bz2", "calendar", "cgi", "cgitb", "chunk",
    "cmath", "cmd", "code", "codecs", "codeop", "collections", "colorsys",
    "compileall", "concurrent", "configparser", "contextlib", "contextvars",
    "copy", "copyreg", "crypt", "csv", "ctypes", "curses", "dataclasses",
    "datetime", "dbm", "decimal", "difflib", "dis", "distutils", "doctest",
    "dummy_threading", "email", "encodings", "ensurepip", "enum", "errno",
    "faulthandler", "fcntl", "filecmp", "fileinput", "fnmatch", "formatter",
    "fpectl", "fractions", "ftplib", "functools", "gc", "getopt", "getpass",
    "gettext", "glob", "graphlib", "grp", "gzip", "hashlib", "heapq", "hmac",
    "html", "http", "imaplib", "imghdr", "imp", "importlib", "inspect", "io",
    "ipaddress", "itertools", "json", "keyword", "lib2to3", "linecache", "locale",
    "logging", "lzma", "mailbox", "mailcap", "marshal", "math", "mimetypes",
    "mmap", "modulefinder", "msilib", "msvcrt", "multiprocessing", "netrc",
    "nis", "nntplib", "numbers", "operator", "optparse", "os", "ossaudiodev",
    "parser", "pathlib", "pdb", "pickle", "pickletools", "pipes", "pkgutil",
    "platform", "plistlib", "poplib", "posix", "posixpath", "pprint", "profile",
    "pstats", "pty", "pwd", "py_compile", "pyclbr", "pydoc", "queue", "quopri",
    "random", "re", "readline", "reprlib", "resource", "rlcompleter", "runpy",
    "sched", "secrets", "select", "selectors", "shelve", "shlex", "shutil",
    "signal", "site", "smtpd", "smtplib", "sndhdr", "socket", "socketserver",
    "spwd", "sqlite3", "ssl", "stat", "statistics", "string", "stringprep",
    "struct", "subprocess", "sunau", "symbol", "symtable", "sys", "sysconfig",
    "syslog", "tabnanny", "tarfile", "telnetlib", "tempfile", "termios", "test",
    "textwrap", "threading", "time", "timeit", "tkinter", "token", "tokenize",
    "trace", "traceback", "tracemalloc", "tty", "turtle", "turtledemo", "types",
    "typing", "unicodedata", "unittest", "urllib", "uu", "uuid", "venv", "warnings",
    "wave", "weakref", "webbrowser", "winreg", "winsound", "wsgiref", "xdrlib",
    "xml", "xmlrpc", "zipapp", "zipfile", "zipimport", "zlib", "zoneinfo"
}

# Node.js Built-in Modules
NODE_BUILTINS = {
    "assert", "async_hooks", "buffer", "child_process", "cluster", "console",
    "constants", "crypto", "dgram", "diagnostics_channel", "dns", "domain",
    "events", "fs", "http", "http2", "https", "inspector", "module", "net",
    "os", "path", "perf_hooks", "process", "punycode", "querystring", "readline",
    "repl", "stream", "string_decoder", "timers", "tls", "trace_events", "tty",
    "url", "util", "v8", "vm", "wasi", "worker_threads", "zlib"
}

# Standard import alias mappings: import name -> package name
BUILTIN_PYTHON_ALIASES = {
    "yaml": "pyyaml",
    "cv2": "opencv-python",
    "pil": "pillow",
    "dotenv": "python-dotenv",
    "sklearn": "scikit-learn",
    "bs4": "beautifulsoup4",
    "jwt": "pyjwt",
    "google.protobuf": "protobuf",
    "git": "gitpython",
    "serial": "pyserial",
    "psutil": "psutil",
    "attr": "attrs",
    "dateutil": "python-dateutil",
    "magic": "python-magic",
    "opengl": "pyopengl",
    "crypto": "pycryptodome",
    "fitz": "pymupdf",
    "docx": "python-docx",
    "pptx": "python-pptx",
    "jose": "python-jose",
    "multipart": "python-multipart",
}

# Curated Popular Packages for Typosquatting / Slopsquatting Heuristic
POPULAR_PACKAGES = {
    # Python
    "requests", "urllib3", "certifi", "charset-normalizer", "idna", "pip",
    "setuptools", "wheel", "pytest", "numpy", "pandas", "scipy", "matplotlib",
    "scikit-learn", "torch", "torchvision", "tensorflow", "boto3", "botocore",
    "pydantic", "fastapi", "flask", "django", "click", "tqdm", "jinja2",
    "markupsafe", "pyyaml", "pillow", "packaging", "six", "typing-extensions",
    "beautifulsoup4", "cryptography", "attrs", "psycopg2", "sqlalchemy",
    # JavaScript / Node
    "lodash", "react", "react-dom", "express", "axios", "chalk", "tslib",
    "commander", "debug", "moment", "dotenv", "async", "next", "vue",
    "webpack", "babel-core", "rxjs", "inquirer", "semver", "glob", "uuid"
}


def normalize_pkg_name(name: str) -> str:
    """Normalize package name according to PEP 503 / npm rules."""
    return re.sub(r"[-_.]+", "-", name.strip().lower())


def get_git_output(args: list[str], cwd: str) -> str:
    """Run a git command and return stripped output."""
    try:
        res = subprocess.run(
            ["git"] + args,
            cwd=cwd,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            check=True
        )
        return res.stdout.strip()
    except Exception:
        return ""


def get_approved_dependencies(target_dir: str, approvals_file: str | None = None) -> dict[str, dict]:
    """Parse .ai/deps-approved.txt."""
    if not approvals_file:
        approvals_file = os.path.join(target_dir, ".ai", "deps-approved.txt")
    if not os.path.isfile(approvals_file):
        return {}

    approved = {}
    with open(approvals_file, "r", encoding="utf-8-sig") as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            parts = [p.strip() for p in line.split("|")]
            if len(parts) >= 2:
                ecosystem = parts[0].lower()
                raw_name = parts[1]
                norm_name = normalize_pkg_name(raw_name)
                justification = parts[2] if len(parts) > 2 else ""
                date = parts[3] if len(parts) > 3 else ""
                approver = parts[4] if len(parts) > 4 else ""
                key = f"{ecosystem}:{norm_name}"
                approved[key] = {
                    "ecosystem": ecosystem,
                    "name": raw_name,
                    "normalized": norm_name,
                    "justification": justification,
                    "date": date,
                    "approver": approver
                }
    return approved


def parse_requirements_txt(content: str) -> set[str]:
    """Extract package names from requirements.txt content."""
    pkgs = set()
    if content.startswith("\ufeff"):
        content = content[1:]
    for line in content.splitlines():
        line = re.sub(r"#.*$", "", line).strip()
        if not line or line.startswith(("-r", "-f", "-i", "--")):
            continue
        # Extract package name before ==, >=, <=, ~=, !=, <, >, ;, @, [
        m = re.match(r"^([a-zA-Z0-9_\-\.]+)", line)
        if m:
            pkgs.add(normalize_pkg_name(m.group(1)))
    return pkgs


def parse_package_json(content: str) -> tuple[set[str], str | None]:
    """Extract dependency names from package.json content."""
    try:
        if content.startswith("\ufeff"):
            content = content[1:]
        data = json.loads(content)
        pkgs = set()
        for field in ("dependencies", "devDependencies", "peerDependencies", "optionalDependencies"):
            deps = data.get(field)
            if isinstance(deps, dict):
                for k in deps.keys():
                    pkgs.add(normalize_pkg_name(k))
        return pkgs, None
    except Exception as e:
        return set(), str(e)


def parse_pyproject_toml(content: str) -> set[str]:
    """Basic extraction of dependencies from pyproject.toml."""
    pkgs = set()
    if content.startswith("\ufeff"):
        content = content[1:]
    in_deps = False
    for line in content.splitlines():
        clean = line.strip()
        if clean.startswith("["):
            in_deps = "dependencies" in clean
            continue
        if in_deps or "dependencies" in clean:
            m = re.search(r'["\']([a-zA-Z0-9_\-\.]+)(?:[<>=~!@;\s]|$)', clean)
            if m:
                pkgs.add(normalize_pkg_name(m.group(1)))
    return pkgs


def get_manifest_deps_from_tree(target_dir: str) -> dict[str, set[str]]:
    """Scan working tree manifests for declared dependencies."""
    deps: dict[str, set[str]] = {"python": set(), "npm": set()}

    # Requirements files
    for root, dirs, files in os.walk(target_dir):
        dirs[:] = [d for d in dirs if d not in (".git", "node_modules", ".venv", "venv", "__pycache__", ".pytest_cache")]
        for f in files:
            path = os.path.join(root, f)
            if f == "package.json":
                try:
                    with open(path, "r", encoding="utf-8-sig") as pf:
                        pkgs, err = parse_package_json(pf.read())
                        if err:
                            sys.stderr.write(f"Warning: malformed package.json at {path}: {err}\n")
                        else:
                            deps["npm"].update(pkgs)
                except Exception as e:
                    sys.stderr.write(f"Warning: could not read {path}: {e}\n")
            elif f.startswith("requirements") and f.endswith(".txt"):
                try:
                    with open(path, "r", encoding="utf-8-sig") as rf:
                        deps["python"].update(parse_requirements_txt(rf.read()))
                except Exception as e:
                    sys.stderr.write(f"Warning: could not read {path}: {e}\n")
            elif f == "pyproject.toml":
                try:
                    with open(path, "r", encoding="utf-8-sig") as tf:
                        deps["python"].update(parse_pyproject_toml(tf.read()))
                except Exception as e:
                    sys.stderr.write(f"Warning: could not read {path}: {e}\n")
    return deps


def get_manifest_deps_from_git_ref(target_dir: str, ref: str) -> dict[str, set[str]]:
    """Scan git ref (e.g. HEAD) for declared dependencies."""
    deps: dict[str, set[str]] = {"python": set(), "npm": set()}
    try:
        ls_tree = subprocess.run(
            ["git", "ls-tree", "-r", "--name-only", ref],
            cwd=target_dir,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            check=False
        )
        if ls_tree.returncode != 0:
            return deps
        for line in ls_tree.stdout.splitlines():
            path = line.strip()
            fname = os.path.basename(path)
            if fname == "package.json":
                content = get_git_output(["show", f"{ref}:{path}"], target_dir)
                pkgs, err = parse_package_json(content)
                if not err:
                    deps["npm"].update(pkgs)
            elif fname.startswith("requirements") and fname.endswith(".txt"):
                content = get_git_output(["show", f"{ref}:{path}"], target_dir)
                deps["python"].update(parse_requirements_txt(content))
            elif fname == "pyproject.toml":
                content = get_git_output(["show", f"{ref}:{path}"], target_dir)
                deps["python"].update(parse_pyproject_toml(content))
    except Exception:
        pass
    return deps


def load_verify_config(target_dir: str) -> dict[str, str]:
    """Load configuration from .ai/verify.conf."""
    conf_path = os.path.join(target_dir, ".ai", "verify.conf")
    config = {
        "deps": "block",
        "imports": "warn",
        "on_missing_python": "warn",
        "approvals_changed": "warn",
    }
    if os.path.isfile(conf_path):
        try:
            with open(conf_path, "r", encoding="utf-8") as f:
                for line in f:
                    line = line.strip()
                    if not line or line.startswith("#"):
                        continue
                    if "=" in line:
                        k, v = line.split("=", 1)
                        config[k.strip()] = v.strip()
        except Exception:
            pass
    return config


def is_approvals_file_modified(target_dir: str, approvals_file: str) -> bool:
    """Check whether the approvals file was modified relative to HEAD in worktree or index."""
    try:
        rel_path = os.path.relpath(approvals_file, target_dir).replace("\\", "/")
    except Exception:
        rel_path = approvals_file

    try:
        diff_res = subprocess.run(
            ["git", "diff", "HEAD", "--", rel_path],
            cwd=target_dir,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            check=False
        )
        if diff_res.returncode == 0 and diff_res.stdout.strip():
            return True

        stat_res = subprocess.run(
            ["git", "status", "--porcelain", "--", rel_path],
            cwd=target_dir,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            check=False
        )
        if stat_res.stdout.strip():
            return True
    except Exception:
        pass
    return False


def cmd_deps(args: argparse.Namespace) -> int:
    """Subcommand: deps - audit newly added dependencies against approvals."""
    target_dir = os.path.abspath(args.target)
    approvals_path = args.approvals if args.approvals else os.path.join(target_dir, ".ai", "deps-approved.txt")
    approved = get_approved_dependencies(target_dir, args.approvals)

    vconf = load_verify_config(target_dir)
    approvals_policy = vconf.get("approvals_changed", "warn").lower()
    approvals_changed = is_approvals_file_modified(target_dir, approvals_path)

    # Current tree / staged dependencies
    current_deps = get_manifest_deps_from_tree(target_dir)

    # HEAD dependencies
    head_deps = get_manifest_deps_from_git_ref(target_dir, "HEAD")

    # Find newly added dependencies
    unapproved = []
    new_approved = []

    for eco in ("python", "npm"):
        added = current_deps[eco] - head_deps[eco]
        for pkg in sorted(added):
            key = f"{eco}:{pkg}"
            if key in approved:
                new_approved.append(key)
            else:
                unapproved.append((eco, pkg))

    has_error = bool(unapproved) or (approvals_changed and approvals_policy == "block")

    result = {
        "status": "PASS" if not has_error else "FAIL",
        "unapproved": [{"ecosystem": e, "package": p} for e, p in unapproved],
        "newly_approved": new_approved,
        "total_approved_tracked": len(approved),
        "approvals_changed": approvals_changed,
        "approvals_policy": approvals_policy
    }

    if args.json:
        print(json.dumps(result, indent=2))
    else:
        if approvals_changed:
            notice = "approval file changed in this commit; require a human code-owner review"
            if approvals_policy == "block":
                print(f"[AI-OS Verifier] ❌ {notice}")
            else:
                print(f"[AI-OS Verifier] ⚠️  {notice}")

        if unapproved:
            print("[AI-OS Verifier] ❌ Unapproved dependency detected:")
            for eco, pkg in unapproved:
                print(f"  • {eco}:{pkg}")
            print("\nTo approve, add a human-approved line to .ai/deps-approved.txt:")
            for eco, pkg in unapproved:
                today = datetime.date.today().isoformat()
                print(f"  {eco}|{pkg}|<justification>|{today}|@your-username")
        elif not (approvals_changed and approvals_policy == "block"):
            print("[AI-OS Verifier] ✅ All newly added dependencies are approved.")

    return 1 if has_error else 0


def get_import_aliases(target_dir: str, custom_file: str | None = None) -> dict[str, str]:
    """Load built-in and custom import aliases."""
    aliases = dict(BUILTIN_PYTHON_ALIASES)
    if not custom_file:
        custom_file = os.path.join(target_dir, ".ai", "import-aliases.txt")
    if os.path.isfile(custom_file):
        with open(custom_file, "r", encoding="utf-8-sig") as f:
            for line in f:
                line = line.strip()
                if not line or line.startswith("#"):
                    continue
                parts = [p.strip() for p in line.split("|")]
                if len(parts) >= 2:
                    aliases[parts[0].lower()] = normalize_pkg_name(parts[1])
    return aliases


class PythonImportVisitor(ast.NodeVisitor):
    """AST visitor extracting imported modules, respecting try/except guards and TYPE_CHECKING."""
    def __init__(self):
        self.imports = set()
        self.compound_imports = set()
        self.compound_by_top = {}
        self.in_try_import = False
        self.in_type_checking = False

    def visit_Try(self, node: ast.Try):
        # Check if any handler catches ImportError, ModuleNotFoundError, Exception, or bare except
        is_import_guarded = False
        for h in node.handlers:
            if h.type is None:
                is_import_guarded = True
            elif isinstance(h.type, ast.Name) and h.type.id in ("ImportError", "ModuleNotFoundError", "Exception", "BaseException"):
                is_import_guarded = True
            elif isinstance(h.type, ast.Tuple):
                for elt in h.type.elts:
                    if isinstance(elt, ast.Name) and elt.id in ("ImportError", "ModuleNotFoundError", "Exception", "BaseException"):
                        is_import_guarded = True

        old_try = self.in_try_import
        if is_import_guarded:
            self.in_try_import = True
        for stmt in node.body:
            self.visit(stmt)
        self.in_try_import = old_try

        for h in node.handlers:
            self.visit(h)
        for stmt in node.orelse:
            self.visit(stmt)
        for stmt in node.finalbody:
            self.visit(stmt)

    def visit_If(self, node: ast.If):
        is_tc = False
        if isinstance(node.test, ast.Name) and node.test.id == "TYPE_CHECKING":
            is_tc = True
        elif isinstance(node.test, ast.Attribute) and node.test.attr == "TYPE_CHECKING":
            is_tc = True

        old_tc = self.in_type_checking
        if is_tc:
            self.in_type_checking = True
        for stmt in node.body:
            self.visit(stmt)
        self.in_type_checking = old_tc

        for stmt in node.orelse:
            self.visit(stmt)

    def visit_Import(self, node: ast.Import):
        if self.in_try_import or self.in_type_checking:
            return
        for alias in node.names:
            top_name = alias.name.split(".")[0]
            self.imports.add(top_name)
            if "." in alias.name:
                self.compound_imports.add(alias.name)
                self.compound_by_top.setdefault(top_name, set()).add(alias.name)

    def visit_ImportFrom(self, node: ast.ImportFrom):
        if self.in_try_import or self.in_type_checking:
            return
        if node.level == 0 and node.module:
            top_name = node.module.split(".")[0]
            self.imports.add(top_name)
            for alias in node.names:
                full_mod = f"{node.module}.{alias.name}"
                self.compound_imports.add(full_mod)
                self.compound_by_top.setdefault(top_name, set()).add(full_mod)


def extract_python_imports(filepath: str) -> tuple[set[str], dict[str, set[str]]]:
    """Extract imported top-level and compound modules from a Python file using AST."""
    visitor = PythonImportVisitor()
    try:
        with open(filepath, "r", encoding="utf-8", errors="ignore") as f:
            tree = ast.parse(f.read(), filename=filepath)
        visitor.visit(tree)
    except Exception:
        pass
    return visitor.imports, visitor.compound_by_top


def get_js_path_alias_prefixes(target_dir: str) -> set[str]:
    """Extract path alias prefixes from tsconfig.json or jsconfig.json."""
    prefixes = {"@/", "~/"}
    for root, dirs, files in os.walk(target_dir):
        dirs[:] = [d for d in dirs if d not in (".git", "node_modules", ".venv", "venv", "__pycache__", "dist", "build", ".next", "out")]
        for f in files:
            if f in ("tsconfig.json", "jsconfig.json"):
                fpath = os.path.join(root, f)
                try:
                    with open(fpath, "r", encoding="utf-8-sig", errors="ignore") as jf:
                        content = jf.read()
                        content = re.sub(r'//.*', '', content)
                        content = re.sub(r'/\*.*?\*/', '', content, flags=re.DOTALL)
                        data = json.loads(content)
                        compiler_opts = data.get("compilerOptions", {})
                        base_url = compiler_opts.get("baseUrl")
                        if base_url:
                            base_dir = os.path.normpath(os.path.join(root, base_url))
                            if os.path.isdir(base_dir):
                                for item in os.listdir(base_dir):
                                    if not item.startswith("."):
                                        prefixes.add(f"{item}/")
                        paths = compiler_opts.get("paths", {})
                        for key in paths:
                            clean_key = key.replace("*", "")
                            if clean_key:
                                prefixes.add(clean_key)
                except Exception:
                    pass
    return prefixes


def extract_js_imports(filepath: str, path_prefixes: set[str] | None = None) -> set[str]:
    """Extract imported packages from JS/TS files using regex."""
    imports = set()
    if path_prefixes is None:
        path_prefixes = {"@/", "~/"}
    try:
        with open(filepath, "r", encoding="utf-8", errors="ignore") as f:
            content = f.read()
        patterns = [
            r"(?:import|from)\s+['\"]([^'\"\r\n]+)['\"]",
            r"require\(\s*['\"]([^'\"\r\n]+)['\"]\s*\)",
            r"import\(\s*['\"]([^'\"\r\n]+)['\"]\s*\)"
        ]
        for pat in patterns:
            for m in re.finditer(pat, content):
                spec = m.group(1).strip()
                if spec.startswith((".", "/", "\\")):
                    continue
                if any(spec.startswith(p) for p in path_prefixes):
                    continue
                if spec.startswith("node:"):
                    continue
                if spec in ("use strict", "use client", "use server"):
                    continue
                if any(c in spec for c in ("${", "+", "(", ")", ",", ";", "\n", "\r", " ")):
                    continue

                if spec.startswith("@"):
                    parts = spec.split("/")
                    if len(parts) >= 2:
                        imports.add(f"{parts[0]}/{parts[1]}")
                else:
                    imports.add(spec.split("/")[0])
    except Exception:
        pass
    return imports


def cmd_imports(args: argparse.Namespace) -> int:
    """Subcommand: imports - check static imports against manifests and stdlib."""
    target_dir = os.path.abspath(args.target)
    manifest_deps = get_manifest_deps_from_tree(target_dir)
    aliases = get_import_aliases(target_dir, args.aliases)

    stdlib = getattr(sys, "stdlib_module_names", FALLBACK_STDLIB_MODULES)

    # Discover workspace internal packages / module directories
    workspace_modules = set()
    for item in os.listdir(target_dir):
        full = os.path.join(target_dir, item)
        if item.endswith(".py"):
            workspace_modules.add(item[:-3])
        elif os.path.isdir(full) and not item.startswith((".", "node_modules", "venv", "__pycache__")):
            workspace_modules.add(item)
            if item in ("src", "lib", "packages"):
                for sub in os.listdir(full):
                    sub_full = os.path.join(full, sub)
                    if sub.endswith(".py"):
                        workspace_modules.add(sub[:-3])
                    elif os.path.isdir(sub_full) and not sub.startswith((".", "__")):
                        workspace_modules.add(sub)

    # Also discover all internal package directories with __init__.py
    for root, dirs, files in os.walk(target_dir):
        dirs[:] = [d for d in dirs if d not in (".git", "node_modules", ".venv", "venv", "__pycache__", ".pytest_cache", ".ai", "dist", "build", ".next", "out", "coverage")]
        if "__init__.py" in files:
            workspace_modules.add(os.path.basename(root))

    # Path prefixes for JS/TS path aliases
    js_path_prefixes = get_js_path_alias_prefixes(target_dir)

    undeclared = []

    # Files to check
    files_to_check = []
    if args.files:
        files_to_check = [os.path.abspath(f) for f in args.files]
    else:
        for root, dirs, files in os.walk(target_dir):
            dirs[:] = [d for d in dirs if d not in (".git", "node_modules", ".venv", "venv", "__pycache__", ".pytest_cache", ".ai", "dist", "build", ".next", "out", "coverage")]
            for f in files:
                if f.endswith((".min.js", ".min.cjs", ".min.mjs")):
                    continue
                if f.endswith((".py", ".js", ".jsx", ".ts", ".tsx", ".mjs", ".cjs")):
                    files_to_check.append(os.path.join(root, f))

    for path in sorted(files_to_check):
        rel_path = os.path.relpath(path, target_dir)
        fname = os.path.basename(path)

        if fname.endswith(".py"):
            imported, compound_by_top = extract_python_imports(path)
            for mod in imported:
                norm_mod = normalize_pkg_name(mod)
                # Check 1: Standard library
                if mod in stdlib or mod.startswith("_"):
                    continue
                # Check 2: Workspace internal package / sibling
                if mod in workspace_modules:
                    continue
                # Check 3: Declared in python dependencies
                resolved_pkg = aliases.get(mod.lower(), norm_mod)
                if resolved_pkg in manifest_deps["python"] or norm_mod in manifest_deps["python"]:
                    continue
                # Check 3b: Namespace package prefix in manifest (e.g. google from google-genai)
                if any(p.startswith(f"{norm_mod}-") or p.startswith(f"{norm_mod}_") for p in manifest_deps["python"]):
                    continue
                # Check 3c: Compound import matching manifest (e.g. google.genai -> google-genai)
                if any(normalize_pkg_name(c) in manifest_deps["python"] for c in compound_by_top.get(mod, set())):
                    continue
                # Check 4: Local file relative to file directory
                file_dir = os.path.dirname(path)
                if os.path.exists(os.path.join(file_dir, f"{mod}.py")) or os.path.exists(os.path.join(file_dir, mod)):
                    continue

                undeclared.append({
                    "file": rel_path,
                    "language": "python",
                    "import": mod,
                    "resolved_pkg": resolved_pkg
                })

        elif fname.endswith((".js", ".jsx", ".ts", ".tsx", ".mjs", ".cjs")):
            imported = extract_js_imports(path, js_path_prefixes)
            for pkg in imported:
                norm_pkg = normalize_pkg_name(pkg)
                underscore_pkg = pkg.replace("-", "_")
                # Check 1: Node builtins
                if pkg in NODE_BUILTINS or underscore_pkg in NODE_BUILTINS or norm_pkg in NODE_BUILTINS or pkg.startswith("node:"):
                    continue
                # Check 2: Declared in npm dependencies
                if norm_pkg in manifest_deps["npm"] or pkg in manifest_deps["npm"]:
                    continue
                # Check 3: Workspace root package
                if norm_pkg in workspace_modules:
                    continue

                undeclared.append({
                    "file": rel_path,
                    "language": "javascript",
                    "import": pkg,
                    "resolved_pkg": norm_pkg
                })

    result = {
        "status": "PASS" if not undeclared else "FAIL",
        "undeclared": undeclared,
        "scanned_files": len(files_to_check)
    }

    if args.json:
        print(json.dumps(result, indent=2))
    else:
        if undeclared:
            print("[AI-OS Verifier] [WARN] Undeclared imports detected:")
            for item in undeclared:
                print(f"  • {item['file']}: '{item['import']}' (expected in manifest as '{item['resolved_pkg']}')")
            return 1
        else:
            print(f"[AI-OS Verifier] [OK] All imports in {len(files_to_check)} files resolved successfully.")

    return 1 if undeclared else 0


def levenshtein_distance(s1: str, s2: str) -> int:
    """Compute Levenshtein distance between two strings."""
    if len(s1) < len(s2):
        return levenshtein_distance(s2, s1)
    if len(s2) == 0:
        return len(s1)
    previous_row = range(len(s2) + 1)
    for i, c1 in enumerate(s1):
        current_row = [i + 1]
        for j, c2 in enumerate(s2):
            insertions = previous_row[j + 1] + 1
            deletions = current_row[j] + 1
            substitutions = previous_row[j] + (c1 != c2)
            current_row.append(min(insertions, deletions, substitutions))
        previous_row = current_row
    return previous_row[-1]


def cmd_registry_check(args: argparse.Namespace) -> int:
    """Subcommand: registry-check - online maturity & typosquat verification."""
    if not args.online:
        sys.stderr.write("[AI-OS Verifier] Error: Network calls are disabled by default.\n")
        sys.stderr.write("To perform remote registry checks, explicitly pass the --online flag.\n")
        return 1

    target_dir = os.path.abspath(args.target)
    approved = get_approved_dependencies(target_dir)

    findings = []
    print(f"[AI-OS Verifier] Running registry verification for {len(approved)} approved packages...")

    all_names = [v["normalized"] for v in approved.values()]

    for key, info in approved.items():
        eco = info["ecosystem"]
        pkg = info["name"]
        norm = info["normalized"]

        # 1. Typosquatting / Slopsquatting Heuristic (Edit distance)
        typosquats = []
        for pop in POPULAR_PACKAGES:
            if pop != norm:
                dist = levenshtein_distance(norm, pop)
                if (dist == 1) or (dist == 2 and len(norm) >= 7):
                    typosquats.append(f"close to popular package '{pop}' (dist {dist})")

        for other in all_names:
            if other != norm:
                dist = levenshtein_distance(norm, other)
                if dist == 1:
                    typosquats.append(f"close to peer dependency '{other}' (dist 1)")

        # 2. Registry Maturity & Existence Check
        pub_date = None
        is_young = False
        error_msg = None

        # Test-only fixture hook: AI_OS_REGISTRY_MOCK_FILE allows offline testing of flags
        mock_file = os.environ.get("AI_OS_REGISTRY_MOCK_FILE")
        mock_entry = None
        if mock_file and os.path.isfile(mock_file):
            try:
                with open(mock_file, "r", encoding="utf-8-sig") as mf:
                    mock_data = json.load(mf)
                    mock_entry = mock_data.get(key)
            except Exception as me:
                error_msg = f"Mock fixture error: {me}"

        if mock_entry is not None:
            if not mock_entry.get("exists", True) or "error" in mock_entry:
                error_msg = mock_entry.get("error", "HTTP 404: package not found")
            else:
                pub_date = mock_entry.get("publish_date")
        else:
            try:
                if eco == "python":
                    url = f"https://pypi.org/pypi/{pkg}/json"
                    req = urllib.request.Request(url, headers={"User-Agent": "AI-OS-Verifier/1.0"})
                    with urllib.request.urlopen(req, timeout=10) as resp:
                        data = json.loads(resp.read().decode())
                        releases = data.get("releases", {})
                        # Find earliest release date
                        dates = []
                        for ver, files in releases.items():
                            for fl in files:
                                dt = fl.get("upload_time_iso_8601") or fl.get("upload_time")
                                if dt:
                                    dates.append(dt)
                        if dates:
                            earliest = min(dates)
                            pub_date = earliest[:10]
                elif eco == "npm":
                    url = f"https://registry.npmjs.org/{pkg}"
                    req = urllib.request.Request(url, headers={"User-Agent": "AI-OS-Verifier/1.0"})
                    with urllib.request.urlopen(req, timeout=10) as resp:
                        data = json.loads(resp.read().decode())
                        times = data.get("time", {})
                        created = times.get("created")
                        if created:
                            pub_date = created[:10]
            except urllib.error.HTTPError as he:
                error_msg = f"HTTP {he.code}: package not found or forbidden"
            except Exception as e:
                error_msg = f"Lookup error: {e}"

        if pub_date:
            try:
                p_dt = datetime.datetime.strptime(pub_date, "%Y-%m-%d").date()
                age_days = (datetime.date.today() - p_dt).days
                if age_days < 14:
                    is_young = True
            except Exception:
                age_days = None
        else:
            age_days = None

        status = "PASS"
        if error_msg:
            status = "FAIL"
        elif is_young:
            status = "WARN"

        findings.append({
            "key": key,
            "ecosystem": eco,
            "package": pkg,
            "publish_date": pub_date,
            "age_days": age_days,
            "is_young": is_young,
            "typosquat_alerts": typosquats,
            "error": error_msg,
            "status": status
        })

    if args.json:
        print(json.dumps(findings, indent=2))
    else:
        has_failure = False
        for f in findings:
            symbol = "[PASS]" if f["status"] == "PASS" else ("[WARN]" if f["status"] == "WARN" else "[FAIL]")
            print(f" {symbol} {f['key']}: age {f['age_days']} days, status {f['status']}")
            if f["error"]:
                print(f"    Error: {f['error']}")
                has_failure = True
            if f["is_young"]:
                print(f"    Notice: Package is younger than 14-day threshold ({f['age_days']} days)")
            for alert in f["typosquat_alerts"]:
                print(f"    Heuristic: Potential typosquat {alert}")

    return 1 if any(f["status"] == "FAIL" for f in findings) else 0


def is_tree_dirty(target_dir: str) -> bool:
    """Check if working tree is dirty, ignoring local evidence records."""
    status_out = get_git_output(["status", "--porcelain", "-uall"], target_dir)
    lines = []
    for line in status_out.splitlines():
        line = line.strip()
        if not line:
            continue
        rel = line[3:].strip() if len(line) > 3 else line
        norm_rel = rel.replace("\\", "/")
        if norm_rel.startswith(".ai/evidence") or norm_rel == ".ai":
            continue
        lines.append(line)
    return bool(lines)


def cmd_run(args: argparse.Namespace) -> int:
    """Subcommand: run - execute command and capture tamper-evident execution proof."""
    target_dir = os.path.abspath(args.target)
    cmd = args.command
    if not cmd:
        sys.stderr.write("[AI-OS Evidence] Error: No command specified to run.\n")
        return 1

    evidence_dir = os.path.join(target_dir, ".ai", "evidence")
    os.makedirs(evidence_dir, exist_ok=True)

    start_time = time.time()
    started_at = datetime.datetime.now(datetime.timezone.utc).isoformat()

    # Capture initial git state
    git_sha = get_git_output(["rev-parse", "HEAD"], target_dir)
    dirty_before = is_tree_dirty(target_dir)

    # Execute command
    proc = subprocess.Popen(
        cmd,
        cwd=target_dir,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True
    )

    lines = []
    while True:
        line = proc.stdout.readline()
        if not line and proc.poll() is not None:
            break
        if line:
            sys.stdout.write(line)
            sys.stdout.flush()
            lines.append(line)

    exit_code = proc.wait()
    duration = time.time() - start_time

    # Output tail hash (last 100 lines)
    tail = "".join(lines[-100:])
    tail_hash = hashlib.sha256(tail.encode("utf-8", errors="ignore")).hexdigest()

    # Check dirty status after command
    dirty_after = is_tree_dirty(target_dir)

    # Build record
    record = {
        "command": " ".join(cmd),
        "exit_code": exit_code,
        "started_at": started_at,
        "duration_seconds": round(duration, 3),
        "git_sha": git_sha,
        "working_tree_dirty": dirty_after or dirty_before,
        "output_tail_hash": tail_hash,
        "tail_lines_count": len(lines[-100:])
    }

    ts_str = datetime.datetime.now(datetime.timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    rec_id = f"{ts_str}_{tail_hash[:8]}"
    record_file = os.path.join(evidence_dir, f"{rec_id}.json")

    with open(record_file, "w", encoding="utf-8") as f:
        json.dump(record, f, indent=2)

    sys.stdout.write(f"\n[AI-OS Evidence] Recorded execution proof: {rec_id} (exit {exit_code}, duration {duration:.2f}s)\n")
    return exit_code


def cmd_evidence(args: argparse.Namespace) -> int:
    """Subcommand: evidence - verify evidence ledger for matching clean HEAD run."""
    target_dir = os.path.abspath(args.target)
    evidence_dir = os.path.join(target_dir, ".ai", "evidence")
    current_sha = get_git_output(["rev-parse", "HEAD"], target_dir)
    current_dirty = is_tree_dirty(target_dir)

    if not os.path.isdir(evidence_dir):
        sys.stderr.write(f"[AI-OS Evidence] No evidence records found in {evidence_dir}\n")
        return 1

    required_pattern = args.require

    matching_records = []
    for f in os.listdir(evidence_dir):
        if f.endswith(".json"):
            path = os.path.join(evidence_dir, f)
            try:
                with open(path, "r", encoding="utf-8-sig") as rf:
                    data = json.load(rf)
                data["_file"] = f
                matching_records.append(data)
            except Exception:
                continue

    # Filter for matching pattern, current sha, clean tree, and exit code 0
    valid_record = None
    for rec in sorted(matching_records, key=lambda x: x.get("started_at", ""), reverse=True):
        cmd = rec.get("command", "")
        if re.search(required_pattern, cmd):
            # Check commit SHA match
            if rec.get("git_sha") != current_sha:
                continue
            # If current tree is dirty, record must match dirty state; if record clean but tree dirty -> stale
            if current_dirty:
                continue
            if rec.get("working_tree_dirty"):
                continue
            if rec.get("exit_code") == 0:
                valid_record = rec
                break

    if valid_record:
        print(f"[AI-OS Evidence] ✅ Verified clean evidence record: {valid_record['_file']}")
        print(f"  Command: '{valid_record['command']}' | Exit: 0 | SHA: {valid_record['git_sha']}")
        return 0
    else:
        sys.stderr.write(f"[AI-OS Evidence] ❌ No valid un-stale evidence record found for pattern: '{required_pattern}'\n")
        sys.stderr.write(f"  Current SHA: {current_sha} (clean: {not current_dirty})\n")
        return 1


def main() -> int:
    parser = argparse.ArgumentParser(description="AI Operating System Verifier Core")
    subparsers = parser.add_subparsers(dest="subcommand", help="Verifier subcommand")

    # deps
    deps_p = subparsers.add_parser("deps", help="Audit manifest dependencies against .ai/deps-approved.txt")
    deps_p.add_argument("--target", default=".", help="Target repository directory")
    deps_p.add_argument("--approvals", default=None, help="Path to custom approvals file")
    deps_p.add_argument("--json", action="store_true", help="Output JSON result")

    # imports
    imp_p = subparsers.add_parser("imports", help="Static check of imported packages")
    imp_p.add_argument("--target", default=".", help="Target repository directory")
    imp_p.add_argument("--files", nargs="*", default=None, help="Explicit list of files to check")
    imp_p.add_argument("--aliases", default=None, help="Path to custom import-aliases.txt")
    imp_p.add_argument("--json", action="store_true", help="Output JSON result")

    # registry-check
    reg_p = subparsers.add_parser("registry-check", help="Online package maturity and typosquat heuristic")
    reg_p.add_argument("--target", default=".", help="Target repository directory")
    reg_p.add_argument("--online", action="store_true", help="Explicit opt-in flag required for remote registry lookups")
    reg_p.add_argument("--json", action="store_true", help="Output JSON result")

    # run
    run_p = subparsers.add_parser("run", help="Run command and record execution evidence into .ai/evidence/")
    run_p.add_argument("--target", default=".", help="Target repository directory")
    run_p.add_argument("command", nargs=argparse.REMAINDER, help="Command to run")

    # evidence
    ev_p = subparsers.add_parser("evidence", help="Verify evidence record exists for current commit")
    ev_p.add_argument("--target", default=".", help="Target repository directory")
    ev_p.add_argument("--require", required=True, help="Command pattern required to have passed")

    args = parser.parse_args()

    # Handle --command remainder in run subcommand
    if args.subcommand == "run" and args.command and args.command[0] == "--":
        args.command = args.command[1:]

    if args.subcommand == "deps":
        return cmd_deps(args)
    elif args.subcommand == "imports":
        return cmd_imports(args)
    elif args.subcommand == "registry-check":
        return cmd_registry_check(args)
    elif args.subcommand == "run":
        return cmd_run(args)
    elif args.subcommand == "evidence":
        return cmd_evidence(args)
    else:
        parser.print_help()
        return 1


if __name__ == "__main__":
    sys.exit(main())
