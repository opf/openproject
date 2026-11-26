import { vi } from 'vitest';

export const pathOf = (input:RequestInfo | URL):string =>
  new URL(input instanceof Request ? input.url : input).pathname;

/** Answers each request with the body given for its path, and every other one with a server error. */
export function answering(bodies:Record<string, unknown>) {
  return vi.spyOn(globalThis, 'fetch').mockImplementation(async (input) => {
    const path = pathOf(input);
    if (!(path in bodies)) return { ok: false, status: 500, statusText: 'Internal Server Error' } as Response;

    return { ok: true, json: async () => bodies[path] } as Response;
  });
}
