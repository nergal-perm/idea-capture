import concurrent.futures
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import time
import unittest

HELPER = Path(__file__).with_name('capture.py')

class CaptureTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.addCleanup(self.wait_for_workers)
        self.vault = self.root / 'vault'
        self.vault.mkdir()
        self.config = self.root / 'config.toml'
        self.config.write_text('')
        self.codex = self.root / 'codex'
        self.started, self.release, self.done = [self.root / n for n in ['started', 'release', 'done']]
        self.model('print(json.dumps({"title": "Очередь исчезающих заметок"}))')
        self.payload = dict(id='202610281805', requestId='ab12cd34ef56ab78',  # pragma: allowlist secret - synthetic request ID
            text='  Первая мысль со второй строкой\nи ещё одна `строка` $(touch nope)\n',
            category='idea', capturedAt='2026-10-28T18:05:30+04:00', contextDate='2027-01-01')

    def wait_for_workers(self):
        deadline = time.monotonic() + 5
        while True:
            active = []
            for entry in Path('/proc').iterdir():
                if not entry.name.isdigit():
                    continue
                try:
                    args = (entry / 'cmdline').read_bytes().split(b'\0')
                    state = (entry / 'stat').read_text().rsplit(')', 1)[1].split()[0]
                    if state != 'Z' and (str(self.vault).encode() in args or str(self.codex).encode() in args):
                        active.append(entry.name)
                except (OSError, IndexError):
                    continue
            if not active:
                return
            if time.monotonic() >= deadline:
                self.fail('Background fixture workers did not finish: ' + ','.join(active))
            time.sleep(0.02)

    def model(self, code):
        self.codex.write_text('#!/usr/bin/env python3\nimport json, time\nfrom pathlib import Path\n'
            + f'Path({str(self.started)!r}).touch()\n'
            + f'while not Path({str(self.release)!r}).exists(): time.sleep(0.01)\n'
            + code + '\n' + f'Path({str(self.done)!r}).touch()\n')
        self.codex.chmod(0o755)

    def save(self, payload=None):
        return subprocess.run([sys.executable, str(HELPER), '--vault', str(self.vault)],
            input=json.dumps(payload or self.payload), text=True, capture_output=True,
            env={**os.environ, 'CAPTURE_CONFIG': str(self.config),
                 'CAPTURE_INBOX': 'inbox', 'CAPTURE_LOCK_FILE': str(self.root / 'capture.lock'),
                 'CAPTURE_CODEX': str(self.codex), 'CAPTURE_TITLE_TIMEOUT': '1',
                 'TZ': 'Etc/GMT-4'}, timeout=3)

    def saved_note(self, result):
        self.assertEqual(result.returncode, 0, result.stderr)
        data = json.loads(result.stdout)
        return data, Path(data['path']).read_bytes().decode('utf-8')

    def wait(self, predicate):
        deadline = time.monotonic() + 3
        while not predicate():
            if time.monotonic() >= deadline: self.fail('Timed out waiting for background behavior')
            time.sleep(0.02)

    def finish_worker(self):
        self.release.touch()
        self.wait(self.done.exists)
        time.sleep(0.08)

    def test_saves_first_five_words_and_returns_before_model(self):
        start = time.monotonic()
        data, note = self.saved_note(self.save())
        self.assertLess(time.monotonic() - start, 0.7)
        self.assertEqual(Path(data['path']).name, '202610281805 Первая мысль со второй строкой.md')
        self.assertEqual(data['id'], '202610281805')
        self.assertIn('id: "202610281805"\n', note)
        self.assertIn('capturedOn: "2026-10-28"\n', note)
        self.assertIn('contextDate: "2027-01-01"\n', note)
        self.assertIn('processingStatus: unprocessed\n', note)
        self.assertEqual(note.split('## Исходная формулировка\n\n', 1)[1], self.payload['text'])
        self.assertFalse((self.vault / 'private/daily').exists())
        self.assertFalse(self.release.exists())

    def test_external_config_controls_storage_and_background_rename(self):
        config_home = self.root / 'config'
        config_dir = config_home / 'idea-capture'
        config_dir.mkdir(parents=True)
        (config_dir / 'config.toml').write_text(
            f'vault = {json.dumps(str(self.vault))}\n'
            'inbox = "incoming"\n'
            f'lock_file = {json.dumps(str(self.root / "sync.lock"))}\n'
            f'codex = {json.dumps(str(self.codex))}\n')
        environment = {**os.environ, 'XDG_CONFIG_HOME': str(config_home),
                       'CAPTURE_TITLE_TIMEOUT': '1', 'TZ': 'Etc/GMT-4'}
        for key in ['CAPTURE_CONFIG', 'CAPTURE_VAULT', 'CAPTURE_INBOX',
                    'CAPTURE_LOCK_FILE', 'CAPTURE_CODEX']:
            environment.pop(key, None)

        result = subprocess.run([sys.executable, str(HELPER)],
            input=json.dumps(self.payload), text=True, capture_output=True,
            env=environment, timeout=3)

        data, note = self.saved_note(result)
        self.assertEqual(Path(data['path']).parent, self.vault / 'incoming')
        self.assertTrue((self.root / 'sync.lock').is_file())
        self.wait(self.started.exists)
        self.finish_worker()
        final = self.vault / 'incoming/202610281805 Очередь исчезающих заметок.md'
        self.wait(final.exists)
        self.assertEqual(final.read_text(), note)

    def test_missing_vault_configuration_fails_without_writing(self):
        environment = {**os.environ, 'XDG_CONFIG_HOME': str(self.root),
                       'CAPTURE_CONFIG': str(self.config)}
        environment.pop('CAPTURE_VAULT', None)

        result = subprocess.run([sys.executable, str(HELPER)],
            input=json.dumps(self.payload), text=True, capture_output=True,
            env=environment, timeout=3)

        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(result.stdout, '')
        self.assertEqual(list(self.vault.rglob('*.md')), [])

    def test_cli_and_environment_override_configured_paths(self):
        self.config.write_text('vault = "missing-vault"\ninbox = "unused"\n')
        environment = {**os.environ, 'CAPTURE_CONFIG': str(self.config),
                       'CAPTURE_VAULT': str(self.vault), 'CAPTURE_INBOX': 'from-env',
                       'CAPTURE_LOCK_FILE': str(self.root / 'override.lock'),
                       'CAPTURE_CODEX': str(self.codex), 'CAPTURE_TITLE_TIMEOUT': '1',
                       'TZ': 'Etc/GMT-4'}

        result = subprocess.run([sys.executable, str(HELPER), '--inbox', 'from-cli'],
            input=json.dumps(self.payload), text=True, capture_output=True,
            env=environment, timeout=3)

        data, _ = self.saved_note(result)
        self.assertEqual(Path(data['path']).parent, self.vault / 'from-cli')
        self.assertTrue((self.root / 'override.lock').is_file())

    def test_inbox_cannot_escape_configured_vault(self):
        environment = {**os.environ, 'CAPTURE_CONFIG': str(self.config),
                       'CAPTURE_VAULT': str(self.vault), 'CAPTURE_INBOX': '../outside'}

        result = subprocess.run([sys.executable, str(HELPER)],
            input=json.dumps(self.payload), text=True, capture_output=True,
            env=environment, timeout=3)

        self.assertNotEqual(result.returncode, 0)
        self.assertFalse((self.root / 'outside').exists())

    def test_background_rename_changes_only_filename(self):
        data, note = self.saved_note(self.save())
        self.wait(self.started.exists)
        self.finish_worker()
        final = self.vault / 'inbox/202610281805 Очередь исчезающих заметок.md'
        self.wait(final.exists)
        self.assertFalse(Path(data['path']).exists())
        self.assertEqual(final.read_bytes().decode('utf-8'), note)

    def test_retry_after_rename_returns_same_id_and_file(self):
        self.saved_note(self.save())
        self.wait(self.started.exists)
        self.finish_worker()
        data, _ = self.saved_note(self.save())
        self.assertEqual(data['id'], '202610281805')
        self.assertEqual(Path(data['path']).name, '202610281805 Очередь исчезающих заметок.md')
        self.assertEqual(len(list((self.vault / 'inbox').glob('*.md'))), 1)

    def test_same_minute_uses_next_free_id_and_preserves_actual_time(self):
        self.saved_note(self.save())
        data, note = self.saved_note(self.save({**self.payload, 'requestId': 'cd34ef56ab78cd90'}))
        self.assertEqual(data['id'], '202610281806')
        self.assertIn('capturedAt: "2026-10-28T18:05:30+04:00"', note)
        self.assertTrue(Path(data['path']).name.startswith('202610281806 '))

    def test_concurrent_same_request_creates_one_note(self):
        with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:
            results = list(pool.map(lambda _: self.save(), range(4)))
        for result in results: self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual({json.loads(r.stdout)['id'] for r in results}, {'202610281805'})
        self.assertEqual(len(list((self.vault / 'inbox').glob('*.md'))), 1)

    def test_conflicting_request_never_overwrites_source(self):
        data, note = self.saved_note(self.save())
        result = self.save({**self.payload, 'text': 'Другое содержание'})
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(Path(data['path']).read_bytes().decode('utf-8'), note)

    def test_deleted_note_is_not_resurrected(self):
        data, _ = self.saved_note(self.save())
        self.wait(self.started.exists)
        Path(data['path']).unlink()
        self.finish_worker()
        self.assertEqual(list((self.vault / 'inbox').glob('*.md')), [])

    def test_changed_note_is_not_renamed_or_rewritten(self):
        data, _ = self.saved_note(self.save())
        self.wait(self.started.exists)
        path = Path(data['path'])
        path.write_bytes(path.read_bytes() + b'\nEdited by owner')
        expected = path.read_bytes()
        self.finish_worker()
        self.assertEqual(path.read_bytes(), expected)
        self.assertEqual(list((self.vault / 'inbox').glob('*.md')), [path])

    def test_moved_note_is_left_at_owner_destination(self):
        data, _ = self.saved_note(self.save())
        self.wait(self.started.exists)
        moved = self.vault / 'moved.md'
        Path(data['path']).rename(moved)
        self.finish_worker()
        self.assertTrue(moved.exists())
        self.assertEqual(list((self.vault / 'inbox').glob('*.md')), [])

    def test_existing_destination_is_never_overwritten(self):
        data, _ = self.saved_note(self.save())
        self.wait(self.started.exists)
        final = self.vault / 'inbox/202610281805 Очередь исчезающих заметок.md'
        final.write_text('Owner-created destination')
        self.finish_worker()
        self.assertEqual(final.read_text(), 'Owner-created destination')
        self.assertTrue(Path(data['path']).exists())

    def test_invalid_model_response_keeps_initial_name(self):
        self.model('print("not JSON")')
        data, note = self.saved_note(self.save())
        self.wait(self.started.exists)
        self.finish_worker()
        self.assertEqual(Path(data['path']).read_bytes().decode('utf-8'), note)

    def test_timeout_keeps_initial_name(self):
        data, note = self.saved_note(self.save())
        self.wait(self.started.exists)
        time.sleep(1.3)
        self.assertEqual(Path(data['path']).read_bytes().decode('utf-8'), note)

    def test_source_preserves_crlf(self):
        payload = {**self.payload, 'text': '  Первая\r\nВторая\r\n  '}
        _, note = self.saved_note(self.save(payload))
        self.assertEqual(note.split('## Исходная формулировка\n\n', 1)[1], payload['text'])

    def test_model_title_is_sanitized_and_fits_filesystem(self):
        self.model('print(json.dumps({"title": "../../<img> [link] / " + "🎸" * 64}))')
        data, _ = self.saved_note(self.save())
        self.wait(self.started.exists)
        self.finish_worker()
        notes = list((self.vault / 'inbox').glob('*.md'))
        self.assertEqual(len(notes), 1)
        self.assertEqual(notes[0].parent, self.vault / 'inbox')
        self.assertLess(len(notes[0].name.encode()), 256)
        self.assertNotRegex(notes[0].stem[13:], r'[/\\<>\[\]]')

    def test_collision_rolls_over_year_without_changing_capture_date(self):
        payload = {**self.payload, 'id': '202612312359', 'capturedAt': '2026-12-31T23:59:30+04:00'}
        self.saved_note(self.save(payload))
        data, note = self.saved_note(self.save({**payload, 'requestId': 'cd34ef56ab78cd90'}))
        self.assertEqual(data['id'], '202701010000')
        self.assertIn('capturedOn: "2026-12-31"', note)

    def test_retry_after_move_finds_original_without_creating_another(self):
        data, _ = self.saved_note(self.save())
        moved = self.vault / 'processed.md'
        Path(data['path']).rename(moved)
        result = self.save({**self.payload, 'retry': True})
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads(result.stdout)['path'], str(moved))
        self.assertEqual(len(list(self.vault.rglob('*.md'))), 1)

    def test_unrelated_binary_markdown_does_not_block_intake(self):
        inbox = self.vault / 'inbox'
        inbox.mkdir(parents=True)
        (inbox / 'broken.md').write_bytes(b'\xff\xfe')
        self.saved_note(self.save())

    def test_edit_at_rename_boundary_restores_original_filename(self):
        import capture
        data = capture.save_capture(self.vault, self.payload)
        initial = Path(data['path'])
        original = initial.read_bytes()
        actual_rename = capture.rename_noreplace
        def concurrent_edit(source, target):
            if source == initial:
                source.write_bytes(original + b'\nConcurrent owner edit')
            actual_rename(source, target)
        old_env = {k: os.environ.get(k) for k in ['CAPTURE_CODEX', 'CAPTURE_TITLE_TIMEOUT']}
        os.environ['CAPTURE_CODEX'] = str(self.codex)
        os.environ['CAPTURE_TITLE_TIMEOUT'] = '1'
        self.release.touch()
        capture.rename_noreplace = concurrent_edit
        try:
            capture.rename_capture(self.vault, initial, data['fingerprint'])
        finally:
            capture.rename_noreplace = actual_rename
            for key, value in old_env.items():
                if value is None: os.environ.pop(key, None)
                else: os.environ[key] = value
        self.assertTrue(initial.exists())
        self.assertEqual(initial.read_bytes(), original + b'\nConcurrent owner edit')
        self.assertEqual(list((self.vault / 'inbox').glob('*.md')), [initial])

    def test_invalid_input_never_creates_capture(self):
        for change in [dict(id='../escape'), dict(contextDate='2026-02-30'), dict(text='  '),
                       dict(text='x' * 8001), dict(capturedAt='not a time')]:
            with self.subTest(change=list(change)):
                self.assertNotEqual(self.save({**self.payload, **change}).returncode, 0)
        self.assertFalse((self.vault / 'inbox').exists())

if __name__ == '__main__':
    unittest.main()
