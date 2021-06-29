import { Injectable } from "@angular/core";
import { EntityState, EntityStore, StoreConfig } from "@datorama/akita";
import { CurrentUserState } from "core-app/core/current-user/current-user.store";
import { InAppNotification } from "./in-app-notification.model";

export interface InAppNotificationsState extends EntityState<InAppNotification> {
  count:number;
  activeFacet:string;
  expanded:boolean;
}

export function createInitialState():InAppNotificationsState {
  return {
    count: 0,
    notShowing: 0,
    activeFacet: "unread",
    expanded: false,
  };
}

@Injectable({ providedIn: "root" })
@StoreConfig({ name: "in-app-notifications" })
export class InAppNotificationsStore extends EntityStore<InAppNotificationsState> {
  constructor() {
    super(createInitialState());
  }
}
