import { ID } from '@datorama/akita';
import {
  HalResourceLink,
  HalResourceLinks,
  Formattable,
} from 'core-app/core/state/hal-resource';

export const NOTIFICATIONS_MAX_SIZE = 100;

export interface InAppNotificationHalResourceLinks extends HalResourceLinks {
  actor:HalResourceLink;
  project:HalResourceLink;
  resource:HalResourceLink;
  activity:HalResourceLink;
}

export interface InAppNotification {
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

  _links:InAppNotificationHalResourceLinks;
}
