import { beforeAll, afterAll } from 'vitest';
import { worker } from './mocks/browser';

beforeAll(async () => {
  await worker.start();
});

afterAll(() => {
  worker.stop();
});