import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import {
  fetchStatuses,
  fetchTypes,
  fetchWorkPackage,
  initOpenProjectApi,
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
        expect(url).toContain('sortBy=%5B%5B%22updatedAt%22%2C%22desc%22%5D%5D');
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
