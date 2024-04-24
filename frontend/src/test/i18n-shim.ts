import * as _ from 'lodash';

export class I18nShim {
  public defaultLocale = 'en';

  public firstDayOfWeek = 1;

  public locale = 'en';

  public translations = {
    en: {},
  };

  t<T=string>(key:string):T {
    return `[missing "${key}" translation]` as unknown as T;
  }

  lookup():boolean {
    return false;
  }

  // Return the input for these helpers
  // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access,@typescript-eslint/no-unsafe-assignment
  public toNumber = _.identity;

  // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access,@typescript-eslint/no-unsafe-assignment
  public toPercentage = _.identity;

  // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access,@typescript-eslint/no-unsafe-assignment
  public toCurrency = _.identity;

  // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access,@typescript-eslint/no-unsafe-assignment
  public strftime = _.identity;

  // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access,@typescript-eslint/no-unsafe-assignment
  public toHumanSize = _.identity;

  // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access,@typescript-eslint/no-unsafe-assignment
  public toTime = _.identity;
}
