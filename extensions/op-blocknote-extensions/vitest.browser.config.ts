import { defineConfig } from 'vitest/config';
import react from '@vitejs/plugin-react';
import { playwright } from '@vitest/browser-playwright';

export default defineConfig({
  plugins: [react()],
  // Pre-bundle the heavy dependencies pulled in transitively by test/setupTests.ts
  // Without this, Vite discovers a not-yet-bundled dependency mid-run, re-optimizes, and force-reloads
  // the page, which drops the in-flight dynamic import() of setupTests.ts and surfaces as
  // an intermittent "Failed to fetch dynamically imported module" across the browser tests.
  optimizeDeps: {
    include: [
      '@blocknote/core',
      '@blocknote/react',
      '@blocknote/mantine',
      'styled-components',
      '@primer/octicons-react',
      'i18next',
      'react-i18next',
      'yjs',
      'msw/browser',
      'react',
      'react-dom',
      'react-dom/client',
      'vitest-browser-react',
      '@testing-library/react',
      '@testing-library/user-event',
    ],
  },
  test: {
    setupFiles: ['./test/setupTests.ts'],
    browser: {
      enabled: true,
      provider: playwright(),
      headless: true,
      instances: [{ browser: 'chromium' }],
    },
    include: ['test/**/*.browser.test.tsx'],
  },
});
