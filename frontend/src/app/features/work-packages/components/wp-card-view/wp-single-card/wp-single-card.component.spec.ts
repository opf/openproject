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
import { ChangeDetectorRef } from '@angular/core';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { WorkPackageViewSelectionService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-selection.service';
import { WorkPackageViewSelectionGesturesService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-selection-gestures.service';
import { WorkPackageViewFocusService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-focus.service';
import { WorkPackageCardViewService } from 'core-app/features/work-packages/components/wp-card-view/services/wp-card-view.service';
import { TimezoneService } from 'core-app/core/datetime/timezone.service';
import { SchemaCacheService } from 'core-app/core/schemas/schema-cache.service';
import { KeepTabService } from 'core-app/features/work-packages/components/wp-single-view-tabs/keep-tab/keep-tab.service';
import { UrlParamsService } from 'core-app/core/navigation/url-params.service';
import { WorkPackageSingleCardComponent } from './wp-single-card.component';

describe('WorkPackageSingleCardComponent', () => {
  let card:WorkPackageSingleCardComponent;
  let activated:string[];

  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [
        ...[
          PathHelperService,
          WorkPackageViewSelectionService,
          WorkPackageViewSelectionGesturesService,
          WorkPackageViewFocusService,
          WorkPackageCardViewService,
          TimezoneService,
          SchemaCacheService,
          KeepTabService,
          UrlParamsService,
          ChangeDetectorRef,
        ].map((provide) => ({ provide, useValue: {} })),
        { provide: I18nService, useValue: { t: (key:string) => key } },
      ],
    });
    card = TestBed.runInInjectionContext(() => new WorkPackageSingleCardComponent());
    card.workPackage = { id: '42' } as WorkPackageResource;
    activated = [];
    card.cardClicked.subscribe(({ workPackageId }) => activated.push(workPackageId));
    document.body.innerHTML = `
      <div class="op-wp-single-card">
        <span>Subject</span>
        <button type="button" aria-disabled="true"><span>Status</span></button>
      </div>
    `;
  });

  afterEach(() => {
    document.body.innerHTML = '';
  });

  const eventOn = (selector:string) => {
    const event = new KeyboardEvent('keydown', { key: 'Enter' });
    Object.defineProperty(event, 'target', { value: document.querySelector(selector) });
    return event;
  };

  it('activates the card from its surface', () => {
    card.activateCard(eventOn('.op-wp-single-card > span'));

    expect(activated).toEqual(['42']);
  });

  it('ignores activation from a disabled control on the card', () => {
    card.activateCard(eventOn('button[aria-disabled] span'));

    expect(activated).toEqual([]);
  });
});
