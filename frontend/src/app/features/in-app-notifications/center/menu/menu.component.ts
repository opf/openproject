// -- copyright
// OpenProject is an open source project management software.
// Copyright (C) 2012-2022 the OpenProject GmbH
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
// along with this program; if not, write to the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
//
// See COPYRIGHT and LICENSE files for more details.
//++

import {
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  OnInit,
  HostBinding,
} from '@angular/core';
import { combineLatest } from 'rxjs';
import { map } from 'rxjs/operators';
import { StateService } from '@uirouter/core';
import idFromLink from 'core-app/features/hal/helpers/id-from-link';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { INotificationPageQueryParameters } from '../../in-app-notifications.routes';
import { IanMenuService } from './state/ian-menu.service';

export const ianMenuSelector = 'op-ian-menu';

const getUiLinkForFilters = (filters:INotificationPageQueryParameters = {}) => ({
  uiSref: 'notifications.center.show',
  uiParams: filters,
});

@Component({
  selector: ianMenuSelector,
  templateUrl: './menu.component.html',
  styleUrls: ['./menu.component.sass'],
  providers: [IanMenuService],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class IanMenuComponent implements OnInit {
  @HostBinding('class.op-ian-menu') className = true;

  baseMenuItems = [
    {
      key: 'inbox',
      title: this.I18n.t('js.notifications.menu.inbox'),
      icon: 'inbox',
      ...getUiLinkForFilters({ filter: '', name: '' }),
    },
  ];

  reasonMenuItems = [
    {
      key: 'mentioned',
      title: this.I18n.t('js.notifications.menu.mentioned'),
      icon: 'mention',
      ...getUiLinkForFilters({ filter: 'reason', name: 'mentioned' }),
    },
    {
      key: 'assigned',
      title: this.I18n.t('js.label_assignee'),
      icon: 'assigned',
      ...getUiLinkForFilters({ filter: 'reason', name: 'assigned' }),
    },
    {
      key: 'responsible',
      title: this.I18n.t('js.notifications.menu.accountable'),
      icon: 'accountable',
      ...getUiLinkForFilters({ filter: 'reason', name: 'responsible' }),
    },
    {
      key: 'watched',
      title: this.I18n.t('js.notifications.menu.watched'),
      icon: 'watching',
      ...getUiLinkForFilters({ filter: 'reason', name: 'watched' }),
    },
    {
      key: 'date_alert',
      title: this.I18n.t('js.notifications.menu.date_alert'),
      icon: 'date-alert',
      ...getUiLinkForFilters({ filter: 'reason', name: 'date_alert' }),
    },
  ];

  notificationsByProject$ = this.ianMenuService.notificationsByProject$.pipe(
    map((items) => items
      .map((item) => ({
        ...item,
        title: (item.projectHasParent ? '... ' : '') + item.value,
        ...getUiLinkForFilters({ filter: 'project', name: idFromLink(item._links.valueLink[0].href) }),
      }))
      .sort((a, b) => {
        if (b.projectHasParent && !a.projectHasParent) {
          return -1;
        }

        return a.value.toLowerCase().localeCompare(b.value.toLowerCase());
      })),
  );

  notificationsByReason$ = this.ianMenuService.notificationsByReason$.pipe(
    map((items) => this.reasonMenuItems.map((reason) => ({
      ...items.find((item) => item.value === reason.key),
      ...reason,
    }))),
  );

  menuItems$ = combineLatest([
    this.notificationsByProject$,
    this.notificationsByReason$,
  ]).pipe(
    map(([byProject, byReason]) => [
      ...this.baseMenuItems.map((baseMenuItem) => ({
        ...baseMenuItem,
        count: byProject.reduce((a, b) => a + (b.count || 0), 0),
      })),
      {
        title: this.I18n.t('js.notifications.menu.by_reason'),
        collapsible: true,
        children: byReason,
      },
      {
        title: this.I18n.t('js.notifications.menu.by_project'),
        collapsible: true,
        children: byProject,
      },
    ]),
  );

  text = {
    title: this.I18n.t('js.notifications.title'),
    button_close: this.I18n.t('js.button_close'),
    no_results: {
      unread: this.I18n.t('js.notifications.no_unread'),
      all: this.I18n.t('js.notice_no_results_to_display'),
    },
  };

  constructor(
    readonly cdRef:ChangeDetectorRef,
    readonly I18n:I18nService,
    readonly ianMenuService:IanMenuService,
    readonly state:StateService,
  ) { }

  ngOnInit():void {
    this.ianMenuService.reload();
  }
}
