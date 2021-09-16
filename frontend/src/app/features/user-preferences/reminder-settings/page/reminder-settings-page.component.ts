import {
  ChangeDetectionStrategy,
  Component,
  Input,
  OnInit,
} from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { CurrentUserService } from 'core-app/core/current-user/current-user.service';
import { take } from 'rxjs/internal/operators/take';
import { UIRouterGlobals } from '@uirouter/core';
import { UserPreferencesService } from 'core-app/features/user-preferences/state/user-preferences.service';

export const myReminderPageComponentSelector = 'op-reminders-page';

@Component({
  selector: myReminderPageComponentSelector,
  templateUrl: './reminder-settings-page.component.html',
  styleUrls: ['./reminder-settings-page.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class ReminderSettingsPageComponent implements OnInit {
  @Input() userId:string;

  text = {
    title: this.I18n.t('js.reminders.settings.title'),
    save: this.I18n.t('js.button_save'),
    daily: {
      title: this.I18n.t('js.reminders.settings.daily.title'),
      explanation: this.I18n.t('js.reminders.settings.daily.explanation'),
    },
    immediate: {
      title: this.I18n.t('js.reminders.settings.immediate.title'),
      explanation: this.I18n.t('js.reminders.settings.immediate.explanation'),
    },
  };

  constructor(
    private I18n:I18nService,
    private storeService:UserPreferencesService,
    private currentUserService:CurrentUserService,
    private uiRouterGlobals:UIRouterGlobals,
  ) {
  }

  ngOnInit():void {
    this.userId = (this.userId || this.uiRouterGlobals.params.userId) as string;
    this
      .currentUserService
      .user$
      .pipe(take(1))
      .subscribe((user) => {
        this.userId = this.userId || user?.id as string;
        this.storeService.get(this.userId);
      });
  }

  public saveChanges():void {
    const prefs = this.storeService.query.getValue();
    this.storeService.update(this.userId, prefs);
  }
}
