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
import '@openproject/primer-view-components/app/components/primer/alpha/action_menu/action_menu_element.js';
import '@openproject/primer-view-components/app/components/primer/alpha/tool_tip.js';
import { fireEvent, screen, waitFor, within } from '@testing-library/dom';
import { userEvent } from 'vitest/browser';
import { of } from 'rxjs';
import { CommonModule } from '@angular/common';
import { ChangeDetectorRef, CUSTOM_ELEMENTS_SCHEMA } from '@angular/core';
import { settlePopover } from 'core-common/testing/timing';
import { HalResourceEditingService } from 'core-app/shared/components/fields/edit/services/hal-resource-editing.service';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';
import { WorkPackageNotificationService } from 'core-app/features/work-packages/services/notifications/work-package-notification.service';
import { OpTooltipDirective } from 'core-app/shared/components/primer/tooltip.directive';
import { OpActionMenuComponent } from 'core-app/shared/components/op-context-menu/action-menu/op-action-menu.component';
import { OpActionMenuTriggerDirective } from 'core-app/shared/components/op-context-menu/action-menu/op-action-menu-trigger.directive';
import { WorkPackageStatusDropdownDirective } from 'core-app/shared/components/op-context-menu/handlers/wp-status-dropdown-menu.directive';
import { WorkPackageStatusButtonComponent } from 'core-app/features/work-packages/components/wp-buttons/wp-status-button/wp-status-button.component';
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

describe('status menu inside a single card', () => {
  let card:WorkPackageSingleCardComponent;
  let cardClicked:string[];
  let projectedResource:{ status?:unknown };

  beforeEach(async () => {
    projectedResource = {};
    const statusSchema = { isReadonly: false, isEditable: true, isAttributeEditable: () => true };
    const workPackage = buildWorkPackage({
      id: '42',
      subject: 'Card',
      attributes: {
        status: { id: '1', name: 'Open', $load: () => Promise.resolve() },
        type: { id: '2', name: 'Task' },
        priority: { id: '3', name: 'Normal' },
      },
    });
    const change = {
      getForm: () => Promise.resolve({
        schema: { status: { allowedValues: [{ id: '1', name: 'Open' }, { id: '2', name: 'Closed' }] } },
      }),
      schema: { status: { writable: true } },
      projectedResource,
    };

    vi.spyOn(OpenprojectWorkPackagesModule, 'bootstrapAttributeGroups').mockImplementation(() => undefined);
    TestBed.overrideModule(OpenprojectWorkPackagesModule, {
      set: {
        imports: [
          CommonModule,
          OpTooltipDirective,
          OpActionMenuComponent,
          OpActionMenuTriggerDirective,
          WorkPackageStatusDropdownDirective,
        ],
        declarations: [WorkPackageSingleCardComponent, WorkPackageStatusButtonComponent],
        exports: [WorkPackageSingleCardComponent],
        providers: [],
        schemas: [CUSTOM_ELEMENTS_SCHEMA],
      },
    });
    await TestBed.configureTestingModule({
      imports: [OpenprojectWorkPackagesModule],
      providers: [
        ...harnessProviders(new FakeDragAndDropService(), { workPackages: [] }),
        WorkPackageCardViewService,
        { provide: ToastService, useValue: {} },
        { provide: WorkPackageNotificationService, useValue: { showSave: vi.fn(), showError: vi.fn() } },
        {
          provide: HalResourceEditingService,
          useValue: {
            changeFor: () => change,
            save: () => Promise.resolve(),
            temporaryEditResource: () => ({ values$: () => of(workPackage) }),
            typedState: () => ({ hasValue: () => false }),
          },
        },
      ],
    }).compileComponents();

    const schemaCache = TestBed.inject(SchemaCacheService);
    vi.spyOn(schemaCache, 'of').mockReturnValue(statusSchema as never);
    const fixture = TestBed.createComponent(WorkPackageSingleCardComponent);
    card = fixture.componentInstance;
    cardClicked = [];
    card.cardClicked.subscribe(({ workPackageId }) => cardClicked.push(workPackageId));
    fixture.componentRef.setInput('workPackage', workPackage);
    vi.spyOn(card, 'isNewResource').mockReturnValue(false);
    vi.spyOn(card, 'baselineIcon').mockReturnValue(null);
    vi.spyOn(card, 'fullWorkPackageLink').mockReturnValue('/work_packages/42');
    document.body.append(fixture.nativeElement as HTMLElement);
    fixture.detectChanges();
    await fixture.whenStable();
  });

  afterEach(() => vi.restoreAllMocks());

  const openMenu = async () => {
    await userEvent.click(screen.getByRole('button', { name: 'js.work_packages.properties.status Open' }));
    const menu = await screen.findByRole('menu', { name: 'js.work_packages.properties.status' });
    await settlePopover();
    return menu;
  };

  it('does not activate the card when the status button is clicked', async () => {
    await userEvent.click(screen.getByRole('button', { name: 'js.work_packages.properties.status Open' }));

    expect(cardClicked).toEqual([]);
  });

  it('does not activate the card when a status is chosen with the pointer', async () => {
    const menu = await openMenu();
    cardClicked.length = 0;

    await userEvent.click(within(menu).getByRole('menuitem', { name: 'Closed' }));

    expect(projectedResource.status).toEqual({ id: '2', name: 'Closed' });
    expect(cardClicked).toEqual([]);
  });

  it('does not activate the card when a status is chosen with Enter', async () => {
    const menu = await openMenu();
    cardClicked.length = 0;
    const item = within(menu).getByRole('menuitem', { name: 'Closed' });
    item.focus();

    await userEvent.keyboard('{Enter}');

    await waitFor(() => expect(projectedResource.status).toEqual({ id: '2', name: 'Closed' }));
    expect(cardClicked).toEqual([]);
  });

  describe('right-click and double-click', () => {
    let pointerEvents:string[];
    const statusButton = () => screen.getByRole('button', { name: 'js.work_packages.properties.status Open' });

    beforeEach(() => {
      pointerEvents = [];
      card.cardContextMenu.subscribe(() => pointerEvents.push('contextmenu'));
      card.cardDblClicked.subscribe(() => pointerEvents.push('dblclick'));
    });

    it('reports them on the card itself', () => {
      fireEvent.contextMenu(screen.getByText('Card'));
      fireEvent.dblClick(screen.getByText('Card'));

      expect(pointerEvents).toEqual(['contextmenu', 'dblclick']);
    });

    it('does not report them on the status button', () => {
      fireEvent.contextMenu(statusButton());
      fireEvent.dblClick(statusButton());

      expect(pointerEvents).toEqual([]);
    });

    it('does not report them on an item of the open status menu', async () => {
      const menu = await openMenu();
      const item = within(menu).getByRole('menuitem', { name: 'Closed' });

      fireEvent.contextMenu(item);
      fireEvent.dblClick(item);

      expect(pointerEvents).toEqual([]);
    });
  });
});
