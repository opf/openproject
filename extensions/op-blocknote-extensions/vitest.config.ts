import { defineConfig } from 'vitest/config';
import react from '@vitejs/plugin-react';
import { yaml } from './vite-plugin-yaml';

export default defineConfig({
  plugins: [react(), yaml()],
  test: {
    include: ['test/**/*.test.ts', 'test/**/*.test.tsx'],
    exclude: ['test/**/*.browser.test.tsx'],
  },
});