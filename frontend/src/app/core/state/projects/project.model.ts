import { ID } from '@datorama/akita';
import {
  HalResourceLink,
  HalResourceLinks,
  CustomText,
} from 'core-app/core/state/hal-resource';

export const PROJECTS_MAX_SIZE = 100;

export interface ProjectHalResourceLinks extends HalResourceLinks {
  categories:HalResourceLink;
  delete:HalResourceLink;
  parent:HalResourceLink;
  self:HalResourceLink;
  status:HalResourceLink;
  schema:HalResourceLink;
}

export interface Project {
  id:ID;
  identifier:string;
  name:string;
  public:boolean;
  active:boolean;
  statusExplanation:CustomText;
  description:CustomText;

  createdAt:string;
  updatedAt:string;

  _links:ProjectHalResourceLinks;
}
