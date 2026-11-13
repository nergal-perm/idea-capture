#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.12"
# dependencies = ["detect-secrets==1.5.0"]
# ///

import json
import subprocess
import sys
import tempfile


def main():
    root = subprocess.check_output(['git', 'rev-parse', '--show-toplevel'], text=True).strip()
    with tempfile.TemporaryDirectory(prefix='idea-capture-index-') as directory:
        subprocess.run(['git', 'checkout-index', '--all', '--prefix', directory + '/'],
                       cwd=root, check=True)
        result = subprocess.run([sys.executable, '-m', 'detect_secrets', 'scan', '--all-files'],
                                cwd=directory, capture_output=True, text=True, check=True)
        findings = json.loads(result.stdout)['results']
    for filename, entries in findings.items():
        for entry in entries:
            print(f"{filename}:{entry['line_number']}: {entry['type']}", file=sys.stderr)
    if findings:
        print('Commit blocked: remove potential secrets from the staged files.', file=sys.stderr)
        return 1
    return 0


if __name__ == '__main__':
    sys.exit(main())
