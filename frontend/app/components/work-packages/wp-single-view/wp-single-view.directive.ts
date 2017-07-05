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

import {opWorkPackagesModule} from "../../../angular-modules";
import {scopedObservable} from "../../../helpers/angular-rx-utils";
import {debugLog} from "../../../helpers/debug_output";
import {WorkPackageResourceInterface} from "../../api/api-v3/hal-resources/work-package-resource.service";
import {DisplayField} from "../../wp-display/wp-display-field/wp-display-field.module";
import {WorkPackageDisplayFieldService} from "../../wp-display/wp-display-field/wp-display-field.service";
import {WorkPackageEditFormController} from "../../wp-edit/wp-edit-form.directive";
import {WorkPackageCacheService} from "../work-package-cache.service";

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
  public formCtrl:WorkPackageEditFormController;
  public workPackage:WorkPackageResourceInterface;

  // Grouped fields returned from API
  public groupedFields:GroupDescriptor[] = [];
  // Special fields (project, type)
  public specialFields:FieldDescriptor[];
  public text:any;
  public scope:any;

  protected firstTimeFocused:boolean = false;

  constructor(protected $scope:ng.IScope,
              protected $rootScope:ng.IRootScopeService,
              protected $stateParams:ng.ui.IStateParamsService,
              protected I18n:op.I18n,
              protected wpDisplayField:WorkPackageDisplayFieldService,
              protected wpCacheService:WorkPackageCacheService) {

    // Create I18n texts
    this.setupI18nTexts();

    // Subscribe to work package
    const workPackageId = this.workPackage ? this.workPackage.id : $stateParams['workPackageId'];
    scopedObservable(
      $scope,
      wpCacheService.loadWorkPackage(workPackageId).values$())
      .subscribe((wp:WorkPackageResourceInterface) => {
        this.init(wp);
      });
  }

  public setFocus() {
    if (!this.firstTimeFocused) {
      this.firstTimeFocused = true;
      angular.element('.work-packages--details--subject .focus-input').focus();
    }
  }

  /**
   * Returns whether a group should be hidden due to being empty
   * (e.g., consists only of CFs and none of them are active in this project.
   */
  public shouldHideGroup(group:GroupDescriptor) {
    // Hide if the group is empty
    return group.members.length === 0;
  }

  public helpTextLabel(attribute:string) {
    return this.I18n.t('js.')
  }

  /*
   * Returns the work package label
   */
  public get idLabel() {
    const label = this.I18n.t('js.label_work_package');
    return `${label} #${this.workPackage.id}`;
  }

  private init(wp:WorkPackageResourceInterface) {
    this.workPackage = wp;

    if (this.workPackage.attachments) {
      this.workPackage.attachments.updateElements();
    }

    this.setFocus();

    // Accept the fields you always need to show.
    this.specialFields = this.getFields(['project', 'status']);

    // Get attribute groups if they are available (in project context)
    const attributeGroups = this.workPackage.schema._attributeGroups;

    if (!attributeGroups) {
      this.groupedFields = [];
      return;
    }

    this.groupedFields = attributeGroups.map((groups:any[]) => {
      return {
        name: groups[0],
        members: this.getFields(groups[1])
      };
    });

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
  private getFields(fieldNames:string[]):FieldDescriptor[] {
    const descriptors:FieldDescriptor[] = [];

    fieldNames.forEach((fieldName:string) => {
      if (fieldName === 'date') {
        descriptors.push(this.getDateField());
        return;
      }

      if (!this.workPackage.schema[fieldName]) {
        debugLog('Unknown field for current schema', fieldName);
        return;
      }

      const field:DisplayField = this.displayField(fieldName);
      descriptors.push({
        name: fieldName,
        label: field.label,
        multiple: false,
        spanAll: field.isLargeField,
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
  private getDateField():FieldDescriptor {
    let object:any = {
      name: 'date',
      label: this.I18n.t('js.work_packages.properties.date'),
      multiple: false
    };

    if (this.workPackage.isMilestone) {
      object.field = this.displayField('date');
    } else {
      object.fields = [this.displayField('startDate'), this.displayField('dueDate')];
      object.multiple = true;
    }

    return object;
  }

  private displayField(name:string):DisplayField {
    return this.wpDisplayField.getField(
      this.workPackage,
      name,
      this.workPackage.schema[name]
    ) as DisplayField;
  }

}

function wpSingleViewDirective() {

  function wpSingleViewLink(scope:ng.IScope,
                            element:ng.IAugmentedJQuery,
                            attrs:ng.IAttributes,
                            controllers:[WorkPackageEditFormController, WorkPackageSingleViewController]) {

    controllers[1].formCtrl = controllers[0];
  }

  return {
    restrict: 'E',
    templateUrl: '/components/work-packages/wp-single-view/wp-single-view.directive.html',

    scope: {
      workPackage: '=?'
    },

    require: ['^wpEditForm', 'wpSingleView'],
    link: wpSingleViewLink,

    bindToController: true,
    controller: WorkPackageSingleViewController,
    controllerAs: '$ctrl'
  };
}

opWorkPackagesModule.directive('wpSingleView', wpSingleViewDirective);
