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

import moment from 'moment';
import { I18n } from 'i18n-js';
import { getMetaElement } from './globals/global-helpers';

export function initializeLocale() {
  const meta = getMetaElement('openproject_initializer');
  const getInitializerValue = (key:string, defaultValue = '') => meta?.dataset[key] ?? defaultValue;
  const userLocale = getInitializerValue('locale', 'en');
  const defaultLocale = getInitializerValue('defaultlocale', 'en');
  const instanceLocale = getInitializerValue('instancelocale', 'en');
  const firstDayOfWeek = parseInt(getInitializerValue('firstdayofweek'), 10); // properties of meta.dataset are exposed in lowercase
  const firstWeekOfYear = parseInt(getInitializerValue('firstweekofyear'), 10); // properties of meta.dataset are exposed in lowercase

  const i18n = new I18n();
  i18n.locale = userLocale;
  i18n.defaultLocale = defaultLocale;

  window.I18n = i18n;

  moment.locale(userLocale);

  // Remove Postformatting numbers in dates, this will ensure we are always using
  // Arabic numbers in dates and durations, regardless of the chosen locale.
  // Using moment.locale() ensures locale like "zh-CN" falls back to "zh-cn"
  moment.updateLocale(moment.locale(), { postformat: (string:string) => string });

  if (!Number.isNaN(firstDayOfWeek) && !Number.isNaN(firstWeekOfYear)) {
    // ensure locale like "zh-CN" falls back to "zh-cn"
    moment.updateLocale(moment.locale(), {
      week: {
        dow: firstDayOfWeek,
        doy: 7 + firstDayOfWeek - firstWeekOfYear,
      },
    });
  }

  // Override the default pluralization function to allow
  // "other" to be used as a fallback for "one" in languages where one is not set
  // (japanese, for example)
  i18n.pluralization.register(
    'default',
    (_i18n:I18n, count:number) => {
      switch (count) {
        case 0:
          return ['zero', 'other'];
        case 1:
          return ['one', 'other'];
        default:
          return ['other'];
      }
    },
  );

  const localeImports = _
    .chain([userLocale, instanceLocale])
    .uniq()
    .map(
      (locale) => import(`../../../locales/${locale}.json`)
        .then((imported:{ default:object }) => {
          i18n.store(imported.default);
        }),
      )
    .value();
  return Promise.all(localeImports);
}
