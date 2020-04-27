//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2020 the OpenProject GmbH
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
// See docs/COPYRIGHT.rdoc for more details.
//++

import {OpContextMenuItem} from 'core-components/op-context-menu/op-context-menu.types';
import {StateService} from '@uirouter/core';
import {OPContextMenuService} from "core-components/op-context-menu/op-context-menu.service";
import {Directive, ElementRef, Input} from "@angular/core";
import {LinkHandling} from "core-app/modules/common/link-handling/link-handling";
import {OpContextMenuTrigger} from "core-components/op-context-menu/handlers/op-context-menu-trigger.directive";
import {TypeResource} from 'core-app/modules/hal/resources/type-resource';
import {Highlighting} from 'core-app/components/wp-fast-table/builders/highlighting/highlighting.functions';
import {BrowserDetector} from "core-app/modules/common/browser/browser-detector.service";
import {WorkPackageCreateService} from 'core-components/wp-new/wp-create.service';

@Directive({
  selector: '[opTypesCreateDropdown]'
})
export class OpTypesContextMenuDirective extends OpContextMenuTrigger {
  @Input('projectIdentifier') public projectIdentifier:string|null|undefined;
  @Input('stateName') public stateName:string;
  @Input('dropdownActive') active:boolean;

  private loadingPromise:Promise<any>;

  constructor(readonly elementRef:ElementRef,
              readonly opContextMenu:OPContextMenuService,
              readonly browserDetector:BrowserDetector,
              readonly wpCreate:WorkPackageCreateService,
              readonly $state:StateService) {
    super(elementRef, opContextMenu);
  }

  ngAfterViewInit():void {
    super.ngAfterViewInit();

    if (!this.active) {
        return;
    }

    // Force full-view create if in mobile view
    if (this.browserDetector.isMobile) {
      this.stateName = 'work-packages.new';
    }

    this.loadingPromise = this
      .wpCreate
      .getEmptyForm(this.projectIdentifier)
      .then(form => {
        return this.buildItems(form.schema.type.allowedValues);
      });
  }

  protected open(evt:JQuery.TriggeredEvent) {
    this.loadingPromise.then(() => {
      this.opContextMenu.show(this, evt);
    });
  }

  public get locals():{ showAnchorRight?:boolean, contextMenuId?:string, items:OpContextMenuItem[] } {
    return {
      items: this.items,
      contextMenuId: 'types-context-menu'
    };
  }

  private buildItems(types:TypeResource[]) {
    this.items = types.map((type:TypeResource) => {
      return {
        disabled: false,
        linkText: type.name,
        href: this.$state.href(this.stateName, { type: type.id! }),
        ariaLabel: type.name,
        class: Highlighting.inlineClass('type', type.id!),
        onClick: ($event:JQuery.TriggeredEvent) => {
          if (LinkHandling.isClickedWithModifier($event)) {
            return false;
          }

          this.$state.go(this.stateName, { type: type.id });
          return true;
        }
      };
    });
  }
}

