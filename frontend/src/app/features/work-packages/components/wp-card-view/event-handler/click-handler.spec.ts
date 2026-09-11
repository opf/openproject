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
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { ElementRef, EventEmitter, Injector } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { fireEvent } from '@testing-library/dom';
import { States } from 'core-app/core/states/states.service';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { registerWorkPackageSelectAll } from 'core-app/features/work-packages/routing/wp-view-base/event-handling/wp-selection-keyboard';
import { WorkPackageViewFocusService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-focus.service';
import { WorkPackageViewSelectionGesturesService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-selection-gestures.service';
import { WorkPackageViewSelectionService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-selection.service';
import { OPContextMenuService } from 'core-app/shared/components/op-context-menu/op-context-menu.service';
import { WorkPackageCardViewService } from '../services/wp-card-view.service';
import { WorkPackageCardViewComponent } from '../wp-card-view.component';
import { CardClickHandler } from './click-handler';

describe('CardClickHandler', () => {
  let root:HTMLElement;
  let selection:WorkPackageViewSelectionService;
  let focus:WorkPackageViewFocusService;
  let cardView:WorkPackageCardViewService;
  let card:WorkPackageCardViewComponent;
  let unregisterSelectAll:() => void;
  let platformSpy:ReturnType<typeof vi.spyOn>;
  let userAgentDataDescriptor:PropertyDescriptor|undefined;
  let closeContextMenu:() => void;

  beforeEach(() => {
    closeContextMenu = vi.fn();
    TestBed.configureTestingModule({ providers: [
      States,
      IsolatedQuerySpace,
      WorkPackageViewSelectionService,
      WorkPackageViewSelectionGesturesService,
      WorkPackageViewFocusService,
      WorkPackageCardViewService,
      { provide: OPContextMenuService, useValue: { close: closeContextMenu } },
    ] });
    const injector = TestBed.inject(Injector);
    selection = TestBed.inject(WorkPackageViewSelectionService);
    focus = TestBed.inject(WorkPackageViewFocusService);
    cardView = TestBed.inject(WorkPackageCardViewService);
    cardView.updateRenderedCardsValues(['A', 'B', 'C', 'D', 'E'].map((id) => ({ id } as WorkPackageResource)));
    root = document.createElement('div');
    root.innerHTML = cardView.renderedCards.map((row) => `
      <wp-single-card data-work-package-id="${row.workPackageId}" data-class-identifier="${row.classIdentifier}">
        <div class="op-wp-single-card" data-test-selector="op-wp-single-card" tabindex="0">
          <span>${row.workPackageId}</span>
        </div>
      </wp-single-card>
    `).join('');
    document.body.append(root);
    card = {
      container: new ElementRef(root),
      itemClicked: new EventEmitter(),
      selectionChanged: new EventEmitter(),
      showInfoButton: false,
    } as unknown as WorkPackageCardViewComponent;
    const handler = new CardClickHandler(injector, card);
    root.addEventListener('click', (event) => {
      const target = event.target;
      if (target instanceof HTMLElement && target.closest(handler.SELECTOR)) {
        handler.handleEvent(card, event);
      }
    });
    unregisterSelectAll = registerWorkPackageSelectAll({
      root,
      focusSelector: '.op-wp-single-card',
      occurrenceSelector: 'wp-single-card[data-work-package-id][data-class-identifier]',
      rendered: () => cardView.renderedCards,
      selectAll: (rows, anchor) => {
        selection.selectAll(rows, anchor);
        closeContextMenu();
      },
    });
    platformSpy = vi.spyOn(navigator, 'platform', 'get').mockReturnValue('Linux');
    userAgentDataDescriptor = Object.getOwnPropertyDescriptor(navigator, 'userAgentData');
    Object.defineProperty(navigator, 'userAgentData', {
      configurable: true,
      value: undefined,
    });
  });

  afterEach(() => {
    unregisterSelectAll();
    root.remove();
    platformSpy.mockRestore();
    if (userAgentDataDescriptor) {
      Object.defineProperty(navigator, 'userAgentData', userAgentDataDescriptor);
    } else {
      delete (navigator as Navigator & { userAgentData?:unknown }).userAgentData;
    }
  });

  const selected = () => selection.getSelectedWorkPackageIds().sort();
  const cardSurface = (id:string) => root.querySelector<HTMLElement>(
    `wp-single-card[data-work-package-id="${id}"] .op-wp-single-card`,
  )!;
  const click = (id:string, init:MouseEventInit = {}) => fireEvent.click(cardSurface(id).querySelector('span')!, init);

  it('preserves independent cards while resizing a pointer range', () => {
    const itemClicked:{ workPackageId:string, double:boolean }[] = [];
    const selectionChanged:string[][] = [];
    card.itemClicked.subscribe((event) => itemClicked.push(event));
    card.selectionChanged.subscribe((ids) => selectionChanged.push(ids));
    click('A');
    click('C', { ctrlKey: true });
    click('E', { shiftKey: true });
    expect(selected()).toEqual(['A', 'C', 'D', 'E']);

    click('C', { shiftKey: true });
    expect(selected()).toEqual(['A', 'C']);
    expect(itemClicked.map((event) => event.workPackageId)).toEqual(['A', 'C', 'E', 'C']);
    expect(selectionChanged.map((ids) => ids.sort())).toEqual([
      ['A'],
      ['A', 'C'],
      ['A', 'C', 'D', 'E'],
      ['A', 'C'],
    ]);
  });

  it('keeps the final member deselected after its focus update', () => {
    click('C');
    click('C', { ctrlKey: true });

    expect(selected()).toEqual([]);
    expect(selection.isEmpty).toBe(true);
    expect(focus.focusedWorkPackage).toBe('C');
  });

  it('narrows from the card that owns Select All without fabricating activation', () => {
    click('A');
    cardSurface('C').removeAttribute('data-test-selector');
    const itemClicked:{ workPackageId:string, double:boolean }[] = [];
    const selectionChanged:string[][] = [];
    card.itemClicked.subscribe((event) => itemClicked.push(event));
    card.selectionChanged.subscribe((ids) => selectionChanged.push(ids));

    expect(fireEvent.keyDown(cardSurface('C'), { key: 'a', ctrlKey: true })).toBe(false);
    expect(selected()).toEqual(['A', 'B', 'C', 'D', 'E']);
    expect(closeContextMenu).toHaveBeenCalledOnce();
    expect(itemClicked).toEqual([]);
    expect(selectionChanged).toEqual([]);

    click('E', { shiftKey: true });
    expect(selected()).toEqual(['C', 'D', 'E']);
    expect(itemClicked).toEqual([{ workPackageId: 'E', double: false }]);
    expect(selectionChanged).toEqual([['C', 'D', 'E']]);
  });
});
