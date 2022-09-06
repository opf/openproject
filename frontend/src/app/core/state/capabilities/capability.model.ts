import {
  IHalOptionalTitledLink,
  IHalResourceLink,
  IHalResourceLinks,
} from 'core-app/core/state/hal-resource';

export interface ICapabilityHalResourceLinks {
  self:IHalOptionalTitledLink;

  action:IHalOptionalTitledLink;
  context:IHalResourceLink;
  principal:IHalResourceLink;
}

export interface ICapability {
  id:string;
  _links:ICapabilityHalResourceLinks;
}
