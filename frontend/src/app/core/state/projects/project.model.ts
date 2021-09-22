import { ID } from '@datorama/akita';

export interface HalResourceLink {
  href:string;
  title:string;
}
export const PROJECTS_MAX_SIZE = 100;

export interface Project {
  id:ID;
  createdAt:string;
  updatedAt:string;

  _links:{
    actor?:HalResourceLink,
    project?:HalResourceLink,
    resource?:HalResourceLink,
    activity?:HalResourceLink,
  };
}
