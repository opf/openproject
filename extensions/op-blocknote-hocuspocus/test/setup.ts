import { beforeAll, afterEach, afterAll } from 'vitest';
import { server } from './mocks/node.js';

// define the secret used in tests
process.env["SECRET"] = "secret12345";
 
beforeAll(() => server.listen({ onUnhandledRequest: 'error' }));
afterEach(() => {
  server.resetHandlers();
  server.events.removeAllListeners();
});
afterAll(() => server.close());
