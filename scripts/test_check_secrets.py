from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


SOURCE = Path(__file__).resolve().parents[1]


class SecretHookTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.repo = Path(self.temp.name)
        self.run_git('init', '--quiet')
        for name in ['.githooks/pre-commit', 'scripts/check-secrets.py']:
            target = self.repo / name
            target.parent.mkdir(exist_ok=True)
            shutil.copy2(SOURCE / name, target)
        self.run_git('config', 'core.hooksPath', '.githooks')

    def run_git(self, *arguments):
        return subprocess.run(['git', *arguments], cwd=self.repo,
                              capture_output=True, text=True, check=True)

    def run_hook(self):
        return subprocess.run(['git', 'hook', 'run', 'pre-commit'], cwd=self.repo,
                              capture_output=True, text=True, timeout=60)

    def test_clean_staged_file_passes(self):
        (self.repo / 'note.txt').write_text('A harmless example.\n')
        self.run_git('add', 'note.txt')

        result = self.run_hook()

        self.assertEqual(result.returncode, 0, result.stderr)

    def test_staged_secret_is_blocked_even_when_worktree_is_clean(self):
        note = self.repo / 'note.txt'
        private_key_header = '-----BEGIN ' + 'RSA PRIVATE KEY-----'
        note.write_text(private_key_header + '\nsynthetic test data\n')
        self.run_git('add', 'note.txt')
        note.write_text('The worktree no longer contains the staged fixture.\n')

        result = self.run_hook()

        self.assertNotEqual(result.returncode, 0)
        self.assertIn('Private Key', result.stderr)
        self.assertNotIn(private_key_header, result.stderr)

    def test_unstaged_secret_does_not_block_clean_index(self):
        (self.repo / 'note.txt').write_text('A harmless staged example.\n')
        self.run_git('add', 'note.txt')
        (self.repo / 'local.txt').write_text('-----BEGIN ' + 'RSA PRIVATE KEY-----\n')

        result = self.run_hook()

        self.assertEqual(result.returncode, 0, result.stderr)

    def test_empty_index_passes_without_creating_commit(self):
        result = self.run_hook()

        self.assertEqual(result.returncode, 0, result.stderr)
        refs = self.run_git('for-each-ref', '--format=%(refname)')
        self.assertEqual(refs.stdout, '')


if __name__ == '__main__':
    unittest.main()
