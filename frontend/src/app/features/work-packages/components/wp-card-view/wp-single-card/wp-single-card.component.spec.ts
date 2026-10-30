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

import { CommonModule } from '@angular/common';
import { TestBed } from '@angular/core/testing';
import { buildWorkPackage } from '../../wp-fast-table/testing/work-package-fixture';
import { OpenprojectWorkPackagesModule } from 'core-app/features/work-packages/openproject-work-packages.module';
import { WorkPackageCardViewService } from '../services/wp-card-view.service';
import { FakeDragAndDropService, harnessProviders } from '../../wp-fast-table/testing/table-harness';
import { WorkPackageSingleCardComponent } from './wp-single-card.component';

describe('single card interactions', () => {
  beforeEach(async () => {
    vi.spyOn(OpenprojectWorkPackagesModule, 'bootstrapAttributeGroups').mockImplementation(() => undefined);
    TestBed.overrideModule(OpenprojectWorkPackagesModule, {
      set: { imports: [CommonModule], declarations: [WorkPackageSingleCardComponent], exports: [WorkPackageSingleCardComponent], providers: [], schemas: [] },
    });
    await TestBed.configureTestingModule({
      imports: [OpenprojectWorkPackagesModule],
      providers: [...harnessProviders(new FakeDragAndDropService(), { workPackages: [] }), WorkPackageCardViewService],
    }).compileComponents();
  });

  afterEach(() => vi.restoreAllMocks());

  function card(id:string|null) {
    const fixture = TestBed.createComponent(WorkPackageSingleCardComponent);
    const component = fixture.componentInstance;
    const wp = buildWorkPackage({ id: '42', subject: 'Card' });
    Object.defineProperty(wp, 'id', { value: id });
    Object.defineProperty(wp, 'status', { value: { id: '1', name: 'Open' } });
    Object.defineProperty(wp, 'type', { value: { id: '2', name: 'Task' } });
    Object.defineProperty(wp, 'priority', { value: { id: '3', name: 'Normal' } });
    component.workPackage = wp;
    component.showStatusButton = false;
    vi.spyOn(component, 'isNewResource').mockReturnValue(false);
    vi.spyOn(component, 'baselineIcon').mockReturnValue(null);
    vi.spyOn(component, 'fullWorkPackageLink').mockReturnValue('/work_packages/42');
    fixture.detectChanges();
    return { fixture, component, element: (fixture.nativeElement as HTMLElement).querySelector('.op-wp-single-card')! };
  }

  it.each(['click', 'dblclick', 'contextmenu', 'Enter', ' '])('does not emit %s without an identity', (type) => {
    const { component, element } = card(null);
    const emit = vi.fn();
    component.cardClicked.subscribe(emit);
    component.cardDblClicked.subscribe(emit);
    component.cardContextMenu.subscribe(emit);
    element.dispatchEvent(type === 'Enter' || type === ' '
      ? new KeyboardEvent('keydown', { key: type, bubbles: true })
      : new MouseEvent(type, { bubbles: true }));
    expect(emit).not.toHaveBeenCalled();
  });

  it('preserves the original click event and modifiers', () => {
    const { component, element } = card('42');
    const emit = vi.fn();
    component.cardClicked.subscribe(emit);
    const event = new MouseEvent('click', { bubbles: true, ctrlKey: true, shiftKey: true, metaKey: true });
    element.dispatchEvent(event);
    expect(emit).toHaveBeenCalledWith({ workPackageId: '42', event });
  });

  it.each(['Enter', ' '])('activates on a plain %j key press', (key) => {
    const { component, element } = card('42');
    const emit = vi.fn();
    component.cardClicked.subscribe(emit);
    const event = new KeyboardEvent('keydown', { key, bubbles: true });
    element.dispatchEvent(event);
    expect(emit).toHaveBeenCalledWith({ workPackageId: '42', event });
  });

  it.each([
    ['Enter', 'altKey'], ['Enter', 'ctrlKey'], ['Enter', 'shiftKey'], ['Enter', 'metaKey'],
    [' ', 'altKey'], [' ', 'ctrlKey'], [' ', 'shiftKey'], [' ', 'metaKey'],
  ])('ignores %j with %s held', (key, modifier) => {
    const { component, element } = card('42');
    const emit = vi.fn();
    component.cardClicked.subscribe(emit);
    element.dispatchEvent(new KeyboardEvent('keydown', { key, bubbles: true, [modifier]: true }));
    expect(emit).not.toHaveBeenCalled();
  });

  it.each(['dblclick', 'contextmenu'])('preserves the pointer event for %s', (type) => {
    const { component, element } = card('42');
    const emit = vi.fn();
    const output = type === 'dblclick' ? component.cardDblClicked : component.cardContextMenu;
    output.subscribe(emit);
    const event = new MouseEvent(type, { bubbles: true, ctrlKey: true, button: 2 });
    element.dispatchEvent(event);
    expect(emit).toHaveBeenCalledWith({ workPackageId: '42', event });
  });

  it('ignores unrelated keyboard keys', () => {
    const { component, element } = card('42');
    const emit = vi.fn();
    component.cardClicked.subscribe(emit);
    element.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape', bubbles: true }));
    expect(emit).not.toHaveBeenCalled();
  });

  it.each(['status', 'priority', 'type', 'inline', 'none'] as const)('renders %s highlighting', (mode) => {
    const { fixture, element } = card('42');
    fixture.componentRef.setInput('highlightingMode', mode);
    fixture.detectChanges();
    const highlighting = element.querySelector('.op-wp-single-card--highlighting')!;
    expect(highlighting.className).toBe(`op-wp-single-card--highlighting${
      ({ status: ' __hl_background __hl_status_1', priority: ' __hl_background __hl_priority_3', type: ' __hl_background __hl_type_2', inline: '', none: '' })[mode]
    }`);
  });
});
