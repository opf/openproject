import { afterEach, beforeEach, describe, expect, it, vi, type MockInstance } from 'vitest';
import { initOpenProjectApi } from '../../../../lib/services/openProjectApi/client';
import {
  fetchWorkPackage,
  fetchWorkPackages,
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

describe('fetchWorkPackages', () => {
  const proxyUrl = 'http://localhost:3000';

  function idsOf(url:string):number[] {
    const filters = JSON.parse(new URL(url).searchParams.get('filters')!) as { id:{ values:string[] } }[];
    return filters[0].id.values.map(Number);
  }

  function stubApi({ visible, maxPageSize = 1000 }:{ visible:number[]; maxPageSize?:number }):MockInstance<typeof fetch> {
    return vi.spyOn(globalThis, 'fetch').mockImplementation(async (input) => {
      const url = new URL(input as string);
      const requested = idsOf(url.toString());
      const valid = visible.filter((id) => requested.includes(id));
      const matching = valid.length > 0 ? valid : visible;
      const pageSize = Math.min(Number(url.searchParams.get('pageSize')), maxPageSize);
      const offset = Number(url.searchParams.get('offset'));
      const elements = matching.slice((offset - 1) * pageSize, offset * pageSize).map((id) => ({ id }));

      return mockResponse({
        ok: true,
        json: async () => ({ total: matching.length, count: elements.length, _embedded: { elements } }),
      });
    });
  }

  beforeEach(() => initOpenProjectApi({ baseUrl: proxyUrl }));
  afterEach(() => vi.restoreAllMocks());

  it('asks for all of them in a single request', async () => {
    const fetchSpy = stubApi({ visible: [1, 2, 3] });

    const workPackages = await fetchWorkPackages([1, 2, 3]);

    expect(workPackages.map(({ id }) => id)).toEqual([1, 2, 3]);
    expect(fetchSpy).toHaveBeenCalledTimes(1);
    const url = new URL(calledUrl(fetchSpy.mock.calls));
    expect(`${url.origin}${url.pathname}`).toBe(`${proxyUrl}/api/v3/work_packages`);
    expect(url.searchParams.get('filters')).toBe('[{"id":{"operator":"=","values":["1","2","3"]}}]');
    expect(url.searchParams.get('valid_subset')).toBe('true');
    expect(url.searchParams.get('pageSize')).toBe('3');
  });

  it('asks for an id given twice only once', async () => {
    const fetchSpy = stubApi({ visible: [1, 2] });

    await fetchWorkPackages([1, 2, 1]);

    expect(idsOf(calledUrl(fetchSpy.mock.calls))).toEqual([1, 2]);
  });

  it('leaves out the work packages the user cannot see', async () => {
    stubApi({ visible: [1, 3] });

    const workPackages = await fetchWorkPackages([1, 2, 3]);

    expect(workPackages.map(({ id }) => id)).toEqual([1, 3]);
  });

  it('answers with none when not one of them is visible, instead of what the dropped filter returns', async () => {
    const fetchSpy = stubApi({ visible: [7, 8, 9, 10] });

    expect(await fetchWorkPackages([1, 2])).toEqual([]);
    expect(fetchSpy).toHaveBeenCalledTimes(1);
  });

  it('follows the pages when the instance caps the page size', async () => {
    const fetchSpy = stubApi({ visible: [1, 2, 3, 4, 5], maxPageSize: 2 });

    const workPackages = await fetchWorkPackages([1, 2, 3, 4, 5]);

    expect(workPackages.map(({ id }) => id)).toEqual([1, 2, 3, 4, 5]);
    expect(fetchSpy.mock.calls.map(([input]) => new URL(input as string).searchParams.get('offset')))
      .toEqual(['1', '2', '3']);
  });

  it('splits a long list of ids over several requests', async () => {
    const ids = Array.from({ length: 250 }, (_, index) => index + 1);
    const fetchSpy = stubApi({ visible: ids });

    const workPackages = await fetchWorkPackages(ids);

    expect(workPackages).toHaveLength(250);
    expect(fetchSpy.mock.calls.map(([input]) => idsOf(input as string).length)).toEqual([100, 100, 50]);
  });

  it('sends no request for no ids', async () => {
    const fetchSpy = stubApi({ visible: [] });

    expect(await fetchWorkPackages([])).toEqual([]);
    expect(fetchSpy).not.toHaveBeenCalled();
  });

  it('leaves out invalid ids instead of failing the others with them', async () => {
    const fetchSpy = stubApi({ visible: [1] });

    const workPackages = await fetchWorkPackages([1, -1, NaN, 1.5]);

    expect(workPackages.map(({ id }) => id)).toEqual([1]);
    expect(idsOf(calledUrl(fetchSpy.mock.calls))).toEqual([1]);
  });

  it('sends no request when no id is valid', async () => {
    const fetchSpy = stubApi({ visible: [1] });

    expect(await fetchWorkPackages([-1, NaN])).toEqual([]);
    expect(fetchSpy).not.toHaveBeenCalled();
  });

  it('rejects with the status of a failed request', async () => {
    vi.spyOn(global, 'fetch').mockResolvedValue(mockResponse({
      ok: false,
      status: 500,
      statusText: 'Internal Server Error',
    }));

    await expect(fetchWorkPackages([1])).rejects.toHaveProperty('responseStatus', 500);
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
