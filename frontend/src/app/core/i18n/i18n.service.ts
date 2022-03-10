import { Injectable } from '@angular/core';

/**
 * General components
 */
export interface GlobalI18n {
  t<T=string>(translateId:string, parameters?:unknown):T;

  lookup(translateId:string):boolean|undefined;

  toNumber(num:number, options?:ToNumberOptions):string;

  toPercentage(num:number, options?:ToPercentageOptions):string;

  toCurrency(num:number, options?:ToCurrencyOptions):string;

  strftime(date:Date, format:string):string;

  toHumanSize(num:number, options?:ToHumanSizeOptions):string;

  toTime(format:string, date:Date):string;

  locale:string;
  firstDayOfWeek:number;
  pluralization:any;
}

interface ToNumberOptions {
  precision?:number;
  separator?:string;
  delimiter?:string;
  strip_insignificant_zeros?:boolean;
}

type ToPercentageOptions = ToNumberOptions;

interface ToCurrencyOptions extends ToNumberOptions {
  format?:string;
  unit?:string;
  sign_first?:boolean;
}

interface ToHumanSizeOptions extends ToNumberOptions {
  format?:string;
}

@Injectable({ providedIn: 'root' })
export class I18nService {
  private i18n:GlobalI18n = window.I18n;

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
