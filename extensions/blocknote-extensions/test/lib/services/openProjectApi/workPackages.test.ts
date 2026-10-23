import { describe, expect, it, vi } from 'vitest';
import { initOpenProjectApi } from '../../../../lib/services/openProjectApi/client';
import {
  fetchWorkPackage,
  linkToNewWorkPackage,
  linkToWorkPackage,
  parseWorkPackageUrl,
  searchWorkPackages
} from '../../../../lib/services/openProjectApi/workPackages';
import { calledUrl, mockResponse } from './fetchStubs';

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

describe('linkToNewWorkPackage', () => {
  it('links to the creation form of a project, or the global one', () => {
    initOpenProjectApi({ baseUrl: 'https://example.com' });
    expect(linkToNewWorkPackage('42')).toBe('https://example.com/projects/42/work_packages/new');
    expect(linkToNewWorkPackage()).toBe('https://example.com/work_packages/new');
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

describe('fetchWorkPackage', () => {
  it('rejects for invalid work package ID', async () => {
    initOpenProjectApi({baseUrl: 'https://example.com'});
    await expect(fetchWorkPackage(-1)).rejects.toHaveProperty('message', 'Invalid work package ID: -1');
    await expect(fetchWorkPackage(NaN)).rejects.toHaveProperty('message', 'Invalid work package ID: NaN');
    await expect(fetchWorkPackage('abublé')).rejects.toHaveProperty('message', 'Invalid work package ID: abublé');
    await expect(fetchWorkPackage('../../admin')).rejects.toHaveProperty('message', 'Invalid work package ID: ../../admin');
  });
});

describe('with a proxyUrl', () => {
  const baseUrl = 'https://openproject.example.com';
  const proxyUrl = 'https://proxy.example.com';

  it('keeps building work package links from the baseUrl', () => {
    initOpenProjectApi({ baseUrl, proxyUrl });
    expect(linkToWorkPackage('42')).toBe(`${baseUrl}/wp/42`);
  });

  it('only recognizes pasted work package URLs of the baseUrl', () => {
    initOpenProjectApi({ baseUrl, proxyUrl });
    expect(parseWorkPackageUrl(`${baseUrl}/wp/123`)).toBe('123');
    expect(parseWorkPackageUrl(`${proxyUrl}/wp/123`)).toBeNull();
  });

  it('fetches work packages through the proxyUrl', async () => {
    initOpenProjectApi({ baseUrl, proxyUrl });
    const fetchSpy = vi.spyOn(global, 'fetch').mockResolvedValue(mockResponse({
      ok: true,
      json: async () => ({ _embedded: { elements: [] } }),
    }));

    try {
      await fetchWorkPackage('DWPS-2');
      expect(calledUrl(fetchSpy.mock.calls)).toBe(`${proxyUrl}/api/v3/work_packages/DWPS-2`);
    } finally {
      fetchSpy.mockRestore();
    }
  });
});
