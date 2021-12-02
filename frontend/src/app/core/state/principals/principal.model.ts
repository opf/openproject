import { ID } from '@datorama/akita';
import {
  HalResourceLink,
  HalResourceLinks,
} from 'core-app/core/state/hal-resource';

export interface PrincipalHalResourceLinks extends HalResourceLinks {
  actor:HalResourceLink;
  project:HalResourceLink;
  resource:HalResourceLink;
  activity:HalResourceLink;
}

export interface Principal {
  id:ID;
  subject:string;
  createdAt:string;
  updatedAt:string;
  reason:string;
  readIAN:boolean|null;
  readEmail:boolean|null;

  // Mark a principal to be kept in the center even though it was saved as "read".
  keep?:boolean;
  // Show message of a principal?
  expanded:boolean;

  _links:PrincipalHalResourceLinks;
}
