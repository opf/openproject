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

import {HalResource} from './hal-resource.service';
import {opApiModule} from '../../../../angular-modules';
import {WorkPackageCacheService} from '../../../work-packages/work-package-cache.service';
import {SchemaCacheService} from './../../../schemas/schema-cache.service';
import {ApiWorkPackagesService} from '../../api-work-packages/api-work-packages.service';
import {CollectionResource, CollectionResourceInterface} from './collection-resource.service';
import {AttachmentCollectionResourceInterface} from './attachment-collection-resource.service';
import {UploadFile} from '../../op-file-upload/op-file-upload.service';
import IQService = angular.IQService;
import IPromise = angular.IPromise;
import ITimeoutService = angular.ITimeoutService;
import {States} from '../../../states.service';
import {SchemaResource} from './schema-resource.service';
import {TypeResource} from './type-resource.service';
import {RelationResourceInterface} from './relation-resource.service';
import {WorkPackageCreateService} from '../../../wp-create/wp-create.service';
import {WorkPackageNotificationService} from '../../../wp-edit/wp-notification.service';
import {debugLog} from '../../../../helpers/debug_output';

export interface WorkPackageResourceEmbedded {
  activities:CollectionResourceInterface;
  ancestors:WorkPackageResourceInterface[];
  assignee:HalResource | any;
  attachments:AttachmentCollectionResourceInterface;
  author:HalResource | any;
  availableWatchers:HalResource | any;
  category:HalResource | any;
  children:WorkPackageResourceInterface[];
  parent:HalResource | any;
  priority:HalResource | any;
  project:HalResource | any;
  relations:CollectionResourceInterface;
  responsible:HalResource | any;
  revisions:CollectionResourceInterface | any;
  status:HalResource | any;
  timeEntries:HalResource[] | any[];
  type:TypeResource;
  version:HalResource | any;
  watchers:CollectionResourceInterface;
  // For regular work packages
  startDate:string;
  dueDate:string;
  // Only for milestones
  date:string;
  relatedBy:RelationResourceInterface | null;
}

export interface WorkPackageResourceLinks extends WorkPackageResourceEmbedded {
  addAttachment(attachment:HalResource):ng.IPromise<any>;
  addChild(child:HalResource):ng.IPromise<any>;
  addComment(comment:HalResource):ng.IPromise<any>;
  addRelation(relation:any):ng.IPromise<any>;
  addWatcher(watcher:HalResource):ng.IPromise<any>;
  changeParent(params:any):ng.IPromise<any>;
  copy():ng.IPromise<WorkPackageResource>;
  delete():ng.IPromise<any>;
  logTime():ng.IPromise<any>;
  move():ng.IPromise<any>;
  removeWatcher():ng.IPromise<any>;
  self():ng.IPromise<any>;
  update(payload:any):ng.IPromise<any>;
  updateImmediately(payload:any):ng.IPromise<any>;
  watch():ng.IPromise<any>;
}

interface WorkPackageLinksObject extends WorkPackageResourceLinks {
  schema:HalResource;
}

var $q:IQService;
var $stateParams:any;
var $timeout:ITimeoutService;
var I18n:op.I18n;
var states:States;
var apiWorkPackages:ApiWorkPackagesService;
var wpCacheService:WorkPackageCacheService;
var schemaCacheService:SchemaCacheService;
var NotificationsService:any;
var wpNotificationsService:WorkPackageNotificationService;
var wpCreate:WorkPackageCreateService;
var AttachmentCollectionResource:any;
var v3Path:any;

export class WorkPackageResource extends HalResource {
  // Add index signature for getter this[attr]
  [attribute:string]:any;

  public $embedded:WorkPackageResourceEmbedded;
  public $links:WorkPackageLinksObject;
  public subject:string;
  public updatedAt:Date;
  public lockVersion:number;
  public description:any;
  public inFlight:boolean;
  public activities:CollectionResourceInterface;
  public attachments:AttachmentCollectionResourceInterface;

