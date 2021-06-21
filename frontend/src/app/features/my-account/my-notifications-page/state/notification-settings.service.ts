import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { NotificationSettingsStore } from './notification-settings.store';
import { applyTransaction } from "@datorama/akita";
import { APIV3Service } from "core-app/core/apiv3/api-v3.service";
import { NotificationsService } from "core-app/shared/components/notifications/notifications.service";
import { Apiv3UserPreferencesPaths } from "core-app/core/apiv3/endpoints/users/apiv3-user-preferences-paths";
import { NotificationSetting } from "core-app/features/my-account/my-notifications-page/state/notification-setting.model";
import { Observable } from "rxjs";
import { tap } from "rxjs/operators";

@Injectable({ providedIn: 'root' })
export class NotificationSettingsService {

  constructor(
    private store:NotificationSettingsStore,
    private http:HttpClient,
    private apiV3Service:APIV3Service,
    private notifications:NotificationsService,
  ) {
  }

  get(user:string):void {
    this.store.setLoading(true);
    this.preferenceAPI(user)
      .get()
      .subscribe(
        prefs => this.store.update({ notifications: prefs.notifications }),
        error => this.notifications.addError(error)
      )
      .add(
        () => this.store.setLoading(false)
      );
  }

  update(user:string, notifications:NotificationSetting[]):void {
    this
      .preferenceAPI(user)
      .patch({ notifications })
      .pipe(
        tap(prefs => this.store.update({ notifications: prefs.notifications }))
      );
  }

  private preferenceAPI(user:string):Apiv3UserPreferencesPaths {
    return this
      .apiV3Service
      .users
      .id(user)
      .preferences;
  }
}
