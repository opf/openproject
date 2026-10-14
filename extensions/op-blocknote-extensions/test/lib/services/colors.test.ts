import { describe, expect, it, vi } from 'vitest';
import { cacheColors, colorOfType } from '../../../lib/services/colors';

vi.mock('../../../lib/services/openProjectApi', () => ({
  fetchTypes: () => Promise.resolve({
    _embedded: { elements: [{ id: '1', color: '#D35400' }, { id: '2' }] },
  }),
  fetchStatuses: () => Promise.resolve({ _embedded: { elements: [] } }),
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
