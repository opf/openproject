import {GlobalI18n} from "core-app/modules/common/i18n/i18n.service";

export class I18nShim implements GlobalI18n {

  public defaultLocale = 'en';
  public firstDayOfWeek = 1;
  public locale = 'en';
  public translations = {
    en: {}
  };

  t(key:string) {
    return '[missing "' + key + '" translation]';
  }

  lookup(translateId:string):boolean {
    return false;
  }
}

