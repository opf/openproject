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
import {I18nService} from 'core-app/modules/common/i18n/i18n.service';
import {PathHelperService} from 'core-app/modules/common/path-helper/path-helper.service';
import {componentDestroyed} from 'ng2-rx-componentdestroyed';
import {distinctUntilChanged, map, takeUntil} from 'rxjs/operators';
import {debugLog} from '../../../helpers/debug_output';
import {CurrentProjectService} from '../../projects/current-project.service';
import {States} from '../../states.service';
import {WorkPackageResource} from 'core-app/modules/hal/resources/work-package-resource';
import {WorkPackageEditingService} from '../../wp-edit-form/work-package-editing-service';
import {WorkPackageCacheService} from '../work-package-cache.service';
import {input, InputState} from 'reactivestates';
import {DisplayFieldService} from "core-app/modules/fields/display/display-field.service";
import {DisplayField} from "core-app/modules/fields/display/display-field.module";
import {QueryResource} from "core-app/modules/hal/resources/query-resource";
import {IWorkPackageEditingServiceToken} from "../../wp-edit-form/work-package-editing.service.interface";
import {WorkPackageTableHighlightingService} from "core-components/wp-fast-table/state/wp-table-highlighting.service";
import {WorkPackageInlineHighlightingService} from "core-components/wp-fast-table/state/wp-table-inline-highlighting.service";

export interface FieldDescriptor {
  name:string;
  label:string;
  field?:DisplayField;
  fields?:DisplayField[];
  spanAll:boolean;
  multiple:boolean;
}

export interface GroupDescriptor {
  name:string;
  members:FieldDescriptor[];
  query?:QueryResource;
  type:string;
}

export interface ResourceContextChange {
  isNew:boolean;
  schema:string|null;
  project:string|null;
}

@Component({
  templateUrl: './wp-single-view.html',
  selector: 'wp-single-view',
})
export class WorkPackageSingleViewComponent implements OnInit, OnDestroy {
  @Input('workPackage') public workPackage:WorkPackageResource;

  // Grouped fields returned from API
  public groupedFields:GroupDescriptor[] = [];

  // State updated when structural changes to the single view may occur.
  // (e.g., when changing the type or project context).
  public resourceContextChange:InputState<ResourceContextChange> = input<ResourceContextChange>();

  // Project context as an indicator
  // when editing the work package in a different project
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

  constructor(readonly I18n:I18nService,
              protected currentProject:CurrentProjectService,
              protected PathHelper:PathHelperService,
              protected states:States,
              @Inject(IWorkPackageEditingServiceToken) protected wpEditing:WorkPackageEditingService,
              protected displayFieldService:DisplayFieldService,
              protected wpCacheService:WorkPackageCacheService) {
  }

  public ngOnInit() {
    if (this.workPackage.attachments) {
      this.workPackage.attachments.updateElements();
    }

    // Whenever the resource context changes in any way,
    // update the visible fields.
    this.resourceContextChange
      .values$()
      .pipe(
        takeUntil(componentDestroyed(this)),
        distinctUntilChanged<ResourceContextChange>((a, b) => _.isEqual(a, b)),
        map(() => this.wpEditing.temporaryEditResource(this.workPackage.id).value!)
      )
      .subscribe((resource:WorkPackageResource) => {
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

        const attributeGroups = resource.schema._attributeGroups;
        this.groupedFields = this.rebuildGroupedFields(resource, attributeGroups);
      });

    // Update the resource context on every update to the temporary resource.
    // This allows detecting a changed type value in a new work package.
    this.wpEditing.temporaryEditResource(this.workPackage.id)
      .values$()
      .pipe(
        takeUntil(componentDestroyed(this))
      )
      .subscribe((resource:WorkPackageResource) => {
        this.resourceContextChange.putValue(this.contextFrom(resource));
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
   *
   * @param attributeGroups
   * @returns {any}
   */
  private rebuildGroupedFields(resource:WorkPackageResource, attributeGroups:any) {
    if (!attributeGroups) {
      return [];
    }

    return attributeGroups.map((group:any) => {
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
  }

  /**
   * Maps the grouped fields into their display fields.
   * May return multiple fields (for the date virtual field).
   */
  private getFields(resource:WorkPackageResource, fieldNames:string[]):FieldDescriptor[] {
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
  private getDateField(resource:WorkPackageResource):FieldDescriptor {
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

  /**
   * Get the current resource context change from the WP resource.
   * Used to identify changes in the schema or project that may result in visual changes
   * to the single view.
   *
   * @param {WorkPackageResource} resource
   * @returns {SchemaContext}
   */
  private contextFrom(resource:WorkPackageResource):ResourceContextChange {
    let schema = resource.schema;

    let schemaHref:string|null = null;
    let projectHref:string|null = resource.project && resource.project.href;

    if (schema.baseSchema) {
      schemaHref = schema.baseSchema.href;
    } else {
      schemaHref = schema.href;
    }


    return {
      isNew: resource.isNew,
      schema: schemaHref,
      project: projectHref
    };
  }

  private displayField(resource:WorkPackageResource, name:string):DisplayField {
    return this.displayFieldService.getField(
      resource,
      name,
      resource.schema[name]
    ) as DisplayField;
  }
}
