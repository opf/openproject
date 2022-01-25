import { ID } from '@datorama/akita';
import { IHalResourceLink, IHalResourceLinks } from 'core-app/core/state/hal-resource';

export interface IUserHalResourceLinks extends IHalResourceLinks {
  lock:IHalResourceLink;
  unlock:IHalResourceLink;
  delete:IHalResourceLink;
  showUser:IHalResourceLink;
}

export interface IUser {
  id:ID;
  name:string;
  createdAt:string;
  updatedAt:string;

  // Properties
  login:string;

  firstName:string;

  lastName:string;

  email:string;

  avatar:string;

  status:string;

  _links:IUserHalResourceLinks;
}
