import { ID } from '@datorama/akita';

export interface HalResourceLink {
  href:string;
  title:string;
}
export type InAppNotificationFormat = 'markdown'|'custom';

export const NOTIFICATIONS_MAX_SIZE = 100;

export interface InAppNotificationDetail {
  format:InAppNotificationFormat;
  raw:string|null;
  html:string;
}

export interface InAppNotification {
  id:ID;
  subject:string;
  createdAt:string;
  updatedAt:string;
  reason:string;
  readIAN:boolean|null;
  readEmail:boolean|null;

  details?:InAppNotificationDetail[];
  // Mark a notification to be kept in the center even though it was saved as "read".
  keep?:boolean;
  // Show message of a notification?
  expanded:boolean;

  _links:{
    actor?:HalResourceLink,
    project?:HalResourceLink,
    resource?:HalResourceLink,
    activity?:HalResourceLink,
  };
}
