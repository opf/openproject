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

import { Injector } from '@angular/core';
import { CardEventHandler } from 'core-app/features/work-packages/components/wp-card-view/event-handler/card-view-handler-registry';
import { WorkPackageCardViewComponent } from 'core-app/features/work-packages/components/wp-card-view/wp-card-view.component';
import { WorkPackageViewSelectionService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-selection.service';
import { StateService } from '@uirouter/core';
import { LazyInject } from 'core-app/shared/helpers/angular/lazy-inject.decorator';
import { EventType } from 'core-app/features/work-packages/routing/wp-view-base/event-handling/event-handler-registry';

export class CardDblClickHandler implements CardEventHandler {
  @LazyInject() $state:StateService;

  @LazyInject() wpTableSelection:WorkPackageViewSelectionService;

  constructor(public readonly injector:Injector,
    card:WorkPackageCardViewComponent) {
  }

  public get EVENT():EventType {
    return 'dblclick';
  }

  public get SELECTOR() {
    return '[data-test-selector="op-wp-single-card"]';
  }

  public eventScope(card:WorkPackageCardViewComponent) {
    return card.container.nativeElement;
  }

  public handleEvent(card:WorkPackageCardViewComponent, evt:Event) {
    const target = evt.target as HTMLElement;

    // Ignore links
    if (target instanceof HTMLAnchorElement || target.parentElement instanceof HTMLAnchorElement) {
      return true;
    }

    // Locate the row from event
    const element = target.closest<HTMLElement>('wp-single-card')!;
    const wpId = element.dataset.workPackageId;

    if (!wpId) {
      return true;
    }

    card.itemClicked.emit({ workPackageId: wpId, double: true });
    return false;
  }
}
