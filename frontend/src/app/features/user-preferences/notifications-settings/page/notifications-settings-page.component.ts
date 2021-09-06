import {
  ChangeDetectionStrategy,
  Component,
  Input,
  OnInit,
} from '@angular/core';
import {
  FormGroup,
  FormControl,
} from '@angular/forms';
import { arrayUpdate } from '@datorama/akita';
import { take } from 'rxjs/internal/operators/take';
import { UIRouterGlobals } from '@uirouter/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { CurrentUserService } from 'core-app/core/current-user/current-user.service';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { UserPreferencesService } from 'core-app/features/user-preferences/state/user-preferences.service';
import { UserPreferencesStore } from 'core-app/features/user-preferences/state/user-preferences.store';
import { UserPreferencesQuery } from 'core-app/features/user-preferences/state/user-preferences.query';
import { NotificationSetting } from 'core-app/features/user-preferences/state/notification-setting.model';

export const myNotificationsPageComponentSelector = 'op-notifications-page';

@Component({
  selector: myNotificationsPageComponentSelector,
  templateUrl: './notifications-settings-page.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class NotificationsSettingsPageComponent extends UntilDestroyedMixin implements OnInit {
  @Input() userId:string;

  public form = new FormGroup({
    involved: new FormControl(false, []),
    workPackageCreated: new FormControl(false, []),
    workPackageProcessed: new FormControl(false, []),
    workPackageScheduled: new FormControl(false, []),
    workPackagePrioritized: new FormControl(false, []),
    workPackageCommented: new FormControl(false, []),
  });

  text = {
    saveImmediately: {
      title: this.I18n.t('js.notifications.settings.global.immediately.title'),
      description: this.I18n.t('js.notifications.settings.global.immediately.description'),
    },
    alsoNotifyFor: {
      title: this.I18n.t('js.notifications.settings.global.delayed.title'),
      description: this.I18n.t('js.notifications.settings.global.delayed.description'),
    },
    mentioned: {
      title: this.I18n.t('js.notifications.settings.reasons.mentioned.title'),
      description: this.I18n.t('js.notifications.settings.reasons.mentioned.description'),
    },
    involved: {
      title: this.I18n.t('js.notifications.settings.reasons.involved.title'),
      description: this.I18n.t('js.notifications.settings.reasons.involved.description'),
    },
    watched: this.I18n.t('js.notifications.settings.reasons.watched'),
    work_package_commented: this.I18n.t('js.notifications.settings.reasons.work_package_commented'),
    work_package_created: this.I18n.t('js.notifications.settings.reasons.work_package_created'),
    work_package_processed: this.I18n.t('js.notifications.settings.reasons.work_package_processed'),
    work_package_prioritized: this.I18n.t('js.notifications.settings.reasons.work_package_prioritized'),
    work_package_scheduled: this.I18n.t('js.notifications.settings.reasons.work_package_scheduled'),
    save: this.I18n.t('js.button_save'),
    projectSpecific: {
      title: this.I18n.t('js.notifications.settings.project_specific.title'),
      description: this.I18n.t('js.notifications.settings.project_specific.description'),
    },
  };

  constructor(
    private I18n:I18nService,
    private stateService:UserPreferencesService,
    private query:UserPreferencesQuery,
    private store:UserPreferencesStore,
    private currentUserService:CurrentUserService,
    private uiRouterGlobals:UIRouterGlobals,
  ) {
    super();
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

    this.query.notificationsForGlobal$
      .pipe(this.untilDestroyed())
      .subscribe((settings) => {
        if (!settings) {
          return;
        }

        this.form.get('involved')?.setValue(settings.involved);
        this.form.get('workPackageCreated')?.setValue(settings.workPackageCreated);
        this.form.get('workPackageProcessed')?.setValue(settings.workPackageProcessed);
        this.form.get('workPackageScheduled')?.setValue(settings.workPackageScheduled);
        this.form.get('workPackagePrioritized')?.setValue(settings.workPackagePrioritized);
        this.form.get('workPackageCommented')?.setValue(settings.workPackageCommented);
      });
  }

  public saveChanges():void {
    this.update(this.form.value);
    const prefs = this.query.getValue();
    this.stateService.update(this.userId, prefs);
  }

  private update(delta:Partial<NotificationSetting>) {
    this.store.update(
      ({ notifications }) => ({
        notifications: arrayUpdate(
          notifications,
          (notification:NotificationSetting) => notification._links.project.href === null,
          {
            ...delta,
            mentioned: true,
            watched: true,
          },
        ),
      }),
    );
  }
}
