import {ConfigurationResource} from 'core-app/modules/hal/resources/configuration-resource';
import {HelpTextResource} from 'core-app/modules/hal/resources/help-text-resource';
import {QueryFilterInstanceSchemaResource} from 'core-app/modules/hal/resources/query-filter-instance-schema-resource';
import {QueryFormResource} from 'core-app/modules/hal/resources/query-form-resource';
import {QueryFilterResource} from 'core-app/modules/hal/resources/query-filter-resource';
import {QueryOperatorResource} from 'core-app/modules/hal/resources/query-operator-resource';
import {HalResource} from 'core-app/modules/hal/resources/hal-resource';
import {ProjectResource} from 'core-app/modules/hal/resources/project-resource';
import {QueryResource} from 'core-app/modules/hal/resources/query-resource';
import {ErrorResource} from 'core-app/modules/hal/resources/error-resource';
import {CollectionResource} from 'core-app/modules/hal/resources/collection-resource';
import {AttachmentCollectionResource} from 'core-app/modules/hal/resources/attachment-collection-resource';
import {QueryFilterInstanceResource} from 'core-app/modules/hal/resources/query-filter-instance-resource';
import {FormResource} from 'core-app/modules/hal/resources/form-resource';
import {QueryGroupByResource} from 'core-app/modules/hal/resources/query-group-by-resource';
import {CustomActionResource} from 'core-app/modules/hal/resources/custom-action-resource';
import {QuerySortByResource} from 'core-app/modules/hal/resources/query-sort-by-resource';
import {RelationResource} from 'core-app/modules/hal/resources/relation-resource';
import {RootResource} from 'core-app/modules/hal/resources/root-resource';
import {SchemaDependencyResource} from 'core-app/modules/hal/resources/schema-dependency-resource';
import {SchemaResource} from 'core-app/modules/hal/resources/schema-resource';
import {TypeResource} from 'core-app/modules/hal/resources/type-resource';
import {UserResource} from 'core-app/modules/hal/resources/user-resource';
import {WorkPackageResource} from 'core-app/modules/hal/resources/work-package-resource';
import {WorkPackageCollectionResource} from 'core-app/modules/hal/resources/wp-collection-resource';
import {GridResource} from "core-app/modules/hal/resources/grid-resource";

export const coreHalResources = [
  AttachmentCollectionResource,
  CollectionResource,
  ConfigurationResource,
  CustomActionResource,
  ErrorResource,
  FormResource,
  HalResource,
  HelpTextResource,
  ProjectResource,
  QueryFilterInstanceResource,
  QueryFilterInstanceSchemaResource,
  QueryFilterResource,
  QueryFormResource,
  QueryGroupByResource,
  QueryOperatorResource,
  QueryResource,
  QuerySortByResource,
  RelationResource,
  RootResource,
  SchemaDependencyResource,
  SchemaResource,
  TypeResource,
  UserResource,
  WorkPackageResource,
  WorkPackageCollectionResource,
  GridResource
];
