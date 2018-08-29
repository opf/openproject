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

import {WorkPackageResource} from 'core-app/modules/hal/resources/work-package-resource';
import {RelationResource} from 'core-app/modules/hal/resources/relation-resource';
import {SchemaResource} from 'core-app/modules/hal/resources/schema-resource';
import {TypeResource} from 'core-app/modules/hal/resources/type-resource';
import {SchemaDependencyResource} from 'core-app/modules/hal/resources/schema-dependency-resource';
import {ErrorResource} from 'core-app/modules/hal/resources/error-resource';
import {UserResource} from 'core-app/modules/hal/resources/user-resource';
import {CollectionResource} from 'core-app/modules/hal/resources/collection-resource';
import {WorkPackageCollectionResource} from 'core-app/modules/hal/resources/wp-collection-resource';
import {QueryResource} from 'core-app/modules/hal/resources/query-resource';
import {FormResource} from 'core-app/modules/hal/resources/form-resource';
import {QueryFilterInstanceResource} from 'core-app/modules/hal/resources/query-filter-instance-resource';
import {QueryFilterInstanceSchemaResource} from 'core-app/modules/hal/resources/query-filter-instance-schema-resource';
import {QueryFilterResource} from 'core-app/modules/hal/resources/query-filter-resource';
import {RootResource} from 'core-app/modules/hal/resources/root-resource';
import {QueryOperatorResource} from 'core-app/modules/hal/resources/query-operator-resource';
import {HelpTextResource} from 'core-app/modules/hal/resources/help-text-resource';
import {CustomActionResource} from 'core-app/modules/hal/resources/custom-action-resource';
import {
  HalResourceFactoryConfigInterface,
  HalResourceService
} from 'core-app/modules/hal/services/hal-resource.service';
import {Injectable} from '@angular/core';
import {HalResource} from 'core-app/modules/hal/resources/hal-resource';
import {WikiPageResource} from "core-app/modules/hal/resources/wiki-page-resource";
import {PostResource} from "core-app/modules/hal/resources/post-resource";

const halResourceDefaultConfig:{ [typeName:string]:HalResourceFactoryConfigInterface } = {
  WorkPackage: {
    cls: WorkPackageResource,
    attrTypes: {
      parent: 'WorkPackage',
      ancestors: 'WorkPackage',
      children: 'WorkPackage',
      relations: 'Relation',
      schema: 'Schema',
      type: 'Type'
    }
  },
  Activity: {
    cls: HalResource,
    attrTypes: {
      user: 'User'
    }
  },
  'Activity::Comment': {
    cls: HalResource,
    attrTypes: {
      user: 'User'
    }
  },
  'Activity::Revision': {
    cls: HalResource,
    attrTypes: {
      user: 'User'
    }
  },
  Relation: {
    cls: RelationResource,
    attrTypes: {
      from: 'WorkPackage',
      to: 'WorkPackage'
    }
  },
  Schema: {
    cls: SchemaResource
  },
  Type: {
    cls: TypeResource
  },
  SchemaDependency: {
    cls: SchemaDependencyResource
  },
  Error: {
    cls: ErrorResource
  },
  User: {
    cls: UserResource
  },
  Collection: {
    cls: CollectionResource
  },
  WorkPackageCollection: {
    cls: WorkPackageCollectionResource
  },
  Query: {
    cls: QueryResource,
    attrTypes: {
      filters: 'QueryFilterInstance'
    }
  },
  Form: {
    cls: FormResource
  },
  QueryFilterInstance: {
    cls: QueryFilterInstanceResource,
    attrTypes: {
      schema: 'QueryFilterInstanceSchema',
      filter: 'QueryFilter',
      operator: 'QueryOperator'
    }
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
    cls: CustomActionResource
  },
  WikiPage: {
    cls: WikiPageResource
  },
  Post: {
    cls: PostResource
  }
};

export function initializeHalResourceConfig(halResourceService:HalResourceService) {
  return () => {
    _.each(halResourceDefaultConfig, (value, key) => halResourceService.registerResource(key, value));
  }
}

