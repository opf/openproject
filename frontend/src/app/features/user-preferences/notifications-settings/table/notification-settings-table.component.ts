// noinspection ES6UnusedImports

import {
  Component,
  ChangeDetectionStrategy,
  Input,
} from '@angular/core';
import { FormArray, FormGroup, FormControl } from '@angular/forms';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import idFromLink from 'core-app/features/hal/helpers/id-from-link';
import { HalSourceLink } from 'core-app/features/hal/resources/hal-resource';
import { OVERDUE_REMINDER_AVAILABLE_TIMEFRAMES, REMINDER_AVAILABLE_TIMEFRAMES } from '../overdue-reminder-available-times';

@Component({
  selector: 'op-notification-settings-table',
  templateUrl: './notification-settings-table.component.html',
  styleUrls: ['./notification-settings-table.component.sass'],
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class NotificationSettingsTableComponent {
  @Input() userId:string;

  @Input() settings:FormArray;

  public availableTimes = [
    {
      // null is not handled well by angular as a option value, it will always return a string.
      // We might as well make this obvious
      value: "null",
      title: this.I18n.t('js.notifications.settings.reminders.no_notification'),
    },
    ...REMINDER_AVAILABLE_TIMEFRAMES,
  ];
  public availableTimesOverdue = [
    {
      // null is not handled well by angular as a option value, it will always return a string.
      // We might as well make this obvious
      value: "null",
      title: this.I18n.t('js.notifications.settings.reminders.no_notification'),
    },
    ...OVERDUE_REMINDER_AVAILABLE_TIMEFRAMES,
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
    assignee: this.I18n.t('js.notifications.settings.reasons.assignee'),
    responsible: this.I18n.t('js.notifications.settings.reasons.responsible'),
    watched_header: this.I18n.t('js.notifications.settings.reasons.watched'),
    work_package_commented_header: this.I18n.t('js.notifications.settings.reasons.work_package_commented'),
    work_package_created_header: this.I18n.t('js.notifications.settings.reasons.work_package_created'),
    work_package_processed_header: this.I18n.t('js.notifications.settings.reasons.work_package_processed'),
    work_package_prioritized_header: this.I18n.t('js.notifications.settings.reasons.work_package_prioritized'),
    work_package_scheduled_header: this.I18n.t('js.notifications.settings.reasons.work_package_scheduled'),
    remove_project_settings: this.I18n.t('js.notifications.settings.project_specific.remove'),
  };

  constructor(
    private I18n:I18nService,
    private pathHelper:PathHelperService,
  ) {}

  projectLink(href:string) {
    return this.pathHelper.projectPath(idFromLink(href));
  }

  addProjectSettings(project:HalSourceLink):void {
    this.settings.push(new FormGroup({
      project: new FormControl(project),
      assignee: new FormControl(false),
      responsible: new FormControl(false),
      workPackageCreated: new FormControl(false),
      workPackageProcessed: new FormControl(false),
      workPackageScheduled: new FormControl(false),
      workPackagePrioritized: new FormControl(false),
      workPackageCommented: new FormControl(false),
      startDate: new FormControl(this.availableTimes[2].value),
      dueDate: new FormControl(this.availableTimes[2].value),
      overdue: new FormControl(this.availableTimes[1].value),
    }));
  }

  removeProjectSettings(index:number):void {
    this.settings.removeAt(index);
  }
}
