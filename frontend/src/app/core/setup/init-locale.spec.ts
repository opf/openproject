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

import moment from 'moment';
import {
  afterEach, describe, expect, it,
} from 'vitest';
import './init-moment-locales';
import { initializeLocale } from './init-locale';

describe('initializeLocale', () => {
  afterEach(() => {
    document.querySelector('meta[name="openproject_initializer"]')?.remove();
    moment.locale('en');
  });

  function setInitializer(locale:string) {
    const meta = document.createElement('meta');
    meta.name = 'openproject_initializer';
    meta.dataset.locale = locale;
    meta.dataset.defaultlocale = 'en';
    meta.dataset.instancelocale = locale;
    document.head.appendChild(meta);
  }

  it('uses the German week numbering rules', async () => {
    setInitializer('de');

    await initializeLocale();

    expect(moment('2020-12-31').format('ww')).toBe('53');
    expect(moment('2021-01-01').format('ww')).toBe('53');
    expect(moment('2021-01-04').format('ww')).toBe('01');
  });

  it('uses the English week numbering rules', async () => {
    setInitializer('en');

    await initializeLocale();

    expect(moment('2020-12-31').format('ww')).toBe('01');
    expect(moment('2021-01-01').format('ww')).toBe('01');
    expect(moment('2021-01-04').format('ww')).toBe('02');
  });
});
