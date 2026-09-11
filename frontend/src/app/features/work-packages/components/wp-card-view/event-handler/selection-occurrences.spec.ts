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

import { EventEmitter, Injector } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { createEvent } from '@testing-library/dom';
import { StateService } from '@uirouter/core';
import { States } from 'core-app/core/states/states.service';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { IsolatedQuerySpace } from 'core-app/features/work-packages/directives/query-space/isolated-query-space';
import { WorkPackageViewFocusService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-focus.service';
import { WorkPackageViewSelectionService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-selection.service';
import { WorkPackageViewSelectionGesturesService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-selection-gestures.service';
import { OPContextMenuService } from 'core-app/shared/components/op-context-menu/op-context-menu.service';
import { CopyToClipboardService } from 'core-app/shared/components/copy-to-clipboard/copy-to-clipboard.service';
import { WorkPackageContextMenuHelperService } from 'core-app/features/work-packages/components/wp-table/context-menu-helper/wp-context-menu-helper.service';
import { WorkPackageCardViewService } from '../services/wp-card-view.service';
import { WorkPackageCardViewComponent } from '../wp-card-view.component';
import { WorkPackageSingleCardComponent } from '../wp-single-card/wp-single-card.component';
import { CardClickHandler } from './click-handler';
import { CardRightClickHandler } from './right-click-handler';

describe('card selection occurrences', () => {
  let selection:WorkPackageViewSelectionService;
  let gestures:WorkPackageViewSelectionGesturesService;
  let injector:Injector;
  let cardView:WorkPackageCardViewService;
  let card:WorkPackageCardViewComponent;
  const rows:RenderedWorkPackage[] = [
    { workPackageId: '1', classIdentifier: 'wp-row-1', hidden: false },
    { workPackageId: '2', classIdentifier: 'wp-relation-row-1-to-2', hidden: false },
    { workPackageId: '3', classIdentifier: 'wp-row-3', hidden: false },
    { workPackageId: '2', classIdentifier: 'wp-row-2', hidden: false },
    { workPackageId: '4', classIdentifier: 'wp-row-4', hidden: false },
  ];

  beforeEach(() => {
    TestBed.configureTestingModule({ providers: [
      States,
      IsolatedQuerySpace,
      WorkPackageViewSelectionService,
      WorkPackageViewSelectionGesturesService,
      WorkPackageViewFocusService,
      WorkPackageCardViewService,
      { provide: OPContextMenuService, useValue: { close: () => undefined, show: () => undefined } },
      { provide: CopyToClipboardService, useValue: {} },
      { provide: WorkPackageContextMenuHelperService, useValue: { getPermittedActions: () => [] } },
      { provide: StateService, useValue: { current: { name: 'work-packages.partitioned.list' } } },
    ] });
    selection = TestBed.inject(WorkPackageViewSelectionService);
    gestures = TestBed.inject(WorkPackageViewSelectionGesturesService);
    cardView = TestBed.inject(WorkPackageCardViewService);
    injector = TestBed.inject(Injector);
    TestBed.inject(IsolatedQuerySpace).tableRendered.putValue(rows);
    TestBed.inject(States).workPackages.get('2').putValue({ id: '2', displayId: '2' } as WorkPackageResource);
    card = {
      itemClicked: new EventEmitter(), selectionChanged: new EventEmitter(), showInfoButton: false,
    } as unknown as WorkPackageCardViewComponent;
  });

  function event(type:'click'|'contextMenu') {
    const element = document.createElement('wp-single-card');
    element.dataset.workPackageId = '2';
    element.dataset.classIdentifier = 'wp-row-2';
    const result = createEvent[type](element) as MouseEvent;
    Object.defineProperty(result, 'target', { value: element });
    return result;
  }

  it('anchors a card click at the clicked occurrence', () => {
    new CardClickHandler(injector, card).handleEvent(card, event('click'));
    gestures.click('4', rows, { shiftKey: true });
    expect(selection.getSelectedWorkPackageIds()).toEqual(['2', '4']);
  });

  it('anchors a card context menu at the clicked occurrence', () => {
    new CardRightClickHandler(injector, card).handleEvent(card, event('contextMenu'));
    gestures.click('4', rows, { shiftKey: true });
    expect(selection.getSelectedWorkPackageIds()).toEqual(['2', '4']);
  });

  it('anchors a title link at its card occurrence', () => {
    const singleCard = Object.assign(Object.create(WorkPackageSingleCardComponent.prototype) as WorkPackageSingleCardComponent, {
      selectionGestures: gestures,
      cardView,
      wpTableFocus: TestBed.inject(WorkPackageViewFocusService),
      stateLinkClicked: new EventEmitter(),
    });
    singleCard.emitStateLinkClicked(event('click'), { id: '2' } as WorkPackageResource);
    gestures.click('4', rows, { shiftKey: true });
    expect(selection.getSelectedWorkPackageIds()).toEqual(['2', '4']);
  });
});
