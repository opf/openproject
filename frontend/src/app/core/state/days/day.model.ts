import { IHalResourceLinks } from 'core-app/core/state/hal-resource';

export interface IDay {
  id:string;
  date:string;
  name:string;
  working:boolean;
  _links:IHalResourceLinks;
}
