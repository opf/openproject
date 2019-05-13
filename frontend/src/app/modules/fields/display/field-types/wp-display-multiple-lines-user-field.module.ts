// -- copyright
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
// ++

import {ResourcesDisplayField} from "./wp-display-resources-field.module";
import {cssClassCustomOption} from "core-app/modules/fields/display/display-field.module";
import {PortalCleanupService} from "core-app/modules/fields/display/display-portal/portal-cleanup.service";
import {UserFieldPortalService} from "core-app/modules/fields/display/display-portal/display-user-field-portal/user-field-portal-service";
import {DomPortalOutlet} from "@angular/cdk/portal";
import {UserResource} from "core-app/modules/hal/resources/user-resource";

export class MultipleLinesUserFieldModule extends ResourcesDisplayField {
  public userDisplayPortal = this.$injector.get(UserFieldPortalService);
  public portalCleanup = this.$injector.get(PortalCleanupService);
  public outlet:DomPortalOutlet;

  public render(element:HTMLElement, displayText:string):void {
    const values = this.attribute;
    element.setAttribute('title', displayText);
    element.textContent = displayText;

    element.innerHTML = '';

    if (values.length === 0) {
      this.renderEmpty(element);
    } else {
      this.renderValues(values, element);
    }
  }

  protected renderValues(values:UserResource[], element:HTMLElement) {
    this.outlet = this.userDisplayPortal.create(element, values, true);
    this.portalCleanup.add(() => this.outlet.dispose());
  }
}
