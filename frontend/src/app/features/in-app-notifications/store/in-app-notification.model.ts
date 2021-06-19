import { ID } from "@datorama/akita";

export interface HalResourceLink {
  href:string;
  title:string;
}

export interface InAppNotification {
  id:ID;
  subject:string;
  date:string;
  reason:string;
  read?:boolean;

  details?:string[];

  _links:{
    context?:HalResourceLink,
    resource:HalResourceLink,
  };
}