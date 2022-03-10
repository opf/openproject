import {
  IHalResourceLink,
  IHalResourceLinks,
} from 'core-app/core/state/hal-resource';

export interface ICapabilityHalResourceLinks extends IHalResourceLinks {
  self:IHalResourceLink;

  action:IHalResourceLink;
  context:IHalResourceLink;
  principal:IHalResourceLink;
}

export interface ICapability {
  id:string;
  _links:ICapabilityHalResourceLinks;
}
