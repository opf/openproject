import { ID } from '@datorama/akita';
import { HalResourceLink, HalResourceLinks } from 'core-app/core/state/hal-resource';

export interface UserHalResourceLinks extends HalResourceLinks {
  lock:HalResourceLink;
  unlock:HalResourceLink;
  delete:HalResourceLink;
  showUser:HalResourceLink;
}

export interface User {
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

  _links:UserHalResourceLinks;
}
