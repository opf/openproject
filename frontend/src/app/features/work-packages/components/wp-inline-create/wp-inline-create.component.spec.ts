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

import { Component, NO_ERRORS_SCHEMA } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { createEvent, fireEvent, screen } from '@testing-library/dom';
import { EMPTY, of, Subject } from 'rxjs';
import { AuthorisationService } from 'core-app/core/model-auth/model-auth.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { SchemaCacheService } from 'core-app/core/schemas/schema-cache.service';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { WorkPackageViewColumnsService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-columns.service';
import { WorkPackageViewFocusService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-focus.service';
import { HalResourceEditingService } from 'core-app/shared/components/fields/edit/services/hal-resource-editing.service';
import { WorkPackageCreateService } from '../wp-new/wp-create.service';
import { WorkPackageTable } from '../wp-fast-table/wp-fast-table';
import { inlineCreateCancelClassName } from './inline-create-row-builder';
import { WorkPackageInlineCreateComponent } from './wp-inline-create.component';
import { WorkPackageInlineCreateService } from './wp-inline-create.service';

@Component({
  template: '',
  standalone: false,
})
class ReferenceStubComponent {}

describe('WorkPackageInlineCreateComponent', () => {
  const mount = () => {
    TestBed.configureTestingModule({
      declarations: [WorkPackageInlineCreateComponent, ReferenceStubComponent],
      schemas: [NO_ERRORS_SCHEMA],
      providers: [
        {
          provide: WorkPackageInlineCreateService,
          useValue: {
            canAdd: of(true),
            canReference: of(true),
            referenceComponentClass: ReferenceStubComponent,
            buttonTexts: { create: 'Create new child', reference: 'Add existing' },
            newInlineWorkPackageCreated: new Subject<string>(),
          },
        },
        { provide: WorkPackageCreateService, useValue: { onNewWorkPackage: () => EMPTY } },
        { provide: WorkPackageViewColumnsService, useValue: { updates$: () => EMPTY } },
        { provide: WorkPackageViewFocusService, useValue: {} },
        { provide: HalResourceEditingService, useValue: {} },
        { provide: AuthorisationService, useValue: {} },
        { provide: SchemaCacheService, useValue: {} },
        { provide: IsolatedQuerySpace, useValue: {} },
        { provide: I18nService, useValue: { t: (key:string) => key } },
      ],
    });

    const fixture = TestBed.createComponent(WorkPackageInlineCreateComponent);
    fixture.componentInstance.table = { configuration: {}, reconcileSection: () => undefined } as unknown as WorkPackageTable;
    fixture.componentInstance.colspan = 3;
    fixture.detectChanges();
    return fixture;
  };

  afterEach(() => TestBed.resetTestingModule());

  it('names the create and reference triggers by their own texts', () => {
    mount();

    expect(screen.getByRole('button', { name: 'Create new child' })).toBeInTheDocument();
    expect(screen.getByRole('button', { name: 'Add existing' })).toBeInTheDocument();
  });

  it.each(['click', 'Enter'])('cancels inline creation without navigation on %s of a Cancel link', (gesture) => {
    const fixture = mount();
    const resetRow = vi.spyOn(fixture.componentInstance, 'resetRow').mockImplementation(() => undefined);
    const cancelLink = document.createElement('a');
    cancelLink.href = '#';
    cancelLink.className = inlineCreateCancelClassName;
    cancelLink.setAttribute('aria-label', 'Cancel');
    (fixture.nativeElement as HTMLElement).append(cancelLink);

    const preventVisit = vi.fn((event:Event) => event.preventDefault());
    document.addEventListener('turbo:before-visit', preventVisit);
    const link = screen.getByRole('link', { name: 'Cancel' });
    const activation = gesture === 'click'
      ? createEvent.click(link)
      : createEvent.keyDown(link, { key: 'Enter' });

    try {
      fireEvent(link, activation);

      expect(resetRow).toHaveBeenCalledOnce();
      expect(activation.defaultPrevented).toBe(true);
      expect(preventVisit).not.toHaveBeenCalled();
    } finally {
      document.removeEventListener('turbo:before-visit', preventVisit);
    }
  });
});
