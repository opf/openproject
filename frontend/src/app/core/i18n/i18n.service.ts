import { Injectable } from '@angular/core';
import { NgSelectConfig } from '@ng-select/ng-select';
import { I18n } from 'i18n-js';
import { FormatNumberOptions, TranslateOptions } from 'i18n-js/src/typing';

@Injectable({ providedIn: 'root' })
export class I18nService {
  private i18n:I18n = window.I18n;

  constructor(
    private config:NgSelectConfig,
  ) {
    this.config.addTagText = this.t('autocomplete_ng_select.add_tag');
    this.config.clearAllText = this.t('autocomplete_ng_select.clear_all');
    this.config.loadingText = this.t('autocomplete_ng_select.loading');
    this.config.notFoundText = this.t('autocomplete_ng_select.not_found');
    this.config.typeToSearchText = this.t('autocomplete_ng_select.type_to_search');
  }

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
