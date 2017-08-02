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

import {opWorkPackagesModule} from '../../../angular-modules';
import {scopedObservable} from '../../../helpers/angular-rx-utils';
import {debugLog} from '../../../helpers/debug_output';
import {WorkPackageResourceInterface} from '../../api/api-v3/hal-resources/work-package-resource.service';
import {DisplayField} from '../../wp-display/wp-display-field/wp-display-field.module';
import {WorkPackageDisplayFieldService} from '../../wp-display/wp-display-field/wp-display-field.service';
import {WorkPackageCacheService} from '../work-package-cache.service';
import {WorkPackageEditFieldGroupController} from "../../wp-edit/wp-edit-field/wp-edit-field-group.directive";
import {
  WorkPackageEditingService
} from '../../wp-edit-form/work-package-editing-service';
import {States} from '../../states.service';

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
}

export class WorkPackageSingleViewController {
  public wpEditFieldGroup:WorkPackageEditFieldGroupController;
  public workPackage:WorkPackageResourceInterface;

  // Grouped fields returned from API
  public groupedFields:GroupDescriptor[] = [];
  // Special fields (project, type)
  public specialFields:FieldDescriptor[] = [];
  public text:any;
  public scope:any;

  protected firstTimeFocused:boolean = false;

  constructor(protected $scope:ng.IScope,
              protected $rootScope:ng.IRootScopeService,
              protected $stateParams:ng.ui.IStateParamsService,
              protected I18n:op.I18n,
              protected states:States,
              protected wpEditing:WorkPackageEditingService,
              protected wpDisplayField:WorkPackageDisplayFieldService,
              protected wpCacheService:WorkPackageCacheService) {
  }

  public initialize() {
    // Create I18n texts
    this.setupI18nTexts();

    if (this.workPackage.attachments) {
      this.workPackage.attachments.updateElements();
    }

    scopedObservable(this.$scope, this.wpEditing.temporaryEditResource(this.workPackage.id).values$())
      .subscribe((resource:WorkPackageResourceInterface) => {
        // Prepare the fields that are required always
        this.specialFields = this.getFields(resource, ['project', 'status']);

        // Get attribute groups if they are available (in project context)
        const attributeGroups = resource.schema._attributeGroups;

        if (!attributeGroups) {
          this.groupedFields = [];
          return;
        }

        this.groupedFields = attributeGroups.map((groups:any[]) => {
          return {
            name: groups[0],
            members: this.getFields(resource, groups[1])
          };
        });
      });
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

  /*
   * Returns the work package label
   */
  public get idLabel() {
    const label = this.I18n.t('js.label_work_package');
    return `${label} #${this.workPackage.id}`;
  }

  private setupI18nTexts() {
    this.text = {
      dropFiles: this.I18n.t('js.label_drop_files'),
      dropFilesHint: this.I18n.t('js.label_drop_files_hint'),
      fields: {
        description: this.I18n.t('js.work_packages.properties.description'),
      },
      date: {
        startDate: this.I18n.t('js.label_no_start_date'),
        dueDate: this.I18n.t('js.label_no_due_date')
      },
      infoRow: {
        createdBy: this.I18n.t('js.label_created_by'),
        lastUpdatedOn: this.I18n.t('js.label_last_updated_on')
      },
    };
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

function wpSingleViewDirective() {

  return {
    restrict: 'E',
    templateUrl: '/components/work-packages/wp-single-view/wp-single-view.directive.html',

    scope: {
      workPackage: '=?'
    },

    require: ['^wpEditFieldGroup'],
    link: (scope:any,
           element:ng.IAugmentedJQuery,
           attrs:any,
           controllers: [WorkPackageEditFieldGroupController]) => {
      scope.$ctrl.wpEditFieldGroup = controllers[0];
      scope.$ctrl.initialize();
    },
    bindToController: true,
    controller: WorkPackageSingleViewController,
    controllerAs: '$ctrl'
  };
}

opWorkPackagesModule.directive('wpSingleView', wpSingleViewDirective);
