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

import {
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  ElementRef,
  Injector,
  Input,
  OnInit
} from '@angular/core';
import { I18nService } from 'core-app/modules/common/i18n/i18n.service';
import { PathHelperService } from 'core-app/modules/common/path-helper/path-helper.service';
import { distinctUntilChanged, map } from 'rxjs/operators';
import { debugLog } from '../../../helpers/debug_output';
import { CurrentProjectService } from '../../projects/current-project.service';
import { States } from '../../states.service';
import { WorkPackageResource } from 'core-app/modules/hal/resources/work-package-resource';

import { HalResourceEditingService } from "core-app/modules/fields/edit/services/hal-resource-editing.service";
import { DisplayFieldService } from 'core-app/modules/fields/display/display-field.service';
import { DisplayField } from 'core-app/modules/fields/display/display-field.module';
import { QueryResource } from 'core-app/modules/hal/resources/query-resource';
import { HookService } from 'core-app/modules/plugins/hook-service';
import { WorkPackageChangeset } from "core-components/wp-edit/work-package-changeset";
import { Subject } from "rxjs";
import { randomString } from "core-app/helpers/random-string";
import { BrowserDetector } from "core-app/modules/common/browser/browser-detector.service";
import { HalResourceService } from "core-app/modules/hal/services/hal-resource.service";
import { UntilDestroyedMixin } from "core-app/helpers/angular/until-destroyed.mixin";
import { SchemaCacheService } from "core-components/schemas/schema-cache.service";
import { ISchemaProxy } from "core-app/modules/hal/schemas/schema-proxy";
import { APIV3Service } from "core-app/modules/apiv3/api-v3.service";

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
  id:string;
  members:FieldDescriptor[];
  query?:QueryResource;
  relationType?:string;
  isolated:boolean;
  type:string;
}

export interface ResourceContextChange {
  isNew:boolean;
  schema:string|null;
  project:string|null;
}

export const overflowingContainerAttribute = 'overflowingIdentifier';

