//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) the OpenProject GmbH
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { Injectable, inject } from '@angular/core';
import { NgSelectConfig } from '@ng-select/ng-select';
import { I18n } from 'i18n-js';
import { FormatNumberOptions, TranslateOptions } from 'i18n-js/src/typing';
import { getMetaValue } from '../setup/globals/global-helpers';

@Injectable({ providedIn: 'root' })
export class I18nService {
  private config = inject(NgSelectConfig);

  private i18n:I18n = window.I18n;
  private instanceLocale:string;

  constructor() {
    this.instanceLocale = getMetaValue('openproject_initializer', 'instanceLocale', 'en');

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
