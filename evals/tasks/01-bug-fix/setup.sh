#!/usr/bin/env bash
set -euo pipefail

TARGET_DIR="${1:-.}"
mkdir -p "$TARGET_DIR"
cd "$TARGET_DIR"

if [ ! -d ".git" ]; then
    git init -q
    git config user.name "AI-OS Eval"
    git config user.email "eval@ai-os.dev"
fi

cat << 'EOF' > calculator.py
def divide(a, b):
    return a / b
EOF

cat << 'EOF' > test_calculator.py
import unittest
from calculator import divide

class TestCalculator(unittest.TestCase):
    def test_divide_valid(self):
        self.assertEqual(divide(10, 2), 5)

    def test_divide_by_zero_returns_none(self):
        self.assertIsNone(divide(10, 0))

if __name__ == "__main__":
    unittest.main()
EOF

git add calculator.py test_calculator.py
git commit -qm "Initial commit with buggy calculator" || true
