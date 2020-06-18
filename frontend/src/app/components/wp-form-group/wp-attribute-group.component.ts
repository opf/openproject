// -- copyright
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
// ++

import {Component, Injector, Input} from '@angular/core';
import {I18nService} from 'core-app/modules/common/i18n/i18n.service';
import {FieldDescriptor, GroupDescriptor} from 'core-components/work-packages/wp-single-view/wp-single-view.component';
import {WorkPackageResource} from 'core-app/modules/hal/resources/work-package-resource';
import {EditFormComponent} from "core-app/modules/fields/edit/edit-form/edit-form.component";

@Component({
  selector: 'wp-attribute-group',
  templateUrl: './wp-attribute-group.template.html'
})
export class WorkPackageFormAttributeGroupComponent {
  @Input() public workPackage:WorkPackageResource;
  @Input() public group:GroupDescriptor;

  constructor(readonly I18n:I18nService,
              public wpeditForm:EditFormComponent,
              protected injector:Injector) {
  }

  public trackByName(_index:number, elem:{ name:string }) {
    return elem.name;
  }

  /**
   * Hide read-only fields, but only when in the create mode
   * @param {FieldDescriptor} field
   */
  public shouldHideField(descriptor:FieldDescriptor) {
    const field = descriptor.field || descriptor.fields![0];
    return this.wpeditForm.editMode && !field.writable;
  }
}
