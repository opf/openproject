// noinspection ES6UnusedImports

import { ChangeDetectionStrategy, Component, Input, OnInit } from '@angular/core';
import { UntypedFormArray, UntypedFormControl, UntypedFormGroup } from '@angular/forms';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import idFromLink from 'core-app/features/hal/helpers/id-from-link';
import { HalSourceLink } from 'core-app/features/hal/resources/hal-resource';
import { BannersService } from 'core-app/core/enterprise/banners.service';
import { overDueReminderTimes, reminderAvailableTimeframes } from '../overdue-reminder-available-times';
import { ConfigurationService } from 'core-app/core/config/configuration.service';

@Component({
  selector: 'op-notification-settings-table',
  templateUrl: './notification-settings-table.component.html',
  styleUrls: ['./notification-settings-table.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class NotificationSettingsTableComponent implements OnInit {
  @Input() userId:string;

  @Input() settings:UntypedFormArray;

  public eeShowBanners = false;

  public availableTimes = [
    {
      value: null,
      title: this.I18n.t('js.notifications.settings.reminders.no_notification'),
    },
    ...reminderAvailableTimeframes(),
  ];

  public availableTimesOverdue = [
    {
      value: null,
      title: this.I18n.t('js.notifications.settings.reminders.no_notification'),
    },
    ...overDueReminderTimes(),
  ];

  text = {
    notify_me: this.I18n.t('js.notifications.settings.notify_me'),
    save: this.I18n.t('js.button_save'),
    mentioned_header: {
      title: this.I18n.t('js.notifications.settings.reasons.mentioned.title'),
      description: this.I18n.t('js.notifications.settings.reasons.mentioned.description'),
    },
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
    assignee: this.I18n.t('js.notifications.settings.reasons.assignee'),
    responsible: this.I18n.t('js.notifications.settings.reasons.responsible'),
    shared: this.I18n.t('js.notifications.settings.reasons.shared'),
    watched_header: this.I18n.t('js.notifications.settings.reasons.watched'),
    work_package_commented_header: this.I18n.t('js.notifications.settings.reasons.work_package_commented'),
    work_package_created_header: this.I18n.t('js.notifications.settings.reasons.work_package_created'),
    work_package_processed_header: this.I18n.t('js.notifications.settings.reasons.work_package_processed'),
    work_package_prioritized_header: this.I18n.t('js.notifications.settings.reasons.work_package_prioritized'),
    work_package_scheduled_header: this.I18n.t('js.notifications.settings.reasons.work_package_scheduled'),
    remove_project_settings: this.I18n.t('js.notifications.settings.project_specific.remove'),
    startDate: this.I18n.t('js.work_packages.properties.startDate'),
    dueDate: this.I18n.t('js.work_packages.properties.dueDate'),
    overdue: this.I18n.t('js.notifications.settings.global.overdue'),
  };

  constructor(
    private I18n:I18nService,
    private pathHelper:PathHelperService,
    readonly bannersService:BannersService,
    readonly configurationService:ConfigurationService,
  ) {}

  ngOnInit():void {
    this.eeShowBanners = this.bannersService.eeShowBanners;
  }

  projectLink(href:string) {
    return this.pathHelper.projectPath(idFromLink(href));
  }

  addProjectSettings(project:HalSourceLink):void {
    this.settings.push(new UntypedFormGroup({
      project: new UntypedFormControl(project),
      assignee: new UntypedFormControl(false),
      responsible: new UntypedFormControl(false),
      shared: new UntypedFormControl(false),
      workPackageCreated: new UntypedFormControl(false),
      workPackageProcessed: new UntypedFormControl(false),
      workPackageScheduled: new UntypedFormControl(false),
      workPackagePrioritized: new UntypedFormControl(false),
      workPackageCommented: new UntypedFormControl(false),
      startDate: new UntypedFormControl(this.availableTimes[2].value),
      dueDate: new UntypedFormControl(this.availableTimes[2].value),
      overdue: new UntypedFormControl(this.availableTimesOverdue[0].value),
    }));
  }

  removeProjectSettings(index:number):void {
    this.settings.removeAt(index);
  }
}
