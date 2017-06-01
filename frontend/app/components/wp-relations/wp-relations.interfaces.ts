import {WorkPackageResourceInterface} from '../api/api-v3/hal-resources/work-package-resource.service';
import {RelationResourceInterface} from '../api/api-v3/hal-resources/relation-resource.service';

export interface RelatedWorkPackagesGroup {
  [key: string] : WorkPackageResourceInterface[];
}

export interface RelationTitle {
  [key: string]: string;
}

