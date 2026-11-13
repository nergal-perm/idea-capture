const {test} = require('node:test');
const assert = require('node:assert/strict');
const {bullet} = require('./Capture.js');
const time = new Date(2026, 8, 10, 11, 38);

test('events use only an explicit start time at the beginning of the text', () => {
    const examples = [
        ['19:30 Мюзикл «1984»', '- 19:30 [event] Мюзикл «1984»'],
        ['9:30 — Встреча', '- 9:30 [event] Встреча'],
        ['19:30 - Мюзикл', '- 19:30 [event] Мюзикл'],
        ['19:30–Мюзикл', '- 19:30 [event] Мюзикл'],
        ['Мюзикл', '- [event] Мюзикл'],
        ['Встреча перенесена на 19:30', '- [event] Встреча перенесена на 19:30'],
        ['00:00 Полночь', '- 00:00 [event] Полночь'],
        ['23:59 Поздно', '- 23:59 [event] Поздно'],
        ['25:30 Встреча', '- [event] 25:30 Встреча'],
        ['19:60 Встреча', '- [event] 19:60 Встреча'],
        ['9:3 Встреча', '- [event] 9:3 Встреча'],
        [' 19:30 Первая\r\nВторая ', '- 19:30 [event] Первая\n  Вторая'],
        ['  ', '']
    ];

    for (const [input, expected] of examples) assert.equal(bullet(input, 'event', time), expected, input);
    assert.equal(bullet('19:30 Встреча', 'task', time), '- [task] 19:30 Встреча');
});

test('a selected category prefixes the text', () => {
    assert.equal(bullet('Ask for clarification', 'question', time), '- [question] Ask for clarification');
});

test('an omitted category produces a plain bullet', () => {
    assert.equal(bullet('Uncategorized thought', '', time), '- Uncategorized thought');
});
test('unknown categories are ignored', () => {
    assert.equal(bullet('Uncategorized thought', 'unknown', time), '- Uncategorized thought');
});


test('pasted multiline text remains within a single Markdown bullet', () => {
    assert.equal(bullet(' first\r\nsecond\n\nthird ', 'fact', time), '- [fact] first\n  second\n  \n  third');
});
test('legacy date argument never adds a creation timestamp', () => {
    assert.equal(bullet('Early', new Date(2026, 8, 10, 0, 5)), '- Early');
    assert.equal(bullet('Late', new Date(2026, 8, 10, 23, 59)), '- Late');
});

test('capture request preserves raw text and separates calendar date from creation time', () => {
    const Capture = require('./Capture.js');
    const raw = '  Первая\nВторая `строка` $(touch nope)\n';
    const id = '202609101138';
    const request = Capture.request(raw, 'idea', time, '2027-01-01', id, 'ab12cd34ef56ab78'); // pragma: allowlist secret - synthetic request ID
    assert.equal(request.text, raw);
    assert.equal(request.contextDate, '2027-01-01');
    assert.equal(request.capturedAt, time.toISOString());
    assert.equal(request.id, id);
    assert.equal(request.category, 'idea');
    assert.equal(request.requestId, 'ab12cd34ef56ab78'); // pragma: allowlist secret - synthetic request ID
    assert.deepEqual(Capture.saveCommand(raw, 'idea', time, '2027-01-01', id, '/tmp/path with spaces/capture.py', 'ab12cd34ef56ab78'), // pragma: allowlist secret - synthetic request ID
                     ['python3', '/tmp/path with spaces/capture.py']);
});

test('empty input, invalid context date and invalid identity never launch a write', () => {
    const Capture = require('./Capture.js');
    for (const [text, date, id] of [['  ', '2027-01-01', '202609101138'],
            ['Thought', '2026-02-30', '202609101138'], ['Thought', '2027-01-01', '../escape']]) {
        assert.equal(Capture.request(text, '', time, date, id, 'ab12cd34ef56ab78'), null); // pragma: allowlist secret - synthetic request ID
        assert.deepEqual(Capture.saveCommand(text, '', time, date, id, '/tmp/capture.py', 'ab12cd34ef56ab78'), []); // pragma: allowlist secret - synthetic request ID
    }
});

test('Zettelkasten prefix uses actual local capture time, not selected context date', () => {
    const Capture = require('./Capture.js');
    const first = Capture.captureId(time);
    const second = Capture.captureId(time);
    assert.equal(first, '202609101138');
    assert.equal(second, '202609101138');
});
