import { ID } from '@datorama/akita';
import {
  IHalResourceLink,
  IHalResourceLinks,
} from 'core-app/core/state/hal-resource';

export interface IViewLinks extends IHalResourceLinks {
  query:IHalResourceLink
}

export interface IView {
  id:ID;
  starred:boolean;
  public:boolean;
  _links:IViewLinks;
}

export interface IViewCreatePayload {
  _links:{
    [P in 'query']:{
      [Q in 'href']:string
    }
  }
}
