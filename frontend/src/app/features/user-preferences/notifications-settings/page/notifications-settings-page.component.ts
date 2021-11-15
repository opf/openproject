import {
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  Input,
  OnInit,
} from '@angular/core';
import {
  FormGroup,
  FormArray,
  FormControl,
} from '@angular/forms';
import { take } from 'rxjs/internal/operators/take';
import { UIRouterGlobals } from '@uirouter/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { CurrentUserService } from 'core-app/core/current-user/current-user.service';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { UserPreferencesService } from 'core-app/features/user-preferences/state/user-preferences.service';
import { NotificationSetting } from 'core-app/features/user-preferences/state/notification-setting.model';

export const myNotificationsPageComponentSelector = 'op-notifications-page';

interface IToastSettingsValue {
  involved:boolean;
  workPackageCreated:boolean;
  workPackageProcessed:boolean;
  workPackageScheduled:boolean;
  workPackagePrioritized:boolean;
  workPackageCommented:boolean;
}

interface IProjectNotificationSettingsValue extends IToastSettingsValue {
  project:{
    title:string;
    href:string;
  };
}

interface IFullNotificationSettingsValue extends IToastSettingsValue {
  projectSettings:IProjectNotificationSettingsValue[];
}

@Component({
  selector: myNotificationsPageComponentSelector,
  templateUrl: './notifications-settings-page.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class NotificationsSettingsPageComponent extends UntilDestroyedMixin implements OnInit {
  @Input() userId:string;

  public form = new FormGroup({
    involved: new FormControl(false),
    workPackageCreated: new FormControl(false),
    workPackageProcessed: new FormControl(false),
    workPackageScheduled: new FormControl(false),
    workPackagePrioritized: new FormControl(false),
    workPackageCommented: new FormControl(false),
    projectSettings: new FormArray([]),
  });

  text = {
    notifyImmediately: {
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
    private changeDetectorRef:ChangeDetectorRef,
    private I18n:I18nService,
    private storeService:UserPreferencesService,
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
        this.storeService.get(this.userId);
      });

    this.storeService.query.notificationsForGlobal$
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

    this.storeService.query.projectNotifications$
      .pipe(this.untilDestroyed())
      .subscribe((settings) => {
        if (!settings) {
          return;
        }

        const projectSettings = new FormArray([]);
        projectSettings.clear();
        settings
          .sort(
            (a, b):number => a._links.project.title!.localeCompare(b._links.project.title!),
          )
          .forEach((setting) => projectSettings.push(new FormGroup({
            project: new FormControl(setting._links.project),
            involved: new FormControl(setting.involved),
            workPackageCreated: new FormControl(setting.workPackageCreated),
            workPackageProcessed: new FormControl(setting.workPackageProcessed),
            workPackageScheduled: new FormControl(setting.workPackageScheduled),
            workPackagePrioritized: new FormControl(setting.workPackagePrioritized),
            workPackageCommented: new FormControl(setting.workPackageCommented),
          })));

        this.form.setControl('projectSettings', projectSettings);
        this.changeDetectorRef.detectChanges();
      });
  }

  public saveChanges():void {
    const prefs = this.storeService.store.getValue();
    const notificationSettings = (this.form.value as IFullNotificationSettingsValue);
    const globalNotification = prefs.notifications.find((notification) => !notification._links.project.href) as NotificationSetting;
    const globalPrefs:NotificationSetting = {
      ...globalNotification,
      _links: { project: { href: null } },
      watched: true,
      mentioned: true,
      involved: notificationSettings.involved,
      workPackageCreated: notificationSettings.workPackageCreated,
      workPackageProcessed: notificationSettings.workPackageProcessed,
      workPackageScheduled: notificationSettings.workPackageScheduled,
      workPackagePrioritized: notificationSettings.workPackagePrioritized,
      workPackageCommented: notificationSettings.workPackageCommented,
    };

    const projectPrefs:NotificationSetting[] = notificationSettings.projectSettings.map((settings) => ({
      _links: { project: { href: settings.project.href } },
      watched: true,
      mentioned: true,
      involved: settings.involved,
      workPackageCreated: settings.workPackageCreated,
      workPackageProcessed: settings.workPackageProcessed,
      workPackageScheduled: settings.workPackageScheduled,
      workPackagePrioritized: settings.workPackagePrioritized,
      workPackageCommented: settings.workPackageCommented,
      newsAdded: false,
      newsCommented: false,
      documentAdded: false,
      forumMessages: false,
      wikiPageAdded: false,
      wikiPageUpdated: false,
      membershipAdded: false,
      membershipUpdated: false,
    }));

    this.storeService.update(this.userId, {
      ...prefs,
      notifications: [
        globalPrefs,
        ...projectPrefs,
      ],
    });
  }
}
