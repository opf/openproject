import {Injectable} from "@angular/core";

/**
 * General components
 */
export interface GlobalI18n {
  t(translateId:string, parameters?:any):string;
  lookup(translateId:string):boolean | undefined;
  locale:string;
  firstDayOfWeek:number;
}

@Injectable()
export class I18nService {
  private _i18n:GlobalI18n;

  constructor() {
    this._i18n = (window as any).I18n;
  }

  public get locale():string {
    return this._i18n.locale;
  }

  public t(translateId:string, parameters?:{ [key:string]:any }):string {
    return this._i18n.t(translateId, parameters);
  }

  public lookup(translateId:string):boolean|undefined {
    return this._i18n.lookup(translateId);
  }

}
