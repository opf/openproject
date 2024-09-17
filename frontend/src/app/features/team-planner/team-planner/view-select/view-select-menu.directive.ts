/*
 * --copyright
 * OpenProject is an open source project management software.
 * Copyright (C) the OpenProject GmbH
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License version 3.
 *
 * OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
 * Copyright (C) 2006-2013 Jean-Philippe Lang
 * Copyright (C) 2010-2013 the ChiliProject Team
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 *
 * See COPYRIGHT and LICENSE files for more details.
 * ++
 */

import {
  Directive,
  EventEmitter,
  Input,
  Output,
} from '@angular/core';
import { OpContextMenuTrigger } from 'core-app/shared/components/op-context-menu/handlers/op-context-menu-trigger.directive';
import {
  TeamPlannerViewOptionKey,
  TeamPlannerViewOptions,
} from 'core-app/features/team-planner/team-planner/planner/team-planner.component';
import { OpContextMenuItem } from 'core-app/shared/components/op-context-menu/op-context-menu.types';

@Directive({
  selector: '[opTeamPlannerViewSelectDropdown]',
})
export class TeamPlannerViewSelectMenuDirective extends OpContextMenuTrigger {
  @Input() public viewOptions:NonNullable<TeamPlannerViewOptions>;

  @Output() public viewSelected = new EventEmitter<TeamPlannerViewOptionKey>();

  public get locals():{ showAnchorRight?:boolean, contextMenuId?:string, items:OpContextMenuItem[] } {
    return {
      items: this.buildItems(),
      contextMenuId: 'op-team-planner--view-select-dropdown',
    };
  }

  private selected(key:TeamPlannerViewOptionKey):boolean {
    this.viewSelected.emit(key);
    // Done to satisfy the interface.
    return true;
  }

  private buildItems():OpContextMenuItem[] {
    return Object.entries(this.viewOptions).map(([key, viewOption]) => ({
      linkText: viewOption.buttonText as string,
      onClick: () => this.selected(key as TeamPlannerViewOptionKey),
    }));
  }
}
