import { ID } from '@datorama/akita';
import { HalResourceLink, HalResourceLinks } from 'core-app/core/state/hal-resource';

export interface PlaceholderUserHalResourceLinks extends HalResourceLinks {
  updateImmediately:HalResourceLink;
  delete:HalResourceLink;
  showUser:HalResourceLink;
}

export interface PlaceholderUser {
  id:ID;
  name:string;
  createdAt:string;
  updatedAt:string;

  _links:PlaceholderUserHalResourceLinks;
}
