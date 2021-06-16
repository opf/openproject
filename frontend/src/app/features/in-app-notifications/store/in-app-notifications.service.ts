import { Injectable } from '@angular/core';
import { ID } from '@datorama/akita';
import { InAppNotification } from './in-app-notification.model';
import { InAppNotificationsStore } from './in-app-notifications.store';
import { timer } from "rxjs";

@Injectable({ providedIn: 'root' })
export class InAppNotificationsService {

  constructor(
    private store:InAppNotificationsStore
  ) {
  }

  get():void {
    timer(5000)
      .subscribe(() => this.add({ id: 3, message: 'A new ticket was assigned to you!' }));

    timer(10000)
      .subscribe(() => this.add({ id: 1, message: 'A new ticket was assigned to you!' }));

    timer(20000)
      .subscribe(() => this.add({ id: 2, message: 'You were mentioned in the following ticket: #1234' }));
  }

  add(inAppNotification:InAppNotification):void {
    this.store.add(inAppNotification);
  }

  update(id:ID, inAppNotification:Partial<InAppNotification>):void {
    this.store.update(id, inAppNotification);
  }

  remove(id:ID):void {
    this.store.remove(id);
  }
}
