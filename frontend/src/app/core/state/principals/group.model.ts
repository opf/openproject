import { ID } from '@datorama/akita';
import { IHalResourceLinks } from 'core-app/core/state/hal-resource';

export interface IGroupHalResourceLinks extends IHalResourceLinks { }

export interface IGroup {
  id:ID;
  name:string;
  createdAt:string;
  updatedAt:string;

  _links:IGroupHalResourceLinks;
}
