import { ID } from '@datorama/akita';
import {
  HalResourceLink,
  HalResourceLinks,
  Formattable,
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
  statusExplanation:Formattable;
  description:Formattable;

  createdAt:string;
  updatedAt:string;

  _links:ProjectHalResourceLinks;
}
