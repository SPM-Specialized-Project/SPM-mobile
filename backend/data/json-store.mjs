import { randomUUID } from 'node:crypto';
import { mkdir, readFile, rename, rm, writeFile } from 'node:fs/promises';
import path from 'node:path';

const identity = (records) => records;

// All callers in this process must share the same store for a given data file.
export function createJsonStore(overrides = {}) {
  const io = { mkdir, readFile, rename, rm, writeFile, ...overrides };
  const queues = new Map();

  function enqueue(file, operation) {
    const resolvedFile = path.resolve(file);
    const result = (queues.get(resolvedFile) ?? Promise.resolve())
      .then(() => operation(resolvedFile));
    const tail = result.catch(() => {});
    queues.set(resolvedFile, tail);
    void tail.then(() => {
      if (queues.get(resolvedFile) === tail) queues.delete(resolvedFile);
    });
    return result;
  }

  async function writeAtomic(file, records) {
    if (!Array.isArray(records)) throw new Error(`Invalid data records: ${file}`);
    const contents = `${JSON.stringify(records, null, 2)}\n`;
    await io.mkdir(path.dirname(file), { recursive: true });
    const temporary = `${file}.${process.pid}.${randomUUID()}.tmp`;
    try {
      await io.writeFile(temporary, contents, { encoding: 'utf8', flag: 'wx', flush: true });
      await io.rename(temporary, file);
    } finally {
      await io.rm(temporary, { force: true });
    }
  }

  async function readOrInitialize(file, initial, initialize = true) {
    let records;
    try {
      records = JSON.parse(await io.readFile(file, 'utf8'));
    } catch (error) {
      if (error?.code !== 'ENOENT') throw error;
      records = structuredClone(initial);
      if (initialize) await writeAtomic(file, records);
    }
    if (!Array.isArray(records)) throw new Error(`Invalid data file: ${file}`);
    return records;
  }

  return {
    readJsonRecords(file, initial, { normalize = identity, initialize = true } = {}) {
      return enqueue(file, async (resolvedFile) => normalize(await readOrInitialize(resolvedFile, initial, initialize)));
    },
    writeJsonRecords(file, records) {
      return enqueue(file, (resolvedFile) => writeAtomic(resolvedFile, records));
    },
    mutateJsonRecords(file, initial, callback, { normalize = identity } = {}) {
      return enqueue(file, async (resolvedFile) => {
        const records = normalize(await readOrInitialize(resolvedFile, initial));
        const value = await callback(records);
        await writeAtomic(resolvedFile, records);
        return value;
      });
    },
  };
}

export const { readJsonRecords, writeJsonRecords, mutateJsonRecords } = createJsonStore();
