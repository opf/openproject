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
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { truncate } from 'lodash-es';
import { InputState } from '@openproject/reactivestates';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { States } from 'core-app/core/states/states.service';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';
import {
  WorkPackagesActivityService,
} from 'core-app/features/work-packages/components/wp-single-view-tabs/activity-panel/wp-activity.service';
import {
  WorkPackageNotificationService,
} from 'core-app/features/work-packages/services/notifications/work-package-notification.service';
import { LazyInject } from 'core-app/shared/helpers/angular/lazy-inject.decorator';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { AttachmentCollectionResource } from 'core-app/features/hal/resources/attachment-collection-resource';
import { HalResource, HalResourceEmbedded, HalResourceLinks } from 'core-app/features/hal/resources/hal-resource';
import { CallableHalLink } from 'core-app/features/hal/hal-link/hal-link';
import { CollectionResource } from 'core-app/features/hal/resources/collection-resource';
import { TypeResource } from 'core-app/features/hal/resources/type-resource';
import { RelationResource } from 'core-app/features/hal/resources/relation-resource';
import { StatusResource } from 'core-app/features/hal/resources/status-resource';
import { FormResource } from 'core-app/features/hal/resources/form-resource';
import { Attachable } from 'core-app/features/hal/resources/mixins/attachable-mixin';
import { ICKEditorContext } from 'core-app/shared/components/editor/components/ckeditor/ckeditor.types';
import isNewResource from 'core-app/features/hal/helpers/is-new-resource';
import { IWorkPackageTimestamp } from 'core-app/features/hal/resources/work-package-timestamp-resource';
import { formatWorkPackageId } from 'core-app/shared/helpers/work-package-id-pattern';

export interface WorkPackageResourceEmbedded {
  activities:CollectionResource;
  assignee:HalResource|null;
  attachments:AttachmentCollectionResource;
  fileLinks?:CollectionResource;
  author:HalResource;
  availableWatchers:HalResource;
  category:HalResource|null;
  children:WorkPackageResource[];
  parent:WorkPackageResource|null;
  priority:HalResource;
  project:HalResource;
  relations:CollectionResource;
  responsible:HalResource|null;
  revisions:CollectionResource;
  status:StatusResource;
  timeEntries:HalResource[];
  type:TypeResource;
  version:HalResource|null;
  watchers:CollectionResource;
  // For regular work packages
  startDate:string;
  dueDate:string;
  // Only for milestones
  date:string;
  relatedBy:RelationResource|null;
  scheduleManually:boolean;
}

export interface WorkPackageResourceLinks {
  addAttachment:CallableHalLink;
  addChild:CallableHalLink;
  addComment:CallableHalLink;
  addRelation:CallableHalLink<RelationResource>;
  addWatcher:CallableHalLink;
  changeParent:CallableHalLink<WorkPackageResource>;
  copy:CallableHalLink<WorkPackageResource>;
  delete:CallableHalLink;
  logTime:CallableHalLink;
  startTimer:CallableHalLink;
  move:CallableHalLink;
  removeWatcher:CallableHalLink;
  update:CallableHalLink<FormResource<WorkPackageResource>>;
  updateImmediately:CallableHalLink<WorkPackageResource>;
  watch:CallableHalLink;
}

export interface WorkPackageLinksObject extends HalResourceLinks, WorkPackageResourceLinks {
  self:CallableHalLink<WorkPackageResource>;
  schema:CallableHalLink;
}

export class WorkPackageBaseResource extends HalResource {
  public $embedded:WorkPackageResourceEmbedded & HalResourceEmbedded;

  public $links:WorkPackageLinksObject;

  public subject:string;

