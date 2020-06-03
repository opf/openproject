//-- copyright
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
//++

import {HalResource} from 'core-app/modules/hal/resources/hal-resource';
import {I18nService} from 'core-app/modules/common/i18n/i18n.service';
import {AttachmentCollectionResource} from 'core-app/modules/hal/resources/attachment-collection-resource';
import {CollectionResource} from 'core-app/modules/hal/resources/collection-resource';
import {TypeResource} from 'core-app/modules/hal/resources/type-resource';
import {RelationResource} from 'core-app/modules/hal/resources/relation-resource';
import {
  OpenProjectFileUploadService,
  UploadFile
} from 'core-components/api/op-file-upload/op-file-upload.service';
import {SchemaResource} from 'core-app/modules/hal/resources/schema-resource';
import {States} from 'core-components/states.service';
import {WorkPackageCacheService} from 'core-components/work-packages/work-package-cache.service';
import {SchemaCacheService} from 'core-components/schemas/schema-cache.service';
import {PathHelperService} from 'core-app/modules/common/path-helper/path-helper.service';
import {NotificationsService} from 'core-app/modules/common/notifications/notifications.service';
import {Attachable} from 'core-app/modules/hal/resources/mixins/attachable-mixin';
import {WorkPackageDmService} from "core-app/modules/hal/dm-services/work-package-dm.service";
import {FormResource} from "core-app/modules/hal/resources/form-resource";
import {InputState} from "reactivestates";
import {WorkPackagesActivityService} from "core-components/wp-single-view-tabs/activity-panel/wp-activity.service";
import {WorkPackageNotificationService} from "core-app/modules/work_packages/notifications/work-package-notification.service";
import {InjectField} from "core-app/helpers/angular/inject-field.decorator";

export interface WorkPackageResourceEmbedded {
  activities:CollectionResource;
  ancestors:WorkPackageResource[];
  assignee:HalResource|any;
  attachments:AttachmentCollectionResource;
  author:HalResource|any;
  availableWatchers:HalResource|any;
  category:HalResource|any;
  children:WorkPackageResource[];
  parent:WorkPackageResource|null;
  priority:HalResource|any;
  project:HalResource|any;
  relations:CollectionResource;
  responsible:HalResource|any;
  revisions:CollectionResource|any;
  status:HalResource|any;
  timeEntries:HalResource[]|any[];
  type:TypeResource;
  version:HalResource|any;
  watchers:CollectionResource;
  // For regular work packages
  startDate:string;
  dueDate:string;
  // Only for milestones
  date:string;
  relatedBy:RelationResource|null;
}

export interface WorkPackageResourceLinks extends WorkPackageResourceEmbedded {
  addAttachment(attachment:HalResource):Promise<any>;

  addChild(child:HalResource):Promise<any>;

  addComment(comment:unknown, headers?:any):Promise<any>;

  addRelation(relation:any):Promise<any>;

  addWatcher(watcher:HalResource):Promise<any>;

  changeParent(params:any):Promise<any>;

  copy():Promise<WorkPackageResource>;

  delete():Promise<any>;

  logTime():Promise<any>;

  move():Promise<any>;

  removeWatcher():Promise<any>;

  self():Promise<WorkPackageResource>;

  update(payload:any):Promise<FormResource<WorkPackageResource>>;

  updateImmediately(payload:any):Promise<WorkPackageResource>;

  watch():Promise<any>;
}

export interface WorkPackageLinksObject extends WorkPackageResourceLinks {
  schema:HalResource;
}

export class WorkPackageBaseResource extends HalResource {
  public $embedded:WorkPackageResourceEmbedded;
  public $links:WorkPackageLinksObject;
  public subject:string;
  public updatedAt:Date;
  public lockVersion:number;
  public description:any;
  public activities:CollectionResource;
  public attachments:AttachmentCollectionResource;

  public overriddenSchema:SchemaResource|undefined = undefined;
  @InjectField() I18n:I18nService;
  @InjectField() tates:States;
  @InjectField() wpActivity:WorkPackagesActivityService;
  @InjectField() workPackageDmService:WorkPackageDmService;
  @InjectField() wpCacheService:WorkPackageCacheService;
  @InjectField() schemaCacheService:SchemaCacheService;
  @InjectField() NotificationsService:NotificationsService;
  @InjectField() workPackageNotificationService:WorkPackageNotificationService;
  @InjectField() pathHelper:PathHelperService;
  @InjectField() opFileUpload:OpenProjectFileUploadService;

  readonly attachmentsBackend = true;

  /**
   * Return the ids of all its ancestors, if any
   */
  public get ancestorIds():string[] {
    const ancestors = (this as any).ancestors;
    return ancestors.map((el:WorkPackageResource) => el.id!);
  }

  public get isReadonly():boolean {
    return this.status && this.status.isReadonly;
  }

  /**
   * Return "<type name>: <subject> (#<id>)" if type and id are known.
   */
  public subjectWithType(truncateSubject:number = 40):string {
    const type = this.type ? `${this.type.name}: ` : '';
    const subject = this.subjectWithId(truncateSubject);

    return `${type}${subject}`;
  }

