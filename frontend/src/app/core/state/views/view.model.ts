import { ID } from '@datorama/akita';
import {
  HalResourceLink,
  HalResourceLinks,
} from 'core-app/core/state/hal-resource';

export interface ViewLinks extends HalResourceLinks {
  query:HalResourceLink
}

export interface View {
  id:ID;
  _links:ViewLinks;
}
