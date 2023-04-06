import { Injectable } from '@angular/core';
import { GlobalI18n } from './i18n.service';

export const GlobalI18nShim = {
  t<T=string>(name:string):any {
    console.log('i18n', name);
    return {
      'date.abbr_day_names': [],
      'date.day_names': [],
      'date.abbr_month_names': [
         'jan', 
         'feb', 
         'mar', 
         'apr', 
         'may', 
         'jun', 
         'jul', 
         'aug', 
         'sep', 
         'oct', 
         'nov', 
         'dec',
      ],
      'date.month_names': [
        'january',
        'february',
        'march',
        'april',
        'may',
        'june',
        'july',
        'august',
        'september',
        'october',
        'november',
        'december',
      ],
    }[name] || name as T;
  },
  lookup(name:string) {
    return { }[name] || name;
  },

  toNumber(num:number):string {
    return num.toString();
  },

  toPercentage(num:number):string {
    return num.toString();
  },

  toCurrency(num:number):string {
    return num.toString();
  },

  strftime(date:Date):string {
    return date.toISOString();
  },

  toHumanSize(num:number):string {
    return num.toString();
  },

  toTime(format:string, date:Date):string {
    return moment(date).format(format);
  },

  locale: 'en',
  firstDayOfWeek: 1,
  pluralization: {},
};

@Injectable({ providedIn: 'root' })
export class I18nServiceShim {
  private i18n:any = GlobalI18nShim;

  public get locale():string {
    return this.i18n.locale;
  }

  public t = this.i18n.t.bind(this.i18n) as GlobalI18n['t'];

  public lookup = this.i18n.lookup.bind(this.i18n) as GlobalI18n['lookup'];

  public toTime = this.i18n.toTime.bind(this.i18n) as GlobalI18n['toTime'];

  public toNumber = this.i18n.toNumber.bind(this.i18n) as GlobalI18n['toNumber'];

  public toPercentage = this.i18n.toPercentage.bind(this.i18n) as GlobalI18n['toPercentage'];

  public toCurrency = this.i18n.toCurrency.bind(this.i18n) as GlobalI18n['toCurrency'];

  public strftime = this.i18n.strftime.bind(this.i18n) as GlobalI18n['strftime'];

  public toHumanSize = this.i18n.toHumanSize.bind(this.i18n) as GlobalI18n['toHumanSize'];
}
