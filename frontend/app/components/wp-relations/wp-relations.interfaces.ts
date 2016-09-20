import {WorkPackageResourceInterface} from '../api/api-v3/hal-resources/work-package-resource.service';
import {HalResource} from '../api/api-v3/hal-resources/hal-resource.service';

export interface RelatedWorkPackage extends WorkPackageResourceInterface {
  relatedBy: RelationResource;
}

export interface RelatedWorkPackagesGroup {
  [key: string] : Array<RelatedWorkPackage>;
}

export interface RelationResource extends HalResource {
  _type: string;
  description: string;
  updateRelation(params:Object): ng.IPromise<any>;
  remove(): ng.IPromise<any>;
}

export interface RelationType {
  name: string;
  id?: string;
  type: string;
}

export interface RelationTitle {
  [key: string]: string;
}

