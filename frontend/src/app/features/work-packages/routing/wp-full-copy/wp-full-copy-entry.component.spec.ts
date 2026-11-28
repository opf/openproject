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
import { WorkPackageFullCopyEntryComponent } from 'core-app/features/work-packages/routing/wp-full-copy/wp-full-copy-entry.component';
import { defineTestCustomElement } from 'core-app/shared/helpers/angular/custom-element.spec-helper';

describe('WorkPackageFullCopyEntryComponent as a custom element', () => {
  beforeEach(async () => {
    TestBed.overrideComponent(WorkPackageFullCopyEntryComponent, {
      set: { template: '<span class="out">{{ type() }}|{{ copiedFromWorkPackageId() }}|{{ parentId() ?? "none" }}|{{ projectIdentifier() ?? "none" }}</span>' },
    });
    await TestBed.configureTestingModule({ declarations: [WorkPackageFullCopyEntryComponent] }).compileComponents();
  });

  it('reads the inputs from the attributes', async () => {
    const custom = await defineTestCustomElement(WorkPackageFullCopyEntryComponent, { type: '3', 'copied-from-work-package-id': '7', 'parent-id': '9', 'project-identifier': 'demo' });

    expect(custom.element.querySelector('.out')).toHaveTextContent('3|7|9|demo');
  });

  it('leaves absent optional inputs undefined', async () => {
    const custom = await defineTestCustomElement(WorkPackageFullCopyEntryComponent, { type: '3', 'copied-from-work-package-id': '7' });

    expect(custom.element.querySelector('.out')).toHaveTextContent('3|7|none|none');
  });
});
