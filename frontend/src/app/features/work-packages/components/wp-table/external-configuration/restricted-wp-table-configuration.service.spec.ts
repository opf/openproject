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
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { TestBed } from '@angular/core/testing';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { RestrictedWpTableConfigurationService } from 'core-app/features/work-packages/components/wp-table/external-configuration/restricted-wp-table-configuration.service';
import { OpQueryConfigurationLocalsToken } from 'core-app/features/work-packages/components/wp-table/external-configuration/external-query-configuration.constants';
import { QueryConfigurationLocals } from 'core-app/features/work-packages/components/wp-table/external-configuration/external-query-configuration.component';

describe('RestrictedWpTableConfigurationService', () => {
  const disabledTabs = { 'display-settings': 'Not available', timelines: 'Not available' };

  function tabsFor(locals:Partial<QueryConfigurationLocals>) {
    TestBed.configureTestingModule({
      providers: [
        RestrictedWpTableConfigurationService,
        { provide: I18nService, useValue: { t: (key:string) => key } },
        { provide: OpQueryConfigurationLocalsToken, useValue: locals },
      ],
    });

    return TestBed.inject(RestrictedWpTableConfigurationService).tabs;
  }

  it('marks unavailable tabs as disabled with their reason', () => {
    const tabs = tabsFor({ disabledTabs });

    expect(tabs.find((tab) => tab.id === 'display-settings')?.disable).toBe('Not available');
    expect(tabs.find((tab) => tab.id === 'timelines')?.disable).toBe('Not available');
    expect(tabs.find((tab) => tab.id === 'columns')?.disable).toBeUndefined();
  });

  it('omits unavailable tabs when asked to hide them', () => {
    const ids = tabsFor({ disabledTabs, hideDisabledTabs: true }).map((tab) => tab.id);

    expect(ids).not.toContain('display-settings');
    expect(ids).not.toContain('timelines');
    expect(ids).toEqual(expect.arrayContaining(['columns', 'filters']));
  });
});
