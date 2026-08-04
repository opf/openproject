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

import { WorkPackageCardViewComponent } from 'core-app/features/work-packages/components/wp-card-view/wp-card-view.component';
import { CardClickHandler } from 'core-app/features/work-packages/components/wp-card-view/event-handler/click-handler';
import { CardDblClickHandler } from 'core-app/features/work-packages/components/wp-card-view/event-handler/double-click-handler';
import { CardRightClickHandler } from 'core-app/features/work-packages/components/wp-card-view/event-handler/right-click-handler';
import {
  WorkPackageViewEventHandler,
  WorkPackageViewHandlerRegistry,
} from 'core-app/features/work-packages/routing/wp-view-base/event-handling/event-handler-registry';

export type CardEventHandler = WorkPackageViewEventHandler<WorkPackageCardViewComponent>;

export class CardViewHandlerRegistry extends WorkPackageViewHandlerRegistry<WorkPackageCardViewComponent> {
  protected eventHandlers:((c:WorkPackageCardViewComponent) => CardEventHandler)[] = [
    // Clicking on the card (not within a cell)
    (c) => new CardClickHandler(this.injector, c),
    // Double Clicking on the row (not within a cell)
    (c) => new CardDblClickHandler(this.injector, c),
    // Right clicking on cards
    (t) => new CardRightClickHandler(this.injector, t),
  ];
}
