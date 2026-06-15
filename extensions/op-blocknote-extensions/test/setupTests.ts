import { beforeAll, afterAll, beforeEach } from 'vitest';
import { worker } from './mocks/browser';
import { initializeOpBlockNoteExtensions } from '../lib';
import { clearWorkPackageCache } from '../lib/hooks/useWorkPackage';

beforeEach(() => {
  clearWorkPackageCache();
});

beforeAll(async () => {
  initializeOpBlockNoteExtensions({ baseUrl: 'http://localhost:3000', locale: 'en' });
  await worker.start({ onUnhandledRequest: 'bypass' });
});

afterAll(() => {
  worker.stop();
});