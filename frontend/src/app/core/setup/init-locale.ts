// -- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2021 the OpenProject GmbH
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

import * as moment from 'moment';

export function initializeLocale() {
  const meta = document.querySelector('meta[name=openproject_initializer]') as HTMLMetaElement;
  const locale = meta.dataset.locale || 'en';
  const firstDayOfWeek = parseInt(meta.dataset.firstDayOfWeek || '', 10);
  const firstWeekOfYear = parseInt(meta.dataset.firstWeekOfYear || '', 10);

  I18n.locale = locale;

  if (!Number.isNaN(firstDayOfWeek) && !Number.isNaN(firstWeekOfYear)) {
    I18n.firstDayOfWeek = firstDayOfWeek;
    moment.updateLocale(locale, {
      week: {
        dow: firstDayOfWeek,
        doy: 7 + firstDayOfWeek - firstWeekOfYear,
      },
    });
  }

  // Override the default pluralization function to allow
  // "other" to be used as a fallback for "one" in languages where one is not set
  // (japanese, for example)
  I18n.pluralization.default = function (count:number) {
    switch (count) {
      case 0:
        return ['zero', 'other'];
      case 1:
        return ['one', 'other'];
      default:
        return ['other'];
    }
  };

  return import(/* webpackChunkName: "locale" */ `../../../locales/${I18n.locale}.js`);
}
