import { useEffect, useState } from 'react';
import i18n from './i18n';
import { fetchConfiguration } from './openProjectApi';
import { firstDayOfWeek, type DateTimeSettings } from '../utils/dateTime';

export interface UserDateTimeSettings extends DateTimeSettings {
  firstDayOfWeek:number;
}

let settings:Promise<UserDateTimeSettings> | undefined;
let loadedSettings:UserDateTimeSettings | undefined;

const browserTimeZone = ():string => Intl.DateTimeFormat().resolvedOptions().timeZone;

async function readSettings(locale:string):Promise<UserDateTimeSettings> {
  const configuration = await fetchConfiguration();
  return {
    timeZone: configuration._embedded?.userPreferences?.timeZone ?? browserTimeZone(),
    locale,
    dateFormat: configuration.dateFormat,
    timeFormat: configuration.timeFormat,
    firstDayOfWeek: firstDayOfWeek(configuration.startOfWeek, locale),
  };
}

const fallbackSettings = (locale:string):UserDateTimeSettings => ({
  timeZone: browserTimeZone(),
  locale,
  dateFormat: null,
  timeFormat: null,
  firstDayOfWeek: firstDayOfWeek(null, locale),
});

export function loadDateTimeSettings():Promise<UserDateTimeSettings> {
  const locale = i18n.language;

  settings ??= readSettings(locale).then(
    (read) => {
      loadedSettings = read;
      return read;
    },
    (error:unknown) => {
      console.error('[date time settings] Failed to load the configuration:', error);
      settings = undefined;
      return fallbackSettings(locale);
    }
  );
  return settings;
}

export function useDateTimeSettings():UserDateTimeSettings | null {
  const [known, setKnown] = useState<UserDateTimeSettings | null>(loadedSettings ?? null);

  useEffect(() => {
    let active = true;
    void loadDateTimeSettings().then((read) => {
      if (active) setKnown(read);
    });
    return () => { active = false; };
  }, []);

  return known;
}

export function clearDateTimeSettings():void {
  settings = undefined;
  loadedSettings = undefined;
}
