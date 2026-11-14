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

import { Directive, inject } from '@angular/core';
import { OpActionMenuItems } from 'core-app/shared/components/op-context-menu/action-menu/op-action-menu-items';
import { OpContextMenuItem } from 'core-app/shared/components/op-context-menu/op-context-menu.types';
import { withOcticon } from 'core-app/shared/components/op-context-menu/wp-context-menu/wp-menu-octicons';
import { HalResourceEditingService } from 'core-app/shared/components/fields/edit/services/hal-resource-editing.service';
import { States } from 'core-app/core/states/states.service';
import { FormResource } from 'core-app/features/hal/resources/form-resource';

@Directive({
  // eslint-disable-next-line @angular-eslint/directive-selector
  selector: '[wpCreateSettingsMenu]',
})
export class WorkPackageCreateSettingsMenuDirective extends OpActionMenuItems {
  readonly states = inject(States);
  readonly halEditing = inject(HalResourceEditingService);

  protected buildItems():Promise<OpContextMenuItem[]> {
    const wp = this.states.workPackages.get('new').value;

    if (!wp) {
      return Promise.resolve([]);
    }

    return this.halEditing
      .changeFor(wp)
      .getForm()
      .then((form:FormResource) => this.formItems(form).map(withOcticon));
  }

  private formItems(form:FormResource):OpContextMenuItem[] {
    const items:OpContextMenuItem[] = [];
    const configureFormLink = form.configureForm;
    const queryCustomFields = form.customFields;

    if (queryCustomFields) {
      items.push({
        href: queryCustomFields.href as string|undefined,
        icon: 'icon-custom-fields',
        linkText: queryCustomFields.name,
        onClick: () => false,
      });
    }

    if (configureFormLink) {
      items.push({
        href: configureFormLink.href as string|undefined,
        icon: 'icon-settings3',
        linkText: configureFormLink.name,
        onClick: () => false,
      });
    }

    return items;
  }
}
