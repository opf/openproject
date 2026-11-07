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

import { page } from 'vitest/browser';
import { Injector } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { fireEvent, within } from '@testing-library/dom';
import { OpDetailsTableAction } from '../../wp-table/table-actions/actions/details-table-action';
import { OpUnlinkTableAction } from '../../wp-table/table-actions/actions/unlink-table-action';
import { WorkPackageTableActionComponent } from './wp-table-action.component';
import { buildWorkPackage } from '../testing/work-package-fixture';
import { FakeDragAndDropService, harnessProviders } from '../testing/table-harness';

describe('template table actions', () => {
  beforeEach(async () => {
    await page.viewport(1280, 900);
    TestBed.configureTestingModule({
    providers: harnessProviders(new FakeDragAndDropService(), { workPackages: [], translations: { 'js.button_open_details': 'Open details' } }),
    });
  });

  it('updates a details link in place with the semantic URL and numeric identity', () => {
    const injector = TestBed.inject(Injector);
    const fixture = TestBed.createComponent(WorkPackageTableActionComponent);
    const first = Object.assign(buildWorkPackage({ id: '42' }), { displayId: 'PROJ-7' });
    fixture.componentRef.setInput('opWpTableAction', new OpDetailsTableAction(injector, first));
    document.body.appendChild(fixture.nativeElement as HTMLElement);
    fixture.detectChanges();
    const link = within(fixture.nativeElement as HTMLElement).getByRole('link', { name: 'Open details' });
    expect(link).toHaveAttribute('href', `/details/PROJ-7/overview${window.location.search}`);
    expect(link).toHaveAttribute('data-work-package-id', '42');
    expect(link).toHaveAttribute('data-wp-state', 'split');
    expect(link).toHaveAttribute('tabindex', '-1');
    const second = Object.assign(buildWorkPackage({ id: '43' }), { displayId: 'PROJ-8' });
    fixture.componentRef.setInput('opWpTableAction', new OpDetailsTableAction(injector, second));
    fixture.detectChanges();
    expect(within(fixture.nativeElement as HTMLElement).getByRole('link', { name: 'Open details' })).toBe(link);
    expect(link).toHaveAttribute('href', `/details/PROJ-8/overview${window.location.search}`);
    (fixture.nativeElement as HTMLElement).remove();
  });

  it('keeps unlink applicable, destructive, and bound to the refreshed resource', () => {
    const injector = TestBed.inject(Injector);
    const fixture = TestBed.createComponent(WorkPackageTableActionComponent);
    const removed:string[] = [];
    const action = (id:string, applicable = true) => new OpUnlinkTableAction(injector, buildWorkPackage({ id }), 'remove', 'Remove', () => applicable, (wp) => removed.push(wp.id!));
    fixture.componentRef.setInput('opWpTableAction', action('1'));
    document.body.appendChild(fixture.nativeElement as HTMLElement);
    fixture.detectChanges();
    const link = within(fixture.nativeElement as HTMLElement).getByRole('link', { name: 'Remove' });
    expect(link).toHaveAttribute('data-wp-table-destructive');
    expect(link).toHaveAttribute('tabindex', '-1');
    fixture.componentRef.setInput('opWpTableAction', action('2'));
    fixture.detectChanges();
    expect(within(fixture.nativeElement as HTMLElement).getByRole('link', { name: 'Remove' })).toBe(link);
    fireEvent.click(link);
    expect(removed).toEqual(['2']);
    fixture.componentRef.setInput('opWpTableAction', action('2', false));
    fixture.detectChanges();
    expect(within(fixture.nativeElement as HTMLElement).queryByRole('link')).toBeNull();
    (fixture.nativeElement as HTMLElement).remove();
  });
});
