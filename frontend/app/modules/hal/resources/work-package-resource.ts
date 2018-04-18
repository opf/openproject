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
import {I18nToken} from 'core-app/angular4-transition-utils';
import {AttachmentCollectionResource} from 'core-app/modules/hal/resources/attachment-collection-resource';
import {CollectionResource} from 'core-app/modules/hal/resources/collection-resource';
import {TypeResource} from 'core-app/modules/hal/resources/type-resource';
import {RelationResource} from 'core-app/modules/hal/resources/relation-resource';
import {UploadFile} from 'core-components/api/op-file-upload/op-file-upload.service';
import {SchemaResource} from 'core-app/modules/hal/resources/schema-resource';
import {States} from 'core-components/states.service';
import {ApiWorkPackagesService} from 'core-components/api/api-work-packages/api-work-packages.service';
import {WorkPackageCacheService} from 'core-components/work-packages/work-package-cache.service';
import {SchemaCacheService} from 'core-components/schemas/schema-cache.service';
import {WorkPackageNotificationService} from 'core-components/wp-edit/wp-notification.service';
import {WorkPackageCreateService} from 'core-components/wp-new/wp-create.service';
import {PathHelperService} from 'core-components/common/path-helper/path-helper.service';
import {NotificationsService} from 'core-components/common/notifications/notifications.service';

interface WorkPackageResourceEmbedded {
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

interface WorkPackageResourceLinks extends WorkPackageResourceEmbedded {
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

interface WorkPackageLinksObject extends WorkPackageResourceLinks {
  schema:HalResource;
}

export class WorkPackageResource extends HalResource {
  public $embedded:WorkPackageResourceEmbedded;
  public $links:WorkPackageLinksObject;
  public subject:string;
  public updatedAt:Date;
  public lockVersion:number;
  public description:any;
  public activities:CollectionResource;
  public attachments:AttachmentCollectionResource;

  public pendingAttachments:UploadFile[] = [];
  public overriddenSchema?:SchemaResource;

  readonly I18n:op.I18n = this.injector.get(I18nToken);
  readonly states:States = this.injector.get(States);
  readonly apiWorkPackages:ApiWorkPackagesService = this.injector.get(ApiWorkPackagesService);
  readonly wpCacheService:WorkPackageCacheService = this.injector.get(WorkPackageCacheService);
  readonly schemaCacheService:SchemaCacheService = this.injector.get(SchemaCacheService);
  readonly NotificationsService:NotificationsService = this.injector.get(NotificationsService);
  readonly wpNotificationsService:WorkPackageNotificationService = this.injector.get(
    WorkPackageNotificationService);
  readonly wpCreate:WorkPackageCreateService = this.injector.get(WorkPackageCreateService);
  readonly pathHelper:PathHelperService = this.injector.get(PathHelperService);

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

  /**
   * Return "<type name>: <subject>" if the type is known.
   */
  public get subjectWithType():string {
    if (this.type) {
      return `${this.type.name}: ${this.subject}`;
    } else {
      return this.subject;
    }
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

  public get isEditable():boolean {
    return !!this.$links.update || this.isNew;
  }

  /**
   * Return whether the user is able to upload an attachment.
   *
   * If either the `addAttachment` link is provided or the resource is being created,
   * adding attachments is allowed.
   */
  public get canAddAttachments():boolean {
    return !!this.$links.addAttachment || this.isNew;
  }

  /**
   * Remove the given attachment either from the pending attachments or from
   * the attachment collection, if it is a resource.
   *
   * Removing it from the elements array assures that the view gets updated immediately.
   * If an error occurs, the user gets notified and the attachment is pushed to the elements.
   */
  public removeAttachment(attachment:any) {
    if (attachment.$isHal) {
      attachment.delete()
        .then(() => {
          this.updateAttachments();
        })
        .catch((error:any) => {
          this.wpNotificationsService.handleErrorResponse(error, this as any);
          this.attachments.elements.push(attachment);
        });
    }

    _.pull(this.attachments.elements, attachment);
    _.pull(this.pendingAttachments, attachment);
  }

  /**
   * Upload the pending attachments if the work package exists.
   * Do nothing, if the work package is being created.
   */
  public uploadPendingAttachments():Promise<any>|void {
    if (!this.pendingAttachments.length) {
      return undefined;
    }

    const attachments = this.pendingAttachments;
    this.pendingAttachments = [];
    return this.uploadAttachments(attachments);
  }

  /**
   * Upload the given attachments, update the resource and notify the user.
   * Return an updated AttachmentCollectionResource.
   */
  public async uploadAttachments(files:UploadFile[]):Promise<any> {
    const href = this.attachments.$href!;
    // TODO upgrade
    const opFileUplaod = angular.element('body').injector().get('opFileUpload');

    const { uploads, finished } = this.opFileUpload.upload(href, files);
    const message = I18n.t('js.label_upload_notification', this);
    const notification = this.NotificationsService.addWorkPackageUpload(message, uploads);

    return finished
      .then(async () => {
        setTimeout(() => this.NotificationsService.remove(notification), 700);
        return this.updateAttachments();
      })
      .catch((error:any) => {
        this.wpNotificationsService.handleRawError(error, this as any);
      });
  }

  /**
   * Uploads the attachments and reloads the work package when done
   * Reloading is skipped if no attachment is added
   */
  public uploadAttachmentsAndReload() {
    const attachmentUpload = this.uploadPendingAttachments();

    if (attachmentUpload) {
      attachmentUpload.then((attachmentsResource) => {
        if (attachmentsResource.count > 0) {
          this.wpCacheService.loadWorkPackage(this.id, true);
        }
      });
    }
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
  public async updateLinkedResources(...resourceNames:string[]):Promise<any> {
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
   * Get updated activities from the server and inform the cache service about the work
   * package update.
   *
   * Return a promise that returns the activities. Reject, if the work package has
   * no activities.
   */
  public async updateActivities():Promise<HalResource> {
    return this
      .updateLinkedResources('activities')
      .then((resources:any) => resources.activities);
  }

  /**
   * Get updated attachments and activities from the server and inform the cache service
   * about the update.
   *
   * Return a promise that returns the attachments. Reject, if the work package has
   * no attachments.
   */
  public async updateAttachments():Promise<HalResource> {
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

    // Set update link to form
    this['update'] = this.$links.update = form.$links.self;
    // Use POST /work_packages for saving link
    this['updateImmediately'] = this.$links.updateImmediately = async (payload) => {
      return this.apiWorkPackages.createWorkPackage(payload);
    };
  }

  public $initialize(source:any) {
    super.$initialize(source);

    let attachments = this.attachments || { $source: {} };
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

export interface WorkPackageResource extends WorkPackageResourceLinks, WorkPackageResourceEmbedded {
}
