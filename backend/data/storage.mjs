import { mkdir } from 'node:fs/promises';
import { mutateJsonRecords, readJsonRecords, writeJsonRecords } from './json-store.mjs';

import {
  COURSE_REQUESTS_FILE,
  MEMBERSHIPS_FILE,
  DATA_DIRECTORY,
  REGISTRATIONS_FILE,
  SESSIONS_FILE,
  SUBMISSIONS_FILE,
} from '../config.mjs';
import {
  INITIAL_COURSE_REQUESTS,
  INITIAL_MEMBERSHIPS,
  INITIAL_REGISTRATIONS,
  INITIAL_SESSIONS,
  INITIAL_SUBMISSIONS,
  normalizeCourse13Memberships,
} from './seeds.mjs';

const ensureDataDirectory = () => mkdir(DATA_DIRECTORY, { recursive: true });

const collectionConfig = {
  sessions: { file: SESSIONS_FILE, seed: INITIAL_SESSIONS },
  registrations: { file: REGISTRATIONS_FILE, seed: INITIAL_REGISTRATIONS },
  courseRequests: { file: COURSE_REQUESTS_FILE, seed: INITIAL_COURSE_REQUESTS },
  memberships: { file: MEMBERSHIPS_FILE, seed: INITIAL_MEMBERSHIPS },
};

function readCollection(name) {
  const config = collectionConfig[name];
  if (!config) throw new Error(`Unknown backend collection: ${name}`);
  return readJsonRecords(config.file, config.seed, {
    normalize: name === 'memberships' ? normalizeCourse13Memberships : undefined,
  });
}

function saveCollection(name, records) {
  const config = collectionConfig[name];
  if (!config) throw new Error(`Unknown backend collection: ${name}`);
  return writeJsonRecords(config.file, records);
}

function mutateCollection(name, callback) {
  const config = collectionConfig[name];
  if (!config) throw new Error(`Unknown backend collection: ${name}`);
  return mutateJsonRecords(config.file, config.seed, callback, {
    normalize: name === 'memberships' ? normalizeCourse13Memberships : undefined,
  });
}

function readSubmissions() {
  return readJsonRecords(SUBMISSIONS_FILE, INITIAL_SUBMISSIONS);
}

function saveSubmissions(records) {
  return writeJsonRecords(SUBMISSIONS_FILE, records);
}

export { ensureDataDirectory, readCollection, saveCollection, mutateCollection, readSubmissions, saveSubmissions };
