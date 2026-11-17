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
import { fireEvent } from '@testing-library/dom';
import { CommonModule } from '@angular/common';
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
import { buildWorkPackage } from '../../wp-fast-table/testing/work-package-fixture';
import { OpenprojectWorkPackagesModule } from 'core-app/features/work-packages/openproject-work-packages.module';
import { FakeDragAndDropService, harnessProviders } from '../../wp-fast-table/testing/table-harness';
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
    const wp = buildWorkPackage({
      id: '42',
      subject: 'Card',
      attributes: {
        status: { id: '1', name: 'Open' },
        type: { id: '2', name: 'Task' },
        priority: { id: '3', name: 'Normal' },
      },
    });
    Object.defineProperty(wp, 'id', { value: id });
    fixture.componentRef.setInput('workPackage', wp);
    fixture.componentRef.setInput('showStatusButton', false);
    vi.spyOn(component, 'isNewResource').mockReturnValue(false);
    vi.spyOn(component, 'baselineIcon').mockReturnValue(null);
    vi.spyOn(component, 'fullWorkPackageLink').mockReturnValue('/work_packages/42');
    fixture.detectChanges();
    return { fixture, component, element: (fixture.nativeElement as HTMLElement).querySelector('.op-wp-single-card')! };
  }

  it.each([
    ['click', (element:Element) => fireEvent.click(element)],
    ['dblclick', (element:Element) => fireEvent.dblClick(element)],
    ['contextmenu', (element:Element) => fireEvent.contextMenu(element)],
    ['Enter', (element:Element) => fireEvent.keyDown(element, { key: 'Enter' })],
    [' ', (element:Element) => fireEvent.keyDown(element, { key: ' ' })],
  ])('does not emit %s without an identity', (_type, fire) => {
    const { component, element } = card(null);
    const emit = vi.fn();
    component.cardClicked.subscribe(emit);
    component.cardDblClicked.subscribe(emit);
    component.cardContextMenu.subscribe(emit);

    fire(element);

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

    fireEvent.keyDown(element, { key, [modifier]: true });

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

    fireEvent.keyDown(element, { key: 'Escape' });

    expect(emit).not.toHaveBeenCalled();
  });

  it.each([
    ['status', 'op-wp-single-card--highlighting __hl_background __hl_status_1'],
    ['priority', 'op-wp-single-card--highlighting __hl_background __hl_priority_3'],
    ['type', 'op-wp-single-card--highlighting __hl_background __hl_type_2'],
    ['inline', 'op-wp-single-card--highlighting'],
    ['none', 'op-wp-single-card--highlighting'],
  ] as const)('renders %s highlighting', (mode, classes) => {
    const { fixture, element } = card('42');

    fixture.componentRef.setInput('highlightingMode', mode);
    fixture.detectChanges();

    expect(element.querySelector('.op-wp-single-card--highlighting')).toHaveClass(classes, { exact: true });
  });
});
