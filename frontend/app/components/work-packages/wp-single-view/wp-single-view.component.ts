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
import {PathHelperService} from 'core-components/common/path-helper/path-helper.service';
import {WorkPackageEditFieldGroupComponent} from 'core-components/wp-edit/wp-edit-field/wp-edit-field-group.directive';
import {componentDestroyed} from 'ng2-rx-componentdestroyed';
import {takeUntil} from 'rxjs/operators';
import {debugLog} from '../../../helpers/debug_output';
import {WorkPackageResourceInterface} from '../../api/api-v3/hal-resources/work-package-resource.service';
import {CurrentProjectService} from '../../projects/current-project.service';
import {States} from '../../states.service';
import {DisplayField} from '../../wp-display/wp-display-field/wp-display-field.module';
import {WorkPackageDisplayFieldService} from '../../wp-display/wp-display-field/wp-display-field.service';
import {WorkPackageEditingService} from '../../wp-edit-form/work-package-editing-service';
import {WorkPackageCacheService} from '../work-package-cache.service';

interface FieldDescriptor {
  name:string;
  label:string;
  field?:DisplayField;
  fields?:DisplayField[];
  spanAll:boolean;
  multiple:boolean;
}

interface GroupDescriptor {
  name:string;
  members:FieldDescriptor[];
  type:string;
}

@Component({
  template: require('!!raw-loader!./wp-single-view.html'),
  selector: 'wp-single-view',
})
export class WorkPackageSingleViewComponent implements OnInit, OnDestroy {
  @Input('workPackage') public workPackage:WorkPackageResourceInterface;

  // Grouped fields returned from API
  public groupedFields:GroupDescriptor[] = [];
  public projectContext:{
    matches:boolean,
    href:string | null,
    field?:FieldDescriptor[]
  };
  public text = {
    attachments: {
      label: this.I18n.t('js.label_attachments')
    },
    project: {
      required: this.I18n.t('js.project.required_outside_context'),
      context: this.I18n.t('js.project.context'),
      switchTo: this.I18n.t('js.project.click_to_switch_context'),
    },

    fields: {
      description: this.I18n.t('js.work_packages.properties.description'),
    },
    description: {
      placeholder: this.I18n.t('js.work_packages.placeholders.description')
    },
    infoRow: {
      createdBy: this.I18n.t('js.label_created_by'),
      lastUpdatedOn: this.I18n.t('js.label_last_updated_on')
    },
  };

  protected firstTimeFocused:boolean = false;

  constructor(@Inject(I18nToken) readonly I18n:op.I18n,
              public wpEditFieldGroup:WorkPackageEditFieldGroupComponent,
              protected currentProject:CurrentProjectService,
              protected PathHelper:PathHelperService,
              protected states:States,
              protected wpEditing:WorkPackageEditingService,
              protected wpDisplayField:WorkPackageDisplayFieldService,
              protected wpCacheService:WorkPackageCacheService) {
  }

  public ngOnInit() {
    if (this.workPackage.attachments) {
      this.workPackage.attachments.updateElements();
    }

    this.wpEditing.temporaryEditResource(this.workPackage.id)
      .values$()
      .pipe(
        takeUntil(componentDestroyed(this))
      )
      .subscribe((resource:WorkPackageResourceInterface) => {
        // Prepare the fields that are required always
        const isNew = this.workPackage.isNew;

        if (!resource.project) {
          this.projectContext = {matches: false, href: null};
        } else {
          this.projectContext = {
            href: this.PathHelper.projectWorkPackagePath(resource.project.idFromLink, this.workPackage.id),
            matches: resource.project.href === this.currentProject.apiv3Path
          };
        }

        if (isNew && !this.currentProject.inProjectContext) {
          this.projectContext.field = this.getFields(resource, ['project']);
        }

        // Get attribute groups if they are available (in project context)
        const attributeGroups = resource.schema._attributeGroups;

        if (!attributeGroups) {
          this.groupedFields = [];
          return;
        }

        this.groupedFields = attributeGroups.map((group:any) => {
          if (group._type === 'WorkPackageFormAttributeGroup') {
            return {
              name: group.name,
              members: this.getFields(resource, group.attributes),
              type: group._type
            };
          } else {
            return {
              name: group.name,
              query: group._embedded.query,
              members: [group._embedded.query],
              type: group._type
            };
          }
        });
      });
  }

  ngOnDestroy() {
    // Nothing to do
  }

  /**
   * Returns whether a group should be hidden due to being empty
   * (e.g., consists only of CFs and none of them are active in this project.
   */
  public shouldHideGroup(group:GroupDescriptor) {
    // Hide if the group is empty
    return group.members.length === 0;
  }

  /**
   * Hide read-only fields, but only when in the create mode
   * @param {FieldDescriptor} field
   */
  public shouldHideField(descriptor:FieldDescriptor) {
    const field = descriptor.field || descriptor.fields![0];
    return this.wpEditFieldGroup.inEditMode && !field.writable;
  }

  /**
   * angular 2 doesn't support track by property any more but requires a custom function
   * https://github.com/angular/angular/issues/12969
   * @param index
   * @param elem
   */
  public trackByName(_index:number, elem:{ name:string }) {
    return elem.name;
  }

  /*
   * Returns the work package label
   */
  public get idLabel() {
    return `#${this.workPackage.id}`;
  }

  public get projectContextText():string {
    let id = this.workPackage.project.idFromLink;
    let projectPath = this.PathHelper.projectPath(id);
    let project = `<a href="${projectPath}">${this.workPackage.project.name}<a>`;
    return this.I18n.t('js.project.work_package_belongs_to', {projectname: project});
  }

  /**
   * Maps the grouped fields into their display fields.
   * May return multiple fields (for the date virtual field).
   */
  private getFields(resource:WorkPackageResourceInterface, fieldNames:string[]):FieldDescriptor[] {
    const descriptors:FieldDescriptor[] = [];

    fieldNames.forEach((fieldName:string) => {
      if (fieldName === 'date') {
        descriptors.push(this.getDateField(resource));
        return;
      }

      if (!resource.schema[fieldName]) {
        debugLog('Unknown field for current schema', fieldName);
        return;
      }

      const field:DisplayField = this.displayField(resource, fieldName);
      descriptors.push({
        name: fieldName,
        label: field.label,
        multiple: false,
        spanAll: field.isFormattable,
        field: field
      });
    });

    return descriptors;
  }

  /**
   * We need to discern between milestones, which have a single
   * 'date' field vs. all other types which should display a
   * combined 'start' and 'due' date field.
   */
  private getDateField(resource:WorkPackageResourceInterface):FieldDescriptor {
    let object:any = {
      name: 'date',
      label: this.I18n.t('js.work_packages.properties.date'),
      multiple: false
    };

    if (resource.schema.hasOwnProperty('date')) {
      object.field = this.displayField(resource, 'date');
    } else {
      object.fields = [this.displayField(resource, 'startDate'), this.displayField(resource, 'dueDate')];
      object.multiple = true;
    }

    return object;
  }

  private displayField(resource:WorkPackageResourceInterface, name:string):DisplayField {
    return this.wpDisplayField.getField(
      resource,
      name,
      resource.schema[name]
    ) as DisplayField;
  }

  private get form() {
    return this.wpEditFieldGroup.form;
  }

}
