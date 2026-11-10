import { describe, expect, it, vi } from 'vitest';
import { cacheColors, colorOfType } from '../../../lib/services/colors';

vi.mock('../../../lib/services/openProjectApi', () => ({
  fetchTypes: () => new Promise((resolve) => {
    setTimeout(() => resolve({ _embedded: { elements: [{ id: '1', color: '#D35400' }] } }), 20);
  }),
  fetchStatuses: () => Promise.resolve({ _embedded: { elements: [] } }),
  fetchPriorities: () => Promise.reject(new Error('Forbidden')),
}));

describe('cacheColors', () => {
  it('waits for every color source, even when another one has already failed', async () => {
    vi.spyOn(console, 'error').mockImplementation(() => undefined);

    await cacheColors();

    expect(colorOfType('/api/v3/types/1')).toBe('#D35400');
  });
});
