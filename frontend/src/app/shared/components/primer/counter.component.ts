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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

/* eslint-disable @angular-eslint/component-selector, @angular-eslint/no-input-rename */

import { ChangeDetectionStrategy, Component, computed, inject, input } from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';

type Scheme = 'default' | 'primary' | 'secondary';

// Angular port of Primer::Beta::Counter, used to add a count to navigational
// elements. The `text` and `round` options of the Ruby component are not
// supported.
@Component({
  selector: 'primer-counter',
  templateUrl: './counter.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  standalone: true,
})
export class PrimerCounterComponent {
  private readonly I18n = inject(I18nService);

  // The number to be displayed (e.g. # of issues, pull requests).
  readonly count = input<number | null>(0);

  // Color scheme. One of default | primary | secondary.
  readonly scheme = input<Scheme>('default');

  // Maximum value to display. Pass `null` for no limit. When `count` exceeds
  // `limit`, the value is rendered as e.g. "5,000+".
  readonly limit = input<number | null>(5_000);

  // When true, a `hidden` attribute is added to the counter if `count` is zero.
  readonly hideIfZero = input(false, { alias: 'hide-if-zero' });

  // Displayed text: "" when no value (CSS hides it), "∞" for infinity,
  // otherwise the delimited count.
  readonly value = computed(() => {
    const count = this.count();
    if (count === null || count === undefined) {
      return ''; // CSS will hide it
    }
    if (count === Infinity || count === -Infinity) {
      return '∞';
    }
    if (Number.isNaN(count)) {
      return '';
    }
    return this.displayNumber(count);
  });

  // Title attribute, mirroring the displayed count (including limit capping) as a tooltip.
  readonly titleText = computed(() => {
    const count = this.count();
    if (count === null || count === undefined) {
      return this.I18n.t('js.label_not_available');
    }
    if (count === Infinity || count === -Infinity) {
      return this.I18n.t('js.label_infinity');
    }
    if (Number.isNaN(count)) {
      return this.I18n.t('js.label_not_available');
    }
    return this.displayNumber(count);
  });

  readonly hidden = computed(() => this.count() === 0 && this.hideIfZero());

  private displayNumber(count:number):string {
    const value = Math.trunc(count);
    const limit = this.limit();
    const capped = limit === null ? value : Math.min(value, limit);
    const formatter = new Intl.NumberFormat(this.I18n.locale, {
      maximumFractionDigits: 0,
      useGrouping: true,
    });
    const str = formatter.format(capped);

    return limit !== null && value > limit ? `${str}+` : str;
  }
}
