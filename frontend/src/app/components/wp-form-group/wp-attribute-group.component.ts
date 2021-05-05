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

import { Component, Injector, Input, AfterViewInit } from '@angular/core';
import { I18nService } from 'core-app/modules/common/i18n/i18n.service';
import { FieldDescriptor, GroupDescriptor } from 'core-components/work-packages/wp-single-view/wp-single-view.component';
import { WorkPackageResource } from 'core-app/modules/hal/resources/work-package-resource';
import { EditFormComponent } from "core-app/modules/fields/edit/edit-form/edit-form.component";
import { UntilDestroyedMixin } from "core-app/helpers/angular/until-destroyed.mixin";
import { fromEvent } from "rxjs";
import { debounceTime } from "rxjs/operators";

@Component({
  selector: 'wp-attribute-group',
  templateUrl: './wp-attribute-group.template.html'
})
export class WorkPackageFormAttributeGroupComponent extends UntilDestroyedMixin implements AfterViewInit {
  @Input() public workPackage:WorkPackageResource;
  @Input() public group:GroupDescriptor;

  constructor(readonly I18n:I18nService,
              public wpEditForm:EditFormComponent,
              protected injector:Injector) {
    super();
  }

  ngAfterViewInit() {
    setTimeout(() => this.fixColumns());

    // Listen to resize event and fix column start again
    fromEvent(window, 'resize', { passive: true })
      .pipe(
        this.untilDestroyed(),
        debounceTime(250)
      )
      .subscribe(() => {
        this.fixColumns();
      });
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

  public fieldName(name:string) {
    if (name === 'startDate') {
      return 'combinedDate';
    } else {
      return name;
    }
  }

  /**
   * Fix the top of the columns after view has been loaded
   * to prevent columns from repositioning (e.g. when editing multi-select fields)
   */
  private fixColumns() {
    let lastOffset = 0;
    // Find corresponding HTML of attribute fields for each group
    const htmlAttributes = jQuery('div.attributes-group:contains(' + this.group.name + ')').find('.attributes-key-value');

    htmlAttributes.each(function() {
      const offset = jQuery(this).position().top;

      if (offset < lastOffset) {
        // Fix position of the column start
        jQuery(this).addClass('-column-start');
      }
      lastOffset = offset;
    });
  }
}