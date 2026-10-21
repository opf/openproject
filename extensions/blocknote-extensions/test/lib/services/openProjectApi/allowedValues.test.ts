import { describe, expect, it, vi } from 'vitest';
import { initOpenProjectApi } from '../../../../lib/services/openProjectApi/client';
import { OpenProjectApiError } from '../../../../lib/services/openProjectApi/errors';
import { fetchAllowedValues } from '../../../../lib/services/openProjectApi/allowedValues';
import { calledUrl, mockResponse } from './fetchStubs';

describe('fetchAllowedValues', () => {
  it('merges the typeahead term into the filters the href already carries', async () => {
    initOpenProjectApi({ baseUrl: 'http://localhost:3000' });
    const fetchSpy = vi.spyOn(global, 'fetch').mockResolvedValue(mockResponse({
      ok: true,
      json: async () => ({ _embedded: { elements: [] } }),
    }));

    try {
      await fetchAllowedValues('/api/v3/principals?filters=[{"status":{"operator":"!","values":["3"]}}]&pageSize=-1', 'eli');

      const calledUrl = fetchSpy.mock.calls[0][0] as string;
      const filters = new URL(calledUrl).searchParams.get('filters');
      expect(JSON.parse(filters!)).toEqual([
        { status: { operator: '!', values: ['3'] } },
        { typeahead: { operator: '**', values: ['eli'] } },
      ]);
      expect(new URL(calledUrl).searchParams.get('pageSize')).toBe('-1');
      // The JSON is percent encoded, braces and quotes included.
      expect(calledUrl).not.toMatch(/[{}"]/);
    } finally {
      fetchSpy.mockRestore();
    }
  });

  it('cannot be broken out of by the search term', async () => {
    initOpenProjectApi({ baseUrl: 'http://localhost:3000' });
    const fetchSpy = vi.spyOn(global, 'fetch').mockResolvedValue(mockResponse({
      ok: true,
      json: async () => ({ _embedded: { elements: [] } }),
    }));

    try {
      await fetchAllowedValues('/api/v3/principals', '"}]&pageSize=999#x');

      const calledUrl = fetchSpy.mock.calls[0][0] as string;
      const params = new URL(calledUrl).searchParams;
      expect(JSON.parse(params.get('filters')!))
        .toEqual([{ typeahead: { operator: '**', values: ['"}]&pageSize=999#x'] } }]);
      // The term stayed inside its parameter: no second pageSize, no fragment.
      expect(params.getAll('pageSize')).toEqual(['100']);
      expect(new URL(calledUrl).hash).toBe('');
    } finally {
      fetchSpy.mockRestore();
    }
  });

  it('keeps a query string it cannot interpret usable', async () => {
    initOpenProjectApi({ baseUrl: 'http://localhost:3000' });
    const fetchSpy = vi.spyOn(global, 'fetch').mockResolvedValue(mockResponse({
      ok: true,
      json: async () => ({ _embedded: { elements: [] } }),
    }));

    try {
      await fetchAllowedValues('/api/v3/principals?filters={"broken":true}&select=all', 'eli');
      await fetchAllowedValues('/api/v3/work_packages/available_projects', 'demo');

      const first = new URL(fetchSpy.mock.calls[0][0] as string);
      expect(JSON.parse(first.searchParams.get('filters')!))
        .toEqual([{ typeahead: { operator: '**', values: ['eli'] } }]);
      expect(first.searchParams.get('select')).toBe('all');

      const second = new URL(fetchSpy.mock.calls[1][0] as string);
      expect(second.searchParams.get('pageSize')).toBe('100');
    } finally {
      fetchSpy.mockRestore();
    }
  });

  it('propagates a failure that is not a rejected filter', async () => {
    initOpenProjectApi({ baseUrl: 'http://localhost:3000' });
    const fetchSpy = vi.spyOn(global, 'fetch').mockResolvedValue(mockResponse({
      ok: false,
      status: 500,
      statusText: 'Internal Server Error',
      json: async () => ({ message: 'Boom.' }),
    }));

    try {
      await expect(fetchAllowedValues('/api/v3/principals', 'eli')).rejects.toHaveProperty('responseStatus', 500);
      expect(fetchSpy).toHaveBeenCalledTimes(1);
    } finally {
      fetchSpy.mockRestore();
    }
  });

  it('retries unfiltered when the endpoint rejects the typeahead filter', async () => {
    initOpenProjectApi({ baseUrl: 'http://localhost:3000' });
    const fetchSpy = vi.spyOn(global, 'fetch')
      .mockResolvedValueOnce(mockResponse({ ok: false, status: 400, statusText: 'Bad Request', json: async () => ({}) }))
      .mockResolvedValueOnce(mockResponse({ ok: true, json: async () => ({ _embedded: { elements: [{ id: 1 }] } }) }));
    const consoleSpy = vi.spyOn(console, 'warn').mockImplementation(() => {});

    try {
      // Unfiltered, and said to be: the caller has to narrow the answer itself.
      await expect(fetchAllowedValues('/api/v3/custom_fields/3/items', 'design'))
        .resolves.toEqual({ resources: [{ id: 1 }], filtered: false });
      expect(fetchSpy.mock.calls[1][0]).toBe('http://localhost:3000/api/v3/custom_fields/3/items?pageSize=100');
    } finally {
      fetchSpy.mockRestore();
      consoleSpy.mockRestore();
    }
  });

  it('reports whether the term reached the API', async () => {
    initOpenProjectApi({ baseUrl: 'http://localhost:3000' });
    const fetchSpy = vi.spyOn(global, 'fetch').mockResolvedValue(mockResponse({
      ok: true,
      json: async () => ({ _embedded: { elements: [{ id: 7 }] } }),
    }));

    try {
      await expect(fetchAllowedValues('/api/v3/principals', 'anna@example.com'))
        .resolves.toEqual({ resources: [{ id: 7 }], filtered: true });
      // With no term there is nothing to narrow by, and nothing is claimed to be.
      await expect(fetchAllowedValues('/api/v3/principals'))
        .resolves.toEqual({ resources: [{ id: 7 }], filtered: false });
    } finally {
      fetchSpy.mockRestore();
    }
  });

  it('refuses an href outside the API', async () => {
    initOpenProjectApi({ baseUrl: 'http://localhost:3000' });
    await expect(fetchAllowedValues('https://evil.example.com/steal')).rejects.toBeInstanceOf(OpenProjectApiError);
  });

  it('asks for the order of the nested set only where there is one to read', async () => {
    initOpenProjectApi({ baseUrl: 'http://localhost:3000' });
    const fetchSpy = vi.spyOn(global, 'fetch').mockResolvedValue(mockResponse({
      ok: true,
      json: async () => ({ _embedded: { elements: [] } }),
    }));

    try {
      await fetchAllowedValues('/api/v3/work_packages/available_projects', '', { nested: true });
      await fetchAllowedValues('/api/v3/principals');

      expect(new URL(calledUrl(fetchSpy.mock.calls)).searchParams.get('sortBy'))
        .toBe('[["lft","asc"]]');
      // A flat listing is left in whatever order its endpoint means it to be.
      expect(new URL(calledUrl(fetchSpy.mock.calls, 1)).searchParams.has('sortBy')).toBe(false);
    } finally {
      fetchSpy.mockRestore();
    }
  });

  it('leaves an order the href already carries alone', async () => {
    initOpenProjectApi({ baseUrl: 'http://localhost:3000' });
    const fetchSpy = vi.spyOn(global, 'fetch').mockResolvedValue(mockResponse({
      ok: true,
      json: async () => ({ _embedded: { elements: [] } }),
    }));

    try {
      await fetchAllowedValues('/api/v3/projects?sortBy=%5B%5B%22name%22%2C%22asc%22%5D%5D', '', { nested: true });

      expect(new URL(calledUrl(fetchSpy.mock.calls)).searchParams.get('sortBy'))
        .toBe('[["name","asc"]]');
    } finally {
      fetchSpy.mockRestore();
    }
  });

  it('takes the first page of a listing, and asks for no page after it', async () => {
    initOpenProjectApi({ baseUrl: 'http://localhost:3000' });
    const fetchSpy = vi.spyOn(global, 'fetch').mockResolvedValue(mockResponse({
      ok: true,
      json: async () => ({
        total: 10_000,
        count: 1,
        _embedded: { elements: [{ _links: { self: { href: '/api/v3/projects/1' } } }] },
      }),
    }));

    try {
      const { resources } = await fetchAllowedValues('/api/v3/work_packages/available_projects');

      expect(fetchSpy).toHaveBeenCalledTimes(1);
      expect(resources).toHaveLength(1);
      expect(new URL(calledUrl(fetchSpy.mock.calls)).searchParams.has('offset')).toBe(false);
    } finally {
      fetchSpy.mockRestore();
    }
  });

  it('asks for a page large enough to browse without typing', async () => {
    initOpenProjectApi({ baseUrl: 'http://localhost:3000' });
    const fetchSpy = vi.spyOn(global, 'fetch').mockResolvedValue(mockResponse({
      ok: true,
      json: async () => ({ _embedded: { elements: [] } }),
    }));

    try {
      await fetchAllowedValues('/api/v3/work_packages/available_projects');

      const params = new URL(calledUrl(fetchSpy.mock.calls)).searchParams;
      expect(params.get('pageSize')).toBe('100');
      // Nothing narrows an unfiltered listing, not even an empty filter set.
      expect(params.has('filters')).toBe(false);
    } finally {
      fetchSpy.mockRestore();
    }
  });
});

describe('fetchAllowedValues, narrowed to the favorites', () => {
  it('narrows the listing to the favored values', async () => {
    initOpenProjectApi({ baseUrl: 'http://localhost:3000' });
    const fetchSpy = vi.spyOn(global, 'fetch').mockResolvedValue(mockResponse({
      ok: true,
      json: async () => ({ _embedded: { elements: [{ id: 2 }] } }),
    }));

    try {
      await fetchAllowedValues('/api/v3/work_packages/available_projects', '', { favoredOnly: true });

      const filters = new URL(calledUrl(fetchSpy.mock.calls)).searchParams.get('filters');
      expect(JSON.parse(filters!)).toEqual([{ favored: { operator: '=', values: ['t'] } }]);
    } finally {
      fetchSpy.mockRestore();
    }
  });

  it('keeps the favorites narrowed while a term narrows them further', async () => {
    initOpenProjectApi({ baseUrl: 'http://localhost:3000' });
    const fetchSpy = vi.spyOn(global, 'fetch').mockResolvedValue(mockResponse({
      ok: true,
      json: async () => ({ _embedded: { elements: [] } }),
    }));

    try {
      await fetchAllowedValues('/api/v3/work_packages/available_projects', 'demo', { favoredOnly: true });

      const filters = new URL(calledUrl(fetchSpy.mock.calls)).searchParams.get('filters');
      expect(JSON.parse(filters!)).toEqual([
        { favored: { operator: '=', values: ['t'] } },
        { typeahead: { operator: '**', values: ['demo'] } },
      ]);
    } finally {
      fetchSpy.mockRestore();
    }
  });

  it('drops only the term where the endpoint rejects it', async () => {
    initOpenProjectApi({ baseUrl: 'http://localhost:3000' });
    const fetchSpy = vi.spyOn(global, 'fetch')
      .mockResolvedValueOnce(mockResponse({ ok: false, status: 400, statusText: 'Bad Request', json: async () => ({}) }))
      .mockResolvedValueOnce(mockResponse({ ok: true, json: async () => ({ _embedded: { elements: [] } }) }));
    const consoleSpy = vi.spyOn(console, 'warn').mockImplementation(() => {});

    try {
      await fetchAllowedValues('/api/v3/work_packages/available_projects', 'demo', { favoredOnly: true });

      const filters = new URL(calledUrl(fetchSpy.mock.calls, 1)).searchParams.get('filters');
      expect(JSON.parse(filters!)).toEqual([{ favored: { operator: '=', values: ['t'] } }]);
    } finally {
      fetchSpy.mockRestore();
      consoleSpy.mockRestore();
    }
  });
});