@Component({
  templateUrl: './wp-single-view.html',
  selector: 'wp-single-view',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class WorkPackageSingleViewComponent extends UntilDestroyedMixin implements OnInit {
  @Input() public workPackage:WorkPackageResource;

  /** Should we show the project field */
  @Input() public showProject = false;

  // Grouped fields returned from API
  public groupedFields:GroupDescriptor[] = [];

  // State updated when structural changes to the single view may occur.
  // (e.g., when changing the type or project context).
  public resourceContextChange = new Subject<ResourceContextChange>();

  // Project context as an indicator
  // when editing the work package in a different project
  public projectContext:{
    matches:boolean,
    href:string|null,
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
    infoRow: {
      createdBy: this.I18n.t('js.label_created_by'),
      lastUpdatedOn: this.I18n.t('js.label_last_updated_on')
    },
  };

  protected firstTimeFocused = false;

  $element:JQuery;

  constructor(readonly I18n:I18nService,
              protected currentProject:CurrentProjectService,
              protected PathHelper:PathHelperService,
              protected states:States,
              protected halEditing:HalResourceEditingService,
              protected halResourceService:HalResourceService,
              protected displayFieldService:DisplayFieldService,
              protected schemaCache:SchemaCacheService,
              protected hook:HookService,
              protected injector:Injector,
              protected cdRef:ChangeDetectorRef,
              readonly elementRef:ElementRef,
              readonly browserDetector:BrowserDetector) {
    super();
  }

  public ngOnInit() {
    this.$element = jQuery(this.elementRef.nativeElement);

    const change = this.halEditing.changeFor<WorkPackageResource, WorkPackageChangeset>(this.workPackage);
    this.resourceContextChange.next(this.contextFrom(change.projectedResource));
    this.refresh(change);

    // Whenever the resource context changes in any way,
    // update the visible fields.
    this.resourceContextChange
      .pipe(
        this.untilDestroyed(),
        distinctUntilChanged<ResourceContextChange>((a, b) => _.isEqual(a, b)),
        map(() => this.halEditing.changeFor(this.workPackage))
      )
      .subscribe((change:WorkPackageChangeset) => this.refresh(change));

    // Update the resource context on every update to the temporary resource.
    // This allows detecting a changed type value in a new work package.
    this.halEditing
      .temporaryEditResource(this.workPackage)
      .values$()
      .pipe(
        this.untilDestroyed()
      )
      .subscribe(resource => {
        this.resourceContextChange.next(this.contextFrom(resource));
      });
  }

  private refresh(change:WorkPackageChangeset) {
    // Prepare the fields that are required always
    const isNew = this.workPackage.isNew;
    const resource = change.projectedResource;

    if (!resource.project) {
      this.projectContext = { matches: false, href: null };
    } else {
      this.projectContext = {
        href: this.PathHelper.projectWorkPackagePath(resource.project.idFromLink, this.workPackage.id!),
        matches: resource.project.href === this.currentProject.apiv3Path
      };
    }

    if (isNew && !this.currentProject.inProjectContext) {
      this.projectContext.field = this.getFields(change, ['project']);
    }

    const attributeGroups = this.schema(resource)._attributeGroups;
    this.groupedFields = this.rebuildGroupedFields(change, attributeGroups);
    this.cdRef.detectChanges();
  }

  /**
   * Returns whether a group should be hidden due to being empty
   * (e.g., consists only of CFs and none of them are active in this project.
   */
  public shouldHideGroup(group:GroupDescriptor) {
    // Hide if the group is empty
    const isEmpty = group.members.length === 0;

    // Is a query in a new screen
    const queryInNew = this.workPackage.isNew && !!group.query;

    return isEmpty || queryInNew;
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

  /**
   * Allow other modules to register groups to insert into the single view
   */
  public prependedAttributeGroupComponents() {
    return this.hook.call('prependedAttributeGroups', this.workPackage);
  }

  public attributeGroupComponent(group:GroupDescriptor) {
    // we take the last registered group component which means that
    // plugins will have their say if they register for it.
    return this.hook.call('attributeGroupComponent', group, this.workPackage).pop() || null;
  }

  public attachmentListComponent() {
    // we take the last registered group component which means that
    // plugins will have their say if they register for it.
    return this.hook.call('workPackageAttachmentListComponent', this.workPackage).pop() || null;
  }

  public attachmentUploadComponent() {
    // we take the last registered group component which means that
    // plugins will have their say if they register for it.
    return this.hook.call('workPackageAttachmentUploadComponent', this.workPackage).pop() || null;
  }

  /*
   * Returns the work package label
   */
  public get idLabel() {
    return `#${this.workPackage.id}`;
  }

  public get projectContextText():string {
    const id = this.workPackage.project.idFromLink;
    const projectPath = this.PathHelper.projectPath(id);
    const project = `<a href="${projectPath}">${this.workPackage.project.name}<a>`;
    return this.I18n.t('js.project.work_package_belongs_to', { projectname: project });
  }

  /*
   * Show two column layout for new WP per default, but disable in MS Edge (#29941)
   */
  public get enableTwoColumnLayout() {
    return this.workPackage.isNew && !this.browserDetector.isEdge;
  }

  private rebuildGroupedFields(change:WorkPackageChangeset, attributeGroups:any) {
    if (!attributeGroups) {
      return [];
    }

    return attributeGroups.map((group:any) => {
      const groupId = this.getAttributesGroupId(group);

      if (group._type === 'WorkPackageFormAttributeGroup') {
        return {
          name: group.name,
          id: groupId || randomString(16),
          members: this.getFields(change, group.attributes),
          type: group._type,
          isolated: false
        };
      } else {
        return {
          name: group.name,
          id: groupId || randomString(16),
          query: this.halResourceService.createHalResourceOfClass(QueryResource, group._embedded.query),
          relationType: group.relationType,
          members: [group._embedded.query],
          type: group._type,
          isolated: true
        };
      }
    });
  }

  /**
   * Maps the grouped fields into their display fields.
   * May return multiple fields (for the date virtual field).
   */
  private getFields(change:WorkPackageChangeset, fieldNames:string[]):FieldDescriptor[] {
    const descriptors:FieldDescriptor[] = [];

    fieldNames.forEach((fieldName:string) => {
      if (fieldName === 'date') {
        descriptors.push(this.getDateField(change));
        return;
      }

      if (!change.schema.ofProperty(fieldName)) {
        debugLog('Unknown field for current schema', fieldName);
        return;
      }

      const field:DisplayField = this.displayField(change, fieldName);
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
  private getDateField(change:WorkPackageChangeset):FieldDescriptor {
    const object:any = {
      label: this.I18n.t('js.work_packages.properties.date'),
      multiple: false
    };

    if (change.schema.ofProperty('date')) {
      object.field = this.displayField(change, 'date');
      object.name = 'date';
    } else {
      object.field = this.displayField(change, 'combinedDate');
      object.name = 'combinedDate';
    }

    return object;
  }

  /**
   * Get the current resource context change from the WP resource.
   * Used to identify changes in the schema or project that may result in visual changes
   * to the single view.
   *
   * @param {WorkPackage} workPackage
   * @returns {SchemaContext}
   */
  private contextFrom(workPackage:WorkPackageResource):ResourceContextChange {
    const schema = this.schema(workPackage);

    let schemaHref:string|null = null;
    const projectHref:string|null = workPackage.project && workPackage.project.href;

    if (schema.baseSchema) {
      schemaHref = schema.baseSchema.href;
    } else {
      schemaHref = schema.href;
    }


    return {
      isNew: workPackage.isNew,
      schema: schemaHref,
      project: projectHref
    };
  }

  private displayField(change:WorkPackageChangeset, name:string):DisplayField {
    return this.displayFieldService.getField(
      change.projectedResource,
      name,
      change.schema.ofProperty(name),
      { container: 'single-view', injector: this.injector, options: {} }
    ) as DisplayField;
  }

  private getAttributesGroupId(group:any):string {
    const overflowingIdentifier = this.$element
      .find("[data-group-name=\'" + group.name + "\']")
      .data(overflowingContainerAttribute);

    if (overflowingIdentifier) {
      return overflowingIdentifier.replace('.__overflowing_', '');
    } else {
      return '';
    }
  }

  private schema(resource:WorkPackageResource) {
    if (this.halEditing.typedState(resource).hasValue()) {
      return this.halEditing.typedState(this.workPackage).value!.schema;
    } else {
      return this.schemaCache.of(resource) as ISchemaProxy;
    }
  }
}
