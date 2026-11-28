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
import { EMPTY } from 'rxjs';
import { InAppNotificationBellComponent } from 'core-app/features/in-app-notifications/bell/in-app-notification-bell.component';
import { IanBellService } from 'core-app/features/in-app-notifications/bell/state/ian-bell.service';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { ActiveWindowService } from 'core-app/core/active-window/active-window.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { AppBadgeService } from 'core-app/features/in-app-notifications/bell/app-badge.service';
import { defineTestCustomElement } from 'core-app/shared/helpers/angular/custom-element.spec-helper';

describe('InAppNotificationBellComponent as a custom element', () => {
  beforeEach(async () => {
    TestBed.overrideComponent(InAppNotificationBellComponent, {
      set: { template: '<span class="interval">{{ interval() }}</span>', templateUrl: undefined, styleUrls: [] },
    });
    await TestBed.configureTestingModule({
      declarations: [InAppNotificationBellComponent],
      providers: [
        { provide: IanBellService, useValue: { unread$: EMPTY, fetchUnread: () => EMPTY } },
        { provide: ApiV3Service, useValue: {} },
        { provide: ActiveWindowService, useValue: { isActive: true } },
        { provide: PathHelperService, useValue: {} },
        { provide: AppBadgeService, useValue: { hiddenPollingFactor: 2 } },
      ],
    }).compileComponents();
  });

  it('reads the polling interval from the attribute', async () => {
    const custom = await defineTestCustomElement(InAppNotificationBellComponent, { interval: '30000' });

    expect(custom.element.querySelector('.interval')).toHaveTextContent('30000');
  });

  it('falls back to the default interval', async () => {
    const custom = await defineTestCustomElement(InAppNotificationBellComponent, {});

    expect(custom.element.querySelector('.interval')).toHaveTextContent('50000');
  });
});
