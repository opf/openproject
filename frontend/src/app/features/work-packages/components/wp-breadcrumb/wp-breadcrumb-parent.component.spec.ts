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

import type { Mock } from 'vitest';
import { NO_ERRORS_SCHEMA } from '@angular/core';
import { ComponentFixture, TestBed } from '@angular/core/testing';
import { By } from '@angular/platform-browser';
import { fireEvent, screen } from '@testing-library/dom';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { WorkPackageRelationsHierarchyService } from 'core-app/features/work-packages/components/wp-relations/wp-relations-hierarchy/wp-relations-hierarchy.service';
import { WorkPackageNotificationService } from 'core-app/features/work-packages/services/notifications/work-package-notification.service';
import { OpTooltipDirective } from 'core-app/shared/components/primer/tooltip.directive';
import { WorkPackageBreadcrumbParentComponent } from './wp-breadcrumb-parent.component';

const translations:Record<string, string> = {
  'js.relation_buttons.change_parent': 'Change parent',
  'js.relation_buttons.remove_parent': 'Remove parent',
  'js.relation_buttons.set_parent': 'Set parent',
};

describe('WorkPackageBreadcrumbParentComponent', () => {
  let fixture:ComponentFixture<WorkPackageBreadcrumbParentComponent>;
  let changeParent:Mock<(workPackage:WorkPackageResource, parentId:string|null) => Promise<void>>;

  const parent = { id: '2', name: 'Parent package', displayId: '2', project: { identifier: 'demo' } };

  beforeEach(async () => {
    changeParent = vi.fn(() => Promise.resolve());
    await TestBed
      .configureTestingModule({
        imports: [OpTooltipDirective],
        declarations: [WorkPackageBreadcrumbParentComponent],
        schemas: [NO_ERRORS_SCHEMA],
        providers: [
          { provide: I18nService, useValue: { t: (key:string) => translations[key] ?? key } },
          { provide: PathHelperService, useValue: { genericWorkPackagePath: () => '/wp/2' } },
          { provide: WorkPackageRelationsHierarchyService, useValue: { changeParent } },
          { provide: WorkPackageNotificationService, useValue: {} },
        ],
      })
      .compileComponents();

    fixture = TestBed.createComponent(WorkPackageBreadcrumbParentComponent);
    showWorkPackage({ parent, changeParent: {} });
    await fixture.whenStable();
  });

  function showWorkPackage(workPackage:object) {
    fixture.componentRef.setInput('workPackage', workPackage);
    fixture.detectChanges();
  }

  afterEach(() => {
    fixture.destroy();
  });

  it('labels the icon-only parent buttons with tooltips', () => {
    expect(screen.getByRole('link', { name: 'Parent package' })).toBeInTheDocument();
    expect(screen.getByRole('button', { name: 'Change parent' })).toBeInTheDocument();
    expect(screen.getByRole('button', { name: 'Remove parent' })).toBeInTheDocument();
    expect(fixture.nativeElement.querySelectorAll('tool-tip')).toHaveLength(2);
  });

  it('names the set parent button by its text once the parent is gone', async () => {
    showWorkPackage({ changeParent: {} });
    await fixture.whenStable();

    expect(screen.getByRole('button', { name: 'Set parent' })).toBeInTheDocument();
    expect(screen.queryByRole('button', { name: 'Remove parent' })).not.toBeInTheDocument();
    expect(fixture.nativeElement.querySelectorAll('tool-tip')).toHaveLength(0);
  });

  it('removes the parent', () => {
    fireEvent.click(screen.getByRole('button', { name: 'Remove parent' }));

    expect(changeParent).toHaveBeenCalledExactlyOnceWith(fixture.componentInstance.workPackage, null);
  });

  function chooseInAutocomplete(choice:unknown) {
    fireEvent.click(screen.getByRole('button', { name: 'Change parent' }));
    fixture.detectChanges();
    fixture.debugElement.query(By.css('wp-relations-autocomplete')).triggerEventHandler('change', choice);
  }

  it('changes the parent to the chosen work package', () => {
    const chosen = Object.create(WorkPackageResource.prototype) as WorkPackageResource;
    chosen.$source = { id: 3, _links: {}, _embedded: {} };

    chooseInAutocomplete(chosen);

    expect(changeParent).toHaveBeenCalledExactlyOnceWith(fixture.componentInstance.workPackage, '3');
  });

  it('ignores a change event that carries no work package', () => {
    chooseInAutocomplete(new Event('change'));

    expect(changeParent).not.toHaveBeenCalled();
  });
});
