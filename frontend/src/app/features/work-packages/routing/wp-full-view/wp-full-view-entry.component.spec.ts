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
import { WorkPackageFullViewEntryComponent } from 'core-app/features/work-packages/routing/wp-full-view/wp-full-view-entry.component';
import { defineTestCustomElement } from 'core-app/shared/helpers/angular/custom-element.spec-helper';

describe('WorkPackageFullViewEntryComponent as a custom element', () => {
  beforeEach(async () => {
    TestBed.overrideComponent(WorkPackageFullViewEntryComponent, {
      set: { template: '<span class="out">{{ workPackageId() }}|{{ activeTab() }}</span>' },
    });
    await TestBed.configureTestingModule({ declarations: [WorkPackageFullViewEntryComponent] }).compileComponents();
  });

  it('reads the inputs from the attributes', async () => {
    const custom = await defineTestCustomElement(WorkPackageFullViewEntryComponent, { 'work-package-id': '12', 'active-tab': 'activity' });

    expect(custom.element.querySelector('.out')).toHaveTextContent('12|activity');
  });

  it('defaults absent inputs to empty strings', async () => {
    const custom = await defineTestCustomElement(WorkPackageFullViewEntryComponent, { 'work-package-id': '12' });

    expect(custom.element.querySelector('.out')).toHaveTextContent('12|');
  });
});
