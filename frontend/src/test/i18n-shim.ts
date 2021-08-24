import { GlobalI18n } from 'core-app/core/i18n/i18n.service';

export class I18nShim implements GlobalI18n {
  public defaultLocale = 'en';

  public firstDayOfWeek = 1;

  public locale = 'en';

  public translations = {
    en: {},
  };

  public pluralization = {};

  t(key:string) {
    return `[missing "${key}" translation]`;
  }

  lookup(translateId:string):boolean {
    return false;
  }

  // Return the input for these helpers
  public toNumber = _.identity;

  public toPercentage = _.identity;

  public toCurrency = _.identity;

  public strftime = _.identity;

  public toHumanSize = _.identity;
}
