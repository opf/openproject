//-- copyright
// OpenProject is an open source project management software.
// Copyright (C) the OpenProject GmbH
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License version 3.
//
// OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
// Copyright (C) 2006-2013 Jean-Philippe Lang
// Copyright (C) 2010-2013 the ChiliProject Team
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import { Config } from './config';
import { Tags } from './constants';
import type { GroupWithFingerprint, MoreWithFingerprint, PlanItem } from './notification-plan';
import { sw } from './sw-global';

/** Lists, closes and shows the worker's notifications; every tag carries the worker's prefix. */
export class Notifications {
  static async listOpen():Promise<Notification[]> {
    const notifications = await sw.registration.getNotifications();
    return notifications.filter((notification) => notification.tag.startsWith(Tags.prefix));
  }

  static ownerOf(tag:string):string|undefined {
    return Tags.workPackage.exec(tag)?.[1];
  }

  static close(open:Notification[], tags:string[]):void {
    open.filter((notification) => tags.includes(notification.tag)).forEach((notification) => notification.close());
  }

  static closeAll(open:Notification[]):void {
    open.forEach((notification) => notification.close());
  }

  static show(item:PlanItem):Promise<void> {
    switch (item.kind) {
      case 'alert':
        return Notifications.showGroup(item.group, { renotify: true });
      case 'refresh':
        return Notifications.showGroup(item.group, { silent: true, renotify: false });
      case 'more':
        return Notifications.showMore(item.more);
      case 'nothingNew':
        return Notifications.showFallback(Tags.nothingNew);
      default:
        return Notifications.showFallback();
    }
  }

  static showGroup(group:GroupWithFingerprint, flags:ShowOptions):Promise<void> {
    return Notifications.display(group.title, {
      tag: group.tag,
      body: group.body,
      data: { url: group.url, revision: group.revision },
      ...flags,
    });
  }

  static showMore(more:MoreWithFingerprint):Promise<void> {
    return Notifications.display(more.title, {
      tag: Tags.more,
      silent: true,
      data: { url: more.url, revision: more.title },
    });
  }

  static showFallback(tag:string = Tags.placeholder):Promise<void> {
    return Notifications.display(Config.push.fallbackTitle, {
      tag,
      silent: true,
      renotify: false,
      data: { url: Config.urls.home, revision: 'fallback' },
    });
  }

  static showAllRead():Promise<void> {
    return Notifications.display(Config.push.allReadTitle, {
      tag: Tags.placeholder,
      silent: true,
      data: { url: Config.urls.home, revision: 'all-read' },
    });
  }

  static display(title:string, options:ShowOptions):Promise<void> {
    return sw.registration.showNotification(title, { icon: Config.push.icon, ...options });
  }
}

type ShowOptions = NotificationOptions & { renotify?:boolean };
