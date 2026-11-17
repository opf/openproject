import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import type { WorkPackage } from '../../../lib/openProjectTypes';
import * as openProjectApi from '../../../lib/services/openProjectApi';
import { OpenProjectApiError } from '../../../lib/services/openProjectApi';
import {
  cachedWorkPackage,
  cachedWorkPackageSchema,
  clearWorkPackageCache,
  loadWorkPackage,
} from '../../../lib/services/workPackageLoader';

const SCHEMA_HREF = '/api/v3/work_packages/schemas/1-2';
const schema = { subject: { type: 'String', name: 'Subject' }, _links: { self: { href: SCHEMA_HREF } } };

const workPackage = (id:number) => ({
  id,
  displayId: String(id),
  subject: `Work package ${id}`,
  _links: { schema: { href: SCHEMA_HREF } },
}) as WorkPackage;

const batchOf = (ids:readonly number[]) => ({
  workPackages: ids.filter((id) => id !== 404).map(workPackage),
  schemas: [schema],
});

describe('workPackageLoader', () => {
  let fetchWorkPackages:ReturnType<typeof vi.spyOn<typeof openProjectApi, 'fetchWorkPackages'>>;

  beforeEach(() => {
    clearWorkPackageCache();
    fetchWorkPackages = vi.spyOn(openProjectApi, 'fetchWorkPackages')
      .mockImplementation(async (ids) => batchOf(ids));
  });

  afterEach(() => vi.restoreAllMocks());

  it('loads the work packages asked for within one task together', async () => {
    const loads = [loadWorkPackage(1), loadWorkPackage(2), loadWorkPackage(3)];

    expect((await Promise.all(loads)).map(({ id }) => id)).toEqual([1, 2, 3]);
    expect(fetchWorkPackages).toHaveBeenCalledTimes(1);
    expect(fetchWorkPackages).toHaveBeenCalledWith([1, 2, 3]);
  });

  it('asks for a work package shown twice only once', async () => {
    const [first, second] = await Promise.all([loadWorkPackage(1), loadWorkPackage(1)]);

    expect(first).toBe(second);
    expect(fetchWorkPackages).toHaveBeenCalledWith([1]);
  });

  it('joins a load that is already under way', async () => {
    const first = loadWorkPackage(1);
    await new Promise((resolve) => setTimeout(resolve, 0));
    const second = loadWorkPackage(1);

    expect(await second).toBe(await first);
    expect(fetchWorkPackages).toHaveBeenCalledTimes(1);
  });

  it('serves a loaded work package from the cache', async () => {
    const loaded = await loadWorkPackage(1);

    expect(cachedWorkPackage(1)).toBe(loaded);
    expect(await loadWorkPackage(1)).toBe(loaded);
    expect(fetchWorkPackages).toHaveBeenCalledTimes(1);
  });

  it('keeps the schemas loaded with the work packages', async () => {
    const loaded = await loadWorkPackage(1);

    expect(cachedWorkPackageSchema(loaded)).toEqual(schema);
  });

  it('rejects a work package missing from the answer as not found', async () => {
    const missing = loadWorkPackage(404);
    const found = loadWorkPackage(1);

    await expect(missing).rejects.toBeInstanceOf(OpenProjectApiError);
    await expect(missing).rejects.toHaveProperty('responseStatus', 404);
    expect((await found).id).toBe(1);
    expect(cachedWorkPackage(404)).toBeUndefined();
  });

  it('asks for each work package of a failed batch on its own', async () => {
    const failure = new OpenProjectApiError('HTTP error! status: 500', 500);
    fetchWorkPackages
      .mockRejectedValueOnce(failure)
      .mockImplementation(async (ids) => (ids.includes(2) ? Promise.reject(failure) : batchOf(ids)));

    const [first, second] = [loadWorkPackage(1), loadWorkPackage(2)];

    expect((await first).id).toBe(1);
    await expect(second).rejects.toBe(failure);
    expect(fetchWorkPackages.mock.calls.map(([ids]) => ids)).toEqual([[1, 2], [1], [2]]);
    expect(cachedWorkPackage(1)).toBeDefined();
    expect(cachedWorkPackage(2)).toBeUndefined();
  });

  it('tries a work package that failed to load again on the next load', async () => {
    const failure = new OpenProjectApiError('HTTP error! status: 500', 500);
    fetchWorkPackages.mockRejectedValueOnce(failure).mockRejectedValueOnce(failure);

    await expect(loadWorkPackage(1)).rejects.toBe(failure);

    expect((await loadWorkPackage(1)).id).toBe(1);
    expect(fetchWorkPackages).toHaveBeenCalledTimes(3);
  });

  it('does not refill the cache from a load started before it was cleared', async () => {
    const stale = loadWorkPackage(1);
    clearWorkPackageCache();

    const loaded = await stale;

    expect(cachedWorkPackage(1)).toBeUndefined();
    expect(cachedWorkPackageSchema(loaded)).toBeUndefined();
  });
});
