import {
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  OnInit,
} from '@angular/core';
import { combineLatest } from 'rxjs';
import { map } from 'rxjs/operators';
import { StateService } from '@uirouter/core';
import idFromLink from 'core-app/features/hal/helpers/id-from-link';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { INotificationPageQueryParameters } from '../../in-app-notifications.routes';
import { IanMenuService } from './state/ian-menu.service';

export const ianMenuSelector = 'op-ian-menu';

@Component({
  selector: ianMenuSelector,
  templateUrl: './menu.component.html',
  styleUrls: ['./menu.component.sass'],
  providers: [ IanMenuService ],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class IanMenuComponent implements OnInit {
  baseMenuItems = [
    {
      title: 'Inbox',
      icon: 'inbox',
      href: this.getHrefForFilters({}),
    },
  ];

  reasonMenuItems = [
    {
      key: 'mentioned',
      title: '@mentioned',
      icon: 'mention',
      href: this.getHrefForFilters({ filter: 'reason', name: 'mentioned' }),
    },
    {
      key: 'assigned',
      title: 'Assigned',
      icon: 'assigned',
      href: this.getHrefForFilters({ filter: 'reason', name: 'assigned'  }),
    },
    {
      key: 'accountable',
      title: 'Accountable',
      icon: 'accountable',
      href: this.getHrefForFilters({ filter: 'reason', name: 'accountable'  }),
    },
    {
      key: 'watched',
      title: 'Watching',
      icon: 'watching',
      href: this.getHrefForFilters({ filter: 'reason', name: 'watched'  }),
    },
  ];

  notificationsByProject$ = this.ianMenuService.query.notificationsByProject$.pipe(
    map((items) => items.map(item => ({
      ...item,
      title: item.value,
      href: this.getHrefForFilters({ filter: 'project', name: idFromLink(item._links.valueLink[0].href) }),
    }))),
  );

  notificationsByReason$ = this.ianMenuService.query.notificationsByReason$.pipe(
    map((items) => this.reasonMenuItems.map(reason => ({
      ...items.find(item => item.value === reason.key),
      ...reason,
    })))
  );

  menuItems$ = combineLatest([
    this.notificationsByProject$,
    this.notificationsByReason$,
  ]).pipe(
    map(([byProject, byReason]) => [
      ...this.baseMenuItems,
      {
        title: 'By Reason',
        collapsible: true,
        children: byReason,
      },
      {
        title: 'By Project',
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

  ngOnInit() {
    this.ianMenuService.reload();
  }

  private getHrefForFilters(filters:INotificationPageQueryParameters = {}) {
    return this.state.href('notifications', filters);
  }
}
