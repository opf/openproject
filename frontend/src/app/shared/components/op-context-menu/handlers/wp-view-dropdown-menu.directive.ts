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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { OPContextMenuService } from 'core-app/shared/components/op-context-menu/op-context-menu.service';
import { Directive, ElementRef } from '@angular/core';
import { OpContextMenuTrigger } from 'core-app/shared/components/op-context-menu/handlers/op-context-menu-trigger.directive';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import {
  WorkPackageViewDisplayRepresentationService,
  wpDisplayCardRepresentation,
  wpDisplayListRepresentation,
} from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-display-representation.service';
import { WorkPackageViewTimelineService } from 'core-app/features/work-packages/routing/wp-view-base/view-services/wp-view-timeline.service';

@Directive({
  selector: '[wpViewDropdown]',
})
export class WorkPackageViewDropdownMenuDirective extends OpContextMenuTrigger {
  constructor(
    readonly elementRef:ElementRef,
    readonly opContextMenu:OPContextMenuService,
    readonly I18n:I18nService,
    readonly wpDisplayRepresentationService:WorkPackageViewDisplayRepresentationService,
    readonly wpTableTimeline:WorkPackageViewTimelineService,
  ) {
    super(elementRef, opContextMenu);
  }

  public isOpen = false;

  protected open(evt:JQuery.TriggeredEvent) {
    this.isOpen = !this.isOpen;
    if (this.isOpen) {
      this.buildItems();
      this.opContextMenu.show(this, evt);
    } else {
      this.opContextMenu.close();
    }
  }

  public get locals() {
    return {
      items: this.items,
      contextMenuId: 'wp-view-context-menu',
    };
  }

  private buildItems() {
    this.items = [];

    if (this.wpDisplayRepresentationService.current !== wpDisplayCardRepresentation) {
      this.items.push(
        {
          // Card View
          linkText: this.I18n.t('js.views.card'),
          title: this.I18n.t('js.button_show_cards'),
          icon: 'icon-view-card',
          onClick: (evt:any) => {
            this.isOpen = false;
            this.wpDisplayRepresentationService.setDisplayRepresentation(wpDisplayCardRepresentation);
            if (this.wpTableTimeline.isVisible) {
              // Necessary for the timeline buttons to disappear
              this.wpTableTimeline.toggle();
            }
            return true;
          },
        },
      );
    }

    if (this.wpTableTimeline.isVisible || this.wpDisplayRepresentationService.current === wpDisplayCardRepresentation) {
      this.items.push(
        {
          // List View
          linkText: this.I18n.t('js.views.list'),
          title: this.I18n.t('js.button_show_table'),
          icon: 'icon-view-list',
          onClick: (evt:any) => {
            this.isOpen = false;
            this.wpDisplayRepresentationService.setDisplayRepresentation(wpDisplayListRepresentation);
            if (this.wpTableTimeline.isVisible) {
              this.wpTableTimeline.toggle();
            }
            return true;
          },
        },
      );
    }

    if (!this.wpTableTimeline.isVisible || this.wpDisplayRepresentationService.current === wpDisplayCardRepresentation) {
      this.items.push(
        {
          // List View with enabled Gantt
          linkText: this.I18n.t('js.views.timeline'),
          title: this.I18n.t('js.button_show_gantt'),
          icon: 'icon-view-timeline',
          onClick: (evt:any) => {
            this.isOpen = false;
            if (!this.wpTableTimeline.isVisible) {
              this.wpTableTimeline.toggle();
            }
            this.wpDisplayRepresentationService.setDisplayRepresentation(wpDisplayListRepresentation);
            return true;
          },
        },
      );
    }
  }
}
