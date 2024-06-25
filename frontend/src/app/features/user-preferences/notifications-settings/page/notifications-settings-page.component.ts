import { ChangeDetectionStrategy, ChangeDetectorRef, Component, ElementRef, Input, OnInit } from '@angular/core';
import { UntypedFormArray, UntypedFormControl, UntypedFormGroup } from '@angular/forms';
import { take } from 'rxjs/internal/operators/take';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { CurrentUserService } from 'core-app/core/current-user/current-user.service';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { UserPreferencesService } from 'core-app/features/user-preferences/state/user-preferences.service';
import { INotificationSetting } from 'core-app/features/user-preferences/state/notification-setting.model';
import { BannersService } from 'core-app/core/enterprise/banners.service';
import { enterpriseDocsUrl } from 'core-app/core/setup/globals/constants.const';
import { overDueReminderTimes, reminderAvailableTimeframes } from '../overdue-reminder-available-times';
import { ConfigurationService } from 'core-app/core/config/configuration.service';
import { populateInputsFromDataset } from 'core-app/shared/components/dataset-inputs';

export const myNotificationsPageComponentSelector = 'op-notifications-page';

interface IToastSettingsValue {
  assignee:boolean;
  responsible:boolean;
  shared:boolean;
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
  startDate:string|null;
  dueDate:string|null;
  overdue:string|null;
}

interface IFullNotificationSettingsValue extends IToastSettingsValue {
  projectSettings:IProjectNotificationSettingsValue[];
  startDate:{ active:boolean, time:string };
  dueDate:{ active:boolean, time:string };
  overdue:{ active:boolean, time:string };
}

