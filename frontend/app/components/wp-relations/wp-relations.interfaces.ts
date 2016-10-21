import {WorkPackageResourceInterface} from '../api/api-v3/hal-resources/work-package-resource.service';
import {RelationResourceInterface} from '../api/api-v3/hal-resources/relation-resource.service';

export interface RelatedWorkPackage extends WorkPackageResourceInterface {
  relatedBy: RelationResourceInterface;
}

export interface RelatedWorkPackagesGroup {
  [key: string] : Array<RelatedWorkPackage>;
}

export interface RelationType {
  name: string;
  id?: string;
  type: string;
}

export interface RelationTitle {
  [key: string]: string;
}

