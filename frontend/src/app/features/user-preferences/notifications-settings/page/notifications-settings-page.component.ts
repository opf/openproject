import {
  ChangeDetectionStrategy, Component, Input, OnInit,
} from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { CurrentUserService } from 'core-app/core/current-user/current-user.service';
import { take } from 'rxjs/internal/operators/take';
import { UIRouterGlobals } from '@uirouter/core';
import { UserPreferencesService } from 'core-app/features/user-preferences/state/user-preferences.service';
import { UserPreferencesQuery } from 'core-app/features/user-preferences/state/user-preferences.query';

export const myNotificationsPageComponentSelector = 'op-notifications-page';

@Component({
  selector: myNotificationsPageComponentSelector,
  templateUrl: './notifications-settings-page.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class NotificationsSettingsPageComponent implements OnInit {
  @Input() userId:string;

  text = {
    save: this.I18n.t('js.button_save'),
    email: this.I18n.t('js.notifications.email'),
    inApp: this.I18n.t('js.notifications.in_app'),
    default_all_projects: this.I18n.t('js.notifications.settings.default_all_projects'),
  };

  constructor(
    private I18n:I18nService,
    private stateService:UserPreferencesService,
    private query:UserPreferencesQuery,
    private currentUserService:CurrentUserService,
    private uiRouterGlobals:UIRouterGlobals,
  ) {
  }

  ngOnInit():void {
    this.userId = this.userId || this.uiRouterGlobals.params.userId;
    this
      .currentUserService
      .user$
      .pipe(take(1))
      .subscribe((user) => {
        this.userId = this.userId || user.id!;
        this.stateService.get(this.userId);
      });
  }

  public saveChanges():void {
    const prefs = this.query.getValue();
    this.stateService.update(this.userId, prefs);
  }
}
