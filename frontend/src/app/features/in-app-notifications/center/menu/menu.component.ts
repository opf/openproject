import {
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  OnInit,
} from '@angular/core';
import { combineLatest } from 'rxjs';
import { map } from 'rxjs/operators';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { IanMenuService } from './state/ian-menu.service';

export const ianMenuSelector = 'op-ian-menu';

const REASON_MENU_ITEMS = [
  { key: 'mentioned', title: '@mentioned' },
  { key: 'involved', title: 'Involved' },
  { key: 'watched', title: 'Watched' },
  { key: 'created', title: 'Created' },
  { key: 'assigned', title: 'Assigned' },
  { key: 'accountable', title: 'Accountable' },
  { key: 'commented', title: 'Commented' },
];

@Component({
  selector: ianMenuSelector,
  templateUrl: './menu.component.html',
  styleUrls: ['./menu.component.sass'],
  providers: [ IanMenuService ],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class IanMenuComponent implements OnInit {
  notificationsByProject$ = this.ianMenuService.query.notificationsByProject$.pipe(
    map((items) => items.map(item => ({
      ...item,
      title: item.value,
    }))),
  );
  notificationsByReason$ = this.ianMenuService.query.notificationsByReason$.pipe(
    map((items) => REASON_MENU_ITEMS.map(reason => ({
      ...items.find(item => item.value === reason.key),
      ...reason,
    })))
  );

  menuItems$ = combineLatest([
    this.notificationsByProject$,
    this.notificationsByReason$,
  ]).pipe(
    map(([byProject, byReason]) => [
      { title: 'Inbox', href: '#' },
      { title: 'Flagged', href: '#' },
      { title: 'My Comments', href: '#' },
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
  ) {
    console.log('menu');
  }

  ngOnInit() {
    this.ianMenuService.reload();
    this.notificationsByProject$.subscribe(console.log);
  }
}
