import { ID } from '@datorama/akita';
import { IHalResourceLink, IHalResourceLinks } from 'core-app/core/state/hal-resource';

export interface IPlaceholderUserHalResourceLinks extends IHalResourceLinks {
  updateImmediately:IHalResourceLink;
  delete:IHalResourceLink;
  showUser:IHalResourceLink;
}

export interface IPlaceholderUser {
  id:ID;
  name:string;
  createdAt:string;
  updatedAt:string;

  _links:IPlaceholderUserHalResourceLinks;
}
