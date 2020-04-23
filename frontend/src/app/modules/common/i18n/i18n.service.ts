import {Injectable} from "@angular/core";

/**
 * General components
 */
export interface GlobalI18n {
  t(translateId:string, parameters?:any):string;

  lookup(translateId:string):boolean|undefined;

  toNumber(num:number, options?:ToNumberOptions):string;

  toPercentage(num:number, options?:ToPercentageOptions):string;

  toCurrency(num:number, options?:ToCurrencyOptions):string;

  strftime(date:Date, format:string):string;

  toHumanSize(num:number, options?:ToHumanSizeOptions):string;

  locale:string;
  firstDayOfWeek:number;

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
  private _i18n:GlobalI18n = (window as any).I18n;

  public get locale():string {
    return this._i18n.locale;
  }

  public t(translateId:string, parameters?:{ [key:string]:any }):string {
    return this._i18n.t(translateId, parameters);
  }

  public lookup(translateId:string):boolean|undefined {
    return this._i18n.lookup(translateId);
  }

  public toNumber = this._i18n.toNumber.bind(this._i18n);
  public toPercentage = this._i18n.toPercentage.bind(this._i18n);
  public toCurrency = this._i18n.toCurrency.bind(this._i18n);
  public strftime = this._i18n.strftime.bind(this._i18n);
  public toHumanSize = this._i18n.toHumanSize.bind(this._i18n);

}
