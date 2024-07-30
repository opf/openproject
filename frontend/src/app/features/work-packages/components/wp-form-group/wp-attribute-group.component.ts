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

import { Component, HostBinding, Injector, Input, ViewEncapsulation } from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { EditFormComponent } from 'core-app/shared/components/fields/edit/edit-form/edit-form.component';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import {
  FieldDescriptor,
  GroupDescriptor,
} from 'core-app/features/work-packages/components/wp-single-view/wp-single-view.component';

@Component({
  selector: 'wp-attribute-group',
  templateUrl: './wp-attribute-group.template.html',
  styleUrls: ['./wp-attribute-group.component.sass'],
  encapsulation: ViewEncapsulation.None,
})
export class WorkPackageFormAttributeGroupComponent extends UntilDestroyedMixin {
  @HostBinding('class.wp-attribute-group') className = true;
  @HostBinding('class.attributes-group--attributes') parentClassName = true;

  @Input() public workPackage:WorkPackageResource;

  @Input() public group:GroupDescriptor;

  constructor(
    readonly I18n:I18nService,
    public wpEditForm:EditFormComponent,
    protected injector:Injector,
  ) {
    super();
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
    return this.wpEditForm.editMode && !field.writable;
  }
}
