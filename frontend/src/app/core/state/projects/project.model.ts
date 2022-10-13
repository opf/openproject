import { ID } from '@datorama/akita';
import {
  IHalResourceLink,
  IHalResourceLinks,
  IFormattable,
} from 'core-app/core/state/hal-resource';

export interface IProjectHalResourceLinks extends IHalResourceLinks {
  ancestors:IHalResourceLink[];
  categories:IHalResourceLink;
  delete:IHalResourceLink;
  parent:IHalResourceLink;
  self:IHalResourceLink;
  status:IHalResourceLink;
  schema:IHalResourceLink;
  storages?:IHalResourceLink[];
}

export interface IProject {
  id:ID;
  identifier:string;
  name:string;
  public:boolean;
  active:boolean;
  statusExplanation:IFormattable;
  description:IFormattable;

  createdAt:string;
  updatedAt:string;

  _links:IProjectHalResourceLinks;
}
