//-- copyright
// OpenProject is a project management system.
// Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
// See doc/COPYRIGHT.rdoc for more details.
//++

import {WorkPackageCreateService} from '../../wp-new/wp-create.service';
import {StateService} from '@uirouter/core';
import {OpContextMenuTrigger} from "core-components/op-context-menu/trigger/op-context-menu-trigger";
import {OPContextMenuService} from "core-components/op-context-menu/op-context-menu.service";
import {Directive, ElementRef, Inject, Input} from "@angular/core";
import {$stateToken} from "core-app/angular4-transition-utils";
import {TypeResource} from "core-components/api/api-v3/hal-resources/type-resource.service";
import {CollectionResource} from "core-components/api/api-v3/hal-resources/collection-resource.service";
import {LinkHandling} from "core-components/common/link-handling/link-handling";

@Directive({
  selector: '[opTypesCreateDropdown]'
})
export class OpTypesContextMenuDirective extends OpContextMenuTrigger {
  @Input('projectIdentifier') public projectIdentifier:string;
  @Input('stateName') public stateName:string;

  private loadingPromise:Promise<any>;

  constructor(readonly elementRef:ElementRef,
              readonly opContextMenu:OPContextMenuService,
              @Inject($stateToken) readonly $state:StateService,
              protected wpCreate:WorkPackageCreateService) {

    super(elementRef, opContextMenu);
  }

  ngAfterViewInit():void {
    super.ngAfterViewInit();

    // Force full-view create if in mobile view
    if (bowser.mobile) {
      this.stateName = 'work-packages.new';
    }

    this.loadingPromise = this.wpCreate.getEmptyForm(this.projectIdentifier)
      .then((form:any) => {
        return this.buildItems(form.schema.type.allowedValues);
      });
  }

  protected open(evt:Event) {
    this.loadingPromise.then(() => {
      this.opContextMenu.show(this, evt);
    });
  }

  /**
   * Positioning args for jquery-ui position.
   *
   * @param {Event} openerEvent
   */
  public positionArgs(openerEvent:Event) {
    return {
      my: 'left top',
      at: 'left bottom',
      of: this.$element
    };
  }

  private buildItems(types:CollectionResource<TypeResource>) {
    this.items = types.map((type:TypeResource) => {
      return {
        disabled: false,
        linkText: type.name,
        href: this.$state.href(this.stateName, { type: type.id }),
        ariaLabel: type.name,
        onClick: ($event:JQueryEventObject) => {
          if (LinkHandling.isClickedWithModifier($event)) {
            return true;
          }

          $event.preventDefault();
          $event.stopPropagation();
          this.$state.go(this.stateName, { type: type.id });

          return false;
        }
      };
    });
  }
}

