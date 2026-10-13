// Shared mock names pool used across schedule components
export type NameEntry = { name: string; present: boolean };

const NAMES_RAW = [
  'Liam Nguyen',
  'Olivia Tran',
  'Noah Le',
  'Emma Pham',
  'Ethan Hoang',
  'Ava Bui',
  'Lucas Vo',
  'Sophia Do',
  'Mason Nguyen',
  'Isabella Le',
  'Logan Tran',
  'Mia Pham',
  'James Hoang',
  'Charlotte Bui',
  'Benjamin Vo',
  'Amelia Do',
];

// Build pool of objects with a present flag (randomized for mock/demo)
export const NAMES_POOL: NameEntry[] = NAMES_RAW.map((name) => ({
  name,
  present: Math.random() < 0.85,
}));

const shuffle = <T,>(arr: T[]) => {
  const a = arr.slice();
  for (let i = a.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [a[i], a[j]] = [a[j], a[i]];
  }
  return a;
};

/**
 * Return `count` random members derived from the shared pool.
 * Each result has shape: { id, name, present }
 */
export function getRandomMembers(count = 8) {
  return shuffle(NAMES_POOL).slice(0, count).map((m, i) => ({ id: i, name: m.name, present: m.present }));
}

export function getAllNames() {
  return NAMES_POOL.map((n, i) => ({ id: i, name: n.name, present: n.present }));
}

export const getNameById = (id: number): NameEntry | undefined => {
  return NAMES_POOL[id];
}