  public pendingAttachments:UploadFile[] = [];
  public overriddenSchema?:SchemaResource;

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
   * Initialise the work package resource.
   *
   * Make the attachments an `AttachmentCollectionResource`. This should actually
   * be done automatically, but the backend does not provide typed collections yet.
   */
  public $initialize(source:any) {
    super.$initialize(source);

    var attachments:{ $source:any, $loaded:boolean } = this.attachments || {
        $source: void 0,
        $loaded: false
      };
    this.attachments = new AttachmentCollectionResource(
      attachments.$source,
      attachments.$loaded
    );
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
          wpNotificationsService.handleErrorResponse(error, this as any);
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
  public uploadPendingAttachments():ng.IPromise<any> | void {
    if (!this.pendingAttachments.length) {
      return;
    }

    const attachments = this.pendingAttachments;
    this.pendingAttachments = [];
    return this.uploadAttachments(attachments);
  }

  /**
   * Upload the given attachments, update the resource and notify the user.
   * Return an updated AttachmentCollectionResource.
   */
  public uploadAttachments(files:UploadFile[]):IPromise<any> {
    const {uploads, finished} = this.attachments.upload(files);
    const message = I18n.t('js.label_upload_notification', this);
    const notification = NotificationsService.addWorkPackageUpload(message, uploads);

    return finished
      .then(() => {
        $timeout(() => NotificationsService.remove(notification), 700);
        return this.updateAttachments();
      })
      .catch(error => {
        wpNotificationsService.handleRawError(error, this as any);
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
          wpCacheService.loadWorkPackage(this.id, true);
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

  public allowedValuesFor(field:string):ng.IPromise<HalResource[]> {
    var deferred = $q.defer();

    this.getForm().then((form:any) => {
      const fieldSchema = form.$embedded.schema[field];

      if (!fieldSchema) {
        deferred.resolve([]);
      } else if (fieldSchema.allowedValues && fieldSchema.allowedValues['$load']) {
        let allowedValues = fieldSchema.allowedValues;

        return allowedValues.$load().then((loadedValues:CollectionResource) => {
          deferred.resolve(loadedValues.elements);
        });
      } else {
        deferred.resolve(fieldSchema.allowedValues);
      }
    });

    return deferred.promise;
  }

  public setAllowedValueFor(field:string, value:string | HalResource) {
    return this.allowedValuesFor(field).then(allowedValues => {
      let newValue;

      if ((value as HalResource)['$href']) {
        newValue = _.find(allowedValues,
          (entry:any) => entry.$href === (value as HalResource).$href);
      } else if (allowedValues) {
        newValue = _.find(allowedValues, (entry:any) => entry === value);
      } else {
        newValue = value;
      }

      if (newValue) {
        (this as any)[field] = newValue;
      }

      wpCacheService.updateWorkPackage(this as any);
    });
  }

  public isParentOf(otherWorkPackage:WorkPackageResourceInterface) {
    return otherWorkPackage.parent.$links.self.$link.href === this.$links.self.$link.href;
  }

  /**
   * Invalidate a set of linked resources of this work package.
   * And inform the cache service about the work package update.
   *
   * Return a promise that returns the linked resources as properties.
   * Return a rejected promise, if the resource is not a property of the work package.
   */
  public updateLinkedResources(...resourceNames:string[]):ng.IPromise<any> {
    const resources:{ [id:string]:IPromise<HalResource> } = {};

    resourceNames.forEach(name => {
      const linked = this[name];
      resources[name] = linked ? linked.$update() : $q.reject();
    });

    const promise = $q.all(resources);
    promise.then(() => {
      wpCacheService.updateWorkPackage(this as any);
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
  public updateActivities():IPromise<HalResource> {
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
  public updateAttachments():IPromise<HalResource> {
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
    this.form = $q.when(form);
    this.$source.id = 'new';

    // Set update link to form
    this['update'] = this.$links.update = form.$links.self;
    // Use POST /work_packages for saving link
    this['updateImmediately'] = this.$links.updateImmediately = (payload) => {
      return apiWorkPackages.createWorkPackage(payload);
    };
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

    const state = schemaCacheService.state(this);

    if (!state.hasValue()) {
      throw `Accessing schema of ${this.id} without it being loaded.`;
    }

    return state.value!;
  }

  public get hasOverriddenSchema():boolean {
    return this.overriddenSchema != null;
  }
}

export interface WorkPackageResourceInterface extends WorkPackageResourceLinks, WorkPackageResourceEmbedded, WorkPackageResource {
}

function wpResource(...args:any[]) {
  [
    $q,
    $stateParams,
    $timeout,
    I18n,
    states,
    apiWorkPackages,
    wpCacheService,
    wpCreate,
    schemaCacheService,
    NotificationsService,
    wpNotificationsService,
    AttachmentCollectionResource,
    v3Path] = args;
  return WorkPackageResource;
}

wpResource.$inject = [
  '$q',
  '$stateParams',
  '$timeout',
  'I18n',
  'states',
  'apiWorkPackages',
  'wpCacheService',
  'wpCreate',
  'schemaCacheService',
  'NotificationsService',
  'wpNotificationsService',
  'AttachmentCollectionResource',
  'v3Path'
];

opApiModule.factory('WorkPackageResource', wpResource);
