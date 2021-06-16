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
      .subscribe(() => this.add({
        id: 1,
        date: '5 minutes ago',
        message: 'The following work package was assigned to you: Task #1234: Deploy new website',
        reason: 'assigned',
        details: [
          'Assignee set to Oliver Günther',
          'Due date changed from 2021-08-01 to 2021-06-16'
        ],
        _links: {
          project: { href: '/api/v3/projects/1', title: 'My website project' },
          resource: { href: '/api/v3/work_packages/1234', title: 'Task #1234: Deploy new website' }
        }
      }));

    timer(10000)
      .subscribe(() => this.add({
        id: 2,
        message: 'You have been mentioned in work package Task #1234: Deploy new website',
        date: '3 minutes ago',
        reason: 'mentioned',
        details: [
          'Wieland Lindenthal wrote: Hi @Oliver Günther, can you please take a look at this one?',
        ],
        _links: {
          project: { href: '/api/v3/projects/1', title: 'My website project' },
          resource: { href: '/api/v3/work_packages/1234', title: 'Task #1234: Deploy new website' }
        }
      }));

    timer(20000)
      .subscribe(() => this.add({
        id: 3,
        date: '1 minute ago',
        message: 'The following work package was assigned to you: Bug #5432: Fix styling issues new website',
        reason: 'assigned',
        _links: {
          project: { href: '/api/v3/projects/1', title: 'My website project' },
          resource: { href: '/api/v3/work_packages/1234', title: 'Bug #5432: Fix styling issues new website' }
        }
      }));
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

  markAllRead() {
    this.store.update(null, { read: true });
  }
}
