import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import path from 'node:path';

const __dirname = path.resolve();

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
      // Externalize deps that shouldn't be bundled
      external: [
        /^react(\/|$)/,
        /^react-dom(\/|$)/,
        '@blocknote/core',
        '@blocknote/react',
        '@blocknote/mantine',
        'yjs',
        /^use-sync-external-store(\/|$)/,
      ],
    },
  },
});
