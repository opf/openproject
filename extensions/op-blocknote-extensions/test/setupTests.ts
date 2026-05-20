import { beforeAll, afterAll } from 'vitest';
import { worker } from './mocks/browser';
import { initializeOpBlockNoteExtensions } from '../lib';

beforeAll(async () => {
  initializeOpBlockNoteExtensions({ baseUrl: 'http://localhost:3000', locale: 'en' });
  await worker.start({ onUnhandledRequest: 'bypass' });
});

afterAll(() => {
  worker.stop();
});