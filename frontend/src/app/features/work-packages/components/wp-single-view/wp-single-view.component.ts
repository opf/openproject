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

import {
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  ElementRef,
  Injector,
  Input,
  OnInit,
} from '@angular/core';
import { StateService } from '@uirouter/core';
import { BehaviorSubject, combineLatest } from 'rxjs';
import { distinctUntilChanged, first, map } from 'rxjs/operators';

import { I18nService } from 'core-app/core/i18n/i18n.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import {
  HalResourceEditingService,
} from 'core-app/shared/components/fields/edit/services/hal-resource-editing.service';
import { DisplayFieldService } from 'core-app/shared/components/fields/display/display-field.service';
import { DisplayField } from 'core-app/shared/components/fields/display/display-field.module';
import { QueryResource } from 'core-app/features/hal/resources/query-resource';
import { HookService } from 'core-app/features/plugins/hook-service';
import { WorkPackageChangeset } from 'core-app/features/work-packages/components/wp-edit/work-package-changeset';
import { randomString } from 'core-app/shared/helpers/random-string';
import { HalResourceService } from 'core-app/features/hal/services/hal-resource.service';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import { States } from 'core-app/core/states/states.service';
import { SchemaCacheService } from 'core-app/core/schemas/schema-cache.service';
import { debugLog } from 'core-app/shared/helpers/debug_output';
import { ProjectsResourceService } from 'core-app/core/state/projects/projects.service';
import { CurrentUserService } from 'core-app/core/current-user/current-user.service';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { ProjectStoragesResourceService } from 'core-app/core/state/project-storages/project-storages.service';
import { IProjectStorage } from 'core-app/core/state/project-storages/project-storage.model';
import idFromLink from 'core-app/features/hal/helpers/id-from-link';
import isNewResource from 'core-app/features/hal/helpers/is-new-resource';

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
  templateUrl: './wp-single-view.component.html',
  selector: 'wp-single-view',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class WorkPackageSingleViewComponent extends UntilDestroyedMixin implements OnInit {
  @Input() public workPackage:WorkPackageResource;

  /** Should we show the project field */
  @Input() public showProject = false;

  // Grouped fields returned from API
  public groupedFields:GroupDescriptor[] = [];

  // Project context as an indicator
  // when editing the work package in a different project
  public projectContext:{
    matches:boolean,
    id:string|null,
    href:string|null,
    field?:FieldDescriptor[]
  };

  public text = {
    attachments: {
      label: this.I18n.t('js.label_attachments'),
    },
    files: {
      label: this.I18n.t('js.work_packages.tabs.files'),
    },
    project: {
      required: this.I18n.t('js.project.required_outside_context'),
    },

    fields: {
      description: this.I18n.t('js.work_packages.properties.description'),
    },
    infoRow: {
      createdBy: this.I18n.t('js.label_created_by'),
      lastUpdatedOn: this.I18n.t('js.label_last_updated_on'),
    },
  };

  public isNewResource:boolean;

  public uiSelfRef:string;

  $element:JQuery;

  projectStorages = new BehaviorSubject<IProjectStorage[]>([]);

  constructor(
    protected readonly injector:Injector,
    private readonly states:States,
    private readonly I18n:I18nService,
    private readonly hook:HookService,
    private readonly $state:StateService,
    private readonly elementRef:ElementRef,
    private readonly cdRef:ChangeDetectorRef,
    private readonly PathHelper:PathHelperService,
    private readonly schemaCache:SchemaCacheService,
    private readonly currentProject:CurrentProjectService,
    private readonly halEditing:HalResourceEditingService,
    private readonly halResourceService:HalResourceService,
    private readonly currentUserService:CurrentUserService,
    private readonly displayFieldService:DisplayFieldService,
    private readonly projectsResourceService:ProjectsResourceService,
    private readonly projectStoragesService:ProjectStoragesResourceService,
  ) {
    super();
  }

  public ngOnInit():void {
    this.$element = jQuery(this.elementRef.nativeElement as HTMLElement);

    this.isNewResource = isNewResource(this.workPackage);

    this.uiSelfRef = this.$state.$current.name;

    const change = this.halEditing.changeFor<WorkPackageResource, WorkPackageChangeset>(this.workPackage);
    this.refresh(change);

    // Whenever the temporary resource changes in any way,
    // update the visible fields.
    this.halEditing
      .temporaryEditResource(this.workPackage)
      .values$()
      .pipe(
        this.untilDestroyed(),
        map((resource) => this.contextFrom(resource)),
        distinctUntilChanged<ResourceContextChange>((a, b) => _.isEqual(a, b)),
        map(() => this.halEditing.changeFor(this.workPackage)),
      )
      .subscribe((changeset:WorkPackageChangeset) => this.refresh(changeset));
  }

  private refresh(change:WorkPackageChangeset) {
    // Prepare the fields that are required always
    const resource = change.projectedResource;

    if (!resource.project) {
      this.projectContext = { matches: false, href: null, id: null };
    } else {
      const project = resource.project as unknown&{ href:string, id:string };
      const workPackageId = this.workPackage.id;
      if (!workPackageId) {
        throw new Error('work package id is invalid');
      }

      this.projectContext = {
        id: project.id,
        href: this.PathHelper.projectWorkPackagePath(project.id, workPackageId),
        matches: project.href === this.currentProject.apiv3Path,
      };
    }

    if (isNewResource(resource)) {
      this.updateWorkPackageCreationState(change);
    }

    // eslint-disable-next-line no-underscore-dangle
    this.groupedFields = this.rebuildGroupedFields(change, this.schema(resource)._attributeGroups) as GroupDescriptor[];
    this.cdRef.detectChanges();
  }

  private updateWorkPackageCreationState(change:WorkPackageChangeset) {
    const resource = change.projectedResource;
    if (!this.currentProject.inProjectContext) {
      this.projectContext.field = this.getFields(change, ['project']);
      this.workPackage.project = resource.project as HalResource;
    }

    if (resource.project === null) {
      this.projectStorages.next([]);
    } else {
      const project = resource.project as unknown&{ href:string, id:string };
      combineLatest([
        this.projectsResourceService.requireEntity(project.href),
        this.projectStoragesService.requireCollection({ filters: [['projectId', '=', [project.id]]] }),
        this.currentUserService.hasCapabilities$('file_links/manage', project.id),
      ])
        .pipe(
          map(([p, projectStorages, manageFileLinks]) => {
            if (!p._links.storages || !manageFileLinks) {
              return [];
            }

            return projectStorages;
          }),
          first(),
        )
        .subscribe((ps) => {
          this.projectStorages.next(ps);
        });
    }
  }

  /**
   * Returns whether a group should be hidden due to being empty
   * (e.g., consists only of CFs and none of them are active in this project.
   */
  public shouldHideGroup(group:GroupDescriptor):boolean {
    // Hide if the group is empty
    const isEmpty = group.members.length === 0;

    // Is a query in a new screen
    const queryInNew = isNewResource(this.workPackage) && !!group.query;

    return isEmpty || queryInNew;
  }

  /**
   * angular 2 doesn't support track by property any more but requires a custom function
   * https://github.com/angular/angular/issues/12969
   * @param _index
   * @param elem
   */
  public trackByName(_index:number, elem:{ name:string }):string {
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
  public get idLabel():string {
    return `#${this.workPackage.id || ''}`;
  }

  public showSwitchToProjectBanner():boolean {
    return !this.isNewResource && this.projectContext && !this.projectContext.matches;
  }

  public get switchToProjectText():string {
    const id = idFromLink(this.workPackage.project.href);
    const projectPath = this.PathHelper.projectPath(id);
    const projectName = this.workPackage.project.name as string;
    const project = `<a href="${projectPath}" class="project-context--switch-link">${projectName}<a>`;
    return this.I18n.t('js.project.click_to_switch_to_project', { projectname: project });
  }

  showTwoColumnLayout():boolean {
    return this.$element[0].getBoundingClientRect().width > 750;
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
          isolated: false,
        };
      }
      return {
        name: group.name,
        id: groupId || randomString(16),
        query: this.halResourceService.createHalResourceOfClass(QueryResource, group._embedded.query),
        relationType: group.relationType,
        members: [group._embedded.query],
        type: group._type,
        isolated: true,
      };
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
        field,
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
    const object:FieldDescriptor = {
      name: 'date',
      label: this.I18n.t('js.work_packages.properties.date'),
      spanAll: false,
      multiple: false,
    };

    if (change.schema.ofProperty('date')) {
      object.field = this.displayField(change, 'date');
    } else {
      object.field = this.displayField(change, 'combinedDate');
    }

    return object;
  }

  /**
   * Get the current resource context change from the WP resource.
   * Used to identify changes in the schema or project that may result in visual changes
   * to the single view.
   *
   * @param {WorkPackage} workPackage
   * @returns {ResourceContextChange}
   */
  private contextFrom(workPackage:WorkPackageResource):ResourceContextChange {
    const schema = this.schema(workPackage);

    let schemaHref:string|null;
    const projectHref:string|null = workPackage.project && workPackage.project.href;

    if (schema.baseSchema) {
      schemaHref = schema.baseSchema.href;
    } else {
      schemaHref = schema.href;
    }

    return {
      isNew: workPackage.isNew,
      schema: schemaHref,
      project: projectHref,
    };
  }

  private displayField(change:WorkPackageChangeset, name:string):DisplayField {
    return this.displayFieldService.getField(
      change.projectedResource,
      name,
      change.schema.ofProperty(name),
      { container: 'single-view', injector: this.injector, options: {} },
    );
  }

  private getAttributesGroupId(group:any):string {
    const overflowingIdentifier = this.$element
      .find(`[data-group-name=\'${group.name}\']`)
      .data(overflowingContainerAttribute);

    if (overflowingIdentifier) {
      return overflowingIdentifier.replace('.__overflowing_', '');
    }
    return '';
  }

  private schema(resource:WorkPackageResource) {
    if (this.halEditing.typedState(resource).hasValue()) {
      return this.halEditing.typedState(this.workPackage).value!.schema;
    }
    return this.schemaCache.of(resource);
  }
}
