import assert from 'node:assert/strict';
import { mkdtemp, rm } from 'node:fs/promises';
import { spawn } from 'node:child_process';
import { once } from 'node:events';
import os from 'node:os';
import path from 'node:path';
import { test } from 'node:test';
import { fileURLToPath } from 'node:url';

const backendDirectory = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
async function startBackend(t) {
  const dataDirectory = await mkdtemp(path.join(os.tmpdir(), 'spm-membership-'));
  const backend = spawn(process.execPath, ['server.mjs'], {
    cwd: backendDirectory,
    env: { ...process.env, BACKEND_PORT: '0', BACKEND_DATA_DIRECTORY: dataDirectory },
    stdio: ['ignore', 'pipe', 'pipe'],
  });
  t.after(async () => {
    if (backend.exitCode === null && backend.signalCode === null) {
      const exited = once(backend, 'exit');
      backend.kill();
      await exited;
    }
    const relative = path.relative(os.tmpdir(), dataDirectory);
    assert.ok(relative && !relative.startsWith('..') && !path.isAbsolute(relative));
    await rm(dataDirectory, { recursive: true, force: true });
  });
  const port = await new Promise((resolve, reject) => {
    const timeout = setTimeout(() => reject(new Error('Backend startup timed out')), 5_000);
    backend.once('error', (error) => { clearTimeout(timeout); reject(error); });
    backend.once('exit', (code) => { clearTimeout(timeout); reject(new Error(`Backend exited: ${code}`)); });
    backend.stdout.on('data', (chunk) => {
      const match = chunk.toString().match(/localhost:(\d+)/);
      if (match) { clearTimeout(timeout); resolve(Number(match[1])); }
    });
  });
  return `http://127.0.0.1:${port}`;
}

async function request(url, token, method = 'GET', body) {
  const response = await fetch(url, {
    method,
    headers: {
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...(body ? { 'Content-Type': 'application/json' } : {}),
    },
    ...(body ? { body: JSON.stringify(body) } : {}),
  });
  return { status: response.status, data: await response.json() };
}

async function login(url, email, password) {
  const result = await request(`${url}/api/auth/login`, null, 'POST', { email, password });
  assert.equal(result.status, 200);
  return result.data.accessToken;
}

test('concurrent enrollments are idempotent and keep different students in the roster', async (t) => {
  const url = await startBackend(t);
  const tutor = await login(url, 'tutor@gmail.com', 'tutor123');
  const roster = `${url}/api/classrooms/13/memberships`;
  const emails = ['vovanf@student.hcmut.edu.vn', 'dangthig@student.hcmut.edu.vn'];
  const results = await Promise.all(emails.flatMap((studentEmail) => Array.from({ length: 4 }, () =>
    request(roster, tutor, 'POST', { studentEmail }))));
  assert.ok(results.every((result) => [200, 201].includes(result.status)), JSON.stringify(results));
  assert.equal(results.filter((result) => result.status === 201).length, 2);
  const fresh = await request(roster, tutor);
  for (const email of emails) {
    assert.equal(fresh.data.items.filter((item) => item.studentEmail === email).length, 1);
  }
});

