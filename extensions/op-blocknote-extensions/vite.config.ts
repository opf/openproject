import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import path from 'node:path';
import { readFileSync } from 'node:fs';

const __dirname = path.resolve();

const { buildExternals } = JSON.parse(
  readFileSync(path.resolve(__dirname, 'package.json'), 'utf8'),
) as { buildExternals:string[] };

// https://vite.dev/config/
export default defineConfig({
  plugins: [react()],
  build: {
    lib: {
      entry: {
        'op-blocknote-extensions': path.resolve(__dirname, 'lib/index.ts'),
        'op-blocknote-extensions-server': path.resolve(__dirname, 'lib/server.ts'),
      },
      name: 'OpBlocknoteExtensions',
      formats: ['es', 'cjs'],
      fileName: (format, entryName) => `${entryName}.${format}.js`,
    },
    rollupOptions: {
      // Externalize deps that shouldn't be bundled, including their subpaths
      external: buildExternals.map((name) => new RegExp(`^${name}(/|$)`)),
    },
  },
});
