import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import {
  createWorkPackage,
  fetchAllowedValues,
  fetchStatuses,
  fetchTypes,
  fetchWorkPackage,
  fetchWorkPackageCreateForm,
  initOpenProjectApi,
  linkToNewWorkPackage,
  linkToWorkPackage,
  OpenProjectApiError,
  parseWorkPackageUrl,
  searchWorkPackages
} from '../../../lib/services/openProjectApi';

function mockResponse(props:Partial<Response>):Response {
  return props as Response;
}

function calledUrl(calls:unknown[][], index = 0):string {
  return calls[index][0] as string;
}

describe('openProjectApi', () => {
  it('works with a baseUrl with trailing slash', () => {
    initOpenProjectApi({baseUrl: 'https://example.com/'});
    expect(linkToWorkPackage('42')).toBe('https://example.com/wp/42');
  });

  it('works with a baseUrl without trailing slash', () => {
    initOpenProjectApi({baseUrl: 'https://example.com'});
    expect(linkToWorkPackage('42')).toBe('https://example.com/wp/42');
  });

  describe('searchWorkPackages', () => {
    it('should fetch work packages sorted by updatedAt descending', () => {
      initOpenProjectApi({baseUrl: 'http://localhost:3000'});
      const fetchSpy = vi.spyOn(global, 'fetch').mockResolvedValue(mockResponse({
        ok: true,
        json: async () => ({ _embedded: { elements: [] } }),
      }));

      try {
        searchWorkPackages('test query');

        const url = calledUrl(fetchSpy.mock.calls);
        expect(url).toContain('&sortBy=%5B%5B%22exactMatch%22%2C%22desc%22%5D%2C%5B%22updatedAt%22%2C%22desc%22%5D%5D');
      } finally {
        fetchSpy.mockRestore();
      }
    });

    it('takes no filter of its own from the search term', async () => {
      initOpenProjectApi({ baseUrl: 'http://localhost:3000' });
      const fetchSpy = vi.spyOn(global, 'fetch').mockResolvedValue(mockResponse({
        ok: true,
        json: async () => ({ _embedded: { elements: [] } }),
      }));

      try {
        await searchWorkPackages('a"]}},{"id":{"operator":"=","values":["1');

        const params = new URL(calledUrl(fetchSpy.mock.calls)).searchParams;
        // The term stayed one value of one filter, quotes and braces included.
        expect(JSON.parse(params.get('filters')!)).toEqual([
          { typeahead: { operator: '**', values: ['a"]}},{"id":{"operator":"=","values":["1'] } },
        ]);
      } finally {
        fetchSpy.mockRestore();
      }
    });
  });

  describe('linkToWorkPackage', () => {
    it('builds a correct URL for a numeric displayId', () => {
      initOpenProjectApi({baseUrl: 'https://example.com'});
      expect(linkToWorkPackage('123')).toBe('https://example.com/wp/123');
      expect(linkToWorkPackage('42')).toBe('https://example.com/wp/42');
    });

    it('builds a correct URL for a semantic displayId', () => {
      initOpenProjectApi({baseUrl: 'https://example.com'});
      expect(linkToWorkPackage('DWPS-1')).toBe('https://example.com/wp/DWPS-1');
      expect(linkToWorkPackage('PROJ-42')).toBe('https://example.com/wp/PROJ-42');
    });

    it('encodes path traversal attempts via encodeURIComponent', () => {
      initOpenProjectApi({baseUrl: 'https://example.com'});
      expect(linkToWorkPackage('../secret')).toBe('https://example.com/wp/..%2Fsecret');
      expect(linkToWorkPackage('../../etc/passwd')).toBe('https://example.com/wp/..%2F..%2Fetc%2Fpasswd');
      expect(linkToWorkPackage('foo/bar')).toBe('https://example.com/wp/foo%2Fbar');
    });
  });

  describe('parseWorkPackageUrl', () => {
    it('parses short work package links', () => {
      initOpenProjectApi({ baseUrl: 'http://localhost:3000' });
      expect(parseWorkPackageUrl('http://localhost:3000/wp/123')).toBe('123');
    });

    it('parses full and project-scoped work package routes', () => {
      initOpenProjectApi({ baseUrl: 'http://localhost:3000' });
      expect(parseWorkPackageUrl('http://localhost:3000/work_packages/123')).toBe('123');
      expect(parseWorkPackageUrl('http://localhost:3000/projects/demo/work_packages/123')).toBe('123');
      expect(parseWorkPackageUrl('http://localhost:3000/work_packages/details/123')).toBe('123');
    });

    it('parses semantic identifiers', () => {
      initOpenProjectApi({ baseUrl: 'http://localhost:3000' });
      expect(parseWorkPackageUrl('http://localhost:3000/wp/DWPS-2')).toBe('DWPS-2');
      expect(parseWorkPackageUrl('http://localhost:3000/work_packages/DWPS-2')).toBe('DWPS-2');
      expect(parseWorkPackageUrl('http://localhost:3000/projects/DWPS/work_packages/DWPS-2/activity')).toBe('DWPS-2');
    });

    it('accepts trailing tab segments, query strings and hashes', () => {
      initOpenProjectApi({ baseUrl: 'http://localhost:3000' });
      expect(parseWorkPackageUrl('http://localhost:3000/work_packages/123/activity')).toBe('123');
      expect(parseWorkPackageUrl('http://localhost:3000/wp/123?query=1')).toBe('123');
      expect(parseWorkPackageUrl('http://localhost:3000/wp/123#comments')).toBe('123');
    });

    it('rejects foreign hosts and non work package URLs', () => {
      initOpenProjectApi({ baseUrl: 'http://localhost:3000' });
      expect(parseWorkPackageUrl('https://other.example.com/wp/123')).toBeNull();
      expect(parseWorkPackageUrl('http://localhost:3000/projects/demo')).toBeNull();
      expect(parseWorkPackageUrl('http://localhost:3000/projects/demo/wp/123')).toBeNull();
      expect(parseWorkPackageUrl('http://localhost:3000/wp/abc')).toBeNull();
      expect(parseWorkPackageUrl('http://localhost:3000/wp/0')).toBeNull();
      expect(parseWorkPackageUrl('not a url')).toBeNull();
    });
  });

  describe('proxyUrl', () => {
    const baseUrl = 'https://openproject.example.com';
    const proxyUrl = 'https://proxy.example.com';

    let fetchSpy = vi.spyOn(global, 'fetch');

    beforeEach(() => {
      fetchSpy = vi.spyOn(global, 'fetch').mockResolvedValue(mockResponse({
        ok: true,
        json: async () => ({ _embedded: { elements: [] } }),
      }));
    });

    afterEach(() => {
      fetchSpy.mockRestore();
    });

    it('sends the authorized API requests to the proxyUrl', async () => {
      initOpenProjectApi({ baseUrl, proxyUrl });

      await fetchStatuses();
      expect(calledUrl(fetchSpy.mock.calls)).toBe(`${proxyUrl}/api/v3/statuses`);

      await fetchTypes();
      expect(calledUrl(fetchSpy.mock.calls, 1)).toBe(`${proxyUrl}/api/v3/types`);

      await fetchWorkPackage('DWPS-2');
      expect(calledUrl(fetchSpy.mock.calls, 2)).toBe(`${proxyUrl}/api/v3/work_packages/DWPS-2`);

      await searchWorkPackages('test query');
      expect(calledUrl(fetchSpy.mock.calls, 3)).toContain(`${proxyUrl}/api/v3/work_packages?`);
    });

    it('sends a write to the proxyUrl as well', async () => {
      initOpenProjectApi({ baseUrl, proxyUrl });

      await fetchWorkPackageCreateForm();
      expect(calledUrl(fetchSpy.mock.calls)).toBe(`${proxyUrl}/api/v3/work_packages/form`);
    });

    it('keeps building work package links from the baseUrl', () => {
      initOpenProjectApi({ baseUrl, proxyUrl });
      expect(linkToWorkPackage('42')).toBe(`${baseUrl}/wp/42`);
    });

    it('only recognizes pasted work package URLs of the baseUrl', () => {
      initOpenProjectApi({ baseUrl, proxyUrl });
      expect(parseWorkPackageUrl(`${baseUrl}/wp/123`)).toBe('123');
      expect(parseWorkPackageUrl(`${proxyUrl}/wp/123`)).toBeNull();
    });

    it('falls back to the baseUrl for the API requests if no proxyUrl is given', async () => {
      initOpenProjectApi({ baseUrl, proxyUrl });
      initOpenProjectApi({ baseUrl });

      await fetchStatuses();
      expect(calledUrl(fetchSpy.mock.calls)).toBe(`${baseUrl}/api/v3/statuses`);
    });

    it('works with a proxyUrl with trailing slash', async () => {
      initOpenProjectApi({ baseUrl: `${baseUrl}/`, proxyUrl: `${proxyUrl}/` });

      await fetchStatuses();
      expect(calledUrl(fetchSpy.mock.calls)).toBe(`${proxyUrl}/api/v3/statuses`);
      expect(linkToWorkPackage('42')).toBe(`${baseUrl}/wp/42`);
    });

    it('strips the trailing slash of the baseUrl it falls back to', async () => {
      initOpenProjectApi({ baseUrl: `${baseUrl}/` });

      await fetchStatuses();
      expect(calledUrl(fetchSpy.mock.calls)).toBe(`${baseUrl}/api/v3/statuses`);
    });
  });

  describe('fetchWorkPackage', () => {
    it('rejects for invalid work package ID', async () => {
      initOpenProjectApi({baseUrl: 'https://example.com'});
      await expect(fetchWorkPackage(-1)).rejects.toHaveProperty('message', 'Invalid work package ID: -1');
      await expect(fetchWorkPackage(NaN)).rejects.toHaveProperty('message', 'Invalid work package ID: NaN');
      await expect(fetchWorkPackage('abublé')).rejects.toHaveProperty('message', 'Invalid work package ID: abublé');
      await expect(fetchWorkPackage('../../admin')).rejects.toHaveProperty('message', 'Invalid work package ID: ../../admin');
    });
  });

  describe('fetchStatuses', () => {
    it('resolves with data on success', async () => {
      initOpenProjectApi({ baseUrl: 'http://localhost:3000' });
      const mockData = { _embedded: { elements: [] } };
      const fetchSpy = vi.spyOn(global, 'fetch').mockResolvedValue(mockResponse({
        ok: true,
        json: async () => mockData,
      }));

      try {
        const result = await fetchStatuses();
        expect(result).toEqual(mockData);
      } finally {
        fetchSpy.mockRestore();
      }
    });

    it('logs to console and rejects on HTTP error', async () => {
      initOpenProjectApi({ baseUrl: 'http://localhost:3000' });
      const fetchSpy = vi.spyOn(global, 'fetch').mockResolvedValue(mockResponse({
        ok: false,
        status: 500,
        statusText: 'Internal Server Error',
      }));
      const consoleSpy = vi.spyOn(console, 'error').mockImplementation(() => {});

      try {
        await expect(fetchStatuses()).rejects.toBeInstanceOf(OpenProjectApiError);
        expect(consoleSpy).toHaveBeenCalledWith(
          '[OpenProjectApi] fetchStatuses failed:',
          expect.any(OpenProjectApiError)
        );
      } finally {
        fetchSpy.mockRestore();
        consoleSpy.mockRestore();
      }
    });
  });

  describe('creating a work package', () => {
    it('posts the form request as JSON', async () => {
      initOpenProjectApi({ baseUrl: 'http://localhost:3000' });
      const fetchSpy = vi.spyOn(global, 'fetch').mockResolvedValue(mockResponse({
        ok: true,
        json: async () => ({ _type: 'Form' }),
      }));

      try {
        await fetchWorkPackageCreateForm({ _links: { project: { href: '/api/v3/projects/1' } } });

        expect(fetchSpy.mock.calls[0][0]).toBe('http://localhost:3000/api/v3/work_packages/form');
        const options = fetchSpy.mock.calls[0][1]!;
        expect(options.method).toBe('POST');
        // The API refuses a session authenticated write without it.
        expect(options.headers).toEqual({
          'Content-Type': 'application/json',
          'X-Requested-With': 'XMLHttpRequest',
        });
        expect(options.body).toBe('{"_links":{"project":{"href":"/api/v3/projects/1"}}}');
      } finally {
        fetchSpy.mockRestore();
      }
    });

    it('posts the work package to the global endpoint', async () => {
      initOpenProjectApi({ baseUrl: 'http://localhost:3000' });
      const fetchSpy = vi.spyOn(global, 'fetch').mockResolvedValue(mockResponse({
        ok: true,
        json: async () => ({ id: 42 }),
      }));

      try {
        const created = await createWorkPackage({ subject: 'Fix the header' });

        expect(fetchSpy.mock.calls[0][0]).toBe('http://localhost:3000/api/v3/work_packages');
        expect(created).toEqual({ id: 42 });
      } finally {
        fetchSpy.mockRestore();
      }
    });

    it('opens the form with an empty payload', async () => {
      initOpenProjectApi({ baseUrl: 'http://localhost:3000' });
      const fetchSpy = vi.spyOn(global, 'fetch').mockResolvedValue(mockResponse({
        ok: true,
        json: async () => ({ _type: 'Form' }),
      }));

      try {
        await fetchWorkPackageCreateForm();
        expect(fetchSpy.mock.calls[0][1]!.body).toBe('{}');
      } finally {
        fetchSpy.mockRestore();
      }
    });

    it('falls back to the status line when the failure carries no message', async () => {
      initOpenProjectApi({ baseUrl: 'http://localhost:3000' });
      const fetchSpy = vi.spyOn(global, 'fetch').mockResolvedValue(mockResponse({
        ok: false,
        status: 503,
        statusText: 'Service Unavailable',
        json: async () => { throw new Error('not JSON'); },
      }));

      try {
        await expect(createWorkPackage({})).rejects
          .toHaveProperty('message', 'HTTP error! status: 503 - Service Unavailable');
      } finally {
        fetchSpy.mockRestore();
      }
    });

    it('joins the attribute errors and prefers them over the summary', async () => {
      initOpenProjectApi({ baseUrl: 'http://localhost:3000' });
      const fetchSpy = vi.spyOn(global, 'fetch').mockResolvedValue(mockResponse({
        ok: false,
        status: 422,
        statusText: 'Unprocessable Entity',
        json: async () => ({
          message: 'Multiple field constraints have been violated.',
          _embedded: { errors: [{ message: 'Subject can\'t be blank.' }, { message: 'Type is not set.' }] },
        }),
      }));

      try {
        await expect(createWorkPackage({})).rejects
          .toHaveProperty('message', 'Subject can\'t be blank. Type is not set.');
      } finally {
        fetchSpy.mockRestore();
      }
    });

    it('keeps every violation under the property it is about', async () => {
      initOpenProjectApi({ baseUrl: 'http://localhost:3000' });
      const fetchSpy = vi.spyOn(global, 'fetch').mockResolvedValue(mockResponse({
        ok: false,
        status: 422,
        statusText: 'Unprocessable Entity',
        json: async () => ({
          message: 'Multiple field constraints have been violated.',
          _embedded: {
            errors: [
              { message: 'Subject can\'t be blank.', _embedded: { details: { attribute: 'subject' } } },
              { message: 'Pages must be greater than 0.', _embedded: { details: { attribute: 'customField9' } } },
              { message: 'Something else went wrong.' },
            ],
          },
        }),
      }));

      try {
        await expect(createWorkPackage({})).rejects.toHaveProperty('attributeErrors', {
          subject: 'Subject can\'t be blank.',
          customField9: 'Pages must be greater than 0.',
        });
      } finally {
        fetchSpy.mockRestore();
      }
    });

    it('reads the property of a lone violation, which carries no nested errors', async () => {
      initOpenProjectApi({ baseUrl: 'http://localhost:3000' });
      const fetchSpy = vi.spyOn(global, 'fetch').mockResolvedValue(mockResponse({
        ok: false,
        status: 422,
        statusText: 'Unprocessable Entity',
        json: async () => ({
          message: 'Subject can\'t be blank.',
          _embedded: { details: { attribute: 'subject' } },
        }),
      }));

      try {
        await expect(createWorkPackage({})).rejects
          .toHaveProperty('attributeErrors', { subject: 'Subject can\'t be blank.' });
      } finally {
        fetchSpy.mockRestore();
      }
    });

    it('reports the message the API returns instead of the status line', async () => {
      initOpenProjectApi({ baseUrl: 'http://localhost:3000' });
      const fetchSpy = vi.spyOn(global, 'fetch').mockResolvedValue(mockResponse({
        ok: false,
        status: 422,
        statusText: 'Unprocessable Entity',
        json: async () => ({ _embedded: { errors: [{ message: 'Subject can\'t be blank.' }] } }),
      }));

      try {
        await expect(createWorkPackage({})).rejects.toHaveProperty('message', 'Subject can\'t be blank.');
      } finally {
        fetchSpy.mockRestore();
      }
    });
  });

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

  describe('linkToNewWorkPackage', () => {
    it('links to the creation form of a project, or the global one', () => {
      initOpenProjectApi({ baseUrl: 'https://example.com' });
      expect(linkToNewWorkPackage('42')).toBe('https://example.com/projects/42/work_packages/new');
      expect(linkToNewWorkPackage()).toBe('https://example.com/work_packages/new');
    });
  });

  describe('fetchTypes', () => {
    it('resolves with data on success', async () => {
      initOpenProjectApi({ baseUrl: 'http://localhost:3000' });
      const mockData = { _embedded: { elements: [] } };
      const fetchSpy = vi.spyOn(global, 'fetch').mockResolvedValue(mockResponse({
        ok: true,
        json: async () => mockData,
      }));

      try {
        const result = await fetchTypes();
        expect(result).toEqual(mockData);
      } finally {
        fetchSpy.mockRestore();
      }
    });

    it('logs to console and rejects on HTTP error', async () => {
      initOpenProjectApi({ baseUrl: 'http://localhost:3000' });
      const fetchSpy = vi.spyOn(global, 'fetch').mockResolvedValue(mockResponse({
        ok: false,
        status: 403,
        statusText: 'Forbidden',
      }));
      const consoleSpy = vi.spyOn(console, 'error').mockImplementation(() => {});

      try {
        await expect(fetchTypes()).rejects.toBeInstanceOf(OpenProjectApiError);
        expect(consoleSpy).toHaveBeenCalledWith(
          '[OpenProjectApi] fetchTypes failed:',
          expect.any(OpenProjectApiError)
        );
      } finally {
        fetchSpy.mockRestore();
        consoleSpy.mockRestore();
      }
    });
  });
});
