import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { APIV3Service } from 'core-app/core/apiv3/api-v3.service';
import { NotificationsService } from 'core-app/shared/components/notifications/notifications.service';
import { Apiv3UserPreferencesPaths } from 'core-app/core/apiv3/endpoints/users/apiv3-user-preferences-paths';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { UserPreferencesModel } from 'core-app/features/user-preferences/state/user-preferences.model';
import { UserPreferencesStore } from 'core-app/features/user-preferences/state/user-preferences.store';

@Injectable({ providedIn: 'root' })
export class UserPreferencesService {
  constructor(
    private store:UserPreferencesStore,
    private http:HttpClient,
    private apiV3Service:APIV3Service,
    private notifications:NotificationsService,
    private I18n:I18nService,
  ) {
  }

  get(user:string):void {
    this.store.setLoading(true);
    this.preferenceAPI(user)
      .get()
      .subscribe(
        (prefs) => this.store.update(prefs),
        (error) => this.notifications.addError(error),
      )
      .add(
        () => this.store.setLoading(false),
      );
  }

  update(user:string, delta:Partial<UserPreferencesModel>):void {
    this.store.setLoading(true);
    this
      .preferenceAPI(user)
      .patch(delta)
      .subscribe(
        (prefs) => {
          this.store.update(prefs);
          this.notifications.addSuccess(this.I18n.t('js.notice_successful_update'));
        },
        (error) => this.notifications.addError(error),
      )
      .add(() => this.store.setLoading(false));
  }

  private preferenceAPI(user:string):Apiv3UserPreferencesPaths {
    return this
      .apiV3Service
      .users
      .id(user)
      .preferences;
  }
}
