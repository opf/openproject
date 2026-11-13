import { describe, expect, it, vi } from 'vitest';
import { cacheColors, colorOfType, priorityColor } from '../../../lib/services/colors';
import type { WorkPackage } from '../../../lib/openProjectTypes';

vi.mock('../../../lib/services/openProjectApi', () => ({
  fetchTypes: () => Promise.resolve({
    _embedded: { elements: [{ id: '1', color: '#D35400' }, { id: '2' }] },
  }),
  fetchStatuses: () => Promise.resolve({ _embedded: { elements: [] } }),
  fetchPriorities: () => Promise.resolve({ _embedded: { elements: [{ id: '9', color: '#E74C3C' }] } }),
}));

describe('colorOfType', () => {
  it('answers with the cached color of the type the href names', async () => {
    await cacheColors();

    expect(colorOfType('/api/v3/types/1')).toBe('#D35400');
  });

  it('falls back for a type left without a color, an unknown one, and none at all', async () => {
    await cacheColors();
    const fallback = colorOfType('/api/v3/types/404');

    expect(fallback).not.toBe('#D35400');
    expect(colorOfType('/api/v3/types/2')).toBe(fallback);
    expect(colorOfType(undefined)).toBe(fallback);
  });
});

describe('priorityColor', () => {
  const withPriority = (href:string | undefined) =>
    ({ _links: { priority: href ? { title: 'High', href } : null } }) as unknown as WorkPackage;

  it('answers with the cached color of the priority of the work package', async () => {
    await cacheColors();

    expect(priorityColor(withPriority('/api/v3/priorities/9'))).toBe('#E74C3C');
  });

  it('falls back for a priority without a color, and for none at all', async () => {
    await cacheColors();
    const fallback = priorityColor(withPriority(undefined));

    expect(fallback).not.toBe('#E74C3C');
    expect(priorityColor(withPriority('/api/v3/priorities/8'))).toBe(fallback);
  });
});
