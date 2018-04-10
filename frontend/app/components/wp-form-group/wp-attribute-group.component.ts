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

import {Component, Inject, Input, OnDestroy, OnInit} from '@angular/core';
import {I18nToken} from 'core-app/angular4-transition-utils';
import {WorkPackageEditFieldGroupComponent} from 'core-components/wp-edit/wp-edit-field/wp-edit-field-group.directive';
import {DisplayField} from 'core-components/wp-display/wp-display-field/wp-display-field.module';
import {WorkPackageResourceInterface} from 'core-components/api/api-v3/hal-resources/work-package-resource.service';
import {FieldDescriptor, GroupDescriptor} from 'core-components/work-packages/wp-single-view/wp-single-view.component';

@Component({
  template: require('!!raw-loader!./wp-attribute-group.template.html'),
  selector: 'wp-attribute-group',
})
export class WorkPackageFormAttributeGroupComponent {
  @Input() public workPackage:WorkPackageResourceInterface;
  @Input() public group:GroupDescriptor;

  public text = {
    date: {
      startDate: this.I18n.t('js.label_no_start_date'),
      dueDate: this.I18n.t('js.label_no_due_date')
    },
  };

  constructor(@Inject(I18nToken) readonly I18n:op.I18n,
              public wpEditFieldGroup:WorkPackageEditFieldGroupComponent) {
  }

  /**
   * Hide read-only fields, but only when in the create mode
   * @param {FieldDescriptor} field
   */
  public shouldHideField(descriptor:FieldDescriptor) {
    const field = descriptor.field || descriptor.fields![0];
    return this.wpEditFieldGroup.inEditMode && !field.writable;
  }
}
