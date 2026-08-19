import { Injectable, inject } from '@angular/core';
import { ApiV3Service } from 'core-app/core/apiv3/api-v3.service';
import { ToastService } from 'core-app/shared/components/toaster/toast.service';
import { ApiV3UserPreferencesPaths } from 'core-app/core/apiv3/endpoints/users/apiv3-user-preferences-paths';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { IUserPreference } from 'core-app/features/user-preferences/state/user-preferences.model';
import { UserPreferencesStore } from 'core-app/features/user-preferences/state/user-preferences.store';
import { UserPreferencesQuery } from 'core-app/features/user-preferences/state/user-preferences.query';

@Injectable({ providedIn: 'root' })
export class UserPreferencesService {
  private apiV3Service = inject(ApiV3Service);
  private toastService = inject(ToastService);
  private I18n = inject(I18nService);

  readonly store = new UserPreferencesStore();

  readonly query = new UserPreferencesQuery(this.store);

  get(user:string):void {
    this.store.setLoading(true);
    this.preferenceAPI(user)
      .get()
      .subscribe(
        (prefs) => this.store.update(prefs),
        (error) => this.toastService.addError(error),
      )
      .add(
        () => this.store.setLoading(false),
      );
  }

  update(user:string, delta:Partial<IUserPreference>):void {
    this.store.setLoading(true);
    this
      .preferenceAPI(user)
      .patch(delta)
      .subscribe(
        (prefs) => {
          this.store.update(prefs);
          this.toastService.addSuccess(this.I18n.t('js.notice_successful_update'));
        },
        (error) => this.toastService.addError(error),
      )
      .add(() => this.store.setLoading(false));
  }

  private preferenceAPI(user:string):ApiV3UserPreferencesPaths {
    return this
      .apiV3Service
      .users
      .id(user)
      .preferences;
  }
}
