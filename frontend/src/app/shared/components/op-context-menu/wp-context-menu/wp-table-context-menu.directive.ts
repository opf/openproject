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

import { Injector } from '@angular/core';
import { WorkPackageAction } from 'core-app/features/work-packages/components/wp-table/context-menu-helper/wp-context-menu-helper.service';
import { WorkPackageTable } from 'core-app/features/work-packages/components/wp-fast-table/wp-fast-table';
import { PositionArgs, WorkPackageViewContextMenu } from 'core-app/shared/components/op-context-menu/wp-context-menu/wp-view-context-menu.directive';
import { WorkPackageViewHierarchyIdentationService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-hierarchy-indentation.service';
import { LazyInject } from 'core-app/shared/helpers/angular/lazy-inject.decorator';
import { FocusPosition } from 'core-app/features/work-packages/components/wp-fast-table/handlers/state/keyboard/focus-position';
import { OpContextMenuCloseReason, OpContextMenuItem } from 'core-app/shared/components/op-context-menu/op-context-menu.types';
import type { DynamicIconName } from 'core-app/shared/components/primer/dynamic-icon-map';
import { forgetKeyboardMenuOpen } from 'core-app/features/work-packages/components/wp-fast-table/handlers/context-menu/context-menu-handler';

const tableActionIcons = {
  'icon-clipboard': 'paste',
  'icon-code-tag': 'hash',
  'icon-copy': 'duplicate',
  'icon-delete': 'trash',
  'icon-duplicate': 'duplicate',
  'icon-edit': 'pencil',
  'icon-export-atom': 'op-file-atom',
  'icon-export-pdf-with-descriptions': 'op-pdf-description',
  'icon-file-text': 'markdown',
  'icon-log_time': 'clock',
  'icon-move': 'op-move',
  'icon-paragraph-left': 'op-outdent',
  'icon-paragraph-right': 'op-indent',
  'icon-project-types': 'op-copy-to-project',
  'icon-relation-follows': 'op-relation-follows',
  'icon-relation-new-child': 'op-relation-new-child',
  'icon-relations': 'op-relations',
  'icon-user-plus': 'person-add',
  'icon-view-fullscreen': 'op-view-fullscreen',
  'icon-view-split': 'op-view-split',
} as const satisfies Record<`icon-${string}`, DynamicIconName>;

function octiconFor(icon:string):DynamicIconName|undefined {
  return Object.hasOwn(tableActionIcons, icon)
    ? tableActionIcons[icon as keyof typeof tableActionIcons]
    : undefined;
}

export class WorkPackageTableContextMenu extends WorkPackageViewContextMenu {
  @LazyInject() wpViewIndentation:WorkPackageViewHierarchyIdentationService;

  private readonly origin:FocusPosition|null;

  constructor(public injector:Injector,
    protected workPackageId:string,
    protected element:HTMLElement,
    additionalPositionArgs:PositionArgs,
    protected table:WorkPackageTable) {
    super(injector, workPackageId, element, additionalPositionArgs, true);
    this.origin = table.keyboardNavigation.originForControl(element);
  }

  protected override buildItems():OpContextMenuItem[] {
    return super.buildItems().map((item):OpContextMenuItem => ({
      ...item,
      octicon: item.icon ? octiconFor(item.icon) : undefined,
    }));
  }

  public override onClose(focus = true, reason?:OpContextMenuCloseReason):void {
    forgetKeyboardMenuOpen(this.table);

    if (this.origin && (reason === 'escape' || reason === 'action')) {
      this.table.keyboardNavigation.returnFocusFromMenu(this.origin);
      return;
    }

    super.onClose(focus);
  }

  protected override get afterFocusOn():HTMLElement {
    return this.element.closest<HTMLElement>('[tabindex="0"]')
      ?? this.element.querySelector<HTMLElement>('[tabindex="0"]')
      ?? super.afterFocusOn;
  }

  public triggerContextMenuAction(action:WorkPackageAction) {
    switch (action.key) {
      case 'relation-precedes':
        this.table.timelineController.startAddRelationPredecessor(this.workPackage);
        break;

      case 'relation-follows':
        this.table.timelineController.startAddRelationFollower(this.workPackage);
        break;

      case 'hierarchy-indent':
        void this.wpViewIndentation.indent(this.workPackage);
        break;

      case 'hierarchy-outdent':
        void this.wpViewIndentation.outdent(this.workPackage);
        break;

      default:
        super.triggerContextMenuAction(action);
        break;
    }
  }
}
