import { ChangeDetectionStrategy, ChangeDetectorRef, Component, ElementRef, Input, OnInit } from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { CurrentUserService } from 'core-app/core/current-user/current-user.service';
import { take } from 'rxjs/internal/operators/take';
import { UserPreferencesService } from 'core-app/features/user-preferences/state/user-preferences.service';
import { UntypedFormArray, UntypedFormBuilder } from '@angular/forms';
import {
  DailyRemindersSettings,
  ImmediateRemindersSettings,
  IUserPreference,
  PauseRemindersSettings,
} from 'core-app/features/user-preferences/state/user-preferences.model';
import {
  emailAlerts,
  EmailAlertType,
} from 'core-app/features/user-preferences/reminder-settings/email-alerts/email-alerts-settings.component';
import { UntilDestroyedMixin } from 'core-app/shared/helpers/angular/until-destroyed.mixin';
import { filter, withLatestFrom } from 'rxjs/operators';
import { filterObservable } from 'core-app/shared/helpers/rxjs/filterWith';
import { INotificationSetting } from 'core-app/features/user-preferences/state/notification-setting.model';
import { populateInputsFromDataset } from 'core-app/shared/components/dataset-inputs';

interface IReminderSettingsFormValue {
  immediateReminders:ImmediateRemindersSettings,
  dailyReminders:DailyRemindersSettings,
  pauseReminders:Partial<PauseRemindersSettings>,
  emailAlerts:Record<EmailAlertType, boolean>;
  workdays:boolean[];
}

@Component({
  templateUrl: './reminder-settings-page.component.html',
  styleUrls: ['./reminder-settings-page.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class ReminderSettingsPageComponent extends UntilDestroyedMixin implements OnInit {
  @Input() userId:string;

  public form = this.fb.group({
    immediateReminders: this.fb.group({
      mentioned: this.fb.control(false),
    }),
    dailyReminders: this.fb.group({
      enabled: this.fb.control(false),
      times: this.fb.array([]),
    }),
    pauseReminders: this.fb.group({
      enabled: this.fb.control(false),
      firstDay: this.fb.control(''),
      lastDay: this.fb.control(''),
    }),
    workdays: this.fb.array([
      this.fb.control(false),
      this.fb.control(true),
      this.fb.control(true),
      this.fb.control(true),
      this.fb.control(true),
      this.fb.control(true),
      this.fb.control(false),
    ]),
    emailAlerts: this.fb.group({
      newsAdded: this.fb.control(false),
      newsCommented: this.fb.control(false),
      documentAdded: this.fb.control(false),
      forumMessages: this.fb.control(false),
      wikiPageAdded: this.fb.control(false),
      wikiPageUpdated: this.fb.control(false),
      membershipAdded: this.fb.control(false),
      membershipUpdated: this.fb.control(false),
    }),
  });

  text = {
    title: this.I18n.t('js.reminders.settings.title'),
    save: this.I18n.t('js.button_save'),
  };

  formInitialized = false;

  constructor(
    readonly elementRef:ElementRef,
    readonly I18n:I18nService,
    readonly storeService:UserPreferencesService,
    readonly currentUserService:CurrentUserService,
    readonly fb:UntypedFormBuilder,
    readonly cdRef:ChangeDetectorRef,
  ) {
    super();
    populateInputsFromDataset(this);
  }

  ngOnInit():void {
    this
      .currentUserService
      .user$
      .pipe(take(1))
      .subscribe((user) => {
        this.userId = this.userId || user?.id as string;
        this.storeService.get(this.userId);
      });

    this.storeService.query.select()
      .pipe(
        filter((settings) => !!settings),
        withLatestFrom(this.storeService.query.globalNotification$),
        filterObservable(this.storeService.query.selectLoading(), (val) => !val),
      )
      .subscribe(([settings, globalSetting]) => {
        this.buildForm(settings, globalSetting);
      });
  }

  private buildForm(settings:IUserPreference, globalSetting:INotificationSetting) {
    this.form.get('immediateReminders.mentioned')?.setValue(settings.immediateReminders.mentioned);

    this.form.get('dailyReminders.enabled')?.setValue(settings.dailyReminders.enabled);

    this.form.get('pauseReminders')?.patchValue(settings.pauseReminders);

    const dailyReminderTimes = this.form.get('dailyReminders.times') as UntypedFormArray;
    dailyReminderTimes.clear({ emitEvent: false });
    [...settings.dailyReminders.times].sort().forEach((time) => {
      dailyReminderTimes.push(this.fb.control(time), { emitEvent: false });
    });

    dailyReminderTimes.enable({ emitEvent: true });

    const workdays = this.form.get('workdays') as UntypedFormArray;
    for (let i = 0; i <= 6; i++) {
      const control = workdays.at(i);
      control.setValue(settings.workdays.includes(i + 1));
    }

    emailAlerts.forEach((alert) => {
      this.form.get(`emailAlerts.${alert}`)?.setValue(globalSetting[alert]);
    });

    this.formInitialized = true;
    this.cdRef.detectChanges();
  }

  public saveChanges():void {
    const prefs = this.storeService.query.getValue();
    const globalNotifications = prefs.notifications.filter((notification) => !notification._links.project.href);
    const projectNotifications = prefs.notifications.filter((notification) => !!notification._links.project.href);
    const reminderSettings = (this.form.value as IReminderSettingsFormValue);
    const workdays = ReminderSettingsPageComponent.buildWorkdays(reminderSettings.workdays);
    const pauseReminders = ReminderSettingsPageComponent.buildPauses(reminderSettings.pauseReminders);
    const { dailyReminders, immediateReminders } = reminderSettings;

    this.storeService.update(this.userId, {
      ...prefs,
      workdays,
      dailyReminders,
      immediateReminders,
      pauseReminders,
      notifications: [
        ...globalNotifications.map((notification) => (
          {
            ...notification,
            ...reminderSettings.emailAlerts,
          }
        )),
        ...projectNotifications,
      ],
    });
  }

  private static buildWorkdays(formValues:boolean[]):number[] {
    return formValues
      .reduce(
        (result, val, index) => {
          if (val) {
            return result.concat([index + 1]);
          }

          return result;
        },
        [] as number[],
      );
  }

  private static buildPauses(formValues:Partial<PauseRemindersSettings>):Partial<PauseRemindersSettings> {
    if (formValues.enabled) {
      return formValues;
    }

    return { enabled: false };
  }
}
