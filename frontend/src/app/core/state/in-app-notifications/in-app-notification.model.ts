import { ID } from '@datorama/akita';
import {
  IHalResourceLink,
  IHalResourceLinks,
} from 'core-app/core/state/hal-resource';

export const NOTIFICATIONS_MAX_SIZE = 100;

export interface IInAppNotificationHalResourceLinks extends IHalResourceLinks {
  actor:IHalResourceLink;
  project:IHalResourceLink;
  resource:IHalResourceLink;
  activity:IHalResourceLink;
}

export type IInAppNotificationDetailsAttribute = 'startDate'|'dueDate'|'date';

export interface IInAppNotificationDetailsResource {
  property:IInAppNotificationDetailsAttribute;
  value:string|null;

  _links:{
    self:IHalResourceLink;
    schema:IHalResourceLink;
  };
}

export interface IInAppNotificationHalResourceEmbedded {
  details:IInAppNotificationDetailsResource[];
}

export interface INotification {
  id:ID;
  subject:string;
  createdAt:string;
  updatedAt:string;
  reason:string;
  readIAN:boolean|null;
  readEmail:boolean|null;

  // Mark a notification to be kept in the center even though it was saved as "read".
  keep?:boolean;
  // Show message of a notification?
  expanded:boolean;

  _links:IInAppNotificationHalResourceLinks;
  _embedded:IInAppNotificationHalResourceEmbedded;
}
