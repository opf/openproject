import { defineConfig } from 'vitest/config';
import react from '@vitejs/plugin-react';
import { playwright } from '@vitest/browser-playwright';

export default defineConfig({
  plugins: [react()],
  // Pre-bundle dependencies to eliminate mid-run dependency discovery which can lead to flaky tests.
  optimizeDeps: {
    entries: [
      'test/setupTests.ts',
      'test/**/*.browser.test.tsx',
    ],
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
