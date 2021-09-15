import {
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  OnInit,
} from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
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
  }
}
