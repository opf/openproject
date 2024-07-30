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

import { WorkPackageResource } from 'core-app/features/hal/resources/work-package-resource';
import { UserResource } from 'core-app/features/hal/resources/user-resource';
import { CollectionResource } from 'core-app/features/hal/resources/collection-resource';
import { QueryResource } from 'core-app/features/hal/resources/query-resource';
import { CustomActionResource } from 'core-app/features/hal/resources/custom-action-resource';
import { HalResource } from 'core-app/features/hal/resources/hal-resource';
import { WikiPageResource } from 'core-app/features/hal/resources/wiki-page-resource';
import { MeetingContentResource } from 'core-app/features/hal/resources/meeting-content-resource';
import { PostResource } from 'core-app/features/hal/resources/post-resource';
import { StatusResource } from 'core-app/features/hal/resources/status-resource';
import { AttachmentCollectionResource } from 'core-app/features/hal/resources/attachment-collection-resource';
import { GridWidgetResource } from 'core-app/features/hal/resources/grid-widget-resource';
import { GridResource } from 'core-app/features/hal/resources/grid-resource';
import { TimeEntryResource } from 'core-app/features/hal/resources/time-entry-resource';
import { NewsResource } from 'core-app/features/hal/resources/news-resource';
import { VersionResource } from 'core-app/features/hal/resources/version-resource';
import { MembershipResource } from 'core-app/features/hal/resources/membership-resource';
import { RoleResource } from 'core-app/features/hal/resources/role-resource';
import { ProjectResource } from 'core-app/features/hal/resources/project-resource';
import { GroupResource } from 'core-app/features/hal/resources/group-resource';
import { RootResource } from 'core-app/features/hal/resources/root-resource';
import { TypeResource } from 'core-app/features/hal/resources/type-resource';
import { QueryOperatorResource } from 'core-app/features/hal/resources/query-operator-resource';
import { QueryFilterInstanceResource } from 'core-app/features/hal/resources/query-filter-instance-resource';
import { FormResource } from 'core-app/features/hal/resources/form-resource';
import { HelpTextResource } from 'core-app/features/hal/resources/help-text-resource';
import {
  HalResourceFactoryConfigInterface,
  HalResourceService,
} from 'core-app/features/hal/services/hal-resource.service';
import {
  QueryFilterInstanceSchemaResource,
} from 'core-app/features/hal/resources/query-filter-instance-schema-resource';
import { ErrorResource } from 'core-app/features/hal/resources/error-resource';
import { SchemaDependencyResource } from 'core-app/features/hal/resources/schema-dependency-resource';
import { WorkPackageCollectionResource } from 'core-app/features/hal/resources/wp-collection-resource';
import { RelationResource } from 'core-app/features/hal/resources/relation-resource';
import { QueryFilterResource } from 'core-app/features/hal/resources/query-filter-resource';
import { SchemaResource } from 'core-app/features/hal/resources/schema-resource';
import { MeetingResource } from 'core-app/features/hal/resources/meeting-resource';

const halResourceDefaultConfig:{ [typeName:string]:HalResourceFactoryConfigInterface } = {
  WorkPackage: {
    cls: WorkPackageResource,
    attrTypes: {
      parent: 'WorkPackage',
      ancestors: 'WorkPackage',
      children: 'WorkPackage',
      relations: 'Relation',
      schema: 'Schema',
      status: 'Status',
      type: 'Type',
    },
  },
  Activity: {
    cls: HalResource,
    attrTypes: {
      user: 'User',
    },
  },
  'Activity::Comment': {
    cls: HalResource,
    attrTypes: {
      user: 'User',
    },
  },
  'Activity::Revision': {
    cls: HalResource,
    attrTypes: {
      user: 'User',
    },
  },
  Relation: {
    cls: RelationResource,
    attrTypes: {
      from: 'WorkPackage',
      to: 'WorkPackage',
    },
  },
  Schema: {
    cls: SchemaResource,
  },
  Type: {
    cls: TypeResource,
  },
  Status: {
    cls: StatusResource,
  },
  SchemaDependency: {
    cls: SchemaDependencyResource,
  },
  Error: {
    cls: ErrorResource,
  },
  User: {
    cls: UserResource,
  },
  Group: {
    cls: GroupResource,
  },
  Collection: {
    cls: CollectionResource,
  },
  WorkPackageCollection: {
    cls: WorkPackageCollectionResource,
  },
  AttachmentCollection: {
    cls: AttachmentCollectionResource,
  },
  Query: {
    cls: QueryResource,
    attrTypes: {
      filters: 'QueryFilterInstance',
    },
  },
  Form: {
    cls: FormResource,
    attrTypes: {
      payload: 'FormPayload',
    },
  },
  FormPayload: {
    cls: HalResource,
    attrTypes: {
      attachments: 'AttachmentsCollection',
    },
  },
  QueryFilterInstance: {
    cls: QueryFilterInstanceResource,
    attrTypes: {
      schema: 'QueryFilterInstanceSchema',
      filter: 'QueryFilter',
      operator: 'QueryOperator',
    },
  },
  QueryFilterInstanceSchema: {
    cls: QueryFilterInstanceSchemaResource,
  },
  QueryFilter: {
    cls: QueryFilterResource,
  },
  Root: {
    cls: RootResource,
  },
  QueryOperator: {
    cls: QueryOperatorResource,
  },
  HelpText: {
    cls: HelpTextResource,
  },
  CustomAction: {
    cls: CustomActionResource,
  },
  WikiPage: {
    cls: WikiPageResource,
  },
  Meeting: {
    cls: MeetingResource,
  },
  MeetingContent: {
    cls: MeetingContentResource,
  },
  Post: {
    cls: PostResource,
  },
  Project: {
    cls: ProjectResource,
  },
  Role: {
    cls: RoleResource,
  },
  Grid: {
    cls: GridResource,
  },
  GridWidget: {
    cls: GridWidgetResource,
  },
  TimeEntry: {
    cls: TimeEntryResource,
  },
  Membership: {
    cls: MembershipResource,
  },
  News: {
    cls: NewsResource,
  },
  Version: {
    cls: VersionResource,
  },
};

export function initializeHalResourceConfig(halResourceService:HalResourceService) {
  return () => {
    _.each(halResourceDefaultConfig, (value, key) => halResourceService.registerResource(key, value));
  };
}