test('roster keeps history and uses authenticated identity', async (t) => {
  const url = await startBackend(t);
  const tutor = await login(url, 'tutor@gmail.com', 'tutor123');
  const student = await login(url, 'student@gmail.com', 'student123');
  const roster = `${url}/api/classrooms/1/memberships`;

  assert.equal((await request(roster, null)).status, 401);
  const initial = await request(`${roster}?viewerRole=student`, tutor);
  assert.equal(initial.status, 200);
  assert.equal(initial.data.items.length, 3);
  const course13Roster = await request(`${url}/api/classrooms/13/memberships`, student);
  assert.equal(course13Roster.status, 200);
  assert.equal(course13Roster.data.items.length, 6);
  assert.deepEqual(
    course13Roster.data.items.map((item) => item.studentEmail),
    [
      'student@gmail.com',
      'nguyenvana@student.hcmut.edu.vn',
      'tranthib@student.hcmut.edu.vn',
      'leminhc@student.hcmut.edu.vn',
      'phamvand@student.hcmut.edu.vn',
      'hoangthie@student.hcmut.edu.vn',
    ],
  );
  assert.equal(
    course13Roster.data.items.find((item) => item.studentEmail === 'student@gmail.com').permissions.canView,
    true,
  );
  assert.equal(
    course13Roster.data.items.find((item) => item.studentEmail === 'nguyenvana@student.hcmut.edu.vn').permissions.canView,
    false,
  );
  const course13MembershipId = course13Roster.data.items[0].id;
  const course13Revoked = await request(
    `${url}/api/classrooms/13/memberships/${course13MembershipId}`,
    tutor,
    'PATCH',
    { status: 'REVOKED' },
  );
  assert.equal(course13Revoked.status, 200);
  assert.equal(course13Revoked.data.item.status, 'REVOKED');
  const course13Reactivated = await request(`${url}/api/classrooms/13/memberships`, tutor, 'POST', {
    studentEmail: course13Revoked.data.item.studentEmail,
  });
  assert.equal(course13Reactivated.status, 200);
  assert.equal(course13Reactivated.data.reactivated, true);
  assert.equal(course13Reactivated.data.item.id, course13MembershipId);
  const own = await request(`${roster}?viewerRole=tutor&viewerEmail=tutor@gmail.com`, student);
  assert.equal(own.status, 200);
  assert.deepEqual(
    own.data.items.map((item) => item.studentEmail),
    [
      'student@gmail.com',
      'nguyenvana@student.hcmut.edu.vn',
      'tranthib@student.hcmut.edu.vn',
    ],
  );
  assert.equal(own.data.permissions.canEdit, false);
  assert.equal((await request(roster, student, 'POST', {
    viewerRole: 'tutor', viewerEmail: 'tutor@gmail.com', studentEmail: 'student2@gmail.com',
  })).status, 403);

  const duplicate = await request(roster, tutor, 'POST', { studentEmail: 'student@gmail.com' });
  assert.equal(duplicate.status, 200);
  assert.equal(duplicate.data.created, false);
  const added = await request(roster, tutor, 'POST', { studentEmail: 'vovanf@student.hcmut.edu.vn' });
  assert.equal(added.status, 201);
  assert.equal((await request(roster, tutor, 'POST', {
    studentEmail: 'missing@student.example.com',
  })).data.code, 'STUDENT_NOT_FOUND');
  const membershipId = added.data.item.id;
  const revoked = await request(`${roster}/${membershipId}`, tutor, 'PATCH', { status: 'REVOKED' });
  assert.equal(revoked.data.item.status, 'REVOKED');
  const reactivated = await request(roster, tutor, 'POST', { studentEmail: 'vovanf@student.hcmut.edu.vn' });
  assert.equal(reactivated.data.reactivated, true);
  assert.equal(reactivated.data.item.id, membershipId);

  const studentMembership = `${roster}/membership-1-student-account-1`;
  assert.equal((await request(studentMembership, tutor, 'PATCH', { status: 'REVOKED' })).status, 200);
  const denied = await request(`${url}/api/courses/1/detail?viewerRole=tutor`, student);
  assert.equal(denied.status, 403);
  assert.equal(denied.data.code, 'MEMBERSHIP_REQUIRED');
  assert.equal((await request(`${url}/api/sessions?courseId=1`, student)).status, 403);
  assert.equal((await request(roster, student)).status, 403);
  assert.equal((await request(roster, tutor, 'POST', { studentEmail: 'student@gmail.com' })).data.reactivated, true);
  assert.equal((await request(`${url}/api/courses/1/detail`, student)).status, 200);
  const sessions = await request(`${url}/api/sessions?courseId=1`, student);
  assert.equal(sessions.status, 200);
  assert.ok(sessions.data.items.length > 0);

  const submissionsUrl = `${url}/api/courses/2/submissions?studentId=2-student-1`;
  const before = await request(submissionsUrl, tutor);
  assert.equal(before.status, 200);
  assert.equal((await request(
    `${url}/api/classrooms/2/memberships/membership-2-student-1`,
    tutor, 'PATCH', { status: 'REVOKED' },
  )).status, 200);
  assert.deepEqual((await request(submissionsUrl, tutor)).data.items, before.data.items);
  const courseThreeRoster = await request(`${url}/api/classrooms/3/memberships`, tutor);
  assert.equal(courseThreeRoster.status, 200);
  assert.deepEqual(
    courseThreeRoster.data.items.map((item) => item.studentEmail),
    [
      'vovanf@student.hcmut.edu.vn',
      'dangthig@student.hcmut.edu.vn',
      'buiminhh@student.hcmut.edu.vn',
    ],
  );
  assert.equal(courseThreeRoster.data.permissions.canCreate, true);
});