  /**
   * The canonical user-facing work package identifier.
   *
   * - Semantic mode: `"PROJ-42"` (project-scoped, contains letters)
   * - Classic mode: `"42"` (numeric only)
   *
   * This is the correct value for URL path segments — use this rather
   * than `id` when constructing work package hrefs. The numeric `id`
   * (primary key) should only appear in data attributes and internal
   * state management (selection, focus, hover).
   *
   * Falls back to the self link's `displayId` — ancestor/children links
   * in the API expose `displayId` alongside `href`/`title` because those
   * HAL resources are built from a link payload alone, without a
   * top-level `displayId`. Finally falls back to `id` (defensive against
   * stale cache during rolling deploys, and for resources built from
   * bare hrefs).
   */
  public get displayId():string {
    return this.$source.displayId?.toString()
      ?? this.$source._links?.self?.displayId?.toString()
      ?? this.id?.toString()
      ?? '';
  }

  /**
   * Returns the work package identifier formatted for inline UI display.
   * Classic mode: `#42` (hash-prefixed numeric ID)
   * Semantic mode: `PROJ-42` (no prefix — the identifier is self-describing)
   */
  public get formattedId():string {
    return formatWorkPackageId(this.displayId);
  }

  public updatedAt:Date;

  public lockVersion:number;

  public hasProjectAttributes:boolean;

  public description:any;

  public activities:CollectionResource;

  public attachments:AttachmentCollectionResource;

  private ancestors?:this[];

  public attributesByTimestamp?:IWorkPackageTimestamp[];

  @LazyInject() I18n!:I18nService;

  @LazyInject() states:States;

  @LazyInject() wpActivity:WorkPackagesActivityService;

  @LazyInject() apiV3Service:ApiV3Service;

  @LazyInject() ToastService:ToastService;

  @LazyInject() workPackageNotificationService:WorkPackageNotificationService;

  @LazyInject() pathHelper:PathHelperService;

  readonly attachmentsBackend = true;

  /**
   * Returns the list of ancestors, if any
   */
  public getAncestors():this[] {
    return this.ancestors || [];
  }

  /**
   * Return the ids of all its ancestors, if any
   */
  public get ancestorIds():string[] {
    return this.getAncestors().map((el:HalResource) => (el.id as string|number).toString());
  }

  /**
   * Return "<type name>: <subject> (<formattedId>)" if type and id are known.
   */
  public subjectWithType(truncateSubject = 40):string {
    // eslint-disable-next-line @typescript-eslint/no-unsafe-member-access
    return `${this.type.name}: ${this.subjectWithId(truncateSubject)}`;
  }

  /**
   * Return "<subject> (<formattedId>)" if the id is known.
   */
  public subjectWithId(truncateSubject = 40):string {
    const id = isNewResource(this) ? '' : ` (${this.formattedId})`;

    return `${this.truncatedSubject(truncateSubject)}${id}`;
  }

  public truncatedSubject(length = 40):string {
    return length <= 0 ? this.subject : truncate(this.subject, { length: length });
  }

  public get isLeaf():boolean {
    const { children } = this.$links;
    return !(children && children.length > 0);
  }

  public previewPath() {
    if (!isNewResource(this)) {
      return this.apiV3Service.work_packages.id(this.id!).path;
    }
    return super.previewPath();
  }

  public getEditorContext(fieldName:string):ICKEditorContext {
    if (fieldName === 'description') {
      return { type: 'full', macros: 'wiki' };
    }

    const isCustomField = fieldName.startsWith('customField');
    return {
      type: 'constrained',
      macros: isCustomField ? 'wiki' : false,
      ...(isCustomField && { disabledMentions: ['user'] }),
    };
  }

  public isParentOf(otherWorkPackage:WorkPackageResource) {
    return otherWorkPackage.parent?.$links.self.$link.href === this.$links.self.$link.href;
  }

  public $initialize(source:any) {
    super.$initialize(source);

    const attachments:any = this.attachments || { $source: {}, elements: [] };
    this.attachments = new AttachmentCollectionResource(
      this.injector,
      // Attachments MAY be an array if we're building from a form
      (attachments as { $source?:unknown }).$source ?? attachments,
      false,
      this.halInitializer,
      'HalResource',
    );
  }

  /**
   * Exclude the schema _link from the linkable Resources.
   */
  public $linkableKeys():string[] {
    return super.$linkableKeys().filter((key) => key !== 'schema');
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
    this.wpActivity.clear(newValue.id);

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
