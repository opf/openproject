import { ID } from "@datorama/akita";

export interface HalResourceLink {
  href:string;
  title:string;
}
export type InAppNotificationFormat = 'markdown'|'custom';

export interface InAppNotificationDetail {
  format:InAppNotificationFormat;
  raw:string|null;
  html:string;
}

export interface InAppNotification {
  id:ID;
  subject:string;
  date:string;
  reason:string;
  read?:boolean;

  details?:InAppNotificationDetail[];

  _links:{
    actor?:HalResourceLink,
    project?:HalResourceLink,
    resource?:HalResourceLink,
    activity?:HalResourceLink,
  };
}