import { describe, expect, it, vi } from 'vitest';
import { initOpenProjectApi } from '../../../../lib/services/openProjectApi/client';
import { OpenProjectApiError } from '../../../../lib/services/openProjectApi/errors';
import {
  avatarUrlOf,
  fetchConfiguration,
  fetchNonWorkingDays,
  fetchPriorities,
  fetchStatuses,
  fetchTypes,
  fetchWeekdays,
} from '../../../../lib/services/openProjectApi/resources';
import { calledUrl, mockResponse } from './fetchStubs';

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

describe('fetchPriorities', () => {
  it('asks the proxyUrl for them', async () => {
    const proxyUrl = 'https://proxy.example.com';
    initOpenProjectApi({ baseUrl: 'https://openproject.example.com', proxyUrl });
    const fetchSpy = vi.spyOn(global, 'fetch').mockResolvedValue(mockResponse({
      ok: true,
      json: async () => ({}),
    }));

    try {
      await fetchPriorities();
      expect(calledUrl(fetchSpy.mock.calls)).toBe(`${proxyUrl}/api/v3/priorities`);
    } finally {
      fetchSpy.mockRestore();
    }
  });
});

describe('what the date pickers are set up with', () => {
  async function requested(call:() => Promise<unknown>, body:unknown = {}):Promise<string> {
    initOpenProjectApi({ baseUrl: 'http://localhost:3000' });
    const fetchSpy = vi.spyOn(global, 'fetch').mockResolvedValue(mockResponse({
      ok: true,
      json: async () => body,
    }));

    try {
      await call();
      return calledUrl(fetchSpy.mock.calls);
    } finally {
      fetchSpy.mockRestore();
    }
  }

  it('reads the formats and time zone of the user from the configuration', async () => {
    expect(await requested(fetchConfiguration)).toBe('http://localhost:3000/api/v3/configuration');
  });

  it('reads which days of the week are worked', async () => {
    expect(await requested(fetchWeekdays)).toBe('http://localhost:3000/api/v3/days/week');
  });

  it('asks for the non working days of one whole year', async () => {
    const url = new URL(await requested(() => fetchNonWorkingDays(2026)));

    expect(url.pathname).toBe('/api/v3/days/non_working');
    expect(JSON.parse(url.searchParams.get('filters')!)).toEqual([
      { date: { operator: '<>d', values: ['2026-01-01', '2026-12-31'] } },
    ]);
  });

  it('answers with the dates of the non working days', async () => {
    initOpenProjectApi({ baseUrl: 'http://localhost:3000' });
    const fetchSpy = vi.spyOn(global, 'fetch').mockResolvedValue(mockResponse({
      ok: true,
      json: async () => ({ _embedded: { elements: [{ date: '2026-12-25', name: 'Christmas' }] } }),
    }));

    try {
      expect(await fetchNonWorkingDays(2026)).toEqual(['2026-12-25']);
    } finally {
      fetchSpy.mockRestore();
    }
  });
});

describe('avatarUrlOf', () => {
  it('loads the pictures of users from the proxyUrl, which authorizes them', () => {
    const proxyUrl = 'https://proxy.example.com';
    initOpenProjectApi({ baseUrl: 'https://openproject.example.com', proxyUrl });
    expect(avatarUrlOf('/api/v3/users/3')).toBe(`${proxyUrl}/api/v3/users/3/avatar`);
  });

  it('has a picture for users only', () => {
    initOpenProjectApi({ baseUrl: 'https://example.com' });

    expect(avatarUrlOf('/api/v3/groups/4')).toBeUndefined();
    expect(avatarUrlOf('/api/v3/placeholder_users/5')).toBeUndefined();
    expect(avatarUrlOf(null)).toBeUndefined();
  });
});
