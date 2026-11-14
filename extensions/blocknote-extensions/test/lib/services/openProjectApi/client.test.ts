import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { get, initOpenProjectApi, instancePathOf, instanceUrl, post } from '../../../../lib/services/openProjectApi/client';
import { OpenProjectApiError } from '../../../../lib/services/openProjectApi/errors';
import { calledUrl, mockResponse } from './fetchStubs';

describe('baseUrl', () => {
  it('works with a baseUrl with trailing slash', () => {
    initOpenProjectApi({ baseUrl: 'https://example.com/' });
    expect(instanceUrl('/wp/42')).toBe('https://example.com/wp/42');
  });

  it('works with a baseUrl without trailing slash', () => {
    initOpenProjectApi({ baseUrl: 'https://example.com' });
    expect(instanceUrl('/wp/42')).toBe('https://example.com/wp/42');
  });

  it('only takes the paths of URLs of the instance', () => {
    initOpenProjectApi({ baseUrl: 'https://example.com' });
    expect(instancePathOf('https://example.com/wp/42')).toBe('/wp/42');
    expect(instancePathOf('https://example.com.evil.org/wp/42')).toBeNull();
    expect(instancePathOf('https://other.example.com/wp/42')).toBeNull();
  });
});

describe('proxyUrl', () => {
  const baseUrl = 'https://openproject.example.com';
  const proxyUrl = 'https://proxy.example.com';

  let fetchSpy = vi.spyOn(global, 'fetch');

  beforeEach(() => {
    fetchSpy = vi.spyOn(global, 'fetch').mockResolvedValue(mockResponse({
      ok: true,
      json: async () => ({}),
    }));
  });

  afterEach(() => {
    fetchSpy.mockRestore();
  });

  it('sends the authorized API requests to the proxyUrl', async () => {
    initOpenProjectApi({ baseUrl, proxyUrl });

    await get('/api/v3/statuses');
    expect(calledUrl(fetchSpy.mock.calls)).toBe(`${proxyUrl}/api/v3/statuses`);
  });

  it('sends a write to the proxyUrl as well', async () => {
    initOpenProjectApi({ baseUrl, proxyUrl });

    await post('/api/v3/work_packages/form', {});
    expect(calledUrl(fetchSpy.mock.calls)).toBe(`${proxyUrl}/api/v3/work_packages/form`);
  });

  it('keeps building links from the baseUrl', () => {
    initOpenProjectApi({ baseUrl, proxyUrl });
    expect(instanceUrl('/wp/42')).toBe(`${baseUrl}/wp/42`);
    expect(instancePathOf(`${proxyUrl}/wp/42`)).toBeNull();
  });

  it('falls back to the baseUrl for the API requests if no proxyUrl is given', async () => {
    initOpenProjectApi({ baseUrl, proxyUrl });
    initOpenProjectApi({ baseUrl });

    await get('/api/v3/statuses');
    expect(calledUrl(fetchSpy.mock.calls)).toBe(`${baseUrl}/api/v3/statuses`);
  });

  it('works with a proxyUrl with trailing slash', async () => {
    initOpenProjectApi({ baseUrl: `${baseUrl}/`, proxyUrl: `${proxyUrl}/` });

    await get('/api/v3/statuses');
    expect(calledUrl(fetchSpy.mock.calls)).toBe(`${proxyUrl}/api/v3/statuses`);
    expect(instanceUrl('/wp/42')).toBe(`${baseUrl}/wp/42`);
  });

  it('strips the trailing slash of the baseUrl it falls back to', async () => {
    initOpenProjectApi({ baseUrl: `${baseUrl}/` });

    await get('/api/v3/statuses');
    expect(calledUrl(fetchSpy.mock.calls)).toBe(`${baseUrl}/api/v3/statuses`);
  });
});

describe('a failed read', () => {
  it('rejects with the status line', async () => {
    initOpenProjectApi({ baseUrl: 'http://localhost:3000' });
    const fetchSpy = vi.spyOn(global, 'fetch').mockResolvedValue(mockResponse({
      ok: false,
      status: 404,
      statusText: 'Not Found',
    }));

    try {
      const failure = get('/api/v3/work_packages/1');
      await expect(failure).rejects.toBeInstanceOf(OpenProjectApiError);
      await expect(failure).rejects.toMatchObject({
        message: 'HTTP error! status: 404 - Not Found',
        responseStatus: 404,
      });
    } finally {
      fetchSpy.mockRestore();
    }
  });
});

describe('a failed write', () => {
  it('falls back to the status line when the failure carries no message', async () => {
    initOpenProjectApi({ baseUrl: 'http://localhost:3000' });
    const fetchSpy = vi.spyOn(global, 'fetch').mockResolvedValue(mockResponse({
      ok: false,
      status: 503,
      statusText: 'Service Unavailable',
      json: async () => { throw new Error('not JSON'); },
    }));

    try {
      await expect(post('/api/v3/work_packages', {})).rejects
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
      await expect(post('/api/v3/work_packages', {})).rejects
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
      await expect(post('/api/v3/work_packages', {})).rejects.toHaveProperty('attributeErrors', {
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
      await expect(post('/api/v3/work_packages', {})).rejects
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
      await expect(post('/api/v3/work_packages', {})).rejects.toHaveProperty('message', 'Subject can\'t be blank.');
    } finally {
      fetchSpy.mockRestore();
    }
  });
});
