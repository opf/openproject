import { Injectable } from '@angular/core';
import { I18n } from 'i18n-js';
import { FormatNumberOptions, TranslateOptions } from 'i18n-js/src/typing';

@Injectable({ providedIn: 'root' })
export class I18nService {
  private i18n:I18n = window.I18n;

  public get locale():string {
    return this.i18n.locale;
  }

  public t<T = string>(input:string, options:Partial<TranslateOptions> = {}) {
    return this.i18n.t<T>(input, options);
  }

  public toTime = this.i18n.toTime.bind(this.i18n);

  public toNumber(val:string|number, options:Partial<FormatNumberOptions>):string {
    return this.i18n.localize('number', val, options);
  }
}
