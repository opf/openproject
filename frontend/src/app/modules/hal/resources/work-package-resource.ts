//-- copyright
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
import {ApiWorkPackagesService} from 'core-components/api/api-work-packages/api-work-packages.service';
import {WorkPackageCacheService} from 'core-components/work-packages/work-package-cache.service';
import {SchemaCacheService} from 'core-components/schemas/schema-cache.service';
import {WorkPackageNotificationService} from 'core-components/wp-edit/wp-notification.service';
import {PathHelperService} from 'core-app/modules/common/path-helper/path-helper.service';
import {NotificationsService} from 'core-app/modules/common/notifications/notifications.service';
import {Attachable} from 'core-app/modules/hal/resources/mixins/attachable-mixin';

export interface WorkPackageResourceEmbedded {
  activities:CollectionResource;
  ancestors:WorkPackageResource[];
  assignee:HalResource|any;
  attachments:AttachmentCollectionResource;
  author:HalResource|any;
  availableWatchers:HalResource|any;
  category:HalResource|any;
  children:WorkPackageResource[];
  parent:HalResource|any;
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

  addComment(comment:{ comment:string }, headers?:any):Promise<any>;

  addRelation(relation:any):Promise<any>;

  addWatcher(watcher:HalResource):Promise<any>;

  changeParent(params:any):Promise<any>;

  copy():Promise<WorkPackageResource>;

  delete():Promise<any>;

  logTime():Promise<any>;

  move():Promise<any>;

  removeWatcher():Promise<any>;

  self():Promise<any>;

  update(payload:any):Promise<any>;

  updateImmediately(payload:any):Promise<any>;

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

  public overriddenSchema?:SchemaResource;
  public __initialized_at:Number;

  readonly I18n:I18nService = this.injector.get(I18nService);
  readonly states:States = this.injector.get(States);
  readonly apiWorkPackages:ApiWorkPackagesService = this.injector.get(ApiWorkPackagesService);
  readonly wpCacheService:WorkPackageCacheService = this.injector.get(WorkPackageCacheService);
  readonly schemaCacheService:SchemaCacheService = this.injector.get(SchemaCacheService);
  readonly NotificationsService:NotificationsService = this.injector.get(NotificationsService);
  readonly wpNotificationsService:WorkPackageNotificationService = this.injector.get(
    WorkPackageNotificationService);
  readonly pathHelper:PathHelperService = this.injector.get(PathHelperService);
  readonly opFileUpload:OpenProjectFileUploadService = this.injector.get(OpenProjectFileUploadService);

  readonly attachmentsBackend = true;

  public get id():string {
    return this.$source.id || this.idFromLink;
  }

  /**
   * Return the ids of all its ancestors, if any
   */
  public get ancestorIds():string {
    const ancestors = (this as any).ancestors;
    return ancestors.map((el:WorkPackageResource) => el.id.toString());
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
    const subject = _.truncate(this.subject, { length: truncateSubject });

    return `${subject}${id}`;
  }

  public get isNew():boolean {
    return this.id === 'new';
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

  /**
   * Return whether the work package is editable with the user's permission
   * on the given work package attribute.
   *
   * @param property
   */
  public isAttributeEditable(property:string):boolean {
    return this.isEditable && (!this.isReadonly || property === 'status');
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
    return otherWorkPackage.parent.$links.self.$link.href === this.$links.self.$link.href;
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
      this.wpCacheService.touch(this.id);
    });

    return promise;
  }

  /**
   * Get updated attachments and activities from the server and inform the cache service
   * about the update.
   *
   * Return a promise that returns the attachments. Reject, if the work package has
   * no attachments.
   */
  public updateAttachments():Promise<HalResource> {
    return this
      .updateLinkedResources('activities', 'attachments')
      .then((resources:any) => resources.attachments);
  }

  /**
   * Assign values from the form for a newly created work package resource.
   * @param form
   */
  public initializeNewResource(form:any) {
    this.overriddenSchema = form.schema;
    this.form = Promise.resolve(form);
    this.$source.id = 'new';

    // Since the ID will change upon saving, keep track of the WP
    // with the actual creation date
    this.__initialized_at = Date.now();

    // Set update link to form
    this['update'] = this.$links.update = form.$links.self;
    // Use POST /work_packages for saving link
    this['updateImmediately'] = this.$links.updateImmediately = (payload) => {
      return this.apiWorkPackages.createWorkPackage(payload);
    };
  }

  /**
   * Retain the internal tracking identifier from the given other work package.
   * This is due to us needing to identify a work package beyond its actual ID,
   * because that changes upon saving.
   *
   * @param other
   */
  public retainFrom(other:WorkPackageResource) {
    this.__initialized_at = other.__initialized_at;
  }

  public $initialize(source:any) {
    super.$initialize(source);

    let attachments = this.attachments || { $source: {}, elements: [] };
    this.attachments = new AttachmentCollectionResource(
      this.injector,
      attachments,
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

  public get hasOverriddenSchema():boolean {
    return this.overriddenSchema != null;
  }
}

export const WorkPackageResource = Attachable(WorkPackageBaseResource);

export interface WorkPackageResource extends WorkPackageBaseResource, WorkPackageResourceLinks, WorkPackageResourceEmbedded {
}
