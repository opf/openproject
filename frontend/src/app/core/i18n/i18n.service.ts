import { Injectable } from '@angular/core';
import { NgSelectConfig } from '@ng-select/ng-select';
import { I18n } from 'i18n-js';
import { FormatNumberOptions, TranslateOptions } from 'i18n-js/src/typing';

@Injectable({ providedIn: 'root' })
export class I18nService {
  private i18n:I18n = window.I18n;
  private instanceLocale:string;

  constructor(
    private config:NgSelectConfig,
  ) {
    const meta = document.querySelector<HTMLMetaElement>('meta[name=openproject_initializer]');
    this.instanceLocale = meta?.dataset.instancelocale || 'en';

    this.config.addTagText = this.t('js.autocomplete_ng_select.add_tag');
    this.config.clearAllText = this.t('js.autocomplete_ng_select.clear_all');
    this.config.loadingText = this.t('js.autocomplete_ng_select.loading');
    this.config.notFoundText = this.t('js.autocomplete_ng_select.not_found');
    this.config.typeToSearchText = this.t('js.autocomplete_ng_select.type_to_search');
  }

  public get locale():string {
    return this.i18n.locale;
  }

  public t<T = string>(input:string, options:Partial<TranslateOptions> = {}) {
    return this.i18n.t<T>(input, options);
  }

  public instance_locale_translate<T = string>(input:string, options:Partial<TranslateOptions> = {}) {
    const locale = this.i18n.locale;
    try {
      this.i18n.locale = this.instanceLocale;
      return this.t<T>(input, options);
    } finally {
      this.i18n.locale = locale;
    }
  }

  public toTime = this.i18n.toTime.bind(this.i18n);

  public toNumber(val:string|number, options:Partial<FormatNumberOptions>):string {
    return this.i18n.localize('number', val, options);
  }
}
