import {
  ChangeDetectionStrategy,
  Component,
  OnInit,
} from '@angular/core';
import { I18nService } from 'core-app/core/i18n/i18n.service';
import { UserPreferencesService } from 'core-app/features/user-preferences/state/user-preferences.service';
import {
  UntypedFormGroup,
  FormGroupDirective,
} from '@angular/forms';

export type EmailAlertType =
  'newsAdded'|'newsCommented'|'documentAdded'|'forumMessages'|'wikiPageAdded'|
  'wikiPageUpdated'|'membershipAdded'|'membershipUpdated';

export const emailAlerts:EmailAlertType[] = [
  'newsAdded',
  'newsCommented',
  'documentAdded',
  'forumMessages',
  'wikiPageAdded',
  'wikiPageUpdated',
  'membershipAdded',
  'membershipUpdated',
];

@Component({
  selector: 'op-email-alerts-settings',
  templateUrl: './email-alerts-settings.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class EmailAlertsSettingsComponent implements OnInit {
  form:UntypedFormGroup;

  alerts:EmailAlertType[] = emailAlerts;

  text = {
    title: this.I18n.t('js.reminders.settings.alerts.title'),
    explanation: this.I18n.t('js.reminders.settings.alerts.explanation'),
    newsAdded: this.I18n.t('js.reminders.settings.alerts.news_added'),
    newsCommented: this.I18n.t('js.reminders.settings.alerts.news_commented'),
    documentAdded: this.I18n.t('js.reminders.settings.alerts.document_added'),
    forumMessages: this.I18n.t('js.reminders.settings.alerts.forum_messages'),
    wikiPageAdded: this.I18n.t('js.reminders.settings.alerts.wiki_page_added'),
    wikiPageUpdated: this.I18n.t('js.reminders.settings.alerts.wiki_page_updated'),
    membershipAdded: this.I18n.t('js.reminders.settings.alerts.membership_added'),
    membershipUpdated: this.I18n.t('js.reminders.settings.alerts.membership_updated'),
  };

  constructor(
    private I18n:I18nService,
    private storeService:UserPreferencesService,
    private rootFormGroup:FormGroupDirective,
  ) {
  }

  ngOnInit():void {
    this.form = this.rootFormGroup.control.get('emailAlerts') as UntypedFormGroup;
  }
}
