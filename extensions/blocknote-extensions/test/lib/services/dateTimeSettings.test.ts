import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { clearDateTimeSettings, loadDateTimeSettings } from '../../../lib/services/dateTimeSettings';
import { initLanguage } from '../../../lib/services/i18n';
import { initOpenProjectApi } from '../../../lib/services/openProjectApi';
import { answering } from '../../helpers/fetchHelpers';

const configuration = {
  dateFormat: 'DD.MM.YYYY',
  timeFormat: 'HH:mm',
  startOfWeek: 7,
  _embedded: { userPreferences: { timeZone: 'Asia/Tokyo' } },
};

describe('dateTimeSettings', () => {
  beforeEach(() => {
    initOpenProjectApi({ baseUrl: 'http://localhost:3000' });
    initLanguage('de');
    clearDateTimeSettings();
  });

  afterEach(() => {
    vi.restoreAllMocks();
    initLanguage('en');
  });

  describe('loadDateTimeSettings', () => {
    it('takes the formats, time zone and week of the user from the configuration', async () => {
      answering({ '/api/v3/configuration': configuration });

      expect(await loadDateTimeSettings()).toEqual({
        timeZone: 'Asia/Tokyo',
        locale: 'de',
        dateFormat: 'DD.MM.YYYY',
        timeFormat: 'HH:mm',
        firstDayOfWeek: 0,
      });
    });

    it('asks only once', async () => {
      const fetchSpy = answering({ '/api/v3/configuration': configuration });

      await loadDateTimeSettings();
      await loadDateTimeSettings();

      expect(fetchSpy).toHaveBeenCalledTimes(1);
    });

    it('falls back to the browser and the language when the configuration cannot be read', async () => {
      answering({});
      vi.spyOn(console, 'error').mockImplementation(() => {});

      expect(await loadDateTimeSettings()).toEqual({
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

      await loadDateTimeSettings();
      await loadDateTimeSettings();

      expect(fetchSpy).toHaveBeenCalledTimes(2);
    });
  });
});
