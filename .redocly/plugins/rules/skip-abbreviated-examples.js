function removeNodesWithKey(obj, key) {
  if (obj === null) return;
  if (typeof obj === 'string') return;
  if (typeof obj === 'number') return;

  if (Array.isArray(obj)) {
    for (let i = obj.length - 1; i >= 0; i--) {
      if (obj[i] === null) continue;
      if (obj[i][key] !== undefined) {
        obj.splice(i, 1);
      }
    }
  } else {
    const keys = Object.keys(obj);
    for (const k of keys) {
      if (obj[k] === null) continue;
      if (obj[k][key] !== undefined) {
        delete obj[k];
      }
    }
  }

  for (const k of Object.keys(obj)) {
    removeNodesWithKey(obj[k], key);
  }
}

export default function SkipAbbreviatedExamples() {
  return {
    Example: {
      enter(example, _ctx) {
        // remove every nested object with the `_abbreviated` key,
        // but keep the rest to be run against other rules.
        removeNodesWithKey(example.value, '_abbreviated');
      },
    },
  }
}
