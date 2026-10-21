import { describe, expect, it, vi } from 'vitest';
import { initOpenProjectApi } from '../../../../lib/services/openProjectApi/client';
import { OpenProjectApiError } from '../../../../lib/services/openProjectApi/errors';
import { fetchStatuses, fetchTypes } from '../../../../lib/services/openProjectApi/resources';
import { mockResponse } from './fetchStubs';

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
