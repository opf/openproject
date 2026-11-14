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

import { usePlatform } from 'core-common/testing/platform';
import { ElementRef, EventEmitter, Injector } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { fireEvent, within } from '@testing-library/dom';
import { States } from 'core-app/core/states/states.service';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { WorkPackageViewSelectionGesturesService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-selection-gestures.service';
import { WorkPackageViewSelectionService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-selection.service';
import { WorkPackageViewFocusService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-focus.service';
import { OpActionMenuService } from 'core-app/shared/components/op-context-menu/action-menu/op-action-menu.service';
import { CopyToClipboardService } from 'core-app/shared/components/copy-to-clipboard/copy-to-clipboard.service';
import {
  WorkPackageContextMenuHelperService,
} from 'core-app/features/work-packages/components/wp-table/context-menu-helper/wp-context-menu-helper.service';
import { OPContextMenuService } from 'core-app/shared/components/op-context-menu/op-context-menu.service';
import { WorkPackageCardViewService } from '../services/wp-card-view.service';
import { WorkPackageCardViewComponent } from '../wp-card-view.component';
import { CardRightClickHandler } from './right-click-handler';
import { CardDblClickHandler } from './double-click-handler';

describe('Card right-click and double-click handlers', () => {
  let root:HTMLElement;
  let selection:WorkPackageViewSelectionService;
  let card:WorkPackageCardViewComponent;
  let show:ReturnType<typeof vi.fn>;
  let itemClicked:{ workPackageId:string, double:boolean }[];

  usePlatform();

  beforeEach(() => {
    show = vi.fn();
    TestBed.configureTestingModule({ providers: [
      States,
      IsolatedQuerySpace,
      WorkPackageViewSelectionService,
      WorkPackageViewSelectionGesturesService,
      WorkPackageViewFocusService,
      WorkPackageCardViewService,
      { provide: OPContextMenuService, useValue: { close: vi.fn() } },
      { provide: OpActionMenuService, useValue: { show } },
      { provide: WorkPackageContextMenuHelperService, useValue: { getPermittedActions: () => [] } },
      { provide: CopyToClipboardService, useValue: {} },
    ] });
    const injector = TestBed.inject(Injector);
    selection = TestBed.inject(WorkPackageViewSelectionService);
    const cardView = TestBed.inject(WorkPackageCardViewService);
    const workPackage = { id: 'A', displayId: 'A' } as WorkPackageResource;
    TestBed.inject(States).workPackages.get('A').putValue(workPackage);
    cardView.updateRenderedCardsValues([workPackage]);
    root = document.createElement('div');
    root.innerHTML = `
      <wp-single-card data-work-package-id="A" data-class-identifier="${cardView.renderedCards[0].classIdentifier}">
        <div class="op-wp-single-card" data-test-selector="op-wp-single-card" tabindex="0">
          <span>Subject</span>
          <button type="button" aria-haspopup="menu"><span>Open menu</span></button>
          <ul role="menu"><li role="none"><button type="button" role="menuitem">Closed</button></li></ul>
        </div>
      </wp-single-card>
    `;
    document.body.append(root);
    itemClicked = [];
    card = {
      container: new ElementRef(root),
      itemClicked: new EventEmitter(),
      showInfoButton: false,
    } as unknown as WorkPackageCardViewComponent;
    card.itemClicked.subscribe((event) => itemClicked.push(event));

    const rightClick = new CardRightClickHandler(injector, card);
    const doubleClick = new CardDblClickHandler(injector, card);
    [rightClick, doubleClick].forEach((handler) => {
      root.addEventListener(handler.EVENT, (event) => {
        const target = event.target;
        if (target instanceof HTMLElement && target.closest(handler.SELECTOR)) {
          handler.handleEvent(card, event);
        }
      });
    });
  });

  afterEach(() => root.remove());

  const surface = () => root.querySelector<HTMLElement>('.op-wp-single-card')!;
  const menuButtonLabel = () => within(surface()).getByText('Open menu');
  const menuItem = () => within(surface()).getByRole('menuitem', { hidden: true });

  describe('right-click', () => {
    it('opens the context menu and selects the card from its surface', () => {
      const notPrevented = fireEvent.contextMenu(within(surface()).getByText('Subject'));

      expect(notPrevented).toBe(false);
      expect(show).toHaveBeenCalledOnce();
      expect(selection.getSelectedWorkPackageIds()).toEqual(['A']);
    });

    it.each([
      ['a control with a menu', menuButtonLabel],
      ['inside an open menu', menuItem],
    ])('leaves the native event alone for %s', (_name, target) => {
      const notPrevented = fireEvent.contextMenu(target());

      expect(notPrevented).toBe(true);
      expect(show).not.toHaveBeenCalled();
      expect(selection.getSelectedWorkPackageIds()).toEqual([]);
    });
  });

  describe('double-click', () => {
    it('opens the work package from the card surface', () => {
      fireEvent.dblClick(within(surface()).getByText('Subject'));

      expect(itemClicked).toEqual([{ workPackageId: 'A', double: true }]);
    });

    it.each([
      ['a control with a menu', menuButtonLabel],
      ['inside an open menu', menuItem],
    ])('ignores %s', (_name, target) => {
      fireEvent.dblClick(target());

      expect(itemClicked).toEqual([]);
      expect(selection.getSelectedWorkPackageIds()).toEqual([]);
    });
  });
});
