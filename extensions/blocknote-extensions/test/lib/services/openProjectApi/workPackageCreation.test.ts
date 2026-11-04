import { afterEach, describe, expect, it, vi } from 'vitest';
import { initOpenProjectApi } from '../../../../lib/services/openProjectApi/client';
import {
  canCreateWorkPackages,
  createWorkPackage,
  fetchWorkPackageCreateForm,
  probeCreateWorkPackagePermission
} from '../../../../lib/services/openProjectApi/workPackageCreation';
import { calledUrl, mockResponse } from './fetchStubs';

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
});

describe('the permission to create work packages', () => {
  let fetchSpy:ReturnType<typeof vi.spyOn>;

  function answerProbeWith(status:number):Promise<boolean> {
    fetchSpy = vi.spyOn(global, 'fetch').mockResolvedValue(mockResponse({
      ok: status < 400,
      status,
      statusText: 'stubbed',
      json: async () => ({}),
    }));
    initOpenProjectApi({ baseUrl: 'https://example.com' });
    return probeCreateWorkPackagePermission();
  }

  afterEach(() => fetchSpy.mockRestore());

  it('is granted when the probe is answered', async () => {
    await answerProbeWith(200);

    expect(canCreateWorkPackages()).toBe(true);
    expect(calledUrl(fetchSpy.mock.calls))
      .toBe('https://example.com/api/v3/work_packages/available_projects?pageSize=1');
  });

  it('is refused when the probe is forbidden', async () => {
    await answerProbeWith(403);

    expect(canCreateWorkPackages()).toBe(false);
  });

  it('is left to the create form to refuse when the instance is in trouble', async () => {
    await answerProbeWith(500);

    expect(canCreateWorkPackages()).toBe(true);
  });

  it('is answered afresh by every probe', async () => {
    await answerProbeWith(403);
    expect(canCreateWorkPackages()).toBe(false);
    fetchSpy.mockRestore();

    await answerProbeWith(200);

    expect(canCreateWorkPackages()).toBe(true);
  });
});
