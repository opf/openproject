import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import {
  clearDatePickerSettings,
  isNonWorkingDay,
  loadDatePickerSettings,
  loadNonWorkingDays,
} from '../../../../lib/components/CreateWorkPackage/datePickerSettings';
import { initLanguage } from '../../../../lib/services/i18n';
import { initOpenProjectApi } from '../../../../lib/services/openProjectApi';

const configuration = {
  dateFormat: 'DD.MM.YYYY',
  timeFormat: 'HH:mm',
  startOfWeek: 7,
  _embedded: { userPreferences: { timeZone: 'Asia/Tokyo' } },
};

const weekdays = [1, 2, 3, 4, 5, 6, 7].map((day) => ({ day, working: day < 6 }));

const pathOf = (input:RequestInfo | URL):string => new URL(input instanceof Request ? input.url : input).pathname;

function answering(bodies:Record<string, unknown>) {
  return vi.spyOn(globalThis, 'fetch').mockImplementation(async (input) => {
    const path = pathOf(input);
    if (!(path in bodies)) return { ok: false, status: 500, statusText: 'Internal Server Error' } as Response;

    return { ok: true, json: async () => bodies[path] } as Response;
  });
}

describe('datePickerSettings', () => {
  beforeEach(() => {
    initOpenProjectApi({ baseUrl: 'http://localhost:3000' });
    initLanguage('de');
    clearDatePickerSettings();
  });

  afterEach(() => {
    vi.restoreAllMocks();
    initLanguage('en');
  });

  describe('loadDatePickerSettings', () => {
    it('takes the formats, time zone and week of the user from the configuration', async () => {
      answering({ '/api/v3/configuration': configuration });

      expect(await loadDatePickerSettings()).toEqual({
        timeZone: 'Asia/Tokyo',
        locale: 'de',
        dateFormat: 'DD.MM.YYYY',
        timeFormat: 'HH:mm',
        firstDayOfWeek: 0,
      });
    });

    it('asks only once', async () => {
      const fetchSpy = answering({ '/api/v3/configuration': configuration });

      await loadDatePickerSettings();
      await loadDatePickerSettings();

      expect(fetchSpy).toHaveBeenCalledTimes(1);
    });

    it('falls back to the browser and the language when the configuration cannot be read', async () => {
      answering({});
      vi.spyOn(console, 'error').mockImplementation(() => {});

      expect(await loadDatePickerSettings()).toEqual({
        timeZone: Intl.DateTimeFormat().resolvedOptions().timeZone,
        locale: 'de',
        dateFormat: null,
        timeFormat: null,
        firstDayOfWeek: 1,
      });
    });

    it('asks again after a failure', async () => {
      const fetchSpy = answering({});
      vi.spyOn(console, 'error').mockImplementation(() => {});

      await loadDatePickerSettings();
      await loadDatePickerSettings();

      expect(fetchSpy).toHaveBeenCalledTimes(2);
    });
  });

  describe('non working days', () => {
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
});
