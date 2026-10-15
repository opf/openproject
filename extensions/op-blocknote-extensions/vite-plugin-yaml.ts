import type { Plugin } from 'vite';
import { parse } from 'yaml';

export function yaml():Plugin {
  return {
    name: 'op-yaml',
    transform(code, id) {
      if (!id.endsWith('.yml')) {
        return null;
      }

      return { code: `export default ${JSON.stringify(parse(code))};`, map: null };
    },
  };
}
