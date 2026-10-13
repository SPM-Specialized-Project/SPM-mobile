import assert from 'node:assert/strict';
import { mkdtemp, readFile, readdir, rename, rm, writeFile } from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import test from 'node:test';
import { createJsonStore } from '../data/json-store.mjs';

async function dataFile(t) {
  const directory = await mkdtemp(path.join(os.tmpdir(), 'spm-json-store-'));
  t.after(async () => {
    const relative = path.relative(os.tmpdir(), directory);
    assert.ok(relative && !relative.startsWith('..') && !path.isAbsolute(relative));
    await rm(directory, { recursive: true, force: true });
  });
  return { directory, file: path.join(directory, 'records.json') };
}

function deferred() {
  let resolve;
  const promise = new Promise((done) => { resolve = done; });
  return { promise, resolve };
}

test('readers wait for a pending replacement and the live file stays complete', async (t) => {
  const { directory, file } = await dataFile(t);
  const before = [{ value: 'before' }];
  const after = [{ value: 'after' }];
  await writeFile(file, JSON.stringify(before));
  const replacementStarted = deferred();
  const allowReplacement = deferred();
  const store = createJsonStore({
    async rename(temporary, destination) {
      assert.equal(path.dirname(temporary), path.dirname(destination));
      replacementStarted.resolve();
      await allowReplacement.promise;
      await rename(temporary, destination);
    },
  });

  const mutation = store.mutateJsonRecords(file, [], (records) => {
    records[0] = after[0];
  });
  await replacementStarted.promise;
  try {
    assert.deepEqual(JSON.parse(await readFile(file, 'utf8')), before);
    let readerFinished = false;
    const reader = store.readJsonRecords(file, []).then((records) => {
      readerFinished = true;
      return records;
    });
    await new Promise((resolve) => setImmediate(resolve));
    assert.equal(readerFinished, false);
    allowReplacement.resolve();
    await mutation;
    assert.deepEqual(await reader, after);
    assert.deepEqual(await readdir(directory), ['records.json']);
  } finally {
    allowReplacement.resolve();
    await mutation;
  }
});

test('concurrent initialization and updates keep every record', async (t) => {
  const { directory, file } = await dataFile(t);
  const store = createJsonStore();
  const seed = [{ id: 'seed' }];
  const operations = [store.readJsonRecords(file, seed)];
  for (let index = 0; index < 30; index += 1) {
    operations.push(store.mutateJsonRecords(file, seed, (records) => records.push({ id: index })));
    operations.push(store.readJsonRecords(file, seed));
  }
  await Promise.all(operations);
  const records = await store.readJsonRecords(file, seed);
  assert.deepEqual(records, [seed[0], ...Array.from({ length: 30 }, (_, id) => ({ id }))]);
  assert.deepEqual(seed, [{ id: 'seed' }]);
  assert.deepEqual(await readdir(directory), ['records.json']);
});

test('a failed partial write preserves committed data, removes the temporary, and releases the queue', async (t) => {
  const { directory, file } = await dataFile(t);
  const before = [{ id: 'committed' }];
  await writeFile(file, JSON.stringify(before));
  let failNextWrite = true;
  const store = createJsonStore({
    async writeFile(temporary, contents, options) {
      if (failNextWrite) {
        failNextWrite = false;
        await writeFile(temporary, contents.slice(0, 4), options);
        throw Object.assign(new Error('Disk write failed'), { code: 'EIO' });
      }
      await writeFile(temporary, contents, options);
    },
  });
  await assert.rejects(store.mutateJsonRecords(file, [], (records) => records.push({ id: 'lost' })), { code: 'EIO' });
  assert.deepEqual(JSON.parse(await readFile(file, 'utf8')), before);
  assert.deepEqual(await readdir(directory), ['records.json']);
  await store.mutateJsonRecords(file, [], (records) => records.push({ id: 'next' }));
  assert.deepEqual(await store.readJsonRecords(file, []), [...before, { id: 'next' }]);
  assert.deepEqual(await readdir(directory), ['records.json']);
});

test('a failed rename removes the temporary and does not poison later writes', async (t) => {
  const { directory, file } = await dataFile(t);
  const before = [{ id: 'before' }];
  await writeFile(file, JSON.stringify(before));
  let failNextRename = true;
  const store = createJsonStore({
    async rename(temporary, destination) {
      if (failNextRename) {
        failNextRename = false;
        throw Object.assign(new Error('Replacement denied'), { code: 'EACCES' });
      }
      await rename(temporary, destination);
    },
  });
  await assert.rejects(store.writeJsonRecords(file, [{ id: 'failed' }]), { code: 'EACCES' });
  assert.deepEqual(await store.readJsonRecords(file, []), before);
  assert.deepEqual(await readdir(directory), ['records.json']);
  await store.writeJsonRecords(file, [{ id: 'after' }]);
  assert.deepEqual(await store.readJsonRecords(file, []), [{ id: 'after' }]);
  assert.deepEqual(await readdir(directory), ['records.json']);
});

test('version checks run against the latest committed state and a conflict releases the queue', async (t) => {
  const { file } = await dataFile(t);
  const store = createJsonStore();
  const seed = [{ stateVersion: 0 }];
  const update = () => store.mutateJsonRecords(file, seed, (records) => {
    if (records[0].stateVersion !== 0) {
      throw Object.assign(new Error('Stale state'), { status: 409 });
    }
    records[0].stateVersion += 1;
    return 200;
  });
  const results = await Promise.allSettled([update(), update()]);
  assert.deepEqual(results.map((result) => result.status === 'fulfilled' ? result.value : result.reason.status), [200, 409]);
  assert.deepEqual(await store.readJsonRecords(file, []), [{ stateVersion: 1 }]);
});

test('invalid JSON is reported without resetting recorded data', async (t) => {
  const { directory, file } = await dataFile(t);
  const store = createJsonStore();
  await writeFile(file, '[incomplete');
  await assert.rejects(store.readJsonRecords(file, []), SyntaxError);
  assert.equal(await readFile(file, 'utf8'), '[incomplete');
  await writeFile(file, '{}');
  await assert.rejects(store.readJsonRecords(file, []), /Invalid data file/);
  assert.equal(await readFile(file, 'utf8'), '{}');
  await store.writeJsonRecords(file, [{ id: 'repaired' }]);
  assert.deepEqual(await store.readJsonRecords(file, []), [{ id: 'repaired' }]);
  assert.deepEqual(await readdir(directory), ['records.json']);
});

test('reading an absent student ledger can stay read-only', async (t) => {
  const { directory, file } = await dataFile(t);
  assert.deepEqual(await createJsonStore().readJsonRecords(file, [], { initialize: false }), []);
  assert.deepEqual(await readdir(directory), []);
});