  /**
   * Return "<subject> (#<id>)" if the id is known.
   */
  public subjectWithId(truncateSubject:number = 40):string {
    const id = this.isNew ? '' : ` (#${this.id})`;
    const subject = _.truncate(this.subject, {length: truncateSubject});

    return `${subject}${id}`;
  }

  public get isMilestone():boolean {
    return this.schema.hasOwnProperty('date');
  }

  public get isLeaf():boolean {
    var children = this.$links.children;
    return !(children && children.length > 0);
  }

  /**
   * Return whether the user in general has permission to edit the work package.
   * This check is required, but not sufficient to check all attribute restrictions.
   *
   * Use +isAttributeEditable(property)+ for this case.
   */
  public get isEditable() {
    return this.isNew || !!this.$links.update;
  }

  public previewPath() {
    if (!this.isNew) {
      return this.pathHelper.api.v3.work_packages.id(this.id!).path;
    } else {
      return super.previewPath();
    }
  }

  public getEditorTypeFor(fieldName:string):"full"|"constrained" {
    return fieldName === 'description' ? 'full' : 'constrained';
  }

  /**
   * Return whether the work package is editable with the user's permission
   * on the given work package attribute.
   *
   * @param property
   */
  public isAttributeEditable(property:string):boolean {
    const fieldSchema = this.schema[property];

    return this.isEditable &&
      fieldSchema &&
      fieldSchema.writable &&
      (!this.isReadonly || property === 'status');
  }

  private performUpload(files:UploadFile[]) {
    let href = '';

    if (this.isNew) {
      href = this.pathHelper.api.v3.attachments.path;
    } else {
      href = this.attachments.$href!;
    }

    return this.opFileUpload.uploadAndMapResponse(href, files);
  }

  public getSchemaName(name:string):string {
    if (this.isMilestone && (name === 'startDate' || name === 'dueDate')) {
      return 'date';
    } else {
      return name;
    }
  }

  public isParentOf(otherWorkPackage:WorkPackageResource) {
    return otherWorkPackage.parent?.$links.self.$link.href === this.$links.self.$link.href;
  }

  /**
   * Invalidate a set of linked resources of this work package.
   * And inform the cache service about the work package update.
   *
   * Return a promise that returns the linked resources as properties.
   * Return a rejected promise, if the resource is not a property of the work package.
   */
  public updateLinkedResources(...resourceNames:string[]):Promise<any> {
    const resources:{ [id:string]:Promise<HalResource> } = {};

    resourceNames.forEach(name => {
      const linked = this[name];
      resources[name] = linked ? linked.$update() : Promise.reject(undefined);
    });

    const promise = Promise.all(_.values(resources));
    promise.then(() => {
      this.wpCacheService.touch(this.id!);
    });

    return promise;
  }

  /**
   * Assign values from the form for a newly created work package resource.
   * @param form
   */
  public initializeNewResource(form:FormResource) {
    this.overriddenSchema = form.schema;
    this.$source.id = 'new';

    // Ensure type is set to identify the resource
    this._type = 'WorkPackage';

    // Since the ID will change upon saving, keep track of the WP
    // with the actual creation date
    this.__initialized_at = Date.now();

    // Set update link to form
    this['update'] = this.$links.update = form.$links.self;
    // Use POST /work_packages for saving link
    this['updateImmediately'] = this.$links.updateImmediately = (payload) => {
      return this.workPackageDmService.createWorkPackage(payload);
    };
  }

  public $initialize(source:any) {
    super.$initialize(source);

    let attachments:any = this.attachments || {$source: {}, elements: []};
    this.attachments = new AttachmentCollectionResource(
      this.injector,
      // Attachments MAY be an array if we're building from a form
      _.get(attachments, '$source', attachments),
      false,
      this.halInitializer,
      'HalResource'
    );
  }

  /**
   * Exclude the schema _link from the linkable Resources.
   */
  public $linkableKeys():string[] {
    return _.without(super.$linkableKeys(), 'schema');
  }

  /**
   * Get the current schema, assuming it is either:
   * 1. Overridden by the current loaded form
   * 2. Available as a schema state
   *
   * If it is neither, an exception is raised.
   */
  public get schema():SchemaResource {
    if (this.hasOverriddenSchema) {
      return this.overriddenSchema!;
    }

    const state = this.schemaCacheService.state(this as any);

    if (!state.hasValue()) {
      throw `Accessing schema of ${this.id} without it being loaded.`;
    }

    return state.value!;
  }

  /**
   * Return the associated state to this HAL resource, if any.
   */
  public get state():InputState<this> {
    return this.states.workPackages.get(this.id!) as any;
  }

  /**
   * Update the state
   */
  public push(newValue:this):Promise<unknown> {
    this.wpActivity.clear(newValue.id!);

    // If there is a parent, its view has to be updated as well
    if (newValue.parent) {
      this.wpCacheService.require(newValue.parent.id!, true);
    }

    return this.wpCacheService.updateWorkPackage(newValue as any);
  }

  public get hasOverriddenSchema():boolean {
    return this.overriddenSchema != null;
  }
}

export const WorkPackageResource = Attachable(WorkPackageBaseResource);

export interface WorkPackageResource extends WorkPackageBaseResource, WorkPackageResourceLinks, WorkPackageResourceEmbedded {
}
