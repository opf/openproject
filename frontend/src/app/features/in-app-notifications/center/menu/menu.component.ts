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
  providers: [IanMenuService],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class IanMenuComponent implements OnInit {
  baseMenuItems = [
    {
      title: this.I18n.t('js.notifications.menu.inbox'),
      icon: 'inbox',
      href: this.getHrefForFilters({}),
    },
  ];

  reasonMenuItems = [
    {
      key: 'mentioned',
      title: this.I18n.t('js.notifications.menu.mentioned'),
      icon: 'mention',
      href: this.getHrefForFilters({ filter: 'reason', name: 'mentioned' }),
    },
    {
      key: 'assigned',
      title: this.I18n.t('js.notifications.menu.assigned'),
      icon: 'assigned',
      href: this.getHrefForFilters({ filter: 'reason', name: 'assigned' }),
    },
    {
      key: 'responsible',
      title: this.I18n.t('js.notifications.menu.accountable'),
      icon: 'accountable',
      href: this.getHrefForFilters({ filter: 'reason', name: 'responsible' }),
    },
    {
      key: 'watched',
      title: this.I18n.t('js.notifications.menu.watching'),
      icon: 'watching',
      href: this.getHrefForFilters({ filter: 'reason', name: 'watched' }),
    },
  ];

  notificationsByProject$ = this.ianMenuService.query.notificationsByProject$.pipe(
    map((items) => items
      .map((item) => ({
        ...item,
        title: (item.projectHasParent ? '...' : '') + item.value,
        href: this.getHrefForFilters({ filter: 'project', name: String(idFromLink(item._links.valueLink[0].href)) }),
      }))
      .sort((a, b) => {
        if (b.projectHasParent && !a.projectHasParent) {
          return -1;
        }

        return a.value.toLowerCase().localeCompare(b.value.toLowerCase());
      })),
  );

  notificationsByReason$ = this.ianMenuService.query.notificationsByReason$.pipe(
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
      ...this.baseMenuItems,
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

  private getHrefForFilters(filters:INotificationPageQueryParameters = {}) {
    return this.state.href('notifications', filters);
  }
}
