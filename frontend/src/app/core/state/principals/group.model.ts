import { ID } from '@datorama/akita';
import { HalResourceLinks } from 'core-app/core/state/hal-resource';

export interface GroupHalResourceLinks extends HalResourceLinks { }

export interface Group {
  id:ID;
  name:string;
  createdAt:string;
  updatedAt:string;

  _links:GroupHalResourceLinks;
}
