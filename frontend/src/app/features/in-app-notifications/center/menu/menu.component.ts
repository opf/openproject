import {
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  OnInit,
} from '@angular/core';
import { combineLatest } from 'rxjs';
import { map } from 'rxjs/operators';
import idFromLink from 'core-app/features/hal/helpers/id-from-link';
import {
  PathHelperService,
  INotificationPageQueryParameters,
} from 'core-app/core/path-helper/path-helper.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { IanMenuService } from './state/ian-menu.service';

export const ianMenuSelector = 'op-ian-menu';

const REASON_MENU_ITEMS = [
];

@Component({
  selector: ianMenuSelector,
  templateUrl: './menu.component.html',
  styleUrls: ['./menu.component.sass'],
  providers: [ IanMenuService ],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class IanMenuComponent implements OnInit {
  baseMenuItems = [
    { title: 'Inbox', href: this.getHrefForFilters({}) },
    { title: 'Flagged', href: this.getHrefForFilters({}) },
    { title: 'My Comments', href: this.getHrefForFilters({}) },
  ];

  reasonMenuItems = [
    { key: 'mentioned', title: '@mentioned', href: this.getHrefForFilters({ reason: 'mentioned' }) },
    { key: 'involved', title: 'Involved', href: this.getHrefForFilters({ reason: 'involved'  }) },
    { key: 'watched', title: 'Watched', href: this.getHrefForFilters({ reason: 'watched'  }) },
    { key: 'created', title: 'Created', href: this.getHrefForFilters({ reason: 'created'  }) },
    { key: 'assigned', title: 'Assigned', href: this.getHrefForFilters({ reason: 'assigned'  }) },
    { key: 'accountable', title: 'Accountable', href: this.getHrefForFilters({ reason: 'accountable'  }) },
    { key: 'commented', title: 'Commented', href: this.getHrefForFilters({ reason: 'commented'  }) },
  ];

  notificationsByProject$ = this.ianMenuService.query.notificationsByProject$.pipe(
    map((items) => items.map(item => ({
      ...item,
      title: item.value,
      href: this.getHrefForFilters({ project: idFromLink(item._links.valueLink[0].href) }),
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
    readonly pathHelper:PathHelperService,
  ) {
  }

  ngOnInit() {
    this.ianMenuService.reload();
  }

  private getHrefForFilters(filters:INotificationPageQueryParameters = {}) {
    return this.pathHelper.notificationsPath(filters);
  }
}
