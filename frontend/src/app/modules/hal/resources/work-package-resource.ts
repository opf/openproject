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

import { HalResource } from 'core-app/modules/hal/resources/hal-resource';
import { I18nService } from 'core-app/modules/common/i18n/i18n.service';
import { AttachmentCollectionResource } from 'core-app/modules/hal/resources/attachment-collection-resource';
import { CollectionResource } from 'core-app/modules/hal/resources/collection-resource';
import { TypeResource } from 'core-app/modules/hal/resources/type-resource';
import { RelationResource } from 'core-app/modules/hal/resources/relation-resource';
import {
  OpenProjectFileUploadService,
  UploadFile
} from 'core-components/api/op-file-upload/op-file-upload.service';
import { States } from 'core-components/states.service';
import { PathHelperService } from 'core-app/modules/common/path-helper/path-helper.service';
import { NotificationsService } from 'core-app/modules/common/notifications/notifications.service';
import { Attachable } from 'core-app/modules/hal/resources/mixins/attachable-mixin';
import { FormResource } from "core-app/modules/hal/resources/form-resource";
import { InputState } from "reactivestates";
import { WorkPackagesActivityService } from "core-components/wp-single-view-tabs/activity-panel/wp-activity.service";
import { WorkPackageNotificationService } from "core-app/modules/work_packages/notifications/work-package-notification.service";
import { InjectField } from "core-app/helpers/angular/inject-field.decorator";
import { APIV3Service } from "core-app/modules/apiv3/api-v3.service";

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
  scheduleManually:boolean;
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

  @InjectField() I18n!:I18nService;
  @InjectField() states:States;
  @InjectField() wpActivity:WorkPackagesActivityService;
  @InjectField() apiV3Service:APIV3Service;
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

  /**
   * Return "<type name>: <subject> (#<id>)" if type and id are known.
   */
  public subjectWithType(truncateSubject = 40):string {
    const type = this.type ? `${this.type.name}: ` : '';
    const subject = this.subjectWithId(truncateSubject);

    return `${type}${subject}`;
  }

  /**
   * Return "<subject> (#<id>)" if the id is known.
   */
  public subjectWithId(truncateSubject = 40):string {
    const id = this.isNew ? '' : ` (#${this.id})`;
    const subject = _.truncate(this.subject, { length: truncateSubject });

    return `${subject}${id}`;
  }

  public get isLeaf():boolean {
    const children = this.$links.children;
    return !(children && children.length > 0);
  }

  public previewPath() {
    if (!this.isNew) {
      return this.apiV3Service.work_packages.id(this.id!).path;
    } else {
      return super.previewPath();
    }
  }

  public getEditorTypeFor(fieldName:string):"full"|"constrained" {
    return fieldName === 'description' ? 'full' : 'constrained';
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

  public $initialize(source:any) {
    super.$initialize(source);

    const attachments:any = this.attachments || { $source: {}, elements: [] };
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
      this.apiV3Service.work_packages.id(newValue.parent).refresh();
    }

    return this.apiV3Service.work_packages.cache.updateWorkPackage(newValue as any);
  }
}

export const WorkPackageResource = Attachable(WorkPackageBaseResource);

export interface WorkPackageResource extends WorkPackageBaseResource, WorkPackageResourceLinks, WorkPackageResourceEmbedded {
}
