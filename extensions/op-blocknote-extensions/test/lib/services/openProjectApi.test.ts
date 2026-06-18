import { describe, expect, it, vi } from 'vitest';
import {
  fetchStatuses,
  fetchTypes,
  fetchWorkPackage,
  initOpenProjectApi,
  linkToWorkPackage,
  OpenProjectApiError,
  searchWorkPackages
} from '../../../lib/services/openProjectApi';

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
      const fetchSpy = vi.spyOn(global, 'fetch').mockResolvedValue({
        ok: true,
        json: async () => ({ _embedded: { elements: [] } }),
      } as Response);

      try {
        searchWorkPackages('test query');

        const calledUrl = fetchSpy.mock.calls[0][0] as string;
        expect(calledUrl).toContain('sortBy=%5B%5B%22updatedAt%22%2C%22desc%22%5D%5D');
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

  describe('fetchWorkPackage', () => {
    it('rejects for invalid work package ID', async () => {
      initOpenProjectApi({baseUrl: 'https://example.com'});
      await expect(fetchWorkPackage(-1)).rejects.toHaveProperty('message', 'Invalid work package ID: -1');
      await expect(fetchWorkPackage(0)).rejects.toHaveProperty('message', 'Invalid work package ID: 0');
      await expect(fetchWorkPackage(NaN)).rejects.toHaveProperty('message', 'Invalid work package ID: NaN');
      await expect(fetchWorkPackage('abublé' as unknown as number)).rejects.toHaveProperty('message', 'Invalid work package ID: abublé');
    });
  });

  describe('fetchStatuses', () => {
    it('resolves with data on success', async () => {
      initOpenProjectApi({ baseUrl: 'http://localhost:3000' });
      const mockData = { _embedded: { elements: [] } };
      const fetchSpy = vi.spyOn(global, 'fetch').mockResolvedValue({
        ok: true,
        json: async () => mockData,
      } as Response);

      try {
        const result = await fetchStatuses();
        expect(result).toEqual(mockData);
      } finally {
        fetchSpy.mockRestore();
      }
    });

    it('logs to console and rejects on HTTP error', async () => {
      initOpenProjectApi({ baseUrl: 'http://localhost:3000' });
      const fetchSpy = vi.spyOn(global, 'fetch').mockResolvedValue({
        ok: false,
        status: 500,
        statusText: 'Internal Server Error',
      } as Response);
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
      const fetchSpy = vi.spyOn(global, 'fetch').mockResolvedValue({
        ok: true,
        json: async () => mockData,
      } as Response);

      try {
        const result = await fetchTypes();
        expect(result).toEqual(mockData);
      } finally {
        fetchSpy.mockRestore();
      }
    });

    it('logs to console and rejects on HTTP error', async () => {
      initOpenProjectApi({ baseUrl: 'http://localhost:3000' });
      const fetchSpy = vi.spyOn(global, 'fetch').mockResolvedValue({
        ok: false,
        status: 403,
        statusText: 'Forbidden',
      } as Response);
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
