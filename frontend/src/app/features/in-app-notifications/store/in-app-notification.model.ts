import { ID } from "@datorama/akita";

export interface InAppNotification {
  id:ID;
  message:string;
  read?:boolean;
}