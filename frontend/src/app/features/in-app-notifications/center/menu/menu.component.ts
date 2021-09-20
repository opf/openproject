import {
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  OnInit,
} from '@angular/core';
import { map } from 'rxjs/operators';
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
  notificationsByProject$ = this.ianMenuService.query.notificationsByProject$;
  notificationsByReason$ = this.ianMenuService.query.notificationsByReason$; /*.pipe(
    map((items) => {

    }),
  );*/

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
