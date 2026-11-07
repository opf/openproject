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

import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { TestBed } from '@angular/core/testing';
import { within } from '@testing-library/dom';
import { WorkPackageTableIdCellComponent } from './wp-table-id-cell.component';
import { FakeDragAndDropService, harnessProviders } from '../testing/table-harness';
import { buildWorkPackage } from '../testing/work-package-fixture';

describe('template ID cell', () => {
  beforeEach(() => TestBed.configureTestingModule({
    providers: [
      ...harnessProviders(new FakeDragAndDropService(), { workPackages: [] }),
      { provide: PathHelperService, useValue: { genericWorkPackagePath: (_project:string, id:string, tab:string) => `/work_packages/${id}/${tab}` } },
    ],
  }));

  it('keeps the ID link while updating its text, URL and numeric identity', () => {
    const fixture = TestBed.createComponent(WorkPackageTableIdCellComponent);
    const root = fixture.nativeElement as HTMLElement;
    fixture.componentRef.setInput('row', { workPackage: Object.assign(buildWorkPackage({ id: '42' }), { displayId: 'DEMO-7' }), revision: 0 });
    fixture.detectChanges();
    const link = within(root).getByRole('link', { name: 'DEMO-7' });
    expect(link).toHaveAttribute('href', `/work_packages/DEMO-7/activity${window.location.search}`);
    expect(link).toHaveAttribute('data-work-package-id', '42');
    expect(link).toHaveAttribute('data-wp-state', 'show');
    expect(link).toHaveAttribute('tabindex', '-1');
    expect(root).toHaveAttribute('data-row-header-name', 'DEMO-7');
    expect(root.querySelector('.inline-edit--display-field')).toHaveClass('-read-only');

    fixture.componentRef.setInput('row', { workPackage: Object.assign(buildWorkPackage({ id: '43' }), { displayId: 'DEMO-8' }), revision: 1 });
    fixture.detectChanges();
    expect(within(root).getByRole('link', { name: 'DEMO-8' })).toBe(link);
    expect(link).toHaveAttribute('data-work-package-id', '43');
    expect(root).toHaveAttribute('data-row-header-name', 'DEMO-8');
  });

  it('refreshes the same mutated resource when the row revision changes', () => {
    const fixture = TestBed.createComponent(WorkPackageTableIdCellComponent);
    const workPackage = Object.assign(buildWorkPackage({ id: '42' }), { displayId: 'DEMO-7' });
    fixture.componentRef.setInput('row', { workPackage, revision: 0 });
    fixture.detectChanges();
    workPackage.displayId = 'DEMO-8';
    fixture.componentRef.setInput('row', { workPackage, revision: 1 });
    fixture.detectChanges();
    expect(within(fixture.nativeElement as HTMLElement).getByRole('link', { name: 'DEMO-8' })).toBeTruthy();
  });

  it('falls back to a numeric ID and leaves new resources without a link', () => {
    const fixture = TestBed.createComponent(WorkPackageTableIdCellComponent);
    fixture.componentRef.setInput('row', { workPackage: buildWorkPackage({ id: '42' }), revision: 0 });
    fixture.detectChanges();
    expect(within(fixture.nativeElement as HTMLElement).getByRole('link', { name: '42' })).toBeTruthy();
    fixture.componentRef.setInput('row', { workPackage: buildWorkPackage({ id: 'new' }), revision: 1 });
    fixture.detectChanges();
    expect(within(fixture.nativeElement as HTMLElement).queryByRole('link')).toBeNull();
    expect(fixture.nativeElement as HTMLElement).toHaveAttribute('data-row-header-name', '');
  });
});
