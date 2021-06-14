//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2021 the OpenProject GmbH
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

import { OPContextMenuService } from "core-components/op-context-menu/op-context-menu.service";
import { Directive, ElementRef } from "@angular/core";
import { OpContextMenuTrigger } from "core-components/op-context-menu/handlers/op-context-menu-trigger.directive";

import { HalResourceEditingService } from "core-app/modules/fields/edit/services/hal-resource-editing.service";
import { States } from "core-components/states.service";
import { FormResource } from 'core-app/modules/hal/resources/form-resource';

@Directive({
  selector: '[wpCreateSettingsMenu]'
})
export class WorkPackageCreateSettingsMenuDirective extends OpContextMenuTrigger {

  constructor(readonly elementRef:ElementRef,
              readonly opContextMenu:OPContextMenuService,
              readonly states:States,
              readonly halEditing:HalResourceEditingService) {

    super(elementRef, opContextMenu);
  }

  protected open(evt:JQuery.TriggeredEvent) {
    const wp = this.states.workPackages.get('new').value;

    if (wp) {
      const change = this.halEditing.changeFor(wp);
      change.getForm().then(
        (loadedForm:FormResource) => {
          this.buildItems(loadedForm);
          this.opContextMenu.show(this, evt);
        }
      );
    }
  }

  /**
   * Positioning args for jquery-ui position.
   *
   * @param {Event} openerEvent
   */
  public positionArgs(evt:JQuery.TriggeredEvent) {
    const additionalPositionArgs = {
      my: 'right top',
      at: 'right bottom'
    };

    const position = super.positionArgs(evt);
    _.assign(position, additionalPositionArgs);

    return position;
  }

  private buildItems(form:FormResource) {
    this.items = [];
    const configureFormLink = form.configureForm;
    const queryCustomFields = form.customFields;

    if (queryCustomFields) {
      this.items.push({
        href: queryCustomFields.href,
        icon: 'icon-custom-fields',
        linkText: queryCustomFields.name,
        onClick: () => false
      });
    }

    if (configureFormLink) {
      this.items.push({
        href: configureFormLink.href,
        icon: 'icon-settings3',
        linkText: configureFormLink.name,
        onClick: () => false
      });
    }
  }
}

