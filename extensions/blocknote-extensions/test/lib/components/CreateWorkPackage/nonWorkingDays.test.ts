import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import {
  clearNonWorkingDays,
  isNonWorkingDay,
  loadNonWorkingDays,
} from '../../../../lib/components/CreateWorkPackage/nonWorkingDays';
import { initOpenProjectApi } from '../../../../lib/services/openProjectApi';
import { answering, pathOf } from '../../../helpers/fetchHelpers';

const weekdays = [1, 2, 3, 4, 5, 6, 7].map((day) => ({ day, working: day < 6 }));

describe('nonWorkingDays', () => {
  beforeEach(() => {
    initOpenProjectApi({ baseUrl: 'http://localhost:3000' });
    clearNonWorkingDays();
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  const christmas = new Date(2026, 11, 25);
  const aWorkingFriday = new Date(2026, 11, 18);
  const aSaturday = new Date(2026, 11, 19);

  it('knows the weekdays not worked and the days off of a loaded year', async () => {
    answering({
      '/api/v3/days/week': { _embedded: { elements: weekdays } },
      '/api/v3/days/non_working': { _embedded: { elements: [{ date: '2026-12-25' }] } },
    });

    await loadNonWorkingDays(2026);

    expect(isNonWorkingDay(christmas)).toBe(true);
    expect(isNonWorkingDay(aSaturday)).toBe(true);
    expect(isNonWorkingDay(aWorkingFriday)).toBe(false);
  });

  it('knows nothing of a year not loaded yet', () => {
    expect(isNonWorkingDay(christmas)).toBe(false);
  });

  it('asks once per year', async () => {
    const fetchSpy = answering({
      '/api/v3/days/week': { _embedded: { elements: weekdays } },
      '/api/v3/days/non_working': { _embedded: { elements: [] } },
    });

    await Promise.all([loadNonWorkingDays(2026), loadNonWorkingDays(2026)]);
    await loadNonWorkingDays(2027);

    const paths = fetchSpy.mock.calls.map(([input]) => pathOf(input));
    expect(paths.filter((path) => path === '/api/v3/days/week')).toHaveLength(1);
    expect(paths.filter((path) => path === '/api/v3/days/non_working')).toHaveLength(2);
  });

  it('marks nothing when the days cannot be read', async () => {
    answering({});
    vi.spyOn(console, 'error').mockImplementation(() => {});

    await loadNonWorkingDays(2026);

    expect(isNonWorkingDay(aSaturday)).toBe(false);
  });
});