@Component({
  templateUrl: './notifications-settings-page.component.html',
  styleUrls: ['./notifications-settings-page.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class NotificationsSettingsPageComponent extends UntilDestroyedMixin implements OnInit {
  @Input() userId:string;

  public availableTimes = reminderAvailableTimeframes();

  public availableTimesOverdue = overDueReminderTimes();

  public eeShowBanners = false;

  public form = new UntypedFormGroup({
    assignee: new UntypedFormControl(false),
    responsible: new UntypedFormControl(false),
    shared: new UntypedFormControl(false),
    workPackageCreated: new UntypedFormControl(false),
    workPackageProcessed: new UntypedFormControl(false),
    workPackageScheduled: new UntypedFormControl(false),
    workPackagePrioritized: new UntypedFormControl(false),
    workPackageCommented: new UntypedFormControl(false),
    startDate: new UntypedFormGroup({
      active: new UntypedFormControl(false),
      time: new UntypedFormControl(this.availableTimes[1]),
    }),
    dueDate: new UntypedFormGroup({
      active: new UntypedFormControl(false),
      time: new UntypedFormControl(this.availableTimes[1]),
    }),
    overdue: new UntypedFormGroup({
      active: new UntypedFormControl(false),
      time: new UntypedFormControl(this.availableTimesOverdue[0]),
    }),
    projectSettings: new UntypedFormArray([]),
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
    dateAlerts: {
      title: this.I18n.t('js.notifications.settings.global.date_alerts.title'),
      description: this.I18n.t('js.notifications.settings.global.date_alerts.description'),
    },
    mentioned: {
      title: this.I18n.t('js.notifications.settings.reasons.mentioned.title'),
      description: this.I18n.t('js.notifications.settings.reasons.mentioned.description'),
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
    assignee: this.I18n.t('js.notifications.settings.reasons.assignee'),
    responsible: this.I18n.t('js.notifications.settings.reasons.responsible'),
    shared: this.I18n.t('js.notifications.settings.reasons.shared'),
    startDate: this.I18n.t('js.work_packages.properties.startDate'),
    dueDate: this.I18n.t('js.work_packages.properties.dueDate'),
    overdue: this.I18n.t('js.notifications.settings.global.overdue'),
    teaser_text: this.I18n.t('js.notifications.settings.global.date_alerts.teaser_text'),
    upgrade_to_ee_text: this.I18n.t('js.boards.upsale.upgrade'),
    more_info_link: enterpriseDocsUrl.website,
  };

  dateAlertsStatuses = {
    startDate: false,
    dueDate: false,
    overdue: false,
  };

  constructor(
    readonly elementRef:ElementRef,
    readonly changeDetectorRef:ChangeDetectorRef,
    readonly I18n:I18nService,
    readonly storeService:UserPreferencesService,
    readonly currentUserService:CurrentUserService,
    readonly bannersService:BannersService,
    readonly configurationService:ConfigurationService,
  ) {
    super();
    populateInputsFromDataset(this);
  }

  ngOnInit():void {
    this.form.disable();
    this.eeShowBanners = this.bannersService.eeShowBanners;

    this
      .currentUserService
      .user$
      .pipe(take(1))
      .subscribe((user) => {
        this.userId = this.userId || user.id!;
        this.storeService.get(this.userId);
      });

    this.form.get('startDate.active')?.valueChanges.subscribe((newValue) => {
      this.dateAlertsStatuses.startDate = !!newValue;
    });

    this.form.get('dueDate.active')?.valueChanges.subscribe((newValue) => {
      this.dateAlertsStatuses.dueDate = !!newValue;
    });

    this.form.get('overdue.active')?.valueChanges.subscribe((newValue) => {
      this.dateAlertsStatuses.overdue = !!newValue;
    });

    this.storeService.query.notificationsForGlobal$
      .pipe(this.untilDestroyed())
      .subscribe((settings) => {
        if (!settings) {
          return;
        }

        this.form.get('assignee')?.setValue(settings.assignee);
        this.form.get('responsible')?.setValue(settings.responsible);
        this.form.get('shared')?.setValue(settings.shared);
        this.form.get('workPackageCreated')?.setValue(settings.workPackageCreated);
        this.form.get('workPackageProcessed')?.setValue(settings.workPackageProcessed);
        this.form.get('workPackageScheduled')?.setValue(settings.workPackageScheduled);
        this.form.get('workPackagePrioritized')?.setValue(settings.workPackagePrioritized);
        this.form.get('workPackageCommented')?.setValue(settings.workPackageCommented);

        this.form.get('startDate.active')?.setValue(!!settings.startDate);
        this.form.get('startDate.time')?.setValue(settings.startDate || this.availableTimes[1].value);

        this.form.get('dueDate.active')?.setValue(!!settings.dueDate);
        this.form.get('dueDate.time')?.setValue(settings.dueDate || this.availableTimes[1].value);

        this.form.get('overdue.active')?.setValue(!!settings.overdue);
        this.form.get('overdue.time')?.setValue(settings.overdue || this.availableTimesOverdue[0].value);
      });

    this.storeService.query.projectNotifications$
      .pipe(this.untilDestroyed())
      .subscribe((settings) => {
        if (!settings) {
          return;
        }

        const projectSettings = new UntypedFormArray([]);
        projectSettings.clear();
        settings
          .sort(
            (a, b):number => a._links.project.title!.localeCompare(b._links.project.title!),
          )
          .forEach((setting) => projectSettings.push(new UntypedFormGroup({
            project: new UntypedFormControl(setting._links.project),
            assignee: new UntypedFormControl(setting.assignee),
            responsible: new UntypedFormControl(setting.responsible),
            shared: new UntypedFormControl(setting.shared),
            workPackageCreated: new UntypedFormControl(setting.workPackageCreated),
            workPackageProcessed: new UntypedFormControl(setting.workPackageProcessed),
            workPackageScheduled: new UntypedFormControl(setting.workPackageScheduled),
            workPackagePrioritized: new UntypedFormControl(setting.workPackagePrioritized),
            workPackageCommented: new UntypedFormControl(setting.workPackageCommented),
            startDate: new UntypedFormControl(setting.startDate),
            dueDate: new UntypedFormControl(setting.dueDate),
            overdue: new UntypedFormControl(setting.overdue),
          })));

        this.form.setControl('projectSettings', projectSettings);
        this.changeDetectorRef.detectChanges();
      });

    this.form.enable();
  }

  public saveChanges():void {
    const prefs = this.storeService.store.getValue();
    const notificationSettings = (this.form.value as IFullNotificationSettingsValue);
    const globalNotification = prefs.notifications.find((notification) => !notification._links.project.href) as INotificationSetting;
    const globalPrefs:INotificationSetting = {
      ...globalNotification,
      _links: { project: { href: null } },
      watched: true,
      mentioned: true,
      assignee: notificationSettings.assignee,
      responsible: notificationSettings.responsible,
      shared: notificationSettings.shared,
      workPackageCreated: notificationSettings.workPackageCreated,
      workPackageProcessed: notificationSettings.workPackageProcessed,
      workPackageScheduled: notificationSettings.workPackageScheduled,
      workPackagePrioritized: notificationSettings.workPackagePrioritized,
      workPackageCommented: notificationSettings.workPackageCommented,
      startDate: notificationSettings.startDate.active ? notificationSettings.startDate.time : null,
      dueDate: notificationSettings.dueDate.active ? notificationSettings.dueDate.time : null,
      overdue: notificationSettings.overdue.active ? notificationSettings.overdue.time : null,
    };

    const projectPrefs:INotificationSetting[] = notificationSettings.projectSettings.map((settings) => ({
      _links: { project: { href: settings.project.href } },
      watched: true,
      mentioned: true,
      assignee: settings.assignee,
      responsible: settings.responsible,
      shared: settings.shared,
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
      startDate: settings.startDate,
      dueDate: settings.dueDate,
      overdue: settings.overdue,
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
